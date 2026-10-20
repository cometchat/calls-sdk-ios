# CometChat Calls SDK — Ringing Sample App (iOS)

A sample iOS app showing 1:1 ringing calls with the **Calls SDK** and the **Push Notifications SDK**.
The caller places and ends the call with the Calls SDK; the callee's phone rings through CallKit — in the
foreground, in the background, locked or killed — and the session is prepared while it rings, so the call
connects as soon as it is answered.

## Prerequisites

- Xcode 16 or later
- iOS 15.1+ on a **physical device** to receive calls (PushKit and CallKit do not work in the simulator)
- A [CometChat](https://www.cometchat.com/) app with:
  - App ID, Auth Key and Region (US, EU or IN)
  - An **APNs push provider** for VoIP pushes (dashboard → Notifications → Push), and its provider ID
- An Apple developer team that can sign the app with the Push Notifications capability

## Setup

1. Clone the repository and open the Xcode project:
   ```sh
   git clone https://github.com/cometchat/calls-sdk-ios.git
   cd calls-sdk-ios/sample-apps/cometchat-calls-sample-app-ringing-ios
   open CometChatCallsRinging.xcodeproj
   ```
2. Wait for Swift Package Manager to resolve dependencies.
3. Under **Signing & Capabilities**, pick your team and change the bundle identifier to one your team owns.
   The project already has the Push Notifications capability and the Audio and Voice over IP background modes.
4. In the CometChat dashboard, set up an APNs provider with the VoIP certificate or `.p8` key for that bundle
   identifier.
5. Run on two devices. On first launch, enter your **App ID**, **Auth Key**, **Region** and the **Push
   Provider ID** — or set them in `AppConstants.swift` before building.
6. Log in as a different user on each device and call one from the other.

`aps-environment` is `development`, matching a development provisioning profile. A TestFlight or App Store build
needs `production`.

## How a call works

**Placing a call** (`OutgoingCallViewModel`)

1. `CometChatCalls.initiateCall(receiver:options:)` creates the call, rings the callee and starts preparing the
   session in the background. The session settings are frozen at this point, so the call screen builds the same
   ones (`CallSettings`).
2. `onParticipantConnected` — the callee's phone has the session: "Calling…" becomes "Ringing…".
3. `onParticipantJoined` — the callee answered: the call screen joins the prepared session by its ID.
4. The end button, or no answer after 45 seconds, withdraws the call with
   `CometChatCalls.endCall(sessionID:status: EndCallStatus.cancelled)`, which stops the callee's phone ringing.
5. A decline is not pushed to the caller, so a ringing call checks the server's call log every 3 seconds and
   shows "Declined" or "Busy".

Every decision is made by `OutgoingCall`, a small state machine with no SwiftUI or SDK code in it.

**Receiving a call** (`PushSetup`, `CallPushDelegate`, `IncomingCallPresenter`)

1. `PushSetup` initializes the Push Notifications SDK in `application(_:didFinishLaunchingWithOptions:)`. It has
   to happen there: iOS only delivers the VoIP push that launched the app if the PushKit registry exists by the
   time that method returns.
2. The SDK registers the device's VoIP token at login, receives the push, shows the CallKit incoming-call screen
   and prepares the session while it rings. Declines, missed calls and the caller cancelling are handled by the
   SDK.
3. When the user answers, the SDK calls `presentCall(_:)`. The app publishes a call screen, which joins by
   session ID — the prepared session, so only the media and the call UI are left to set up.
4. `callDidEnd(_:reason:)` takes the screen down when the call ends from CallKit or the far side.

**Logging out** waits for `CometChatPushNotifications.shared.unregisterTokens(completion:)` before logging out of
the SDKs: the request is authenticated by the session being logged out, and without it the device keeps ringing
for the user who left.

## Project Structure

```
cometchat-calls-sample-app-ringing-ios/
├── CometChatCallsRinging/
│   ├── CometChatCallsRingingApp.swift  # @main entry point, AppDelegate, push SDK setup
│   ├── AppConstants.swift              # Credentials (optional)
│   ├── Credentials.swift               # Credentials in use: AppConstants or the ones entered
│   ├── AppState.swift                  # SDK init, login, logout, navigation
│   ├── CallPushDelegate.swift          # Push SDK delegate: answered and ended calls
│   ├── IncomingCallPresenter.swift     # Answered call → call screen
│   ├── OutgoingCall.swift              # Outgoing call state machine
│   ├── OutgoingCallViewModel.swift     # Places the call and feeds the state machine
│   ├── OutgoingCallView.swift          # "Calling… / Ringing…" screen
│   ├── CallSessionViewModel.swift      # Joined call + shared session settings
│   ├── CallSessionView.swift           # Call screen
│   ├── Styles.swift                    # Colors, buttons, text fields
│   ├── SampleUser.swift                # Sample user model + fetch
│   ├── RootView.swift                  # Screen router
│   ├── SplashView.swift                # Bootstrap screen
│   ├── AppCredentialsView.swift        # Region + credentials input
│   ├── LoginView.swift                 # Sample user / UID login
│   ├── HomeView.swift                  # Tabs (Users + Call Logs) and the call screens
│   ├── UsersView.swift                 # User list with call buttons
│   └── CallLogsView.swift              # Call history
├── CometChatCallsRinging.xcodeproj/
├── project.yml                         # XcodeGen spec the project is generated from
└── README.md
```

## Dependencies

- `CometChatCallsSDK` 5.1 — calls, sessions and call logs (local SPM package at the repository root)
- `CometChatPushNotificationsCalls` 2.0 — VoIP push, CallKit and ringing
  ([push-notifications-sdk-ios](https://github.com/cometchat/push-notifications-sdk-ios))
- `CometChatSDK` 4.1.10+ — user list
