# CometChat Calls SDK — Ringing Sample App (iOS)

A sample iOS app demonstrating the CometChat ringing flow using both the **Chat SDK** (for call signaling) and the **Calls SDK** (for session management). This app shows how to initiate, receive, accept, reject, and end calls with a complete ringing experience.

## Prerequisites

- Xcode 15 or later
- iOS 15.0+, Swift 5.0+
- A [CometChat](https://www.cometchat.com/) account with:
  - App ID
  - Auth Key
  - Region (US, EU, or IN)

## Setup

1. Clone the repository and open the Xcode project:
   ```sh
   git clone https://github.com/cometchat/calls-sdk-ios.git
   cd sample-apps/cometchat-calls-sample-app-ringing-ios
   open CometChatCallsRinging.xcodeproj
   ```
2. Wait for Swift Package Manager to resolve dependencies.
3. On first launch, enter your CometChat **App ID**, **Auth Key**, and select your **Region**.
   - Alternatively, set them in `AppConstants.swift` before building.
4. Log in with a sample user or enter a UID manually.

## Features

- **Dual SDK Integration** — Chat SDK handles call signaling (initiate, accept, reject, cancel, end); Calls SDK handles the media session.
- **User List** — Browse CometChat users with audio and video call buttons.
- **Outgoing Call Screen** — Shows receiver info with a cancel button. Listens for accepted/rejected events.
- **Incoming Call Screen** — Shows caller info with accept and reject buttons. Auto-dismisses if the caller cancels.
- **Call Session** — Full call UI powered by `CometChatCalls.joinSession()` with SwiftUI UIViewRepresentable.
- **Global Incoming Call Listener** — Receives incoming calls from any screen.
- **Call Logs** — View call history with pull-to-refresh.

## Architecture

The app follows a SwiftUI MVVM pattern:

- **Views** — SwiftUI views for each screen
- **AppState** — ObservableObject managing navigation, dual SDK init, and credentials
- **UIViewRepresentable** — Bridges the Calls SDK UIView container into SwiftUI

## Project Structure

```
cometchat-calls-sample-app-ringing-ios/
├── CometChatCallsRinging/
│   ├── CometChatCallsRingingApp.swift  # @main entry point
│   ├── AppConstants.swift              # Credentials
│   ├── AppState.swift                  # Dual SDK init, navigation, call listener
│   ├── Styles.swift                    # Design system (colors, buttons, text fields)
│   ├── SampleUser.swift                # Sample user model + fetch
│   ├── RootView.swift                  # Screen router
│   ├── SplashView.swift                # Bootstrap screen
│   ├── AppCredentialsView.swift        # Region + credentials input
│   ├── LoginView.swift                 # Sample user / UID login
│   ├── HomeView.swift                  # Tabbed home (Users + Call Logs)
│   ├── UsersView.swift                 # User list with call buttons
│   ├── CallLogsView.swift              # Call history
│   ├── OutgoingCallView.swift          # Outgoing call UI
│   ├── IncomingCallView.swift          # Incoming call UI
│   └── CallView.swift                  # Active call session
├── CometChatCallsRinging.xcodeproj/
└── README.md
```

## Dependencies

- `CometChatCallsSDK` v5.0.0 — Call session management (via local SPM package)
- `CometChatSDK` v4.0.+ — Call signaling, user management (via remote SPM)

## Build It with AI

This sample app was built using the agent skills in `skills/`. To recreate this exact functionality in your own project, copy the `skills/` folder and use this prompt with your AI coding assistant:

```text
Using the skills in skills/, build an iOS SwiftUI app with CometChat Calls SDK v5 and Chat
SDK v4 that implements a full ringing flow. The app should: let users enter App ID, Auth Key,
and Region; log in to both SDKs; show a user list with audio/video call buttons; initiate
calls via Chat SDK signaling; show incoming/outgoing call screens with accept/reject/cancel;
join the call session on accept using UIViewRepresentable; display call logs with
pull-to-refresh; and register a global incoming call listener. Use setup for SDK init,
ringing-integration for the call signaling flow, join-session and session-settings for the
call session, event-listeners for session and button events, background-handling for keeping
calls alive, and call-logs for call history.
```

**Skills used:** `setup`, `ringing-integration`, `join-session`, `session-settings`, `event-listeners`, `background-handling`, `call-logs`
