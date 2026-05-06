---
name: video-controls
description: Control video during calls — pause/resume camera, switch front/back camera. Use when implementing camera toggle, camera switch, or custom video buttons. Triggers on "pause video", "resume video", "switch camera", "camera toggle", "video controls".
inclusion: manual
---

# CometChat Calls SDK v5 — Video Controls

## Overview

Programmatically control the local camera (pause/resume) and switch between front/back cameras during an active call.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### Pause / Resume Video

```swift
CallSession.shared.pauseVideo()   // turn off camera
CallSession.shared.resumeVideo()  // turn on camera
```

### Switch Camera

```swift
CallSession.shared.switchCamera()  // toggle front ↔ back
```

### Listen for Video Events

```swift
class MediaHandler: NSObject, MediaEventsListener {
    func onVideoPaused() {
        // Update video button to "off" state
    }
    func onVideoResumed() {
        // Update video button to "on" state
    }
    func onCameraFacingChanged(cameraFacing: CameraFacing) {
        // .FRONT or .REAR
    }
    // ... other required methods
}

CallSession.shared.addMediaEventsListener(handler)
```

### Initial Video Settings (Pre-Session)

```swift
let settings = SessionSettingsBuilder()
    .startVideoPaused(false)                // start with camera on
    .hideToggleVideoButton(false)           // show video toggle
    .hideSwitchCameraButton(false)          // show camera switch
    .build()
```

## Gotchas

- `pauseVideo()` / `resumeVideo()` only work during an active session
- `switchCamera()` toggles between front and back — no parameter needed
- For voice calls, set `.startVideoPaused(true)`
- Camera permissions must be granted before joining

## Sample App Reference

- `CallView.swift` — Session settings with video configuration
