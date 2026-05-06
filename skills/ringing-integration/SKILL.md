---
name: ringing-integration
description: Implement ringing with dual SDK (Chat + Calls). Use when adding incoming/outgoing call screens, CometChat.initiateCall, accept/reject/cancel calls. Triggers on "ringing", "incoming call", "outgoing call", "initiateCall", "acceptCall", "rejectCall".
inclusion: manual
---

# CometChat Calls SDK v5 — Ringing Integration

## Overview

Implement call ringing using both CometChat Chat SDK (signaling) and Calls SDK (session). The Chat SDK handles initiating, accepting, rejecting, and cancelling calls. The Calls SDK manages the actual call session after acceptance.

## Prerequisites

- Both SDKs added via SPM:
  - `CometChatCallsSDK` — local or remote package
  - `CometChatSDK` — `https://github.com/cometchat/chat-sdk-ios.git`
- Both SDKs initialized and user logged in to both

## Key Imports

```swift
// Chat SDK — signaling
import CometChatSDK

// Calls SDK — session
import CometChatCallsSDK
```

## Implementation

### 1. Initiate a Call (Caller Side)

```swift
let call = Call(receiverId: receiverUID, callType: .video, receiverType: .user)

CometChat.initiateCall(call: call) { outgoingCall in
    // Show outgoing call UI with outgoingCall?.sessionID
} onError: { error in
    print("Initiate failed: \(error?.errorDescription ?? "")")
}
```

### 2. Listen for Incoming Calls (Global Listener)

Register early in app lifecycle:

```swift
CometChat.addCallListener("call_listener", self)

// Conform to CometChatCallDelegate
extension AppDelegate: CometChatCallDelegate {
    func onIncomingCallReceived(incomingCall: Call?, error: CometChatException?) {
        guard let call = incomingCall else { return }
        // Show incoming call UI
        // call.sessionID, call.sender?.name, call.callType
    }

    func onOutgoingCallAccepted(acceptedCall: Call?, error: CometChatException?) {
        guard let call = acceptedCall else { return }
        // Navigate to call screen, join session with call.sessionID
    }

    func onOutgoingCallRejected(rejectedCall: Call?, error: CometChatException?) {
        // Dismiss outgoing call UI
    }

    func onIncomingCallCancelled(cancelledCall: Call?, error: CometChatException?) {
        // Dismiss incoming call UI
    }
}
```

### 3. Accept a Call (Receiver Side)

```swift
CometChat.acceptCall(sessionID: sessionId) { call in
    // Navigate to call screen, join session with call?.sessionID
} onError: { error in
    print("Accept failed: \(error?.errorDescription ?? "")")
}
```

### 4. Reject a Call

```swift
CometChat.rejectCall(sessionID: sessionId, status: .rejected) { call in
    // Dismiss incoming call UI
} onError: { error in
    print("Reject failed: \(error?.errorDescription ?? "")")
}
```

### 5. Cancel an Outgoing Call

```swift
CometChat.rejectCall(sessionID: sessionId, status: .cancelled) { call in
    // Dismiss outgoing call UI
} onError: { error in
    print("Cancel failed: \(error?.errorDescription ?? "")")
}
```

### 6. End a Call (During Session)

```swift
// 1. Leave the Calls SDK session
CallSession.shared.leaveSession()

// 2. Notify via Chat SDK
CometChat.endCall(sessionID: sessionId) { call in
    // Navigate away
} onError: { error in
    print("End call failed: \(error?.errorDescription ?? "")")
}
```

### 7. Handle Remote User Ending the Call

V5 SDK does not auto-disconnect when the remote user leaves. Use `onCallEndedMessageReceived` from the Chat SDK to detect when the other party ends the call:

```swift
extension AppState: CometChatCallDelegate {
    // ... other delegate methods ...

    func onCallEndedMessageReceived(endedCall: Call?, error: CometChatException?) {
        // Remote user ended the call via Chat SDK
        let session = CallSession.shared
        session.leaveSession()
        DispatchQueue.main.async {
            self.activeSessionID = nil
            self.currentScreen = .home
        }
    }
}
```

As a secondary safety net, also listen for `onParticipantLeft` via `ParticipantEventListener` on the Calls SDK session to handle 1-on-1 calls where the participant count drops to zero:

```swift
class Coordinator: NSObject, ParticipantEventListener {
    private var participantCount = 0

    func onParticipantJoined(participant: Participant) { participantCount += 1 }

    func onParticipantLeft(participant: Participant) {
        participantCount -= 1
        if participantCount <= 0 {
            CallSession.shared.leaveSession()
        }
    }

    func onParticipantListChanged(participants: [Participant]) {
        participantCount = participants.count
    }
}

// Register after joinSession succeeds
CallSession.shared.addParticipantEventListener(coordinator)
```

## SwiftUI App Lifecycle

CometChatSDK internally accesses `UIApplication.shared.delegate?.window`. In a pure SwiftUI app, add a `UIApplicationDelegateAdaptor`:

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // ...
}
```

## Gotchas

- Cancel uses `CometChat.rejectCall()` with `.cancelled` status
- Always call `CometChat.endCall()` when ending — otherwise the other party won't know
- V5 SDK does NOT auto-disconnect when remote user leaves — the app must handle `onCallEndedMessageReceived` (Chat SDK) or `onParticipantLeft` (Calls SDK) to leave the session
- Use `CometChat.CallType` (not `CometChatSDK.CallType`) when both SDKs are imported — `CallType` is nested inside the `CometChat` class
- CometChatSDK `onError` closures pass non-optional `CometChatException`; CometChatCallsSDK `onError` closures may pass optional `CometChatCallException?` — check the specific API
- Remove call listeners when no longer needed to prevent retain cycles
- Use `CometChatSDK.Call` for signaling, `CometChatCallsSDK.CallSession` for the session
- Initialize both SDKs separately — they have independent init flows
- In SwiftUI apps, add `UIApplicationDelegateAdaptor` with a `window` property to avoid `unrecognized selector` crash

## Sample App Reference

- `AppState.swift` — Dual SDK initialization
- `OutgoingCallView.swift` — Cancel call, listen for accept/reject
- `IncomingCallView.swift` — Accept/reject incoming call
- `CallView.swift` — Join session after accept
