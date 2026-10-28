---
name: ringing-integration
description: Implement 1:1 and group ringing with the Calls SDK 5.1 (initiateCall / endCall, prepared sessions) and the Push Notifications SDK 2.0 (VoIP push + CallKit on the callee). Use when adding outgoing call screens, ringing a user or a group, cancelling, detecting declines, or presenting an answered call. Triggers on "ringing", "incoming call", "outgoing call", "initiateCall", "endCall", "group call", "call back".
inclusion: manual
---

# CometChat Calls SDK v5.1 — Ringing

## Overview

Ringing is split between two SDKs:

| Side | SDK | What it does |
|---|---|---|
| Caller | Calls SDK 5.1 | `initiateCall` creates the call, rings the receiver and **prepares the session** while it rings; `endCall` withdraws it |
| Callee | Push Notifications SDK 2.0 (`CometChatPushNotificationsCalls`) | Receives the VoIP push, rings **CallKit**, prepares the session, answers or declines. The app only shows its call screen |

The Chat SDK is not part of the call flow. The sample still uses it for the user and group lists.

There is no `CometChat.initiateCall` / `acceptCall` / `rejectCall` / call listener in this flow.

## Prerequisites

- `CometChatCallsSDK` 5.1+, initialized and logged in (`CometChatCalls.login`)
- `CometChatPushNotificationsCalls` 2.0+, set up in `didFinishLaunching` (see the `voip-calling` skill)
- Microphone permission before `initiateCall` (and camera for video): the media session is prepared straight away

## 1. Session settings: build them once

`initiateCall` freezes the settings on the session it prepares, and the `joinSession` that follows **ignores** the ones it is given. Build both from one function:

```swift
enum CallSettings {
    static func make(title: String, isVideoCall: Bool, isPeerCall: Bool) -> SessionSettingsBuilder.SessionSettings {
        SessionSettingsBuilder()
            .setTitle(title)
            .setSessionType(isVideoCall ? .video : .voice)
            .startVideoPaused(!isVideoCall)
            .startAudioMuted(false)
            .setPeerCall(isPeerCall)      // 1:1: ends for both when either leaves; group: false
            .enableIOSPictureInPicture(true)
            .build()
    }
}
```

## 2. Place the call (caller)

```swift
let options = InitiateCallOptions()
options.type = isVideo ? CallSessionType.video : CallSessionType.audio
options.receiverType = isGroup ? CallReceiverType.group : CallReceiverType.user
options.sessionSettings = CallSettings.make(title: name, isVideoCall: isVideo, isPeerCall: !isGroup)

CometChatCalls.initiateCall(receiver: uidOrGuid, options: options) { initiatedCall in
    let sessionID = initiatedCall.sessionId   // keep it: endCall and joinSession use it
    // Show "Calling…", arm a ring timer, start polling for a decline (step 5)
} onError: { error in
    // Nothing exists on the server: show "Call failed"
}
```

A group receiver rings every member. The first to answer joins, and others can join while it lasts.

## 3. Follow the prepared session

Register on `CallSession.shared` before calling `initiateCall`:

```swift
final class OutgoingListener: NSObject, SessionStatusListener, ParticipantEventListener {
    func onParticipantConnected(participant: Participant) { /* callee's device has the session: "Ringing…" */ }
    func onParticipantJoined(participant: Participant)    { /* accepted: show the call screen and join */ }
    func onConnectionClosed()                             { /* the prepared session went away: ask the server why */ }
}
CallSession.shared.addSessionStatusListener(listener)
CallSession.shared.addParticipantEventListener(listener)
```

`onParticipantJoined` is the only acceptance signal. Once it fires, remove these listeners: the call screen registers its own.

## 4. Join the accepted call

Join **by session ID**. That takes over the prepared session, so only the media and the UI are left to set up:

