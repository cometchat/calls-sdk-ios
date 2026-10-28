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

### 2. One Media State, Driven by the SDK's Events

The controls must not keep their own flags: the call can start muted (`startAudioMuted`) or be muted from elsewhere (a moderator), and a flag only the button flips goes stale or mutes on every tap. Keep one observed object, updated **only** from `MediaEventsListener`:

```swift
final class CallMediaState: NSObject, ObservableObject, MediaEventsListener {
    @Published private(set) var isAudioMuted: Bool
    @Published private(set) var isVideoPaused: Bool

    /// Seed from the session settings the call was joined with.
    init(audioMuted: Bool, videoPaused: Bool) {
        isAudioMuted = audioMuted
        isVideoPaused = videoPaused
        super.init()
        CallSession.shared.addMediaEventsListener(self)
    }

    func stopListening() { CallSession.shared.removeMediaEventsListener(self) }

    func onAudioMuted() { DispatchQueue.main.async { self.isAudioMuted = true } }
    func onAudioUnMuted() { DispatchQueue.main.async { self.isAudioMuted = false } }
    func onVideoPaused() { DispatchQueue.main.async { self.isVideoPaused = true } }
    func onVideoResumed() { DispatchQueue.main.async { self.isVideoPaused = false } }
}
```

### 3. Custom SwiftUI Controls

The buttons read that state and ask the SDK to change it; the icons flip when the event arrives:

```swift
struct CustomCallControls: View {
    @ObservedObject var media: CallMediaState

    var body: some View {
        HStack(spacing: 24) {
            Button(action: toggleAudio) {
                Image(systemName: media.isAudioMuted ? "mic.slash.fill" : "mic.fill")
            }
            Button(action: toggleVideo) {
                Image(systemName: media.isVideoPaused ? "video.slash.fill" : "video.fill")
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
        if media.isAudioMuted { CallSession.shared.unmuteAudio() }
        else { CallSession.shared.muteAudio() }
    }
    private func toggleVideo() {
        if media.isVideoPaused { CallSession.shared.resumeVideo() }
        else { CallSession.shared.pauseVideo() }
    }
    private func switchCamera() { CallSession.shared.switchCamera() }
    private func endCall() { CallSession.shared.leave() }
}

// The call screen owns the state for the life of the call:
struct CallScreen: View {
    @StateObject private var media: CallMediaState

    init(settings: SessionSettingsBuilder.SessionSettings) {
        _media = StateObject(wrappedValue: CallMediaState(
            audioMuted: settings.startAudioMuted,
            videoPaused: settings.startVideoPaused
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // CallContainer() — your UIViewRepresentable hosting the call view
            CustomCallControls(media: media)
        }
        .onDisappear { media.stopListening() }
    }
}
```

### Available CallSession Actions

| Action | Method |
|--------|--------|
| Mute/unmute audio | `muteAudio()`, `unmuteAudio()` |
| Pause/resume video | `pauseVideo()`, `resumeVideo()` |
| Switch camera | `switchCamera()` |
| Start/stop recording | `startRecording()`, `stopRecording()` |
| Pin/unpin participant | `pinParticipant(participantId:, type:)`, `unpinParticipant()` |
| Mute participant | `muteParticipant(participantId:)` |
| Leave session | `leave()` |
| Enable/disable PiP | `enablePictureInPictureLayout()`, `disablePictureInPictureLayout()` |

## Gotchas

- Drive the controls from `MediaEventsListener` (`onAudioMuted` / `onAudioUnMuted` / `onVideoPaused` / `onVideoResumed`), never from a flag the button flips itself
- `DispatchQueue.main.async` is required for UI updates from listener callbacks
- `hideControlPanel(true)` hides the entire bottom bar
- The call view container still renders video tiles even with controls hidden

## Sample App Reference

- `CallView.swift` — Default UI with `SessionStatusListener` and `ButtonClickListener`
