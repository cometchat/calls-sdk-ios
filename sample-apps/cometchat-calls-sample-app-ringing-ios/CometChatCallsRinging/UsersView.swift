import SwiftUI
import CometChatSDK
import CometChatCallsSDK

// MARK: - UsersViewModel

/// Pages through the app's users, with a debounced search.
///
/// Every request carries a generation number, and a page that arrives after the list was
/// reset (a new search, a refresh) is dropped. Without that, a slow page from an old keyword
/// can land after the new one and leave the list showing the wrong people.
final class UsersViewModel: ObservableObject {
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorText: String?
    @Published var searchText = "" {
        didSet { if searchText != oldValue { scheduleSearch() } }
    }

    private var request: UsersRequest?
    private var hasMore = true
    private var generation = 0
    private var searchWork: DispatchWorkItem?
    private let pageSize = 30

    func loadIfNeeded() {
        if users.isEmpty && !isLoading { reload() }
    }

    func reload() {
        searchWork?.cancel()
        generation += 1
        users = []
        hasMore = true
        errorText = nil
        isLoading = false
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        var builder = UsersRequest.UsersRequestBuilder().set(limit: pageSize)
        if !keyword.isEmpty { builder = builder.set(searchKeyword: keyword) }
        request = builder.build()
        loadMore()
    }

    /// Loads the next page; called when one of the last rows appears.
    func loadMore() {
        guard hasMore, !isLoading, let request else { return }
        isLoading = true
        let current = generation
        request.fetchNext(onSuccess: { [weak self] page in
            DispatchQueue.main.async {
                guard let self, current == self.generation else { return }
                self.isLoading = false
                self.hasMore = page.count >= self.pageSize
                let me = CometChat.getLoggedInUser()?.uid
                self.users.append(contentsOf: page.filter { $0.uid != me })
            }
        }, onError: { [weak self] error in
            DispatchQueue.main.async {
                guard let self, current == self.generation else { return }
                self.isLoading = false
                self.hasMore = false
                if self.users.isEmpty { self.errorText = error?.errorDescription ?? "Couldn't load users" }
            }
        })
    }

    func rowAppeared(_ user: User) {
        if let index = users.firstIndex(where: { $0.uid == user.uid }), index >= users.count - 3 {
            loadMore()
        }
    }

    private func scheduleSearch() {
        searchWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        searchWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }
}

// MARK: - UsersView

struct UsersView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = UsersViewModel()

    var body: some View {
        VStack(spacing: 0) {
            SearchField(placeholder: "Search users", text: $viewModel.searchText)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)

            if let errorText = viewModel.errorText {
                ListMessage(icon: "exclamationmark.triangle.fill", title: errorText, actionTitle: "Retry") {
                    viewModel.reload()
                }
            } else if viewModel.users.isEmpty && !viewModel.isLoading {
                ListMessage(
                    icon: "person.2",
                    title: viewModel.searchText.isEmpty ? "No users yet" : "No user called “\(viewModel.searchText)”"
                )
            } else {
                List {
                    ForEach(viewModel.users, id: \.uid) { user in
                        UserRow(user: user) { callType in
                            appState.startCall(receiverID: user.uid ?? "", name: user.name ?? "",
                                               avatarURL: user.avatar, callType: callType, isGroup: false)
                        }
                        .onAppear { viewModel.rowAppeared(user) }
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
        .background(Color.appBackground)
        .onAppear { viewModel.loadIfNeeded() }
    }
}

// MARK: - Rows

private struct UserRow: View {
    let user: User
    let onCall: (String) -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            AvatarView(name: user.name, avatarURL: user.avatar, size: 40, isOnline: user.status == .online)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? user.uid ?? "")
                    .font(AppType.bodyStrong)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text(user.status == .online ? "Online" : "Offline")
                    .font(AppType.caption)
                    .foregroundColor(user.status == .online ? .statusOnline : .textSecondary)
            }
            Spacer(minLength: AppSpacing.sm)
            CircleIconButton(systemName: "phone.fill", accessibilityLabel: "Voice call \(user.name ?? "")") {
                onCall(CallSessionType.audio)
            }
            CircleIconButton(systemName: "video.fill", accessibilityLabel: "Video call \(user.name ?? "")") {
                onCall(CallSessionType.video)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

/// An empty or error state: an icon, a line of text and an optional button.
struct ListMessage: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.textDisabled)
                .frame(width: 88, height: 88)
                .background(Circle().fill(Color.background2))
            Text(title)
                .font(AppType.bodyStrong)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(AppType.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    .padding(.top, AppSpacing.xs)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

extension View {
    /// A list row with no separator or background, inset like the rest of the screen.
    func plainListRow() -> some View {
        listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.lg, bottom: 4, trailing: AppSpacing.lg))
    }

    @ViewBuilder
    func hiddenScrollBackground() -> some View {
        if #available(iOS 16.0, *) {
            scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}
