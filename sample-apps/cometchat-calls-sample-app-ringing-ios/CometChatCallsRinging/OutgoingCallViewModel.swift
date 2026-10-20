import Foundation
import CometChatCallsSDK

// MARK: - OutgoingCallViewModel

/// Places a call to a user or a whole group and drives the "Calling… / Ringing…" screen until
/// someone accepts it or it is over.
///
/// Every decision lives in `OutgoingCall`; this type only feeds it (the `initiateCall` result,
/// the SDK's participant and session events, the end button, the ring timer) and renders what it
/// says. Each input reports whether it moved the state, so the side effects below — arming the
/// timer, calling `endCall`, dismissing — hang off the return value and need no guards of their
/// own. That is also the double-tap protection.
///
/// When the callee accepts, `callSessionViewModel` becomes non-nil and `OutgoingCallView` swaps
/// in `CallSessionView`, which joins by session ID and so takes over the session `initiateCall`
/// prepared.
final class OutgoingCallViewModel: ObservableObject {

    // MARK: - Callee

    let calleeUID: String
    let calleeName: String
    let calleeAvatarURL: String?
    /// `CallSessionType.audio` or `CallSessionType.video`.
    let callType: String
    /// Rings every member of the group `calleeUID` names, rather than one user.
    let isGroup: Bool

    var isVideo: Bool { callType == CallSessionType.video }

    /// A 1:1 call ends for both sides when either leaves; a group call outlives any one member.
    var isPeerCall: Bool { !isGroup }

    var header: String {
        switch (isGroup, isVideo) {
        case (true, true): return "Group video call"
        case (true, false): return "Group voice call"
        case (false, true): return "Video call"
        case (false, false): return "Voice call"
        }
    }

    // MARK: - Published

    /// The status line under the callee's name; empty while there is nothing to say.
    @Published private(set) var statusText: String = ""

    /// Whether the end button is live. False until the call exists on the server: there is no
    /// session ID to cancel before that.
    @Published private(set) var canCancel: Bool = false

    /// Non-nil once the callee accepted — the call screen for the session that was just joined.
    @Published private(set) var callSessionViewModel: CallSessionViewModel?

    /// Flipped when the screen has said what it had to say and should go away.
    @Published private(set) var shouldDismiss: Bool = false

    // MARK: - State

    private let call = OutgoingCall()

    /// Plain `NSObject` for the SDK's `@objc` listener protocols; see `CallSessionViewModel`.
    private var listenerDelegate: OutgoingCallListenerDelegate?

    private var ringTimeoutWork: DispatchWorkItem?
    private var ringPollWork: DispatchWorkItem?
    private var dismissWork: DispatchWorkItem?
    /// Set once the screen is gone, so a late `initiateCall` reply knows the call it just created
    /// has to be withdrawn.
    private var isScreenGone = false
    private var didStart = false

    /// How long a final status line ("No answer", "Declined", …) stays before the screen goes.
    private let endTextDelay: TimeInterval = 1.5

    // MARK: - Init

    init(calleeUID: String, calleeName: String, calleeAvatarURL: String?, callType: String, isGroup: Bool = false) {
        self.calleeUID = calleeUID
        self.calleeName = calleeName
        self.calleeAvatarURL = calleeAvatarURL
        self.callType = callType
        self.isGroup = isGroup
    }

    deinit {
        removeListeners()
        ringTimeoutWork?.cancel()
        ringPollWork?.cancel()
        dismissWork?.cancel()
    }

    // MARK: - Placing the Call

