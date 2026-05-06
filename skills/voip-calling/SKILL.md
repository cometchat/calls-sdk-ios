---
name: voip-calling
description: Implement native VoIP calling with CallKit (CXProvider, CXCallController) and PushKit for VoIP push notifications. Use when receiving calls in background/killed state or system call UI. Triggers on "VoIP", "voip calling", "CallKit", "CXProvider", "PushKit", "push notification call", "background call".
inclusion: manual
---

# CometChat Calls SDK v5 — VoIP Calling

## Overview

Native VoIP calling using Apple's CallKit framework. Shows the system call UI on lock screen, integrates with Bluetooth/CarPlay, and works when the app is killed. Requires PushKit for VoIP push notifications.

## Prerequisites

- Chat SDK v4 + Calls SDK v5 integrated
- Apple Push Notification service (APNs) VoIP certificate
- Push notifications enabled in CometChat Dashboard
- Background Modes: `voip`, `audio`

## Key Imports

```swift
import CallKit
import PushKit
import CometChatSDK
import CometChatCallsSDK
```

## Implementation

### 1. PushKit Registration

```swift
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    let pushRegistry = PKPushRegistry(queue: .main)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        return true
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        CometChat.registerTokenForPushNotification(token: token) { success in
            print("VoIP token registered")
        } onError: { error in
            print("Token registration failed: \(error?.errorDescription ?? "")")
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // Parse payload and report to CallKit
        let data = payload.dictionaryPayload
        guard let sessionId = data["sessionId"] as? String else {
            completion()
            return
        }
        CallKitManager.shared.reportIncomingCall(
            sessionId: sessionId,
            callerName: data["senderName"] as? String ?? "Unknown",
            hasVideo: (data["callType"] as? String) == "video"
        ) {
            completion()
        }
    }
}
```

### 2. CallKit Manager

```swift
class CallKitManager: NSObject, CXProviderDelegate {
    static let shared = CallKitManager()

    private let provider: CXProvider
    private let callController = CXCallController()
    private var activeCallUUID: UUID?
    private var activeSessionId: String?

    override init() {
        let config = CXProviderConfiguration()
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.generic]
        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    func reportIncomingCall(sessionId: String, callerName: String, hasVideo: Bool, completion: @escaping () -> Void) {
        let uuid = UUID()
        activeCallUUID = uuid
        activeSessionId = sessionId

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.localizedCallerName = callerName
        update.hasVideo = hasVideo

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("Report incoming call failed: \(error)")
            }
            completion()
        }
    }

    // MARK: - CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {
        activeCallUUID = nil
        activeSessionId = nil
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let sessionId = activeSessionId else {
            action.fail()
            return
        }
        CometChat.acceptCall(sessionID: sessionId) { call in
            action.fulfill()
            // Navigate to call screen
        } onError: { error in
            action.fail()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let sessionId = activeSessionId else {
            action.fulfill()
            return
        }
        CometChat.rejectCall(sessionID: sessionId, status: .rejected) { _ in
            action.fulfill()
        } onError: { _ in
            action.fulfill()
        }
        activeCallUUID = nil
        activeSessionId = nil
    }
}
```

### 3. Background Modes

In `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>voip</string>
    <string>audio</string>
</array>
```

## Gotchas

- PushKit requires you to report every VoIP push to CallKit — failing to do so causes iOS to terminate your app
- VoIP certificate must be configured in APNs (not regular push certificate)
- CallKit is mandatory for VoIP apps on iOS — you cannot use VoIP push without it
- The `pushRegistry` must be initialized early (AppDelegate) to receive pushes when killed
- Always call `action.fulfill()` or `action.fail()` in CXProviderDelegate methods

## Sample App Reference

- `CallKitManager.swift` — CallKit integration
- `AppDelegate.swift` — PushKit registration
