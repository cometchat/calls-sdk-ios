---
name: event-listeners
description: Register call event listeners — SessionStatusListener, ParticipantEventListener, MediaEventsListener, ButtonClickListener. Use when handling call events, session status, participant changes, media state, or button clicks. Triggers on "event listener", "session listener", "participant listener", "media listener", "button click".
inclusion: manual
---

# CometChat Calls SDK v5 — Event Listeners

## Overview

Five protocol-based listeners monitor call events. All are registered on `CallSession.shared` after joining a session.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### 1. SessionStatusListener

```swift
class CallCoordinator: NSObject, SessionStatusListener {
    func onSessionJoined() { /* connected */ }
    func onSessionLeft() { /* navigate away */ }
    func onSessionTimedOut() { /* navigate away */ }
    func onConnectionLost() { /* show reconnecting UI */ }
    func onConnectionRestored() { /* hide reconnecting UI */ }
    func onConnectionClosed() { /* navigate away */ }
}

// Register after joinSession succeeds
CallSession.shared.addSessionStatusListener(coordinator)
```

### 2. ParticipantEventListener

```swift
class ParticipantHandler: NSObject, ParticipantEventListener {
    func onParticipantJoined(participant: Participant) {}
    func onParticipantLeft(participant: Participant) {}
    func onParticipantListChanged(participants: [Participant]) {}
    func onParticipantAudioMuted(participant: Participant) {}
    func onParticipantAudioUnmuted(participant: Participant) {}
    func onParticipantVideoPaused(participant: Participant) {}
    func onParticipantVideoResumed(participant: Participant) {}
    func onParticipantHandRaised(participant: Participant) {}
    func onParticipantHandLowered(participant: Participant) {}
    func onParticipantStartedScreenShare(participant: Participant) {}
    func onParticipantStoppedScreenShare(participant: Participant) {}
    func onParticipantStartedRecording(participant: Participant) {}
    func onParticipantStoppedRecording(participant: Participant) {}
    func onDominantSpeakerChanged(participant: Participant) {}
}

CallSession.shared.addParticipantEventListener(handler)
```

### 3. MediaEventsListener

```swift
class MediaHandler: NSObject, MediaEventsListener {
    func onAudioMuted() {}
    func onAudioUnMuted() {}
    func onVideoPaused() {}
    func onVideoResumed() {}
    func onRecordingStarted() {}
    func onRecordingStopped() {}
    func onAudioModeChanged(audioMode: AudioMode) {}
    func onCameraFacingChanged(cameraFacing: CameraFacing) {}
}

CallSession.shared.addMediaEventsListener(handler)
```

### 4. ButtonClickListener

```swift
class ButtonHandler: NSObject, ButtonClickListener {
    func onLeaveSessionButtonClicked() {}
    func onToggleAudioButtonClicked() {}
    func onToggleVideoButtonClicked() {}
    func onSwitchCameraButtonClicked() {}
    func onRaiseHandButtonClicked() {}
    func onShareInviteButtonClicked() {}
    func onChangeLayoutButtonClicked() {}
    func onParticipantListButtonClicked() {}
    func onChatButtonClicked() {}
    func onRecordingToggleButtonClicked() {}
}

CallSession.shared.addButtonClickListener(handler)
```

### 5. LayoutListener

```swift
@objc public protocol LayoutListener {
    @objc optional func onCallLayoutChanged(layoutType: LayoutType)
    @objc optional func onParticipantListVisible()
    @objc optional func onParticipantListHidden()
    @objc optional func onPictureInPictureLayoutEnabled()
    @objc optional func onPictureInPictureLayoutDisabled()
}

// Registration: CallSession.shared.addLayoutListener(handler)
```

## Gotchas

- Register listeners after `joinSession()` succeeds (in the `onSuccess` closure)
- Use `DispatchQueue.main.async` for UI updates inside listener callbacks
- A single object can conform to multiple listener protocols
- Button click events fire before the SDK's default action
- `Participant` has: `uid`, `name`, `avatar`, `totalAudioMinutes`, `totalVideoMinutes`, `totalDurationInMinutes`, `deviceID`, `isJoined`, `joinedAt`, `mid`, `state`, `leftAt`
- V5 SDK does NOT auto-disconnect when remote user leaves — use `ParticipantEventListener.onParticipantLeft` to track participant count and leave the session when it drops to zero (for 1-on-1 calls). For ringing calls, also use `CometChatCallDelegate.onCallEndedMessageReceived` from the Chat SDK as the primary signal.

## Sample App Reference

- `CallView.swift` — `Coordinator` conforms to `SessionStatusListener` and `ButtonClickListener`
