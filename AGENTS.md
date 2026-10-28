# CometChat Calls SDK v5 — iOS

This repository contains the CometChat Calls SDK sample apps for iOS. When working with this codebase, use the agent skills in the `skills/` directory for SDK-specific guidance.

## Skills

Load the relevant skill based on the task:

### Core
- `skills/setup/SKILL.md` — SPM, CallAppSettingsBuilder, CometChatCalls init, Info.plist permissions
- `skills/join-session/SKILL.md` — CometChatCalls.joinSession, SessionSettingsBuilder, UIView container, UIViewRepresentable
- `skills/ringing-integration/SKILL.md` — Calls SDK 5.1 initiateCall / endCall, prepared sessions, 1:1 and group ringing
- `skills/session-settings/SKILL.md` — All SessionSettingsBuilder options: layouts, session type, audio mode, hide buttons
- `skills/event-listeners/SKILL.md` — SessionStatusListener, ParticipantEventListener, MediaEventsListener, ButtonClickListener
- `skills/call-logs/SKILL.md` — CallLogRequest, fetching and displaying call history

### Advanced
- `skills/recording/SKILL.md` — Auto-start recording, recording events
- `skills/screen-sharing/SKILL.md` — Screen share viewing, presenter status
- `skills/picture-in-picture/SKILL.md` — PiP mode configuration
- `skills/background-handling/SKILL.md` — Background modes, AVAudioSession, keeping calls alive
- `skills/voip-calling/SKILL.md` — Push Notifications SDK 2.0: VoIP push + CallKit in every app state, APNs provider
- `skills/audio-controls/SKILL.md` — Mute/unmute, audio route switching
- `skills/video-controls/SKILL.md` — Camera on/off, switch camera
- `skills/participant-management/SKILL.md` — Participant list, mute/kick, raise hand
- `skills/custom-ui/SKILL.md` — Custom control panel, UIViewRepresentable patterns
- `skills/in-call-chat/SKILL.md` — In-call messaging during active session

## Key Rules

- Use `CometChatCallsSDK` module import (not `CometChatCalls`)
- `CallSession.shared` (not `CallSession.getInstance()`)
- `SessionSettingsBuilder()` to configure call settings
- `CallAppSettingsBuilder().set(appID:).set(region:).build()` for init
- UIView container for call rendering (wrap in `UIViewRepresentable` for SwiftUI)
- Language: Swift 5.0+, SwiftUI. Platform: iOS 15.1+
- Dependency management: Swift Package Manager
- Documentation: https://www.cometchat.com/docs/calls/ios/overview
