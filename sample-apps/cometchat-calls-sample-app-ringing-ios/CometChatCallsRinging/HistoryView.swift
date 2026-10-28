import SwiftUI
import CometChatCallsSDK

// MARK: - HistoryViewModel

/// The signed-in user's call logs, newest first. Reloaded every time the tab appears, so a
/// call that just ended is already in the list.
final class HistoryViewModel: ObservableObject {
    @Published private(set) var logs: [CallLog] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorText: String?

    private var request: CallLogsRequest?
    private var hasMore = true
    private var generation = 0
    private let pageSize = 30

    func reload() {
        generation += 1
        hasMore = true
        errorText = nil
        isLoading = false
        request = CallLogsRequest.CallLogsBuilder().set(limit: pageSize).build()
        loadMore(replacing: true)
    }

    func loadMore(replacing: Bool = false) {
        guard hasMore, !isLoading, let request else { return }
        isLoading = true
        let current = generation
        request.fetchNext { [weak self] page in
            DispatchQueue.main.async {
                guard let self, current == self.generation else { return }
                self.isLoading = false
                self.hasMore = page.count >= self.pageSize
                // Replacing on the first page keeps the old rows on screen until the new
                // ones arrive, instead of flashing an empty list on every visit.
                self.logs = replacing ? page : self.logs + page
            }
        } onError: { [weak self] error in
            DispatchQueue.main.async {
                guard let self, current == self.generation else { return }
                self.isLoading = false
                self.hasMore = false
                if self.logs.isEmpty { self.errorText = error?.errorDescription ?? "Couldn't load call history" }
            }
        }
    }

    func rowAppeared(at index: Int) {
        if index >= logs.count - 3 { loadMore() }
    }
}

// MARK: - HistoryView

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        content
            .background(Color.appBackground)
            .onAppear { viewModel.reload() }
    }

    @ViewBuilder
    private var content: some View {
        if let errorText = viewModel.errorText {
            ListMessage(icon: "exclamationmark.triangle.fill", title: errorText, actionTitle: "Retry") {
                viewModel.reload()
            }
        } else if viewModel.logs.isEmpty && viewModel.isLoading {
            VStack(spacing: AppSpacing.md) {
                ProgressView().tint(.brandAccent)
                Text("Loading call history…").font(AppType.caption).foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.logs.isEmpty {
            ListMessage(icon: "clock", title: "No calls yet", subtitle: "Calls you make and receive show up here.")
        } else {
            List {
                ForEach(Array(viewModel.logs.enumerated()), id: \.element.sessionID) { index, log in
                    NavigationLink { CallDetailsView(log: log) } label: { CallLogRow(log: log) }
                        .onAppear { viewModel.rowAppeared(at: index) }
                        .plainListRow()
                }
                if viewModel.isLoading {
                    ProgressView().tint(.brandAccent).frame(maxWidth: .infinity).plainListRow()
                }
            }
            .listStyle(.plain)
            .hiddenScrollBackground()
            .refreshable { viewModel.reload() }
        }
    }
}

// MARK: - Display helpers

/// How a call log reads in the list and on the details screen.
enum CallLogDisplay {
    static func kind(_ log: CallLog) -> String {
        guard log.mode == .call else { return "Meeting" }
        if log.receiverType == .callGroup { return "Group call" }
        return isVoice(log) ? "Voice call" : "Video call"
    }

    static func isVoice(_ log: CallLog) -> Bool {
        ["voice", "audio"].contains(log.type.value.lowercased())
    }

    static func status(_ log: CallLog) -> (label: String, color: Color) {
        switch log.status {
        case .ongoing: return ("Live", .statusOnline)
        case .ended: return ("Ended", .textSecondary)
        case .cancelled: return ("Cancelled", .statusError)
        case .unanswered: return ("No answer", .statusError)
        case .missed: return ("Missed", .statusError)
        case .rejected: return ("Declined", .statusError)
        case .busy: return ("Busy", .statusError)
        case .initiated: return ("Not connected", .statusError)
        @unknown default: return ("Unknown", .textSecondary)
        }
    }

    /// The other side of the call: the group for a group call, otherwise whichever of the
    /// initiator and receiver is not the signed-in user.
    static func counterpart(_ log: CallLog) -> (id: String, name: String, avatar: String?, isGroup: Bool)? {
        if let group = log.receiver as? CallGroup {
            return (group.guid, log.receiver.name, group.icon, true)
        }
        let me = CometChatCalls.getLoggedInUser()?.uid
        for entity in [log.initiator, log.receiver] {
            if let user = entity as? CallUser, !user.uid.isEmpty, user.uid != me {
                return (user.uid, entity.name, user.avatar, false)
            }
        }
        return nil
    }

    static func title(_ log: CallLog) -> String {
        counterpart(log)?.name ?? log.receiver.name
    }

    static func date(_ seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    static func time(_ seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "—" }
        return Date(timeIntervalSince1970: TimeInterval(seconds)).formatted(date: .omitted, time: .shortened)
    }

    static func duration(minutes: Double) -> String {
        let total = Int((minutes * 60).rounded())
        guard total > 0 else { return "—" }
        let (h, m, s) = (total / 3600, (total % 3600) / 60, total % 60)
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

// MARK: - Row

private struct CallLogRow: View {
    let log: CallLog

    var body: some View {
        let status = CallLogDisplay.status(log)
        let counterpart = CallLogDisplay.counterpart(log)
        HStack(spacing: AppSpacing.md) {
            AvatarView(name: CallLogDisplay.title(log), avatarURL: counterpart?.avatar, size: 40,
                       initialsCount: counterpart?.isGroup == true ? 2 : 1)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppSpacing.sm) {
                    Text(CallLogDisplay.title(log))
                        .font(AppType.bodyStrong)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    KindChip(text: CallLogDisplay.kind(log))
                }
                HStack(spacing: 6) {
                    Circle().fill(status.color).frame(width: 8, height: 8)
                    Text(status.label)
                        .foregroundColor(status.color == .textSecondary ? .textSecondary : status.color)
                    Text("·").foregroundColor(.textTertiary)
                    Text("\(CallLogDisplay.date(log.initiatedAt)), \(CallLogDisplay.time(log.initiatedAt))")
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                .font(AppType.caption)
            }
            Spacer(minLength: AppSpacing.sm)
            VStack(alignment: .trailing, spacing: 4) {
                ParticipantStack(participants: log.participants)
                Text(CallLogDisplay.duration(minutes: log.totalDurationInMinutes))
                    .font(AppType.caption.monospacedDigit())
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}

private struct KindChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppType.label)
            .foregroundColor(.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.background2))
            .fixedSize()
    }
}

/// Up to three overlapping participant avatars, then "+N".
private struct ParticipantStack: View {
    let participants: [Participant]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(participants.prefix(3).enumerated()), id: \.offset) { _, participant in
                AvatarView(name: participant.name, avatarURL: participant.avatar, size: 26)
                    .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
            }
            if participants.count > 3 {
                Text("+\(participants.count - 3)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.background3))
                    .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
            }
        }
    }
}

