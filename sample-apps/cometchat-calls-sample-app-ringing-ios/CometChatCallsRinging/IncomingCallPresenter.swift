import Foundation
import Combine
import CometChatPushNotificationsCalls
import CometChatCallsSDK

// MARK: - IncomingCallPresenter

/// Turns an answered call into the call screen.
///
/// Receiving the VoIP push, ringing CallKit, preparing the session, answering and declining all
/// belong to the Push Notifications SDK. What is left is the one thing an app cannot delegate:
/// showing its own call screen. `CallPushDelegate.presentCall(_:)` is the single entry point.
///
/// The join is by session ID, which claims the session the SDK prepared while the phone was
/// ringing: only the media and the call UI are left to set up.
///
/// A singleton with a published property, because the answer arrives from CallKit — possibly in
/// a process the push launched moments ago that has not drawn anything yet. `HomeView` presents
/// whatever is published here, so the call screen comes up whenever the UI gets there.
final class IncomingCallPresenter: ObservableObject {

    // MARK: - Shared

    static let shared = IncomingCallPresenter()

    // MARK: - Published

    /// Non-nil once a call has been answered: the call screen for the session to join.
    @Published private(set) var callSessionViewModel: CallSessionViewModel?

    private init() {}

    // MARK: - Answering

    /// The user answered `call`. The SDK asks for the microphone itself; a denial joins muted
    /// rather than declining the call.
    func answered(_ call: IncomingCall) {
        // The SDK guarantees one `presentCall` per session; this only guards a screen that
        // outlived its call.
        if let existing = callSessionViewModel, existing.sessionId == call.sessionId { return }

        print("[IncomingCallPresenter] Answered \(call.sessionId)")
        let viewModel = CallSessionViewModel(
            sessionId: call.sessionId,
            title: call.callerName,
            isVideoCall: call.isVideo,
            isPeerCall: call.isPeerCall
        )
        DispatchQueue.main.async { [weak self] in self?.present(viewModel) }
    }

    /// Shows the call screen for `viewModel`, after any other call has let go of the Calls SDK.
    ///
    /// End & Accept on CallKit's call-waiting screen ends the live call and answers this one back
    /// to back. The Calls SDK holds one session at a time: joining while it is still leaving the
    /// old one fails. So the old screen comes down first and the join waits (up to
    /// `switchWaitLimit`) for the old session to go.
    private func present(_ viewModel: CallSessionViewModel) {
        let otherSessionUp = CometChatCalls.getActiveSession().map { $0.sessionId != viewModel.sessionId } ?? false
        guard callSessionViewModel != nil || otherSessionUp else {
            callSessionViewModel = viewModel
            return
        }
        print("[IncomingCallPresenter] Switching to \(viewModel.sessionId); waiting for the previous call to leave")
        callSessionViewModel = nil
        pendingViewModel = viewModel
        waitForPreviousSession(of: viewModel, startedAt: Date())
    }

    private func waitForPreviousSession(of viewModel: CallSessionViewModel, startedAt: Date) {
        guard pendingViewModel === viewModel else { return } // superseded or ended meanwhile
        let active = CometChatCalls.getActiveSession()
        let previousGone = active == nil || active?.sessionId == viewModel.sessionId || active?.isSessionActive() == false
        if previousGone || Date().timeIntervalSince(startedAt) > Self.switchWaitLimit {
            pendingViewModel = nil
            callSessionViewModel = viewModel
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.waitForPreviousSession(of: viewModel, startedAt: startedAt)
        }
    }

    /// How long a switch waits for the previous session before joining anyway.
    private static let switchWaitLimit: TimeInterval = 5

    /// The answered call waiting for the previous one to leave (End & Accept).
    private var pendingViewModel: CallSessionViewModel?

    // MARK: - Dismissal

    /// The SDK says the call is over: take the screen down. CallKit has already been told.
    func ended(sessionId: String) {
        if pendingViewModel?.sessionId == sessionId {
            DispatchQueue.main.async { [weak self] in self?.pendingViewModel = nil }
        }
        guard callSessionViewModel?.sessionId == sessionId else { return }
        if Thread.isMainThread {
            callSessionViewModel = nil
        } else {
            DispatchQueue.main.async { [weak self] in self?.callSessionViewModel = nil }
        }
    }

    /// The call screen went away on its own — the user hung up in the app, or the join failed.
    /// Reporting the end keeps CallKit in step; it is a no-op when the call is already gone.
    func dismiss() {
        guard let sessionId = callSessionViewModel?.sessionId else { return }
        callSessionViewModel = nil
        CometChatPushNotificationsCalls.reportCallEnded(sessionId: sessionId)
    }
}
