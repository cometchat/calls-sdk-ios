---
name: background-handling
description: Keep calls alive in background using Background Modes and AVAudioSession. Use when handling home button press during calls or preventing call termination. Triggers on "background handling", "background modes", "keep call alive", "AVAudioSession", "background audio".
inclusion: manual
---

# CometChat Calls SDK v5 — Background Handling

## Overview

Keep calls alive when users press HOME or switch apps using iOS Background Modes and proper AVAudioSession configuration.

## Prerequisites

- Active call session
- Background Modes capability enabled in Xcode

## Implementation

### 1. Enable Background Modes

In Xcode: Target → Signing & Capabilities → + Capability → Background Modes. Enable:
- Audio, AirPlay, and Picture in Picture
- Voice over IP (if using CallKit)

Or in `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

### 2. Configure AVAudioSession

```swift
import AVFoundation

func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
        try session.setActive(true)
    } catch {
        print("Audio session config failed: \(error)")
    }
}
```

### 3. Handle Background Transition

```swift
// SwiftUI
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
    // Call continues in background with audio
    CallSession.shared.enablePictureInPictureLayout()
}

.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    CallSession.shared.disablePictureInPictureLayout()
}
```

## Gotchas

- Background Modes must be enabled in Xcode capabilities — not just Info.plist
- `voip` background mode is required for CallKit integration
- `audio` background mode keeps the audio session alive when backgrounded
- AVAudioSession category must be set before joining the call
- iOS may terminate background audio after extended periods — CallKit helps prevent this

## Sample App Reference

- `CallView.swift` — Call session management
