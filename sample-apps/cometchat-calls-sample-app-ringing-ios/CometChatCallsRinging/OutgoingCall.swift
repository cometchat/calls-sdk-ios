import Foundation

// MARK: - OutgoingCall

/// State of one outgoing 1:1 call, from the tap on a Users row until the call is joined or over.
///
/// Deliberately free of SwiftUI and of the Calls SDK so it can be unit-tested on its own:
/// `OutgoingCallViewModel` feeds it SDK callbacks and user actions and renders whatever it says.
///
/// Every input is idempotent and returns `true` only when it actually moved the state, so a
/// duplicate SDK event or a double-tapped button changes nothing and the caller can key its side
/// effects — arming the ring timer, calling `endCall`, dismissing the screen — on the return
/// value instead of guarding at each call site.
///
/// ```
/// initiating ──initiated(id)──▶ ringing ──participantJoined──▶ joined
///     │                           │
///     └──initiateFailed──▶ ended(.failed)
///                                 ├──cancel──────────▶ ended(.cancelled)
///                                 ├──timeout─────────▶ ended(.timeout)
///                                 └──closedWithServerStatus─▶ ended(.declined / .busy)  the server said why
///                                                           or ended(.closed)   far side ended it
///                                                    or ended(.lost)     our own connection failed
/// ```
///
/// `initiating` has no session ID yet, so nothing can be cancelled from it: the red button stays
/// disabled until `initiated(sessionId:)`, and a timeout cannot start before then either.
///
/// Every accepted input goes through `transition(to:)`, which reports the old and new state to
/// `onTransition`; rejected inputs never reach it. The view model uses this to log every state
/// change in one place, so one log line per ring covers the whole call.
final class OutgoingCall {

    // MARK: - State

    enum State: Equatable, CustomStringConvertible {
        /// `initiateCall` is in flight; no session ID yet.
        case initiating

        /// The call exists and the callee's device is ringing. `remoteConnected` flips on
        /// `onParticipantConnected`.
        case ringing(sessionId: String, remoteConnected: Bool)

        /// The callee accepted and the session has been joined.
        case joined(sessionId: String)

        /// Terminal. `sessionId` is `nil` when the call never got past `initiating`.
        case ended(sessionId: String?, reason: EndReason)

        var description: String {
            switch self {
            case .initiating:
                return "initiating"
            case let .ringing(sessionId, remoteConnected):
                return "ringing(\(sessionId), remoteConnected: \(remoteConnected))"
            case let .joined(sessionId):
                return "joined(\(sessionId))"
            case let .ended(sessionId, reason):
                return "ended(\(sessionId ?? "-"), \(reason))"
            }
        }
    }

    /// Why the call ended. `closed` is the far side ending it (the server destroyed the room the
    /// callee had connected to); `lost` is the session closing before any callee device connected,
    /// which is our own prepare failing — the server and the callee know nothing about it.
    /// `declined` and `busy` are the callee declining it, as the server recorded the outcome.
    enum EndReason: String {
        case cancelled
        case timeout
        case failed
        case closed
        case lost
        case declined
        case busy
    }

    /// What the status line should say. The view model maps these to user-facing strings, so
    /// this type stays free of copy.
    enum StatusText {
        case calling
        case ringing
        case noAnswer
        case failed
        case ended
        case declined
        case busy
        case none
    }

    // MARK: - Properties

    private(set) var state: State = .initiating

    /// Called after each accepted input, once `state` already holds the new value.
    var onTransition: ((_ from: State, _ to: State) -> Void)?

    var sessionId: String? {
        switch state {
        case .initiating: return nil
        case let .ringing(sessionId, _): return sessionId
        case let .joined(sessionId): return sessionId
        case let .ended(sessionId, _): return sessionId
        }
    }

    /// The red button is live only while ringing: before that there is nothing to cancel, after
    /// it the SDK's own call UI owns the call.
    var canCancel: Bool { isRinging }

    var isRinging: Bool {
        if case .ringing = state { return true }
        return false
    }

    var isJoined: Bool {
        if case .joined = state { return true }
        return false
    }

    var isEnded: Bool {
        if case .ended = state { return true }
        return false
    }

    var statusText: StatusText {
        switch state {
        case .initiating:
            return .calling
        case let .ringing(_, remoteConnected):
            return remoteConnected ? .ringing : .calling
        case .joined:
            return .none
        case let .ended(_, reason):
            switch reason {
            case .cancelled: return .none
            case .timeout: return .noAnswer
            case .failed, .lost: return .failed
            case .closed: return .ended
            case .declined: return .declined
            case .busy: return .busy
            }
        }
    }

    // MARK: - Inputs

    /// `initiateCall` succeeded. Only meaningful from `initiating`.
    @discardableResult
    func initiated(sessionId: String) -> Bool {
        guard case .initiating = state else { return false }
        transition(to: .ringing(sessionId: sessionId, remoteConnected: false))
        return true
    }

    /// `initiateCall` failed: nothing exists on the server, so this ends the call outright.
    @discardableResult
    func initiateFailed() -> Bool {
        guard case .initiating = state else { return false }
        transition(to: .ended(sessionId: nil, reason: .failed))
        return true
    }

