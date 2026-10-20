import Foundation
import UIKit
import CometChatCallsSDK
import CometChatPushNotificationsCalls

// MARK: - CallSettings

/// Builds the session settings for a call.
///
/// The caller and the call screen must build the *same* settings: `initiateCall` freezes them on
/// the session it prepares, and the `joinSession` that follows ignores the ones it is given.
/// Keeping one builder makes the two sides impossible to drift.
enum CallSettings {
    /// - Parameters:
    ///   - isVideoCall: `false` joins an audio call with the camera off and no camera button.
    ///   - isPeerCall: `true` for a 1:1 call, so the session ends for both parties as soon as
    ///     either one leaves.
    static func make(title: String, isVideoCall: Bool, isPeerCall: Bool) -> SessionSettingsBuilder.SessionSettings {
        SessionSettingsBuilder()
            .setTitle(title)
            .setSessionType(isVideoCall ? .video : .voice)
            .startVideoPaused(!isVideoCall)
            .startAudioMuted(false)
            .setAudioMode(.speaker)
            .setPeerCall(isPeerCall)
            .hideChatButton(true)
            .hideShareInviteButton(true)
            .enableIOSPictureInPicture(true)
            .build()
    }
}

// MARK: - CallSessionViewModel

/// One joined call: the caller's after the callee accepted, or the callee's after answering.
final class CallSessionViewModel: ObservableObject {

    let sessionId: String
    let title: String
    let isVideoCall: Bool
    let isPeerCall: Bool

    @Published var showReconnecting = false
    @Published var shouldDismiss = false

    /// Plain `NSObject` for the SDK's `@objc` listener protocols, which the SDK stores weakly.
    /// Kept out of this `ObservableObject` because Combine's `@Published` wrappers break
    /// Objective-C weak references to the object holding them.
    private var listenerDelegate: CallSessionListenerDelegate?
    private var didCleanUp = false

    init(sessionId: String, title: String, isVideoCall: Bool, isPeerCall: Bool) {
        self.sessionId = sessionId
        self.title = title
        self.isVideoCall = isVideoCall
        self.isPeerCall = isPeerCall
    }

    deinit {
        removeListeners()
    }

    // MARK: - Join

    /// Joins by session ID, which takes over the session that was prepared while the call rang —
    /// by `initiateCall` on the caller's side, by the push SDK on the callee's.
    func joinSession(container: UIView) {
        let delegate = CallSessionListenerDelegate(viewModel: self)
        listenerDelegate = delegate
        CallSession.shared.addSessionStatusListener(delegate)
        CallSession.shared.addButtonClickListener(delegate)

        CometChatCalls.joinSession(
            sessionID: sessionId,
            callSetting: CallSettings.make(title: title, isVideoCall: isVideoCall, isPeerCall: isPeerCall),
            container: container
        ) { [weak self] _ in
            guard let self else { return }
            print("[CallSessionViewModel] Joined \(self.sessionId)")
            // Puts the call on CallKit so it survives a cellular interruption, shows in Recents
            // and can be ended from the lock screen. Both are no-ops for an answered incoming
            // call, which the push SDK already has on CallKit.
            CometChatPushNotificationsCalls.reportOutgoingCall(
                sessionId: self.sessionId,
                calleeName: self.title,
                hasVideo: self.isVideoCall
            )
            CometChatPushNotificationsCalls.reportCallConnected(sessionId: self.sessionId)
        } onError: { [weak self] error in
            print("[CallSessionViewModel] Join failed: \(error?.errorDescription ?? "unknown")")
            DispatchQueue.main.async { self?.cleanUp() }
        }
    }

    // MARK: - Leave

    func leaveSession() {
        CallSession.shared.leave()
        cleanUp()
    }

    // MARK: - Picture in Picture

    func enterPiP() {
        CallSession.shared.enablePictureInPictureLayout()
    }

    func exitPiP() {
        CallSession.shared.disablePictureInPictureLayout()
    }

    // MARK: - Cleanup

    /// Runs once, however the call ended: the leave button, the far side leaving, or a failed join.
    fileprivate func cleanUp() {
        guard !didCleanUp else { return }
        didCleanUp = true
        // Ends the CallKit call; a no-op when it ended from CallKit in the first place.
        CometChatPushNotificationsCalls.reportCallEnded(sessionId: sessionId)
        removeListeners()
        // Re-initialize the Calls SDK so the next call starts from a clean state.
        AppState.initializeCallsSDK { success in
            print("[CallSessionViewModel] Calls SDK re-initialized after the call: \(success)")
        }
        shouldDismiss = true
    }

    private func removeListeners() {
        guard let delegate = listenerDelegate else { return }
        CallSession.shared.removeSessionStatusListener(delegate)
        CallSession.shared.removeButtonClickListener(delegate)
        listenerDelegate = nil
    }
}

// MARK: - CallSessionListenerDelegate

private final class CallSessionListenerDelegate: NSObject, SessionStatusListener, ButtonClickListener {

    /// Swift weak reference (not the Objective-C one the SDK uses), so it is safe to point at an
    /// `ObservableObject`.
    private weak var viewModel: CallSessionViewModel?

    init(viewModel: CallSessionViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    // MARK: SessionStatusListener

    func onConnectionLost() {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.showReconnecting = true }
    }

    func onConnectionRestored() {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.showReconnecting = false }
    }

    func onSessionLeft() {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.cleanUp() }
    }

    func onConnectionClosed() {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.cleanUp() }
    }

    func onSessionTimedOut() {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.cleanUp() }
    }

    // MARK: ButtonClickListener

    func onLeaveSessionButtonClicked() {
        DispatchQueue.main.async { [weak self] in self?.viewModel?.leaveSession() }
    }
}
