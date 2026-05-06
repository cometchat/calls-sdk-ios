---
name: call-logs
description: Fetch call history using CallLogsRequest with pagination and filters. Use when displaying call logs, filtering by type/status/recording, or accessing recordings. Triggers on "call logs", "call history", "CallLogsRequest", "fetch recordings".
inclusion: manual
---

# CometChat Calls SDK v5 — Call Logs

## Overview

Retrieve call history using `CallLogsRequest` with pagination, filtering by type, status, direction, recordings, and specific users/groups.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### Basic Fetch

```swift
let request = CallLogsRequest.CallLogsBuilder()
    .set(limit: 30)
    .build()

request.fetchNext(onSuccess: { callLogs in
    for log in callLogs {
        print("Session: \(log.sessionID), Duration: \(log.totalDurationInMinutes), Status: \(log.status)")
    }
}, onError: { error in
    print("Error: \(error?.errorDescription ?? "")")
})
```

### Filtered Queries

```swift
// Video calls only
CallLogsRequest.CallLogsBuilder().set(callType: SessionType.video).set(limit: 20).build()

// Calls with recordings
CallLogsRequest.CallLogsBuilder().set(hasRecording: true).build()

// Missed incoming calls
CallLogsRequest.CallLogsBuilder().set(callStatus: CallStatus.missed).set(callDirection: CallDirection.incoming).build()

// Calls with a specific user
CallLogsRequest.CallLogsBuilder().set(uid: "user_id").build()
```

### Pagination

```swift
// Forward pagination
request.fetchNext(onSuccess:onError:)

// Backward pagination
request.fetchPrevious(onSuccess:onError:)
```

### Access Recordings

```swift
for callLog in callLogs {
    if callLog.hasRecording {
        callLog.recordings?.forEach { recording in
            print("URL: \(recording.recordingURL)")
            print("Duration: \(recording.duration) seconds")
        }
    }
}
```

## Gotchas

- `CallLogsRequest` is from the Calls SDK, not the Chat SDK
- `set(callType:)` takes `SessionType` enum: `.video` or `.audio`
- `set(callDirection:)` takes `CallDirection` enum: `.incoming` or `.outgoing`
- Auth token is automatically resolved from the SDK's stored login token — no need to pass it manually
- Create a new `CallLogsRequest` to reset pagination

## Sample App Reference

- `CallLogsView.swift` — Fetching and displaying call history in a SwiftUI List
