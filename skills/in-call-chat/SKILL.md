---
name: in-call-chat
description: Add in-call messaging using CometChat Chat SDK. Use when implementing chat during calls, chat button, unread badge count, or group messaging linked to call session. Triggers on "in-call chat", "chat during call", "chat button", "in call messaging".
inclusion: manual
---

# CometChat Calls SDK v5 — In-Call Chat

## Overview

Add real-time text messaging during calls. Uses a CometChat Group (GUID = session ID) for chat. Requires Chat SDK alongside the Calls SDK.

## Prerequisites

- Calls SDK + Chat SDK integrated
- Both SDKs initialized and user logged in

## Key Imports

```swift
import CometChatCallsSDK
import CometChatSDK
```

## Implementation

### 1. Enable Chat Button

```swift
let settings = SessionSettingsBuilder()
    .hideChatButton(false)  // show chat button (hidden by default)
    .build()
```

### 2. Create/Join Chat Group

Use session ID as group GUID:

```swift
func setupChatGroup(sessionId: String) {
    CometChat.getGroup(GUID: sessionId) { group in
        if !group.hasJoined {
            CometChat.joinGroup(GUID: sessionId, groupType: .public, password: nil) { group in
                print("Joined chat group")
            } onError: { error in
                print("Join group failed: \(error?.errorDescription ?? "")")
            }
        }
    } onError: { error in
        // Group doesn't exist, create it
        let group = Group(guid: sessionId, name: "Call Chat", groupType: .public, password: nil)
        CometChat.createGroup(group: group) { group in
            print("Created chat group")
        } onError: { error in
            print("Create group failed: \(error?.errorDescription ?? "")")
        }
    }
}
```

### 3. Handle Chat Button Click

```swift
class ButtonHandler: NSObject, ButtonClickListener {
    var onChatTapped: (() -> Void)?

    func onChatButtonClicked() {
        CallSession.shared.setChatButtonUnreadCount(0)
        onChatTapped?()
    }
    // ... other required methods
}
```

### 4. Track Unread Messages

```swift
CometChat.addMessageListener("call_chat_listener", self)

// CometChatMessageDelegate
func onTextMessageReceived(textMessage: TextMessage) {
    if let group = textMessage.receiver as? Group, group.guid == sessionId {
        unreadCount += 1
        CallSession.shared.setChatButtonUnreadCount(unreadCount)
    }
}
```

## Gotchas

- Chat button is hidden by default — use `.hideChatButton(false)` to show it
- The group GUID should match the session ID to link chat to the call
- `setChatButtonUnreadCount()` updates the badge on the built-in chat button
- Remove message listeners when the call ends to prevent retain cycles

## Sample App Reference

- `CallView.swift` — Session settings and button click listener setup
