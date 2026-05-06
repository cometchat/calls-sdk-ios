---
name: custom-ui
description: Build custom call UI — custom control panel, UIViewRepresentable patterns, layout customization. Use when hiding default controls and building your own call interface. Triggers on "custom control panel", "custom UI", "hideControlPanel", "custom call interface", "UIViewRepresentable".
inclusion: manual
---

# CometChat Calls SDK v5 — Custom UI

## Overview

Build fully custom call interfaces by hiding the default SDK controls and implementing your own using `CallSession` actions and event listeners. In SwiftUI, use `UIViewRepresentable` to host the call view.

## Key Imports

```swift
import CometChatCallsSDK
import SwiftUI
```

## Implementation

### 1. Hide Default Controls

```swift
let settings = SessionSettingsBuilder()
    .hideControlPanel(true)          // hide entire bottom bar
    .hideHeaderPanel(true)           // hide top header
    .build()
```

### 2. Custom SwiftUI Controls

```swift
struct CustomCallControls: View {
    @State private var isAudioMuted = false
    @State private var isVideoPaused = false

    var body: some View {
        HStack(spacing: 24) {
            Button(action: toggleAudio) {
                Image(systemName: isAudioMuted ? "mic.slash.fill" : "mic.fill")
            }
            Button(action: toggleVideo) {
                Image(systemName: isVideoPaused ? "video.slash.fill" : "video.fill")
            }
            Button(action: switchCamera) {
                Image(systemName: "camera.rotate")
            }
            Button(action: endCall) {
                Image(systemName: "phone.down.fill")
                    .foregroundColor(.red)
            }
        }
    }

    private func toggleAudio() {
        if isAudioMuted { CallSession.shared.unMuteAudio() }
        else { CallSession.shared.muteAudio() }
    }
    private func toggleVideo() {
        if isVideoPaused { CallSession.shared.resumeVideo() }
        else { CallSession.shared.pauseVideo() }
    }
    private func switchCamera() { CallSession.shared.switchCamera() }
    private func endCall() { CallSession.shared.leaveSession() }
}
```

### 3. Sync UI with Media Events

```swift
class MediaHandler: NSObject, MediaEventsListener, ObservableObject {
    @Published var isAudioMuted = false
    @Published var isVideoPaused = false

    func onAudioMuted() { DispatchQueue.main.async { self.isAudioMuted = true } }
    func onAudioUnMuted() { DispatchQueue.main.async { self.isAudioMuted = false } }
    func onVideoPaused() { DispatchQueue.main.async { self.isVideoPaused = true } }
    func onVideoResumed() { DispatchQueue.main.async { self.isVideoPaused = false } }
    // ... other required methods
}
```

### Available CallSession Actions

| Action | Method |
|--------|--------|
| Mute/unmute audio | `muteAudio()`, `unMuteAudio()` |
| Pause/resume video | `pauseVideo()`, `resumeVideo()` |
| Switch camera | `switchCamera()` |
| Start/stop recording | `startRecording()`, `stopRecording()` |
| Pin/unpin participant | `pinParticipant(uid:)`, `unPinParticipant()` |
| Mute participant | `muteParticipant(uid:)` |
| Leave session | `leaveSession()` |
| Enable/disable PiP | `enablePictureInPictureLayout()`, `disablePictureInPictureLayout()` |

## Gotchas

- Always use `MediaEventsListener` to sync your custom UI with actual state
- `DispatchQueue.main.async` is required for UI updates from listener callbacks
- `hideControlPanel(true)` hides the entire bottom bar
- The call view container still renders video tiles even with controls hidden

## Sample App Reference

- `CallView.swift` — Default UI with `SessionStatusListener` and `ButtonClickListener`
