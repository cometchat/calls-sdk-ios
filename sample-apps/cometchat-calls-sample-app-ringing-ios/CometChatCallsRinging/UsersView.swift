import SwiftUI
import CometChatSDK

struct UsersView: View {
    @EnvironmentObject var appState: AppState
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var searchText = ""

    @State private var usersRequest: UsersRequest?

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textSecondary)
                TextField("Search users", text: $searchText)
                    .foregroundColor(.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: searchText) { _ in
                        searchUsers()
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        resetAndFetch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if users.isEmpty && !isLoading {
                Spacer()
                Text("No users found")
                    .foregroundColor(.textSecondary)
                    .font(.system(size: 14))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(users, id: \.uid) { user in
                            UserRow(user: user, onAudioCall: {
                                initiateCall(user: user, type: CometChat.CallType.audio)
                            }, onVideoCall: {
                                initiateCall(user: user, type: CometChat.CallType.video)
                            })

                            Divider()
                                .background(Color.borderLight)
                                .padding(.leading, 64)
                        }

                        if hasMore && !isLoading && searchText.isEmpty {
                            Color.clear
                                .frame(height: 1)
                                .onAppear { fetchUsers() }
                        }

                        if isLoading {
                            ProgressView()
                                .tint(.accentPurple)
                                .padding()
                        }
                    }
                }
            }
        }
        .background(Color.appBackground)
        .onAppear { resetAndFetch() }
    }

    // MARK: - Fetch Users

    private func resetAndFetch() {
        users = []
        hasMore = true
        usersRequest = UsersRequest.UsersRequestBuilder()
            .set(limit: 30)
            .build()
        fetchUsers()
    }

    private func fetchUsers() {
        guard !isLoading, hasMore else { return }
        isLoading = true

        usersRequest?.fetchNext(onSuccess: { [self] fetchedUsers in
            DispatchQueue.main.async {
                isLoading = false
                let loggedInUID = CometChat.getLoggedInUser()?.uid ?? ""
                let filtered = fetchedUsers.filter { $0.uid != loggedInUID }
                if fetchedUsers.isEmpty {
                    hasMore = false
                } else {
                    users.append(contentsOf: filtered)
                }
            }
        }, onError: { error in
            DispatchQueue.main.async {
                isLoading = false
                print("[UsersView] Fetch error: \(error?.errorDescription ?? "")")
            }
        })
    }

    private func searchUsers() {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else {
            resetAndFetch()
            return
        }

        isLoading = true
        let request = UsersRequest.UsersRequestBuilder()
            .set(limit: 30)
            .set(searchKeyword: keyword)
            .build()

        request.fetchNext(onSuccess: { fetchedUsers in
            DispatchQueue.main.async {
                isLoading = false
                let loggedInUID = CometChat.getLoggedInUser()?.uid ?? ""
                users = fetchedUsers.filter { $0.uid != loggedInUID }
                hasMore = false
            }
        }, onError: { error in
            DispatchQueue.main.async {
                isLoading = false
                users = []
                print("[UsersView] Search error: \(error?.errorDescription ?? "")")
            }
        })
    }

    // MARK: - Initiate Call

    private func initiateCall(user: User, type: CometChat.CallType) {
        let call = Call(receiverId: user.uid ?? "", callType: type, receiverType: .user)

        CometChat.initiateCall(call: call) { outgoingCall in
            DispatchQueue.main.async {
                appState.outgoingSessionID = outgoingCall?.sessionID
                appState.outgoingReceiverName = user.name
                appState.outgoingReceiverAvatar = user.avatar
                appState.outgoingCallType = type == .audio ? "audio" : "video"
                appState.currentScreen = .outgoingCall
                print("[UsersView] Call initiated, session: \(outgoingCall?.sessionID ?? "")")
            }
        } onError: { error in
            DispatchQueue.main.async {
                appState.errorMessage = "Call failed: \(error?.errorDescription ?? "Unknown error")"
            }
        }
    }
}

// MARK: - User Row

private struct UserRow: View {
    let user: User
    let onAudioCall: () -> Void
    let onVideoCall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.borderPrimary)
                    .overlay(
                        Text(String((user.name ?? "U").prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            // Name + status
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? "Unknown")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text(user.status == .online ? "Online" : "Offline")
                    .font(.system(size: 12))
                    .foregroundColor(user.status == .online ? .green : .textTertiary)
            }

            Spacer()

            // Audio call button
            Button(action: onAudioCall) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentPurple)
                    .frame(width: 36, height: 36)
            }

            // Video call button
            Button(action: onVideoCall) {
                Image(systemName: "video.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentPurple)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
