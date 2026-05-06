<p align="center">
  <img alt="CometChat" src="https://assets.cometchat.io/website/images/logos/banner.png">
</p>

# CometChat iOS Calls SDK

The CometChat Calls SDK enables real-time voice and video calling capabilities in your iOS application. Built on top of WebRTC, it provides a complete calling solution with built-in UI components and extensive customization options.

<p align="center">
  <img src="./screenshots/showcase-1.png" alt="iOS Screenshot 1" width="30%">&nbsp;&nbsp;
  <img src="./screenshots/showcase-2.png" alt="iOS Screenshot 2" width="30%">&nbsp;&nbsp;
  <img src="./screenshots/showcase-3.png" alt="iOS Screenshot 3" width="30%">
</p>

---

## Getting Started

To set up the CometChat Calls SDK and utilize CometChat for your calling functionality, you'll need to follow these steps:

1. Registration: Go to the [CometChat Dashboard](https://app.cometchat.com/) and sign up for an account.
2. After registering, log into your CometChat account and create a new app. Once created, CometChat will generate an Auth Key and App ID for you. Keep these credentials secure as you'll need them later.
3. Check the [Key Concepts](https://www.cometchat.com/docs/fundamentals/key-concepts) to understand the basic components of CometChat.

## 📦 Installation

### Swift Package Manager

In Xcode, go to File > Add Package Dependencies and enter:

```
https://github.com/cometchat/calls-sdk-ios.git
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'CometChatCallsSDK', '5.0.0-beta.3'
end
```

Then run:

```bash
pod install
```

For the complete setup guide, refer to our [official documentation](https://www.cometchat.com/docs/calls/ios/overview).

## 🚀 Explore the Sample Apps

Dive straight into our sample apps to see the CometChat Calls SDK in action.

| Sample App | Description |
|------------|-------------|
| [Standalone Calling](sample-apps/cometchat-calls-sample-app-ios#readme) | Join or start meetings with a session ID — Calls SDK only |
| [Ringing](sample-apps/cometchat-calls-sample-app-ringing-ios#readme) | Full ringing flow with user list, incoming/outgoing screens — Chat SDK + Calls SDK |

## 🤖 Agent Skills

This repository includes agent skills in `skills/` for AI-assisted development. See the [skills README](skills/README.md) for the full list.

---

## Help and Support

For issues running the project or integrating with our UI Kits, consult our [documentation](https://www.cometchat.com/docs/calls/ios/overview) or create a [support ticket](https://help.cometchat.com/hc/en-us) or seek real-time support via the [CometChat Dashboard](https://app.cometchat.com/).
