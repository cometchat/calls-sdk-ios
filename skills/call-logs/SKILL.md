---
name: call-logs
description: Fetch call history using CallLogRequest with pagination and filters. Use when displaying call logs, filtering by type/status/recording, or accessing recordings. Triggers on "call logs", "call history", "CallLogRequest", "fetch recordings".
inclusion: manual
---

# CometChat Calls SDK v5 — Call Logs

## Overview

Retrieve call history using `CallLogRequest` with pagination, filtering by type, status, direction, recordings, and specific users/groups.

## Key Imports

```swift
import CometChatCallsSDK
```

## Implementation

### Basic Fetch

```swift
let request = CallLogRequest.CallLogRequestBuilder()
    .set(limit: 30)
    .build()

request.fetchNext { callLogs in
    for log in callLogs {
        print("Session: \(log.sessionID), Duration: \(log.totalDuration), Status: \(log.status)")
    }
} onError: { error in
    print("Error: \(error?.errorDescription ?? "")")
}
```

### Filtered Queries

```swift
// Video calls only
CallLogRequest.CallLogRequestBuilder().set(sessionType: "video").set(limit: 20).build()

// Calls with recordings
CallLogRequest.CallLogRequestBuilder().set(hasRecording: true).build()

// Missed incoming calls
CallLogRequest.CallLogRequestBuilder().set(callStatus: "missed").set(callDirection: "incoming").build()

// Calls with a specific user
CallLogRequest.CallLogRequestBuilder().set(uid: "user_id").build()
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

- `CallLogRequest` is from the Calls SDK, not the Chat SDK
- `set(sessionType:)` takes lowercase strings: `"video"` or `"audio"`
- `set(callDirection:)` takes `"incoming"` or `"outgoing"`
- Create a new `CallLogRequest` to reset pagination

## Sample App Reference

- `CallLogsView.swift` — Fetching and displaying call history in a SwiftUI List
