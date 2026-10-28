import SwiftUI
import CometChatSDK
import CometChatCallsSDK

/// The Chat SDK's group model, named apart from SwiftUI's `Group` view.
typealias ChatGroup = CometChatSDK.Group

// MARK: - GroupsViewModel

/// Pages through the groups the user has joined, with a debounced search. Stale pages are
/// dropped the same way `UsersViewModel` drops them.
final class GroupsViewModel: ObservableObject {
    @Published private(set) var groups: [ChatGroup] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorText: String?
    @Published var searchText = "" {
        didSet { if searchText != oldValue { scheduleSearch() } }
    }

    private var request: GroupsRequest?
    private var hasMore = true
    private var generation = 0
    private var searchWork: DispatchWorkItem?
    private let pageSize = 30

    func loadIfNeeded() {
        if groups.isEmpty && !isLoading { reload() }
    }

    func reload() {
        searchWork?.cancel()
        generation += 1
        groups = []
        hasMore = true
        errorText = nil
        isLoading = false
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        var builder = GroupsRequest.GroupsRequestBuilder(limit: pageSize).set(joinedOnly: true)
        if !keyword.isEmpty { builder = builder.set(searchKeyword: keyword) }
        request = builder.build()
        loadMore()
    }

    func loadMore() {
        guard hasMore, !isLoading, let request else { return }
        isLoading = true
        let current = generation
        request.fetchNext(onSuccess: { [weak self] page in
            DispatchQueue.main.async {
                guard let self, current == self.generation else { return }
                self.isLoading = false
                self.hasMore = page.count >= self.pageSize
                self.groups.append(contentsOf: page)
            }
        }, onError: { [weak self] error in
            DispatchQueue.main.async {
                guard let self, current == self.generation else { return }
                self.isLoading = false
                self.hasMore = false
                if self.groups.isEmpty { self.errorText = error?.errorDescription ?? "Couldn't load groups" }
            }
        })
    }

    func rowAppeared(_ group: ChatGroup) {
        if let index = groups.firstIndex(where: { $0.guid == group.guid }), index >= groups.count - 3 {
            loadMore()
        }
    }

    /// Shows a group created on this device straight away, ahead of the next reload.
    func insert(_ group: ChatGroup) {
        groups.removeAll { $0.guid == group.guid }
        groups.insert(group, at: 0)
    }

    private func scheduleSearch() {
        searchWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        searchWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }
}

// MARK: - GroupsView

/// The groups the user can ring. Calling a group rings every member; whoever answers joins
/// the same session, and the call carries on when one of them leaves.
struct GroupsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GroupsViewModel()
    @State private var showNewGroup = false

    var body: some View {
        VStack(spacing: 0) {
            SearchField(placeholder: "Search groups", text: $viewModel.searchText)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)

            if let errorText = viewModel.errorText {
                ListMessage(icon: "exclamationmark.triangle.fill", title: errorText, actionTitle: "Retry") {
                    viewModel.reload()
                }
            } else if viewModel.groups.isEmpty && !viewModel.isLoading {
                if viewModel.searchText.isEmpty {
                    ListMessage(icon: "person.3", title: "No groups yet",
                                subtitle: "Pick a few people and ring them all at once.",
                                actionTitle: "New group call") { showNewGroup = true }
                } else {
                    ListMessage(icon: "person.3", title: "No group called “\(viewModel.searchText)”")
                }
            } else {
                List {
                    ForEach(viewModel.groups, id: \.guid) { group in
                        GroupRow(group: group) { callType in call(group, callType: callType) }
                            .onAppear { viewModel.rowAppeared(group) }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showNewGroup = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("New group call")
            }
        }
        .sheet(isPresented: $showNewGroup) {
            NewGroupCallView { group, callType in
                viewModel.insert(group)
                call(group, callType: callType)
            }
        }
        .onAppear { viewModel.loadIfNeeded() }
    }

    private func call(_ group: ChatGroup, callType: String) {
        appState.startCall(receiverID: group.guid, name: group.name ?? group.guid,
                           avatarURL: group.icon, callType: callType, isGroup: true)
    }
}