```swift
CometChatCalls.joinSession(
    sessionID: sessionID,
    callSetting: CallSettings.make(title: name, isVideoCall: isVideo, isPeerCall: !isGroup),
    container: containerView
) { _ in
    CometChatPushNotificationsCalls.reportOutgoingCall(sessionId: sessionID, calleeName: name, hasVideo: isVideo)
    CometChatPushNotificationsCalls.reportCallConnected(sessionId: sessionID)   // CallKit: Recents, lock screen
} onError: { _ in }
```

## 5. Cancel, timeout and decline

```swift
// End button, or no answer after ~45 s (no longer than the callee's ring timeout, 45 s by default)
CometChatCalls.endCall(sessionID: sessionID, status: EndCallStatus.cancelled, onSuccess: {}, onError: { _ in })
```

The SDK tears the prepared session down itself. Losing the race to the other side hanging up returns an error, and that's harmless.

A decline reaches the server at once but nothing pushes it to the caller. While ringing, poll the call log every few seconds:

```swift
CallLogsRequest.CallLogsBuilder().set(limit: 5).build().fetchNext { logs in
    switch logs.first(where: { $0.sessionID == sessionID })?.status {
    case .rejected: break   // "Declined"
    case .busy: break       // "Busy"
    default: break          // still ringing, or not recorded yet
    }
} onError: { _ in }
```

Keep the caller's decisions in a small state machine (initiating → ringing → joined / ended(reason)). Duplicate events and double taps then change nothing.

## 6. Present an answered call (callee)

The Push SDK calls your delegate when the user answers, in every app state, including killed and locked:

```swift
final class CallPushDelegate: NSObject, CometChatPushNotificationsCallsDelegate {
    func presentCall(_ call: IncomingCall) -> Bool {
        // Publish a call screen that joins call.sessionId (step 4, isPeerCall: call.isPeerCall)
        return true          // false = nobody can take it; the SDK ends the CallKit call
    }
    func callDidEnd(_ call: IncomingCall, reason: CallEndReason) {
        // Take the call screen down
    }
}
```

Publish the screen from a singleton store (`@Published var activeCall`) rather than presenting directly. The answer can arrive before any view exists, in a process the push just launched.

When your call screen goes away on its own (hang-up, failed join), call `CometChatPushNotificationsCalls.reportCallEnded(sessionId:)` so CallKit ends too. It is a no-op if the call already ended.

## 7. Leave a call

```swift
CallSession.shared.leave()
```

A 1:1 call (`setPeerCall(true)`) ends for both sides. A group call carries on for whoever is left. Listen for `onSessionLeft` / `onConnectionClosed` on `SessionStatusListener` to take your screen down when the other side ends it.

## Gotchas

- **Settings at join are ignored for a prepared session.** Build them with the same function on both sides.
- **Microphone (and camera) before `initiateCall`.** Preparing creates the media session.
- **Listener objects must be plain `NSObject`s.** The SDKs hold delegates and listeners weakly through Objective-C. An `ObservableObject` with `@Published` properties breaks that. Keep a separate `NSObject` that forwards to it.
- **End & Accept on CallKit:** the old call is still leaving when the new one is answered. Wait for `CometChatCalls.getActiveSession()` to be nil (or `isSessionActive() == false`) before joining.
- **Group calls:** `receiverType` group plus `setPeerCall(false)`. Without that, the session ends when the first member leaves.
- **Don't wait on a push for the decline:** poll the call log while ringing (step 5).
- **SwiftUI:** `Group` is ambiguous when `CometChatSDK` is imported. Use `CometChatSDK.Group`.

## Sample App Reference

`sample-apps/cometchat-calls-sample-app-ringing-ios`:

- `OutgoingCall.swift` — caller state machine
- `OutgoingCallViewModel.swift` — `initiateCall`, listeners, cancel/timeout, decline polling
- `CallSessionViewModel.swift` — `CallSettings`, `joinSession`, CallKit reporting, leave
- `CallPushDelegate.swift`, `IncomingCallPresenter.swift` — answered calls
- `GroupsView.swift` — ringing a group, creating one from picked members
