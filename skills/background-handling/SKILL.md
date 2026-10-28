---
name: background-handling
description: Keep calls alive in background using Background Modes and AVAudioSession. Use when handling home button press during calls or preventing call termination. Triggers on "background handling", "background modes", "keep call alive", "AVAudioSession", "background audio".
inclusion: manual
---

# CometChat Calls SDK v5 — Background Handling

## Overview

Keep calls alive when users press HOME or switch apps using iOS Background Modes. The SDKs own the AVAudioSession; your app doesn't configure it.

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

### 2. Leave AVAudioSession to the SDKs

**Calls that ring through the Push Notifications SDK 2.0 (CallKit):** do not set the `AVAudioSession` category and do not call `setActive(true)` yourself, before or after joining. CallKit activates the session when the call is answered and the Calls SDK starts audio from that activation. Activating it yourself gives one-way audio, most often after answering on the lock screen (see the `voip-calling` skill).

**Calls without CallKit** (you call `CometChatCalls.joinSession` directly): the Calls SDK configures and activates the audio session itself when it joins. You don't need to set it up either.

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
- Don't configure or activate AVAudioSession yourself: CallKit owns it for ringing calls, and the Calls SDK sets it up for direct joins
- iOS may terminate background audio after extended periods — CallKit helps prevent this

## Sample App Reference

- `CallView.swift` — Call session management
