import SwiftUI
import CometChatSDK
import CometChatCallsSDK
import CometChatPushNotificationsSwift

/// The signed-in user, the app's settings, and sign out. Opened from the avatar in the header.
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw = AppearancePreference.system.rawValue
    @State private var toast: String?
    @State private var confirmSignOut = false

    private var user: User? { CometChat.getLoggedInUser() }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                identity
                appearance
                details
                Button("Sign out") { confirmSignOut = true }
                    .buttonStyle(DangerButtonStyle())
                    .disabled(appState.isLoading)
            }
            .frame(maxWidth: 720)
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) { toastView }
        .confirmationDialog("Sign out?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { appState.logout() }
        } message: {
            Text("This device stops ringing for \(user?.name ?? "this user") until you sign in again.")
        }
    }

    // MARK: Sections

    private var identity: some View {
        VStack(spacing: AppSpacing.md) {
            AvatarView(name: user?.name, avatarURL: user?.avatar, size: 88, initialsCount: 2)
            Text(user?.name?.isEmpty == false ? user?.name ?? "" : "No name")
                .font(AppType.title)
                .foregroundColor(.textPrimary)
            row("UID") {
                HStack(spacing: AppSpacing.sm) {
                    Text(user?.uid ?? "—")
                        .font(AppType.code)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button { copy(user?.uid, as: "UID") } label: {
                        Image(systemName: "doc.on.doc").foregroundColor(.brandAccent)
                    }
                    .accessibilityLabel("Copy UID")
                }
            }
            .surfaceSection()
        }
    }

    private var appearance: some View {
        section("Appearance") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Picker("Appearance", selection: $appearanceRaw) {
                    ForEach(AppearancePreference.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Text("System follows your phone's setting.")
                    .font(AppType.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(AppSpacing.lg)
        }
    }

    private var details: some View {
        section("App") {
            VStack(spacing: 0) {
                infoRow("App ID", Credentials.appID, copyable: true)
                infoRow("Region", Credentials.region.uppercased())
                infoRow("Push provider", Credentials.pushProviderID.isEmpty ? "Default" : Credentials.pushProviderID)
                infoRow("App version", Self.version(of: .main))
                infoRow("Calls SDK", Self.version(of: Bundle(for: CometChatCalls.self)))
                infoRow("Chat SDK", Self.version(of: Bundle(for: CometChat.self)))
                infoRow("Push SDK", Self.version(of: Bundle(for: CometChatPushNotifications.self)), isLast: true)
            }
        }
    }

    // MARK: Building blocks

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: title)
            content().surfaceSection()
        }
    }

    private func row<Content: View>(_ title: String, @ViewBuilder _ trailing: () -> Content) -> some View {
        HStack {
            Text(title).font(AppType.body).foregroundColor(.textSecondary)
            Spacer(minLength: AppSpacing.md)
            trailing()
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(minHeight: 48)
    }

    private func infoRow(_ title: String, _ value: String, copyable: Bool = false, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            row(title) {
                Text(value.isEmpty ? "—" : value)
                    .font(AppType.body)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if copyable {
                    Button { copy(value, as: title) } label: {
                        Image(systemName: "doc.on.doc").foregroundColor(.brandAccent)
                    }
                    .accessibilityLabel("Copy \(title)")
                }
            }
            if !isLast { Divider().background(Color.borderLight).padding(.leading, AppSpacing.lg) }
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Text(toast)
                .font(AppType.label)
                .foregroundColor(.onEmphasis)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(Capsule().fill(Color.emphasis))
                .padding(.bottom, AppSpacing.xl)
                .transition(.opacity)
        }
    }

    private func copy(_ value: String?, as title: String) {
        guard let value, !value.isEmpty else { return }
        UIPasteboard.general.string = value
        withAnimation { toast = "\(title) copied" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { toast = nil } }
    }

    private static func version(of bundle: Bundle) -> String {
        bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}
