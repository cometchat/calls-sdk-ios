---
name: screen-sharing
description: Handle screen sharing in calls. iOS mobile can receive/view screen shares from web clients. Use when implementing screen share viewing or checking presenter status. Triggers on "screen sharing", "screen share", "presenter", "share screen".
inclusion: manual
---

# CometChat Calls SDK v5 — Screen Sharing

## Overview

The iOS Calls SDK can receive and display screen shares initiated from web clients. iOS mobile does not support initiating screen sharing. The call layout automatically adjusts to display shared content.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### Listen for Screen Share Events

```swift
class ParticipantHandler: NSObject, ParticipantEventListener {
    func onParticipantStartedScreenShare(participant: Participant) {
        print("\(participant.name) started screen sharing")
        // Layout auto-adjusts to show shared screen
    }
    func onParticipantStoppedScreenShare(participant: Participant) {
        print("\(participant.name) stopped screen sharing")
    }
    // ... other required methods
}

CallSession.shared.addParticipantEventListener(handler)
```

### Check Presenter Status

```swift
func onParticipantStartedScreenShare(participant: Participant) {
    print("\(participant.name) is sharing their screen")
}
```

## Gotchas

- iOS mobile cannot initiate screen sharing — only web clients can
- The SDK automatically adjusts the layout when a screen share starts
- Use `ParticipantEventListener.onParticipantStartedScreenShare(participant:)` and `onParticipantStoppedScreenShare(participant:)` to detect screen sharing

## Sample App Reference

- `CallView.swift` — Session settings configuration
