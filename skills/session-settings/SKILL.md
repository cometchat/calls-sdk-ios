---
name: session-settings
description: Configure all SessionSettingsBuilder options — layouts, session type, audio mode, hide buttons, idle timeout, recording. Use when customizing call UI or pre-session config. Triggers on "SessionSettingsBuilder", "session settings", "hide button", "layout type", "audio mode", "idle timeout".
inclusion: manual
---

# CometChat Calls SDK v5 — Session Settings

## Overview

`SessionSettingsBuilder` configures every aspect of a call session before joining. Settings are immutable after `build()` — pass the result to `joinSession()`.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### Full Builder Example

```swift
let sessionSettings = SessionSettingsBuilder()
    // Identity
    .setTitle("Team Meeting")
    .setDisplayName("John Doe")

    // Initial media state
    .startAudioMuted(false)
    .startVideoPaused(false)

    // Timeout & recording
    .setIdleTimeoutPeriod(300)               // seconds (default 300)
    .enableAutoStartRecording(false)

    // Hide panels
    .hideControlPanel(false)
    .hideHeaderPanel(false)
    .hideSessionTimer(false)

    // Hide individual buttons
    .hideLeaveSessionButton(false)
    .hideToggleAudioButton(false)
    .hideToggleVideoButton(false)
    .hideSwitchCameraButton(false)
    .hideRecordingButton(true)               // hidden by default
    .hideAudioModeButton(false)
    .hideRaiseHandButton(false)
    .hideShareInviteButton(true)             // hidden by default
    .hideParticipantListButton(false)
    .hideChangeLayoutButton(false)
    .hideChatButton(true)                    // hidden by default

    .build()
```

### Common Presets

**Voice call:**
```swift
let voiceSettings = SessionSettingsBuilder()
    .startVideoPaused(true)
    .startAudioMuted(false)
    .build()
```

**Video call:**
```swift
let videoSettings = SessionSettingsBuilder()
    .startVideoPaused(false)
    .startAudioMuted(false)
    .build()
```

**Custom UI (hide default controls):**
```swift
let customSettings = SessionSettingsBuilder()
    .hideControlPanel(true)
    .hideHeaderPanel(true)
    .build()
```

### Button Defaults

| Button | Default Hidden? |
|--------|----------------|
| Recording | Yes (`true`) |
| Share Invite | Yes (`true`) |
| Chat | Yes (`true`) |
| All others | No (`false`) |

## Gotchas

- Settings are immutable after `build()` — create a new builder for changes
- `setIdleTimeoutPeriod()` takes seconds, default is 300 (5 minutes)
- Recording, share invite, and chat buttons are hidden by default
- These are pre-session configs only; use `CallSession.shared` actions for runtime changes

## Sample App Reference

- `CallView.swift` — `SessionSettingsBuilder` configuration in `startSession()`
