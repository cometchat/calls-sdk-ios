<p align="center">
  <img alt="CometChat" src="https://assets.cometchat.io/website/images/logos/banner.png">
</p>


# CometChat iOS Calls SDK

CometChat enables you to add voice, video & text chat for your website & app.
___

## Prerequisites :star:

Before you begin, ensure you have met the following requirements:

✅ &nbsp; You have installed the latest version of Xcode. (Above Xcode 12 Recommended)

✅ &nbsp; iOS Calls SDK works for iOS devices from iOS 11 and above.

___

## Installing iOS Chat SDK 

## 1. Setup  :wrench:

To install iOS Call SDK, you need to first register on CometChat Dashboard. Click here to [sign up](https://app.cometchat.com/login).

### i. Get your Application Keys :key:

* Create a new app
* Head over to the Quick Start or API & Auth Keys section and note the `App ID`, `Auth Key`,  and  `Region`.
---

### ii. Add the CometChatCallsSDK Dependency


We recommend using CocoaPods, as they are the most advanced way of managing iOS project dependencies. Open a terminal window, move to your project directory, and then create a Podfile by running the following command


Create podfile using below command.

```bash
$ pod init
```
Add the following lines to the Podfile.

```bash
________________________________________________________________

For Xcode 12 and above:

platform :ios, '11.0'
use_frameworks!

target 'YourApp' do
     pod 'CometChatCallsSDK', '4.0.5'
end
________________________________________________________________


```
And then install the `CometChatCallsSDK` framework through CocoaPods.

```bash
pod install
```

If you're facing any issues while installing pods then use the below command. 


```bash
pod install --repo-update
```

___

## 2. Configure CometChat inside your app

### i. Initialize CometChat :star2:

The `init()` method initializes the settings required for CometChatCallsSDK. We suggest calling the `init()` method on app startup, preferably in the `didFinishLaunchingWithOptions()` method of the Application class. If you are using CometChat's iOS Chats SDK then initialize Calls SDK after initializing Chat SDK. 

```swift
import Foundation
import CometChatCallsSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let callAppSettings = CallAppSettingsBuilder()
            .setAppId(APP_ID)
            .setRegion(REGION)
            .build()
        
        CometChatCalls.init(callsAppSettings: callAppSettings) { success in
            print("CometChatCalls init success")
        } onError: { error in
            print("CometChatCalls init failed With error \(error)")
        }
        
        return true
    }
```
**Note :**
Make sure you replace the APP_ID with your CometChat `appId` and `region` with your app region in the above code.

___

**Note :** </br>
* Make sure you replace the `authKey` with your CometChat Auth Key in the above code.

* We have set up 5 users for testing having UIDs: `SUPERHERO1`, `SUPERHERO2`, `SUPERHERO3`, `SUPERHERO4`, and `SUPERHERO5`.

---

# Checkout our sample apps

## Swift: 
Visit our [Swift sample app](https://github.com/cometchat/cometchat-sample-app-ios) repo to run the Swift sample app.

---


## Help and Support
For issues running the project or integrating with our UI Kits, consult our [documentation](https://www.cometchat.com/docs/react-uikit/integration) or create a [support ticket](https://help.cometchat.com/hc/en-us) or seek real-time support via the [CometChat Dashboard](https://app.cometchat.com/).