// MARK: - Details

struct CallDetailsView: View {
    let log: CallLog
    @EnvironmentObject var appState: AppState

    var body: some View {
        let status = CallLogDisplay.status(log)
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading,
                          spacing: AppSpacing.lg) {
                    field("Status") {
                        Text(status.label)
                            .font(AppType.label)
                            .foregroundColor(status.color)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .fill(status.color == .textSecondary ? Color.statusNeutralBg
                                      : status.color == .statusOnline ? .statusSuccessBg : .statusErrorBg))
                    }
                    field("Duration") { value(CallLogDisplay.duration(minutes: log.totalDurationInMinutes)) }
                    field("Started") { value("\(CallLogDisplay.date(log.startedAt ?? log.initiatedAt)), \(CallLogDisplay.time(log.startedAt ?? log.initiatedAt))") }
                    field("Ended") { value(CallLogDisplay.time(log.endedAt)) }
                    field("Type") { value(CallLogDisplay.kind(log)) }
                    field("Participants") { value("\(log.participants.count)") }
                }
                .cardStyle()

                if let counterpart = CallLogDisplay.counterpart(log) {
                    Button {
                        appState.startCall(receiverID: counterpart.id, name: counterpart.name,
                                           avatarURL: counterpart.avatar,
                                           callType: CallLogDisplay.isVoice(log) ? CallSessionType.audio : CallSessionType.video,
                                           isGroup: counterpart.isGroup)
                    } label: {
                        Label(callBackTitle(counterpart.isGroup), systemImage: CallLogDisplay.isVoice(log) ? "phone.fill" : "video.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    SectionLabel(text: "Session ID")
                    Text(log.sessionID)
                        .font(AppType.code)
                        .foregroundColor(.textPrimary)
                        .textSelection(.enabled)
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: AppRadius.medium).fill(Color.codeBackground))
                }

                if !log.participants.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionLabel(text: "Participants")
                        VStack(spacing: 0) {
                            ForEach(Array(log.participants.enumerated()), id: \.offset) { index, participant in
                                participantRow(participant)
                                if index < log.participants.count - 1 {
                                    Divider().background(Color.borderLight).padding(.leading, 64)
                                }
                            }
                        }
                        .surfaceSection()
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Call details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        let counterpart = CallLogDisplay.counterpart(log)
        return HStack(spacing: AppSpacing.md) {
            AvatarView(name: CallLogDisplay.title(log), avatarURL: counterpart?.avatar, size: 56,
                       initialsCount: counterpart?.isGroup == true ? 2 : 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(CallLogDisplay.title(log))
                    .font(AppType.title)
                    .foregroundColor(.textPrimary)
                Text(CallLogDisplay.kind(log))
                    .font(AppType.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private func callBackTitle(_ isGroup: Bool) -> String {
        let kind = CallLogDisplay.isVoice(log) ? "voice" : "video"
        return isGroup ? "Ring the group (\(kind))" : "Call back (\(kind))"
    }

    private func field<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(AppType.caption).foregroundColor(.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func value(_ text: String) -> some View {
        Text(text).font(AppType.bodyStrong).foregroundColor(.textPrimary)
    }

    private func participantRow(_ participant: Participant) -> some View {
        HStack(spacing: AppSpacing.md) {
            AvatarView(name: participant.name, avatarURL: participant.avatar, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.name ?? participant.uid ?? "Unknown")
                    .font(AppType.bodyStrong)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                if let state = participant.state, !state.isEmpty {
                    Text(state.capitalized).font(AppType.caption).foregroundColor(.textSecondary)
                }
            }
            Spacer()
            Text(CallLogDisplay.duration(minutes: participant.totalDurationInMinutes ?? 0))
                .font(AppType.caption.monospacedDigit())
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }
}
