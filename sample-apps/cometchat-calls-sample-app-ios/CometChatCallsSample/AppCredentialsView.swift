import SwiftUI

struct AppCredentialsView: View {
    @EnvironmentObject var appState: AppState
    @State private var appID = ""
    @State private var authKey = ""
    @State private var selectedRegion: String?
    @State private var isLoading = false

    private let regions = [("us", "🇺🇸 US"), ("eu", "🇪🇺 EU"), ("in", "🇮🇳 IN")]

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

                        credentialsCard
                            .cardStyle()
                            .padding(.horizontal, 24)
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
        .alert("Error", isPresented: .init(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Region
            SectionLabel(text: "Region")
                .padding(.bottom, 8)

            HStack(spacing: 8) {
                ForEach(regions, id: \.0) { code, label in
                    RegionChip(label: label, isSelected: selectedRegion == code) {
                        selectedRegion = code
                    }
                }
            }

            // App ID
            SectionLabel(text: "App ID")
                .padding(.top, 20)
                .padding(.bottom, 8)

            TextField("Enter App ID", text: $appID)
                .textFieldStyle(RoundedTextFieldStyle())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            // Auth Key
            SectionLabel(text: "Auth Key")
                .padding(.top, 20)
                .padding(.bottom, 8)

            TextField("Enter Auth Key", text: $authKey)
                .textFieldStyle(RoundedTextFieldStyle())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            // Continue
            Button { continueAction() } label: {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            .padding(.top, 24)
        }
    }

    private func continueAction() {
        guard let region = selectedRegion else {
            appState.errorMessage = "Please select a region"
            return
        }
        guard !appID.trimmingCharacters(in: .whitespaces).isEmpty else {
            appState.errorMessage = "Please enter App ID"
            return
        }
        guard !authKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            appState.errorMessage = "Please enter Auth Key"
            return
        }

        isLoading = true
        let trimmedAppID = appID.trimmingCharacters(in: .whitespaces)
        let trimmedAuthKey = authKey.trimmingCharacters(in: .whitespaces)

        appState.saveCredentials(appID: trimmedAppID, region: region, authKey: trimmedAuthKey)
        appState.initializeSDK(appID: trimmedAppID, region: region) { success in
            isLoading = false
            if success { appState.currentScreen = .login }
        }
    }
}


// MARK: - Region Chip

private struct RegionChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentPurple.opacity(0.15) : Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentPurple : Color.borderPrimary, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
