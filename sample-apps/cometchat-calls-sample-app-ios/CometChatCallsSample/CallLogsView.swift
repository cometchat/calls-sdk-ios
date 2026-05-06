import SwiftUI
import CometChatCallsSDK

/// Call history tab — uses CallLogsRequest.fetchNext() from the Calls SDK.
/// This is the same SDK API used by the Connect app's HistoryViewModel.
struct CallLogsView: View {
    @EnvironmentObject var appState: AppState
    @State private var callLogs: [CallLog] = []
    @State private var isLoading = false
    @State private var hasMorePages = true
    @State private var callLogsRequest: CallLogsRequest?
    @State private var errorText: String?

    private let pageLimit = 30

    var body: some View {
        VStack(spacing: 0) {
            Text("History")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

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
                List {
                    ForEach(Array(callLogs.enumerated()), id: \.element.mid) { index, callLog in
                        CallLogRow(callLog: callLog)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onAppear {
                                if index >= callLogs.count - 3 {
                                    loadMore()
                                }
                            }
                    }
                }
                .listStyle(.plain)
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

    private func loadInitial() {
        isLoading = true
        errorText = nil
        callLogs = []
        hasMorePages = true

        let request = CallLogsRequest.CallLogsBuilder()
            .set(limit: pageLimit)
            .build()
        callLogsRequest = request

        print("[CallLogsView] Fetching call logs via SDK...")
        request.fetchNext(onSuccess: { logs in
            DispatchQueue.main.async {
                isLoading = false
                callLogs = logs
                hasMorePages = logs.count >= pageLimit
                print("[CallLogsView] Fetched \(logs.count) call logs")
            }
        }, onError: { error in
            DispatchQueue.main.async {
                isLoading = false
                errorText = error?.errorDescription ?? "Failed to load call logs"
                print("[CallLogsView] Error: \(error?.errorDescription ?? "unknown") code: \(error?.errorCode ?? "")")
            }
        })
    }

    private func loadMore() {
        guard hasMorePages, let request = callLogsRequest else { return }
        request.fetchNext(onSuccess: { logs in
            DispatchQueue.main.async {
                callLogs.append(contentsOf: logs)
                hasMorePages = logs.count >= pageLimit
            }
        }, onError: { _ in
            DispatchQueue.main.async { hasMorePages = false }
        })
    }
}

// MARK: - Row

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
                Text(callLog.sessionID.isEmpty ? "Unknown" : String(callLog.sessionID.prefix(20)))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(statusText)
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                    if callLog.totalDurationInMinutes > 0 {
                        Text("• \(formatDuration(callLog.totalDurationInMinutes))")
                            .font(.system(size: 12))
                            .foregroundColor(.textTertiary)
                    }
                }
            }
            Spacer()
            if callLog.initiatedAt > 0 {
                Text(formatTime(Double(callLog.initiatedAt)))
                    .font(.system(size: 11))
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusText: String {
        switch callLog.status {
        case .ongoing: return "Ongoing"
        case .ended: return "Ended"
        case .cancelled: return "Cancelled"
        case .rejected: return "Rejected"
        case .unanswered: return "Unanswered"
        case .initiated: return "Initiated"
        case .busy: return "Busy"
        case .missed: return "Missed"
        @unknown default: return "Unknown"
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
