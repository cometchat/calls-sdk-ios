import SwiftUI
import CometChatSDK

/// The signed-in shell: Users, Groups and History tabs, with the call screens on top.
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    /// The answered incoming call, published by the push SDK's delegate in any app state.
    @ObservedObject private var incomingCallPresenter = IncomingCallPresenter.shared
    @State private var selectedTab = Tab.users

    enum Tab: Hashable { case users, groups, history }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                tab("Users", systemImage: "person.2.fill", tag: .users) { UsersView() }
                tab("Groups", systemImage: "person.3.fill", tag: .groups) { GroupsView() }
                tab("History", systemImage: "clock.fill", tag: .history) { HistoryView() }
            }
            .tint(.brandAccent)
            // Attached here rather than beside the outgoing cover below: two
            // `fullScreenCover`s on the same view do not both present reliably.
            .fullScreenCover(isPresented: incomingCallPresented) {
                if let viewModel = incomingCallPresenter.callSessionViewModel {
                    // Keyed by session: a call switched to with End & Accept gets a fresh
                    // screen, whose container is what starts the join.
                    CallSessionView(viewModel: viewModel)
                        .id(viewModel.sessionId)
                }
            }

            if appState.isLoading {
                Color.scrim.ignoresSafeArea()
                ProgressView().tint(.onAccent).scaleEffect(1.4)
            }
        }
        .fullScreenCover(isPresented: outgoingCallPresented) {
            if let viewModel = appState.outgoingCall {
                OutgoingCallView(viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: .init(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }

    private func tab<Content: View>(_ title: String, systemImage: String, tag: Tab,
                                    @ViewBuilder content: () -> Content) -> some View {
        let screen = content()
        return AppNavigation(title: title) {
            screen
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) { ProfileButton() }
                }
        }
        .tabItem { Label(title, systemImage: systemImage) }
        .tag(tag)
    }

    // MARK: - Call Screens

    /// Only ever set to `false` by the call screen taking itself down, which the presenter turns
    /// into ending the call on CallKit.
    private var incomingCallPresented: Binding<Bool> {
        Binding(
            get: { incomingCallPresenter.callSessionViewModel != nil },
            set: { if !$0 { incomingCallPresenter.dismiss() } }
        )
    }

    private var outgoingCallPresented: Binding<Bool> {
        Binding(
            get: { appState.outgoingCall != nil },
            set: { if !$0 { appState.outgoingCall = nil } }
        )
    }
}

/// The signed-in user's avatar in the header; opens the Profile screen.
private struct ProfileButton: View {
    var body: some View {
        let user = CometChat.getLoggedInUser()
        NavigationLink { ProfileView() } label: {
            AvatarView(name: user?.name, avatarURL: user?.avatar, size: 32, initialsCount: 2)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")
    }
}

/// A navigation container: `NavigationStack` where available, the stack-style
/// `NavigationView` on iOS 15.
struct AppNavigation<Content: View>: View {
    let title: String
    var displayMode: NavigationBarItem.TitleDisplayMode = .large
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { titled }
        } else {
            NavigationView { titled }.navigationViewStyle(.stack)
        }
    }

    private var titled: some View {
        content()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
    }
}
