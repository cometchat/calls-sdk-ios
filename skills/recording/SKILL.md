---
name: recording
description: Record call sessions with start/stop, auto-start recording, and recording events. Use when implementing call recording, accessing recordings from call logs, or showing recording indicators. Triggers on "recording", "record call", "auto start recording", "recording events".
inclusion: manual
---

# CometChat Calls SDK v5 — Recording

## Overview

Record call sessions server-side. Supports manual start/stop, auto-start via `SessionSettings`, and event listeners for recording state.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### Start/Stop Recording

```swift
CallSession.shared.startRecording()
CallSession.shared.stopRecording()
```

### Auto-Start Recording (SessionSettings)

```swift
let settings = SessionSettingsBuilder()
    .enableAutoStartRecording(true)
    .hideRecordingButton(false)  // show button (hidden by default)
    .build()
```

### Listen for Recording Events (Local)

```swift
class MediaHandler: NSObject, MediaEventsListener {
    func onRecordingStarted() { /* show indicator */ }
    func onRecordingStopped() { /* hide indicator */ }
    // ... other required methods
}

CallSession.shared.addMediaEventsListener(handler)
```

### Track Participant Recording

```swift
class ParticipantHandler: NSObject, ParticipantEventListener {
    func onParticipantStartedRecording(participant: Participant) {
        print("\(participant.name) started recording")
    }
    func onParticipantStoppedRecording(participant: Participant) {
        print("\(participant.name) stopped recording")
    }
    // ... other required methods
}
```

## Gotchas

- Recording must be enabled in your CometChat Dashboard
- The recording button is hidden by default — use `.hideRecordingButton(false)` to show it
- All participants are notified when recording starts
- Recordings are stored server-side and available after the call ends

## Sample App Reference

- `CallView.swift` — Session settings configuration
