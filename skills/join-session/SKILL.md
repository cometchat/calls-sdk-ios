---
name: join-session
description: Join a CometChat call session using CometChatCalls.joinSession with SessionSettingsBuilder and UIView container. Use when joining calls, configuring session settings, voice vs video calls, or UIViewRepresentable. Triggers on "join session", "join call", "start call", "SessionSettingsBuilder", "UIViewRepresentable".
inclusion: manual
---

# CometChat Calls SDK v5 — Join Session

## Overview

Join a call session using `CometChatCalls.joinSession()`. Requires a `UIView` container and configured `SessionSettings`. In SwiftUI, wrap the UIView in a `UIViewRepresentable`.

## Prerequisites

- Calls SDK initialized and user logged in
- A valid session ID (from Chat SDK's `Call.sessionId` or your backend)

## Key Imports

```swift
import CometChatCallsSDK
import SwiftUI
```

## Implementation

### UIKit — Join Session

```swift
let container = UIView()
view.addSubview(container)
// Set container frame/constraints to fill the screen

let settings = SessionSettingsBuilder()
    .setTitle("Team Meeting")
    .startVideoPaused(false)
    .startAudioMuted(false)
    .build()

CometChatCalls.joinSession(
    sessionID: sessionId,
    callSetting: settings,
    container: container
) { success in
    print("Joined session")
    let session = CallSession.shared
    session.addSessionStatusListener(self)
    session.addButtonClickListener(self)
} onError: { error in
    print("Failed to join: \(error?.errorDescription ?? "")")
}
```

### SwiftUI — UIViewRepresentable Wrapper

```swift
struct CallContainerView: UIViewRepresentable {
    let sessionID: String
    let onEnd: () -> Void

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        startSession(container: container, coordinator: context.coordinator)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onEnd: onEnd)
    }

    private func startSession(container: UIView, coordinator: Coordinator) {
        let settings = SessionSettingsBuilder()
            .setTitle("CometChat Meeting")
            .startVideoPaused(false)
            .startAudioMuted(false)
            .build()

        CometChatCalls.joinSession(
            sessionID: sessionID,
            callSetting: settings,
            container: container
        ) { success in
            let session = CallSession.shared
            session.addSessionStatusListener(coordinator)
            session.addButtonClickListener(coordinator)
        } onError: { error in
            print("Join error: \(error?.errorDescription ?? "")")
        }
    }

    class Coordinator: NSObject, SessionStatusListener, ButtonClickListener {
        let onEnd: () -> Void
        init(onEnd: @escaping () -> Void) { self.onEnd = onEnd }

        func onSessionJoined() {}
        func onSessionLeft() { DispatchQueue.main.async { self.onEnd() } }
        func onConnectionClosed() { DispatchQueue.main.async { self.onEnd() } }
        func onSessionTimedOut() { DispatchQueue.main.async { self.onEnd() } }
        func onConnectionLost() {}
        func onConnectionRestored() {}
        func onLeaveSessionButtonClicked() {
            CallSession.shared.leaveSession()
        }
    }
}
```

### Voice Call vs Video Call

```swift
// Video call
let videoSettings = SessionSettingsBuilder()
    .startVideoPaused(false)
    .startAudioMuted(false)
    .build()

// Voice call
let voiceSettings = SessionSettingsBuilder()
    .startVideoPaused(true)
    .startAudioMuted(false)
    .build()
```

## Gotchas

- The container must be a `UIView` — SwiftUI views need `UIViewRepresentable`
- All participants must use the same session ID to join the same call
- Call `joinSession` only after SDK is initialized and user is logged in
- Register listeners in the `onSuccess` callback of `joinSession`
- Use `DispatchQueue.main.async` for UI updates from listener callbacks

## Sample App Reference

- `CallView.swift` — SwiftUI view with `CallContainerView` UIViewRepresentable
- `HomeView.swift` — Session ID input and call initiation
