---
name: audio-controls
description: Control audio during calls — mute/unmute microphone, switch audio output device (speaker, earpiece, bluetooth). Use when implementing audio toggle, audio mode switching, or custom mute buttons. Triggers on "mute audio", "unmute", "audio mode", "speaker", "earpiece", "bluetooth audio".
inclusion: manual
---

# CometChat Calls SDK v5 — Audio Controls

## Overview

Programmatically control the local microphone (mute/unmute) and audio output device during an active call.

## Key Imports

```swift
import CometChatCallsSDK
import AVFoundation
```

## Implementation

### Mute / Unmute

```swift
CallSession.shared.muteAudio()    // mute microphone
CallSession.shared.unmuteAudio()  // unmute microphone
```

### Switch Audio Output (AVAudioSession)

```swift
let session = AVAudioSession.sharedInstance()

// Speaker
try session.overrideOutputAudioPort(.speaker)

// Earpiece (default)
try session.overrideOutputAudioPort(.none)

// Bluetooth — set category with options
try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
```

### Listen for Audio Events

```swift
class MediaHandler: NSObject, MediaEventsListener {
    func onAudioMuted() {
        // Update mute button to "muted" state
    }
    func onAudioUnMuted() {
        // Update mute button to "unmuted" state
    }
    func onAudioModeChanged(audioMode: AudioMode) {
        // Update audio mode indicator
    }
    // ... other required methods
}

CallSession.shared.addMediaEventsListener(handler)
```

### Initial Audio Settings (Pre-Session)

```swift
let settings = SessionSettingsBuilder()
    .startAudioMuted(true)              // join muted
    .hideToggleAudioButton(false)       // show mute button
    .hideAudioModeButton(false)         // show audio mode button
    .build()
```

## Gotchas

- `muteAudio()` / `unmuteAudio()` only work during an active session
- For voice calls, default to earpiece; for video calls, default to speaker
- Bluetooth audio mode only works when a Bluetooth device is connected
- AVAudioSession changes should be wrapped in try/catch

## Sample App Reference

- `CallView.swift` — Session settings with audio configuration