    /// The callee's device prepared the session (`onParticipantConnected`): "Calling…" becomes
    /// "Ringing…".
    @discardableResult
    func participantConnected() -> Bool {
        guard case let .ringing(sessionId, remoteConnected) = state, !remoteConnected else { return false }
        transition(to: .ringing(sessionId: sessionId, remoteConnected: true))
        return true
    }

    /// The callee accepted (`onParticipantJoined`).
    @discardableResult
    func participantJoined() -> Bool {
        guard case let .ringing(sessionId, _) = state else { return false }
        transition(to: .joined(sessionId: sessionId))
        return true
    }

    /// The prepared session went away while ringing (`onConnectionClosed`). Ignored once joined —
    /// the SDK's own call UI handles the end of a live call — and before `initiated(sessionId:)`,
    /// when there is no session to close.
    ///
    /// Once the callee's device has connected to the room (`participantConnected()`), a close is
    /// the server destroying that room: the far side rejected, was busy, or did not answer
    /// (`.closed`). A close before the callee's device connected is our own prepare failing
    /// (`.lost`, for example when the caller could not reach the room's host):
    /// the callee's phone may already be ringing from the push and the server still holds the
    /// call, so the caller must end it (`needsServerEnd`).
    ///
    /// The SDK gives the caller no event for its own connection reaching the room (`onConnected`
    /// fires only for an explicit `connect()`), so the callee connecting is the evidence. A far
    /// side that declines before its device connects is also counted as `.lost`; the extra
    /// `endCall` then lands on a call that is already over and is refused, which is harmless.
    @discardableResult
    func connectionClosed() -> Bool {
        guard case let .ringing(sessionId, remoteConnected) = state else { return false }
        transition(to: .ended(sessionId: sessionId, reason: remoteConnected ? .closed : .lost))
        return true
    }

    /// The call ended in a way only this device knows about, so the view model must send
    /// `endCall` to stop the callee ringing. `cancel()` and `timeout()` already do so at their own
    /// call site; this covers `.lost`.
    var needsServerEnd: Bool {
        if case .ended(_, .lost) = state { return true }
        return false
    }

    /// The callee declined the call while it rang, as the server recorded it:
    /// `rejected` is "Declined", `busy` is "Busy". Ending the call here also keeps a decline
    /// from being mistaken for `.lost`, so no second `endCall` goes out. Any other status is not
    /// the caller's to act on and is ignored; `closedWithServerStatus(_:)` is the only caller.
    @discardableResult
    func remoteEnded(status: String?) -> Bool {
        guard case let .ringing(sessionId, _) = state else { return false }
        let reason: EndReason
        switch status {
        case "rejected": reason = .declined
        case "busy": reason = .busy
        default: return false
        }
        transition(to: .ended(sessionId: sessionId, reason: reason))
        return true
    }

    /// The server says this call is already over, read while it was still ringing here.
    /// The callee's decline reaches the server at once, but nothing pushes it to
    /// the caller — the room announce is never delivered and no call message arrives — so the
    /// caller polls instead, as the callee already does.
    ///
    /// `rejected` / `busy` end it as `.declined` / `.busy`; any other terminal status ends it as
    /// `.closed`. Unlike `connectionClosed()` this never asks for a second `endCall`
    /// (`needsServerEnd`): the server is where the status came from, so it already knows.
    ///
    /// `initiated`, `ongoing` and a status that could not be read keep the call ringing — a
    /// failed request must never end a live call.
    @discardableResult
    func serverEnded(_ serverStatus: String?) -> Bool {
        guard case let .ringing(sessionId, _) = state,
              let status = serverStatus?.lowercased(),
              status != "initiated", status != "ongoing" else { return false }
        let reason: EndReason
        switch status {
        case "rejected": reason = .declined
        case "busy": reason = .busy
        default: reason = .closed
        }
        transition(to: .ended(sessionId: sessionId, reason: reason))
        return true
    }

    /// The prepared session closed while ringing. The close itself carries no reason, so the
    /// view model reads the call's status from the server and passes it here: `rejected` /
    /// `busy` end the call as `.declined` / `.busy`; anything else (or no answer from the
    /// server) is an ordinary `connectionClosed()`.
    @discardableResult
    func closedWithServerStatus(_ serverStatus: String?) -> Bool {
        remoteEnded(status: serverStatus) || connectionClosed()
    }

    /// The user tapped the red button. A no-op until there is a session ID to cancel.
    @discardableResult
    func cancel() -> Bool {
        guard case let .ringing(sessionId, _) = state else { return false }
        transition(to: .ended(sessionId: sessionId, reason: .cancelled))
        return true
    }

    /// The local ring timer expired. Ignored once joined or already over.
    @discardableResult
    func timeout() -> Bool {
        guard case let .ringing(sessionId, _) = state else { return false }
        transition(to: .ended(sessionId: sessionId, reason: .timeout))
        return true
    }

    // MARK: - Private

    private func transition(to newState: State) {
        let from = state
        state = newState
        onTransition?(from, newState)
    }

    // MARK: - Constants

    /// How long the caller waits for an answer before giving up with "No answer".
    ///
    /// No longer than the callee's ring timeout (the push SDK's `RingConstants.defaultRingTimeoutMs`):
    /// the caller must give up first so the callee's device does not keep ringing for a call the
    /// caller has already stopped waiting on.
    static let ringTimeout: TimeInterval = 45
}
