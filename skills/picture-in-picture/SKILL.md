---
name: picture-in-picture
description: Enable Picture-in-Picture mode for calls. Use when implementing PiP, floating call window, or PiP layout events. Triggers on "picture in picture", "PiP", "pip mode", "floating window".
inclusion: manual
---

# CometChat Calls SDK v5 — Picture-in-Picture

## Overview

PiP lets users continue calls in a floating window while using other apps. The Calls SDK provides methods to enable/disable the PiP-optimized layout.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### Enable/Disable PiP Layout

```swift
CallSession.shared.enablePictureInPictureLayout()
CallSession.shared.disablePictureInPictureLayout()
```

### Handle App Backgrounding

```swift
// In your call view controller or SwiftUI view
NotificationCenter.default.addObserver(
    forName: UIApplication.didEnterBackgroundNotification,
    object: nil, queue: .main
) { _ in
    if CallSession.shared.isSessionActive {
        CallSession.shared.enablePictureInPictureLayout()
    }
}

NotificationCenter.default.addObserver(
    forName: UIApplication.willEnterForegroundNotification,
    object: nil, queue: .main
) { _ in
    CallSession.shared.disablePictureInPictureLayout()
}
```

## Gotchas

- The SDK adjusts the call UI layout — your app manages the PiP window lifecycle
- iOS PiP for non-AVPlayer content requires additional setup with `AVPictureInPictureController`
- Hide custom controls in PiP mode — they won't be usable in the small window
- Check `isSessionActive` before enabling PiP to avoid errors

## Sample App Reference

- `CallView.swift` — Call activity that could be extended with PiP support
