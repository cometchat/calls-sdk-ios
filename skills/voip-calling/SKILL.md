---
name: voip-calling
description: Ring the callee with CallKit in every app state (foreground, background, locked, killed) using the CometChat Push Notifications SDK 2.0 Calls product, which owns PushKit, CallKit, token registration and answer/decline. Use when setting up VoIP push, CallKit, the APNs provider, or debugging calls that don't ring. Triggers on "VoIP", "voip calling", "CallKit", "PushKit", "push notification call", "background call", "killed state", "not ringing".
inclusion: manual
---

# CometChat Calls SDK v5.1 — VoIP Calling (Push Notifications SDK 2.0)

## Overview

`CometChatPushNotificationsCalls` (Push Notifications SDK 2.0) owns the whole incoming side:

- PushKit registration and the VoIP token, registered at login and removed at logout
- Receiving the VoIP push, and reporting it to **CallKit** straight away (iOS requires this for every VoIP push)
- Preparing the call session while the phone rings
- Answer, decline and missed calls, plus busy handling and End & Accept

Your app sets it up once and shows its own call screen when the user answers. **Do not create your own `PKPushRegistry`, `CXProvider` or call `AVAudioSession.setActive`.**

## Prerequisites

- Calls SDK 5.1+ (ringing uses its prepared sessions — see the `ringing-integration` skill)
- SwiftPM: `https://github.com/cometchat/push-notifications-sdk-ios.git` from 2.0.0, product **`CometChatPushNotificationsCalls`**
- Xcode capabilities: **Push Notifications**; **Background Modes** → Audio, Voice over IP:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

- CometChat dashboard → Notifications → Push: an **APNs provider** using a `.p8` key. Its **Bundle ID must be your app's bundle ID**, because VoIP pushes go to the topic `<bundle id>.voip`.
  - **The provider's APNs environment must match the build.** Builds run from Xcode need "Enable Production Mode" off; TestFlight and App Store builds need it on. A mismatch makes APNs reject the push with a 400, and nothing rings.

## 1. Initialize in `didFinishLaunching`

It has to be there: iOS only delivers the VoIP push that launched a killed app if the PushKit registry exists by the time `didFinishLaunching` returns.

```swift
import CometChatPushNotificationsSwift
import CometChatPushNotificationsCalls

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let pushDelegate = CallPushDelegate()   // the SDK holds it weakly; keep it alive

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        CometChatPushNotifications.shared.delegate = pushDelegate
        CometChatPushNotifications.shared.initialize(
            config: PNConfiguration.builder(appId: APP_ID, region: REGION)
                .providerId(PROVIDER_ID)                    // required to register tokens
                .requestNotificationPermission(false)       // calls need no notification permission
                .callKit(name: "My App", iconTemplateImageName: nil, ringtone: nil,
                         includeInRecents: true, supportsVideo: true)
                .build()
        )
        return true
    }
}
```

If the app ID is only known after launch (entered by the user), initialize right after it is known. The configuration is fixed for the life of the process.

## 2. The delegate

```swift
final class CallPushDelegate: NSObject, CometChatPushNotificationsCallsDelegate {
    /// The user answered; CallKit already accepted. Show the call screen and join call.sessionId.
    func presentCall(_ call: IncomingCall) -> Bool {
        IncomingCallPresenter.shared.answered(call)   // publishes a screen; joins by session ID
        return true
    }

    func callDidEnd(_ call: IncomingCall, reason: CallEndReason) {
        IncomingCallPresenter.shared.ended(sessionId: call.sessionId)
    }

    func onPushTokenRegistered(platform: CometChatPushTokenPlatform) { }
    func onPushTokenRegistrationFailed(platform: CometChatPushTokenPlatform, error: PNError) {
        // Wrong provider ID or a missing capability shows up here first
    }
}
```

`IncomingCall` carries `sessionId`, `callerName`, `callerAvatarUrl`, `isVideo` and `isPeerCall` (false for a group call).

## 3. Tokens: login and logout

The SDK registers the VoIP token when the user logs in to the Chat or Calls SDK. Before logging out, **wait** for the token to be removed. The request is authenticated by the session you are about to end:

```swift
CometChatPushNotifications.shared.unregisterTokens(completion: { (result: PNResult<Void>) in
    CometChatCalls.logout(onSuccess: { _ in }, onError: { _ in })
    CometChat.logout(onSuccess: { _ in }, onError: { _ in })
})
```

If you don't wait, the device keeps ringing for the user who left.

## 4. Keep CallKit in step with your call screen

```swift
// After joining an OUTGOING call (no-op for an answered incoming one):
CometChatPushNotificationsCalls.reportOutgoingCall(sessionId: id, calleeName: name, hasVideo: isVideo)
CometChatPushNotificationsCalls.reportCallConnected(sessionId: id)

// When your call screen ends the call itself:
CometChatPushNotificationsCalls.reportCallEnded(sessionId: id)
```

## Troubleshooting

| Symptom | Check |
|---|---|
| `onPushTokenRegistrationFailed` | `providerId` set; Push Notifications capability present; user logged in |
| Rings in the foreground but not when killed | Dashboard → Notifications → Logs: find the call's message ID and the device's `APNS_IOS_VOIP` token. A 400 or 403 there is the provider (environment, bundle ID, key), not the app |
| Rings when it shouldn't (after logout) | `unregisterTokens` must complete **before** `logout` |
| One-way audio after answering on the lock screen | Something else activates `AVAudioSession`, but CallKit owns it. Remove it |

**Only a killed app proves the push works.** When the app is open, in the background or locked, the call can still arrive over the app's live connection.

## Sample App Reference

`sample-apps/cometchat-calls-sample-app-ringing-ios`:

- `CometChatCallsRingingApp.swift` — `PushSetup` in `didFinishLaunching`
- `CallPushDelegate.swift` — the delegate
- `IncomingCallPresenter.swift` — answered call → call screen, End & Accept, dismissal
- `AppState.swift` — `unregisterTokens` before logout
