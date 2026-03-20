<p align="center">
  <img alt="CometChat" src="https://assets.cometchat.io/website/images/logos/banner.png">
</p>

# iOS Calls Sample App by CometChat

This is a reference application showcasing the integration of [CometChat's iOS Calls SDK](https://www.cometchat.com/docs/calls/ios/overview) in a SwiftUI project. It demonstrates how to implement real-time voice and video calling features with ease.

<p align="center">
  <img src="../../screenshots/showcase-1.png" alt="iOS Screenshot 1" width="30%">&nbsp;&nbsp;
  <img src="../../screenshots/showcase-2.png" alt="iOS Screenshot 2" width="30%">&nbsp;&nbsp;
  <img src="../../screenshots/showcase-3.png" alt="iOS Screenshot 3" width="30%">
</p>


## Prerequisites

Sign up for a [CometChat](https://app.cometchat.com/) account to obtain your app credentials: _`App ID`_, _`Region`_, and _`Auth Key`_

- Xcode 15 or later
- iOS 15.0+
- Swift 5.0+


## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/cometchat/calls-sdk-ios.git
   ```

1. Open the Xcode project:
   ```sh
   cd sample-apps/cometchat-calls-sample-app-ios
   open CometChatCallsSample.xcodeproj
   ```

1. Wait for Swift Package Manager to resolve dependencies automatically.

1. `[Optional]` Configure CometChat credentials:
    - Open `AppConstants.swift` and enter your CometChat _`appID`_, _`region`_, and _`authKey`_:
      ```swift
      enum AppConstants {
          static let appID = "YOUR_APP_ID"
          static let region = "YOUR_REGION"
          static let authKey = "YOUR_AUTH_KEY"
      }
      ```
    - Alternatively, you can enter your credentials on first launch via the in-app credentials screen.

1. Select your target device or simulator and run the app.


## Help and Support

For issues running the project or integrating with our UI Kits, consult our [documentation](https://www.cometchat.com/docs/calls/ios/overview) or create a [support ticket](https://help.cometchat.com/hc/en-us). You can also access real-time support via the [CometChat Dashboard](http://app.cometchat.com/).
