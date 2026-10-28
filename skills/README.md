# CometChat Calls SDK v5 — iOS Skills

Agent skills for building with the CometChat Calls SDK v5 on iOS. Install individually or browse all available skills.

## How It Works

Skills are bundled in this repository under `skills/`. When you clone the repo and open it in a supported AI coding assistant, skills auto-trigger based on what you're doing — mention "join session" and the join-session skill loads, ask about "CallKit" and the voip-calling skill loads. No manual activation needed.

To use these skills in your own project, copy the `skills/` folder into your project root:

```bash
cp -r skills/ /path/to/your/project/skills/
```

## Available Skills

### Core

| Skill | Triggers On |
|-------|-------------|
| `setup` | SPM/CocoaPods, CallAppSettingsBuilder, CometChatCalls init, Info.plist permissions |
| `join-session` | CometChatCalls.joinSession, SessionSettingsBuilder, UIView container |
| `ringing-integration` | Calls SDK 5.1 initiateCall / endCall, prepared sessions, 1:1 and group ringing, answered calls |
| `session-settings` | All SessionSettingsBuilder options: layouts, session type, audio mode, hide buttons |
| `event-listeners` | SessionStatusListener, ParticipantEventListener, MediaEventsListener, ButtonClickListener |
| `call-logs` | CallLogRequest, fetching and displaying call history |

### Advanced

| Skill | Triggers On |
|-------|-------------|
| `recording` | Auto-start recording, recording events |
| `screen-sharing` | Screen share viewing, presenter status |
| `picture-in-picture` | PiP mode configuration |
| `background-handling` | Background modes, AVAudioSession, keeping calls alive |
| `voip-calling` | Push Notifications SDK 2.0: VoIP push + CallKit in every app state, APNs provider, tokens |
| `audio-controls` | Mute/unmute, audio route switching |
| `video-controls` | Camera on/off, switch camera |
| `participant-management` | Participant list, mute/kick, raise hand |
| `custom-ui` | Custom control panel, UIViewRepresentable patterns |
| `in-call-chat` | In-call messaging during active session |

## How Auto-Detection Works

Each skill has a `description` field in its YAML frontmatter that lists trigger keywords. When you mention something related (like "join a call" or "add CallKit support"), the agent reads the description, decides the skill is relevant, and loads its full content. You never need to manually select a skill.

## Compatibility

- CometChat Calls SDK v5 (5.1.0+)
- CometChat Chat SDK 4.1.10 or later — required by the Push Notifications SDK 2.0 chat and calls products; the Chat SDK carries no call signalling
- Swift 5.0+, SwiftUI
- iOS 15.1+, Xcode 16.4+
- SPM (preferred) or CocoaPods — Calls SDK 5.1.0 and Push Notifications SDK 2.0 are not on the CocoaPods trunk yet, so use SPM until they are
- Works with: Kiro, Claude Code, Cursor, Copilot, and other AI coding assistants that support the skills ecosystem