    /// Places the call. On success the callee is ringing: the end button becomes live and the
    /// ring timer is armed. On error nothing exists on the server, so "Call failed" shows briefly.
    ///
    /// `initiateCall` also prepares the session on `CallSession.shared` in the background; the
    /// callee accepting shows up there as `onParticipantJoined`, and the far side ending the call
    /// as `onConnectionClosed`.
    ///
    /// Guarded against a second `onAppear`, which would ring the callee twice.
    func start() {
        guard !didStart else { return }
        didStart = true

        call.onTransition = { from, to in
            print("[OutgoingCallViewModel] \(from) -> \(to)")
        }

        addListeners()
        render()

        let options = InitiateCallOptions()
        options.type = callType
        options.receiverType = isGroup ? CallReceiverType.group : CallReceiverType.user
        // Frozen on the prepared session: the join after an accept runs with these.
        options.sessionSettings = CallSettings.make(title: calleeName, isVideoCall: isVideo, isPeerCall: isPeerCall)

        print("[OutgoingCallViewModel] Calling \(calleeUID) (\(callType))")
        CometChatCalls.initiateCall(receiver: calleeUID, options: options) { [weak self] initiatedCall in
            let sessionID = initiatedCall.sessionId
            DispatchQueue.main.async {
                guard let self, !self.isScreenGone else {
                    // The screen went away before the call existed. Withdraw it now, or the callee
                    // rings for a call nobody is waiting on.
                    OutgoingCallViewModel.withdraw(sessionID: sessionID)
                    return
                }
                guard self.call.initiated(sessionId: sessionID) else { return }
                self.armRingTimeout()
                self.startRingStatusPoll(sessionID: sessionID)
                self.render()
            }
        } onError: { [weak self] error in
            print("[OutgoingCallViewModel] initiateCall failed: \(error?.errorDescription ?? "unknown")")
            DispatchQueue.main.async {
                guard let self, !self.isScreenGone, self.call.initiateFailed() else { return }
                self.render()
                self.dismissAfterEndText()
            }
        }
    }

    // MARK: - Ending the Call

    /// The end button: the caller gives up while the callee is still ringing.
    func cancelTapped() {
        end(reason: .cancelled)
    }

    /// The screen is gone, whichever way it went. A dismissal that did not come from the end
    /// button would otherwise leave the callee ringing, so it withdraws the call too.
    func screenDismissed() {
        isScreenGone = true
        ringTimeoutWork?.cancel()
        ringPollWork?.cancel()
        dismissWork?.cancel()
        removeListeners()
        if call.cancel(), let sessionID = call.sessionId {
            OutgoingCallViewModel.withdraw(sessionID: sessionID)
        }
    }

    /// The end button (`cancelled`) or the ring timer (`timeout`). Ignored unless the call is
    /// ringing: before that there is no session ID, after a join the call UI owns the call.
    private func end(reason: OutgoingCall.EndReason) {
        let changed = reason == .timeout ? call.timeout() : call.cancel()
        guard changed, let sessionID = call.sessionId else { return }

        ringTimeoutWork?.cancel()
        OutgoingCallViewModel.withdraw(sessionID: sessionID)
        render()

        if reason == .timeout {
            dismissAfterEndText() // let "No answer" show
        } else {
            shouldDismiss = true
        }
    }

    /// Tells the server the call is withdrawn, which reaches the callee as a cancelled call and
    /// stops their ringing. The SDK tears the prepared session down itself first.
    ///
    /// Fire-and-forget: losing the race to the far side hanging up fails harmlessly.
    private static func withdraw(sessionID: String) {
        CometChatCalls.endCall(sessionID: sessionID, status: EndCallStatus.cancelled) {
            print("[OutgoingCallViewModel] Withdrew \(sessionID)")
        } onError: { error in
            print("[OutgoingCallViewModel] endCall failed: \(error?.errorDescription ?? "unknown")")
        }
    }

    // MARK: - SDK Events

    /// The callee's device prepared the session: "Calling…" becomes "Ringing…".
    fileprivate func participantConnected() {
        guard call.participantConnected() else { return }
        render()
    }

    /// The callee accepted — the only acceptance signal. The session's events now belong to the
    /// call screen, which registers its own listeners.
    fileprivate func participantJoined() {
        guard call.participantJoined(), let sessionID = call.sessionId else { return }
        ringTimeoutWork?.cancel()
        ringPollWork?.cancel()
        removeListeners()
        render()

        callSessionViewModel = CallSessionViewModel(
            sessionId: sessionID,
            title: calleeName,
            isVideoCall: isVideo,
            isPeerCall: isPeerCall
        )
    }

    /// The prepared session went away. The close carries no reason, so ask the server why before
    /// saying anything. Before the call even existed there is nothing to say.
    fileprivate func connectionClosed() {
        if call.isRinging, let sessionID = call.sessionId {
            fetchServerCallStatus(sessionID: sessionID) { [weak self] status in
                self?.applyClose(serverStatus: status)
            }
        } else if !call.isEnded {
            shouldDismiss = true
        }
    }