private struct GroupRow: View {
    let group: ChatGroup
    let onCall: (String) -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            AvatarView(name: group.name, avatarURL: group.icon, size: 40, initialsCount: 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name ?? group.guid)
                    .font(AppType.bodyStrong)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text(group.membersCount == 1 ? "1 member" : "\(group.membersCount) members")
                    .font(AppType.caption)
                    .foregroundColor(.textSecondary)
            }
            Spacer(minLength: AppSpacing.sm)
            CircleIconButton(systemName: "phone.fill", accessibilityLabel: "Voice call \(group.name ?? "")") {
                onCall(CallSessionType.audio)
            }
            CircleIconButton(systemName: "video.fill", accessibilityLabel: "Video call \(group.name ?? "")") {
                onCall(CallSessionType.video)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - NewGroupCallView

/// Pick people, create a private group with them, and ring it.
///
/// There is no name field: the group is named after its first members ("Ada, Ben, Cy +2"),
/// which is what a call screen and a call log need to show.
struct NewGroupCallView: View {
    /// The created group and the call type to ring it with.
    let onCreated: (ChatGroup, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var users = UsersViewModel()
    @State private var selected: [User] = []
    @State private var working: String?
    @State private var errorText: String?

    static let maxMembers = 20

    var body: some View {
        AppNavigation(title: "New group call", displayMode: .inline) {
            VStack(spacing: 0) {
                header
                userList
                footer
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(working != nil)
                }
            }
        }
        .onAppear { users.loadIfNeeded() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Members · \(selected.count) selected")
                .font(AppType.label)
                .foregroundColor(.textSecondary)
            SearchField(placeholder: "Search people", text: $users.searchText)
            if !selected.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(selected, id: \.uid) { user in
                            Button { toggle(user) } label: {
                                HStack(spacing: AppSpacing.xs) {
                                    Text(user.name ?? user.uid ?? "").lineLimit(1)
                                    Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                                }
                                .font(AppType.label)
                                .foregroundColor(.onAccent)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.xs)
                                .background(Capsule().fill(Color.selected))
                            }
                            .accessibilityLabel("Remove \(user.name ?? "")")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    @ViewBuilder
    private var userList: some View {
        if users.users.isEmpty && users.isLoading {
            VStack { Spacer(); ProgressView().tint(.brandAccent); Spacer() }.frame(maxWidth: .infinity)
        } else if users.users.isEmpty {
            ListMessage(icon: "person.2", title: users.errorText ?? "No one to add")
        } else {
            List {
                ForEach(users.users, id: \.uid) { user in
                    Button { toggle(user) } label: {
                        HStack(spacing: AppSpacing.md) {
                            AvatarView(name: user.name, avatarURL: user.avatar, size: 36,
                                       initialsCount: 2, isOnline: user.status == .online)
                            Text(user.name ?? user.uid ?? "")
                                .font(AppType.body)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: isSelected(user) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(isSelected(user) ? .brandAccent : .textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected(user) ? .isSelected : [])
                    .onAppear { users.rowAppeared(user) }
                    .plainListRow()
                }
            }
            .listStyle(.plain)
            .hiddenScrollBackground()
        }
    }

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            if let errorText {
                Text(errorText).font(AppType.caption).foregroundColor(.statusError)
            }
            HStack(spacing: AppSpacing.md) {
                startButton(title: "Start voice", icon: "phone.fill", callType: CallSessionType.audio)
                startButton(title: "Start video", icon: "video.fill", callType: CallSessionType.video)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
        .overlay(Rectangle().fill(Color.borderLight).frame(height: 1), alignment: .top)
    }

    private func startButton(title: String, icon: String, callType: String) -> some View {
        Button { start(callType: callType) } label: {
            HStack(spacing: AppSpacing.sm) {
                if working == callType {
                    ProgressView().tint(.onAccent)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(selected.isEmpty || working != nil)
    }

    private func isSelected(_ user: User) -> Bool {
        selected.contains { $0.uid == user.uid }
    }

    private func toggle(_ user: User) {
        errorText = nil
        if let index = selected.firstIndex(where: { $0.uid == user.uid }) {
            selected.remove(at: index)
        } else if selected.count >= Self.maxMembers {
            errorText = "A group call can ring up to \(Self.maxMembers) people"
        } else {
            selected.append(user)
        }
    }

    private func start(callType: String) {
        guard !selected.isEmpty, working == nil else { return }
        working = callType
        errorText = nil
        let name = Self.groupName(for: selected.compactMap { $0.name ?? $0.uid })
        Self.createGroup(name: name, memberUIDs: selected.compactMap(\.uid)) { group in
            guard let group else {
                working = nil
                errorText = "Couldn't create the group. Try again."
                return
            }
            dismiss()
            // After the sheet is gone, so the call screen can present over the tabs.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onCreated(group, callType) }
        }
    }

    // MARK: Helpers

    /// "Ada, Ben, Cy" or "Ada, Ben, Cy +2".
    static func groupName(for memberNames: [String]) -> String {
        let names = memberNames.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !names.isEmpty else { return "Group call" }
        let head = names.prefix(3).joined(separator: ", ")
        return names.count > 3 ? "\(head) +\(names.count - 3)" : head
    }

    /// Creates a private group and adds the members. They are added in a second call so a
    /// member who cannot be added does not stop the group from being created. Completes on
    /// the main queue with the group, or `nil` when it could not be created.
    static func createGroup(name: String, memberUIDs: [String], completion: @escaping (ChatGroup?) -> Void) {
        let guid = "grp-" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(16)
        let group = ChatGroup(guid: guid, name: name, groupType: .private, password: nil)
        CometChat.createGroup(group: group) { created in
            let members = memberUIDs.map { GroupMember(UID: $0, groupMemberScope: .participant) }
            CometChat.addMembersToGroup(guid: created.guid, groupMembers: members) { _ in
                created.membersCount = members.count + 1
                DispatchQueue.main.async { completion(created) }
            } onError: { error in
                print("[NewGroupCallView] Adding members failed: \(error?.errorDescription ?? "-")")
                DispatchQueue.main.async { completion(created) }
            }
        } onError: { error in
            print("[NewGroupCallView] Creating the group failed: \(error?.errorDescription ?? "-")")
            DispatchQueue.main.async { completion(nil) }
        }
    }
}
