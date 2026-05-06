import SwiftUI
import CometChatCallsSDK

struct CallLogsView: View {
    @State private var callLogs: [CallLog] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var hasMorePages = true
    @State private var errorText: String?
    @State private var callLogsRequest: CallLogsRequest?

    private let pageLimit = 30

    var body: some View {
        VStack(spacing: 0) {
            if errorText != nil {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.textSecondary)
                    Text(errorText ?? "")
                        .foregroundColor(.textSecondary)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Retry") {
                        self.errorText = nil
                        loadInitial()
                    }
                    .foregroundColor(.accentPurple)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.top, 4)
                }
                Spacer()
            } else if callLogs.isEmpty && !isLoading {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "phone.badge.clock")
                        .font(.system(size: 40))
                        .foregroundColor(.textSecondary)
                    Text("No call logs yet")
                        .foregroundColor(.textSecondary)
                        .font(.system(size: 14))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(callLogs.enumerated()), id: \.offset) { index, callLog in
                            CallLogRow(callLog: callLog)
                            if index < callLogs.count - 1 {
                                Divider()
                                    .padding(.leading, 64)
                            }
                            if index >= callLogs.count - 3 {
                                Color.clear.frame(height: 0)
                                    .onAppear { loadMore() }
                            }
                        }
                        if isLoadingMore {
                            ProgressView()
                                .tint(.accentPurple)
                                .padding()
                        }
                    }
                }
            }
            if isLoading && callLogs.isEmpty {
                ProgressView()
                    .tint(.accentPurple)
                    .padding()
            }
        }
        .background(Color.appBackground)
        .onAppear {
            if callLogs.isEmpty && callLogsRequest == nil {
                loadInitial()
            }
        }
    }

    // MARK: - Load Initial

    private func loadInitial() {
        isLoading = true
        errorText = nil
        callLogs = []
        hasMorePages = true

        callLogsRequest = CallLogsRequest.CallLogsBuilder()
            .set(limit: pageLimit)
            .build()

        callLogsRequest?.fetchNext(onSuccess: { logs in
            DispatchQueue.main.async {
                self.isLoading = false
                self.callLogs = logs
                self.hasMorePages = logs.count >= self.pageLimit
                print("[CallLogsView] Fetched \(logs.count) call logs")
            }
        }, onError: { error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorText = error?.errorDescription ?? "Failed to load call logs"
                print("[CallLogsView] Error: \(error?.errorDescription ?? "unknown")")
            }
        })
    }

    // MARK: - Load More

    private func loadMore() {
        guard hasMorePages, !isLoadingMore, let request = callLogsRequest else { return }
        isLoadingMore = true

        request.fetchNext(onSuccess: { logs in
            DispatchQueue.main.async {
                self.isLoadingMore = false
                self.callLogs.append(contentsOf: logs)
                self.hasMorePages = logs.count >= self.pageLimit
                print("[CallLogsView] Loaded more: \(logs.count) logs")
            }
        }, onError: { _ in
            DispatchQueue.main.async {
                self.isLoadingMore = false
                self.hasMorePages = false
            }
        })
    }
}

// MARK: - Call Log Row

private struct CallLogRow: View {
    let callLog: CallLog

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentPurple.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: callLog.type == .video ? "video.fill" : "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentPurple)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(participantNames)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 10))
                        .foregroundColor(statusColor)
                    Text(statusText)
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if callLog.totalDurationInMinutes > 0 {
                    Text(formatDuration(callLog.totalDurationInMinutes))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                if callLog.initiatedAt > 0 {
                    Text(formatTime(Double(callLog.initiatedAt)))
                        .font(.system(size: 11))
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var participantNames: String {
        // Show the other party's name from initiator/receiver
        let loggedInUID = (CometChatCalls.getLoggedInUser()?.uid) ?? ""
        
        if let initiatorUser = callLog.initiator as? CallUser,
           initiatorUser.uid == loggedInUID {
            // Current user initiated — show receiver name
            let receiverName = callLog.receiver.name
            return receiverName.isEmpty ? "Unknown" : receiverName
        } else {
            // Current user received — show initiator name
            let initiatorName = callLog.initiator.name
            return initiatorName.isEmpty ? "Unknown" : initiatorName
        }
    }

    private var statusText: String {
        switch callLog.status {
        case .ongoing: return "Ongoing"
        case .busy: return "Busy"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        case .ended: return "Ended"
        case .initiated: return "Initiated"
        case .unanswered: return "Unanswered"
        case .missed: return "Missed"
        @unknown default: return "Unknown"
        }
    }

    private var statusIcon: String {
        switch callLog.status {
        case .ended: return "arrow.down.left"
        case .unanswered, .cancelled, .missed: return "phone.arrow.down.left"
        case .rejected, .busy: return "phone.down.fill"
        default: return "phone.fill"
        }
    }

    private var statusColor: Color {
        switch callLog.status {
        case .ended: return .green
        case .unanswered, .cancelled, .rejected, .busy, .missed: return .statusError
        default: return .textTertiary
        }
    }

    private func formatDuration(_ minutes: Double) -> String {
        let totalSeconds = Int(minutes * 60)
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private func formatTime(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
