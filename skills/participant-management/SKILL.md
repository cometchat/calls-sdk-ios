---
name: participant-management
description: Manage call participants — mute, pause video, pin/unpin, raise hand, view participant list. Use when implementing moderation, participant actions, or custom participant UI. Triggers on "mute participant", "pin participant", "participant list", "raise hand", "participant management".
inclusion: manual
---

# CometChat Calls SDK v5 — Participant Management

## Overview

Control other participants during calls: mute their audio, pause their video, pin/unpin in layout. Monitor participant state via `ParticipantEventListener`.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### Participant Actions

```swift
CallSession.shared.muteParticipant(uid: participant.uid)
CallSession.shared.pauseParticipantVideo(uid: participant.uid)
CallSession.shared.pinParticipant(uid: participant.uid)
CallSession.shared.unPinParticipant()
```

### Listen for Participant Events

```swift
class ParticipantHandler: NSObject, ParticipantEventListener {
    func onParticipantJoined(participant: Participant) {}
    func onParticipantLeft(participant: Participant) {}
    func onParticipantListChanged(participants: [Participant]) {
        // Full participant list — use for UI updates
    }
    func onParticipantAudioMuted(participant: Participant) {}
    func onParticipantAudioUnmuted(participant: Participant) {}
    func onParticipantVideoPaused(participant: Participant) {}
    func onParticipantVideoResumed(participant: Participant) {}
    func onParticipantHandRaised(participant: Participant) {}
    func onParticipantHandLowered(participant: Participant) {}
    func onDominantSpeakerChanged(participant: Participant) {}
    func onParticipantStartedScreenShare(participant: Participant) {}
    func onParticipantStoppedScreenShare(participant: Participant) {}
    func onParticipantStartedRecording(participant: Participant) {}
    func onParticipantStoppedRecording(participant: Participant) {}
}

CallSession.shared.addParticipantEventListener(handler)
```

### Participant Properties

| Property | Type | Description |
|----------|------|-------------|
| `uid` | String | CometChat user ID |
| `name` | String | Display name |
| `avatar` | String | Avatar URL |
| `isAudioMuted` | Bool | Audio muted? |
| `isVideoPaused` | Bool | Video paused? |
| `isPinned` | Bool | Pinned in layout? |
| `isPresenting` | Bool | Screen sharing? |

### Show/Hide Participant List Button

```swift
let settings = SessionSettingsBuilder()
    .hideParticipantListButton(false)  // show participant list
    .hideRaiseHandButton(false)        // show raise hand
    .build()
```

## Gotchas

- By default, all participants have moderator access (can mute/pause others)
- Pinning only affects your local view
- `unPinParticipant()` takes no arguments — unpins whoever is currently pinned
- There is no "kick" API — only mute and pause video

## Sample App Reference

- `CallView.swift` — Session settings and listener setup
