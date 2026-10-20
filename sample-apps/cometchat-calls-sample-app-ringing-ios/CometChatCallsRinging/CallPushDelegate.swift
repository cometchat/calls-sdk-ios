import Foundation
import CometChatPushNotificationsSwift
import CometChatPushNotificationsCalls

// MARK: - CallPushDelegate

/// The push SDK's delegate, and nothing else.
///
/// Deliberately a bare `NSObject` that forwards to `IncomingCallPresenter` rather than being the
/// presenter: `CometChatPushNotifications.shared.delegate` is an Objective-C weak reference, and
/// an object carrying Combine's `@Published` properties interferes with it. The presenter keeps
/// its `@Published` call screen; this keeps the `@objc` conformance.
final class CallPushDelegate: NSObject, CometChatPushNotificationsCallsDelegate {

    // MARK: - Calls

    /// The user answered, and the SDK has already accepted the call on CallKit's side.
    ///
    /// Fires in every app state — foreground, background, launched by the push and locked — so
    /// the join starts while the phone may still be locked. Returning `false` tells the SDK nobody
    /// can take the call, and it ends the CallKit call rather than leaving one with nothing behind it.
    func presentCall(_ call: IncomingCall) -> Bool {
        IncomingCallPresenter.shared.answered(call)
        return true
    }

    /// The call is over. Never `.answered` — that is not an ending.
    func callDidEnd(_ call: IncomingCall, reason: CallEndReason) {
        print("[CallPushDelegate] Call \(call.sessionId) ended: \(reason.rawString)")
        IncomingCallPresenter.shared.ended(sessionId: call.sessionId)
    }

    // MARK: - Tokens

    func onPushTokenRegistered(platform: CometChatPushTokenPlatform) {
        print("[CallPushDelegate] \(platform.rawName) token registered")
    }

    /// The fastest way to catch a wrong provider ID or a missing Push Notifications capability.
    func onPushTokenRegistrationFailed(platform: CometChatPushTokenPlatform, error: PNError) {
        print("[CallPushDelegate] \(platform.rawName) token registration failed: \(error)")
    }
}
