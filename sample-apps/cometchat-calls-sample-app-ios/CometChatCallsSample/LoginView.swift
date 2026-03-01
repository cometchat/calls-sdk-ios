import SwiftUI
import CometChatCallsSDK

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var sampleUsers: [SampleUser] = []
    @State private var selectedUser: SampleUser?
    @State private var manualUID = ""
    @State private var isLoading = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        Image("cometchat_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.bottom, 32)

                        loginCard
                            .cardStyle()
                            .padding(.horizontal, 24)

                        // Change credentials link
                        Button {
                            appState.currentScreen = .appCredentials
                        } label: {
                            HStack(spacing: 4) {
                                Text("Change")
                                    .foregroundColor(.textSecondary)
                                Text("App Credentials")
                                    .foregroundColor(.accentPurple)
                            }
                            .font(.system(size: 14))
                        }
                        .padding(.top, 20)
                    }
                    .frame(minHeight: geo.size.height)
                    .frame(maxWidth: .infinity)
                }
            }

            if isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView().tint(.accentPurple).scaleEffect(1.5)
            }
        }
        .task { sampleUsers = await SampleUserService.fetch() }
        .alert("Error", isPresented: .init(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !sampleUsers.isEmpty {
                SectionLabel(text: "Choose a sample user")
                    .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(sampleUsers) { user in
                        SampleUserCard(user: user, isSelected: selectedUser?.uid == user.uid) {
                            manualUID = ""
                            selectedUser = selectedUser?.uid == user.uid ? nil : user
                        }
                    }
                }

                OrDivider()
                    .padding(.vertical, 16)
            }

            SectionLabel(text: "Enter your UID")
                .padding(.bottom, 8)

            TextField("Enter UID", text: $manualUID)
                .textFieldStyle(RoundedTextFieldStyle())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: manualUID) { _ in
                    if !manualUID.isEmpty { selectedUser = nil }
                }

            Button { login() } label: {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            .padding(.top, 24)
        }
    }


    private func login() {
        let uid = selectedUser?.uid ?? manualUID.trimmingCharacters(in: .whitespaces)
        guard !uid.isEmpty else {
            appState.errorMessage = "Select a user or enter a UID"
            return
        }

        isLoading = true
        let authKey = appState.getAuthKey()

        CometChatCalls.login(UID: uid, authKey: authKey) { _ in
            DispatchQueue.main.async {
                isLoading = false
                appState.currentScreen = .home
            }
        } onError: { error in
            DispatchQueue.main.async {
                isLoading = false
                appState.errorMessage = error.errorDescription
            }
        }
    }
}

// MARK: - Sample User Card

private struct SampleUserCard: View {
    let user: SampleUser
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: user.avatar)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.borderPrimary)
                            .overlay(
                                Text(String(user.name.prefix(1)).uppercased())
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                            )
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentPurple)
                            .font(.system(size: 16))
                            .background(Circle().fill(Color.appBackground).frame(width: 14, height: 14))
                    }
                }

                Text(user.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text(user.uid)
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentPurple.opacity(0.12) : Color.appBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentPurple : Color.borderPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