    private func applyClose(serverStatus: String?) {
        guard !isScreenGone, call.closedWithServerStatus(serverStatus) else { return }
        ringTimeoutWork?.cancel()
        // Our own connection failed while the callee may be ringing from the push.
        if call.needsServerEnd, let sessionID = call.sessionId {
            OutgoingCallViewModel.withdraw(sessionID: sessionID)
        }
        render()
        dismissAfterEndText()
    }

    // MARK: - Server Status

    /// How often a ringing call asks the server whether it is still ringing.
    private static let ringStatusPoll: TimeInterval = 3

    /// The callee's decline reaches the server at once, but nothing pushes it to the caller, so a
    /// ringing caller polls the server's call log for it.
    private func startRingStatusPoll(sessionID: String) {
        ringPollWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.call.isRinging, !self.isScreenGone else { return }
            self.fetchServerCallStatus(sessionID: sessionID) { [weak self] status in
                guard let self, !self.isScreenGone else { return }
                if self.call.serverEnded(status) {
                    self.ringTimeoutWork?.cancel()
                    self.render()
                    self.dismissAfterEndText()
                } else if self.call.isRinging {
                    self.startRingStatusPoll(sessionID: sessionID)
                }
            }
        }
        ringPollWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.ringStatusPoll, execute: work)
    }

    /// How long to wait on the server before giving up on its answer.
    private static let serverStatusTimeout: TimeInterval = 1.5

    /// The server's status for `sessionID` from the newest call logs, or `nil` when it is not
    /// found, the request fails or it takes longer than `serverStatusTimeout`. Delivered once, on
    /// the main queue.
    private func fetchServerCallStatus(sessionID: String, completion: @escaping (String?) -> Void) {
        var delivered = false
        let deliver: (String?) -> Void = { status in
            DispatchQueue.main.async {
                guard !delivered else { return }
                delivered = true
                completion(status)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.serverStatusTimeout) { deliver(nil) }

        CallLogsRequest.CallLogsBuilder().set(limit: 5).build().fetchNext { logs in
            guard let log = logs.first(where: { $0.sessionID == sessionID }) else {
                deliver(nil)
                return
            }
            switch log.status {
            case .rejected: deliver("rejected")
            case .busy: deliver("busy")
            default: deliver(nil)
            }
        } onError: { _ in
            deliver(nil)
        }
    }

    // MARK: - Rendering

    private func render() {
        canCancel = call.canCancel
        statusText = Self.statusString(for: call.statusText)
    }

    private static func statusString(for status: OutgoingCall.StatusText) -> String {
        switch status {
        case .calling: return "Calling…"
        case .ringing: return "Ringing…"
        case .noAnswer: return "No answer"
        case .failed: return "Call failed"
        case .ended: return "Call ended"
        case .declined: return "Declined"
        case .busy: return "Busy"
        case .none: return ""
        }
    }

    // MARK: - Timers

    private func armRingTimeout() {
        ringTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.end(reason: .timeout)
        }
        ringTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + OutgoingCall.ringTimeout, execute: work)
    }

    private func dismissAfterEndText() {
        dismissWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.shouldDismiss = true
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + endTextDelay, execute: work)
    }

    // MARK: - Listeners

    private func addListeners() {
        guard listenerDelegate == nil else { return }
        let delegate = OutgoingCallListenerDelegate(viewModel: self)
        listenerDelegate = delegate
        CallSession.shared.addSessionStatusListener(delegate)
        CallSession.shared.addParticipantEventListener(delegate)
    }

    private func removeListeners() {
        guard let delegate = listenerDelegate else { return }
        CallSession.shared.removeSessionStatusListener(delegate)
        CallSession.shared.removeParticipantEventListener(delegate)
        listenerDelegate = nil
    }
}

// MARK: - OutgoingCallListenerDelegate

/// Forwards the events an outgoing call turns on: the callee's device preparing the session, the
/// callee accepting, and the session going away.
private final class OutgoingCallListenerDelegate: NSObject, SessionStatusListener, ParticipantEventListener {

    private weak var viewModel: OutgoingCallViewModel?

    init(viewModel: OutgoingCallViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    func onParticipantConnected(participant: Participant) {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.participantConnected() }
    }

    func onParticipantJoined(participant: Participant) {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.participantJoined() }
    }

    func onConnectionClosed() {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.connectionClosed() }
    }
}
