---
name: setup
description: Set up CometChat Calls SDK v5 for iOS. Use when adding SDK via SPM or CocoaPods, configuring CallAppSettingsBuilder, CometChatCalls init, Info.plist permissions. Triggers on "setup calls sdk", "add cometchat dependency", "initialize calls", "spm setup", "cocoapods setup".
inclusion: manual
---

# CometChat Calls SDK v5 — Setup

## Overview

Install and initialize the CometChat Calls SDK v5 (beta) in an iOS project. Covers Swift Package Manager, CocoaPods, Info.plist permissions, and `CometChatCalls` initialization.

## Prerequisites

- iOS 15.0+, Xcode 15+, Swift 5.0+
- App ID and Region from CometChat Dashboard

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### 1. Add via Swift Package Manager (Preferred)

In Xcode: File → Add Package Dependencies → Enter:

```
https://github.com/cometchat/calls-sdk-ios.git
```

Select version `5.0.0-beta.3` or later. Add `CometChatCallsSDK` to your target.

### 2. Add via CocoaPods

In your `Podfile`:

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'CometChatCallsSDK', '~> 5.0.0-beta'
end
```

Then run `pod install`.

### 3. Info.plist Permissions

Add to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for voice and video calls</string>
```

### 4. Initialize SDK

Call once at app launch (e.g., in `App.init()` or `AppDelegate`):

```swift
let settings = CallAppSettingsBuilder()
    .set(appID: "APP_ID")
    .set(region: "REGION")  // "us", "eu", or "in"
    .build()

CometChatCalls(callsAppSettings: settings) { success in
    print("Calls SDK initialized")
} onError: { error in
    print("Init failed: \(error?.errorDescription ?? "unknown")")
}
```

### 5. Authentication

Login with UID + Auth Key (dev only) or Auth Token (production):

```swift
CometChatCalls.login(UID: "user_uid", authKey: "AUTH_KEY") { user in
    print("Logged in as: \(user?.uid ?? "")")
} onError: { error in
    print("Login failed: \(error.errorDescription ?? "")")
}
```

### 6. Check Logged-In User

```swift
if let user = CometChatCalls.getLoggedInUser() {
    // User is already logged in
}
```

### 7. Logout

```swift
CometChatCalls.logout { success in
    print("Logged out")
} onError: { error in
    print("Logout failed: \(error.errorDescription ?? "")")
}
```

## Gotchas

- Request camera and microphone permissions at runtime using `AVCaptureDevice.requestAccess(for:)`
- Call `CometChatCalls(callsAppSettings:)` before any other SDK method
- If using both Chat SDK and Calls SDK, initialize both separately
- SPM resolves two binary targets: `CometChatCallsSDK` and `WebRTC`
- The SDK requires iOS 15.0+ minimum deployment target

## Sample App Reference

- `AppState.swift` — SDK initialization and login flow
- `AppConstants.swift` — Credential storage
- `CometChatCallsSampleApp.swift` — App entry point
