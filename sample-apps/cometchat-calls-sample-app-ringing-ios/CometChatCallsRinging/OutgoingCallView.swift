import SwiftUI
import CometChatSDK

struct OutgoingCallView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCallView = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Avatar
                AsyncImage(url: URL(string: appState.outgoingReceiverAvatar ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.borderPrimary)
                        .overlay(
                            Text(String((appState.outgoingReceiverName ?? "U").prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.textSecondary)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .padding(.bottom, 20)

                // Receiver name
                Text(appState.outgoingReceiverName ?? "Unknown")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .padding(.bottom, 8)

                // Calling status
                Text("Calling...")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)

                // Call type indicator
                HStack(spacing: 6) {
                    Image(systemName: appState.outgoingCallType == "audio" ? "phone.fill" : "video.fill")
                        .font(.system(size: 14))
                    Text(appState.outgoingCallType == "audio" ? "Audio Call" : "Video Call")
                        .font(.system(size: 14))
                }
                .foregroundColor(.textTertiary)
                .padding(.top, 8)

                Spacer()

                // Cancel button
                Button {
                    cancelCall()
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.statusError)
                                .frame(width: 64, height: 64)
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        Text("Cancel")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .fullScreenCover(isPresented: $showCallView) {
            if let sessionID = appState.activeSessionID {
                CallView(sessionID: sessionID)
            }
        }
        .onChange(of: appState.activeSessionID) { newValue in
            if newValue != nil {
                showCallView = true
            }
        }
        .onChange(of: showCallView) { showing in
            if !showing {
                // Call ended — return to home
                appState.activeSessionID = nil
                appState.outgoingSessionID = nil
                appState.currentScreen = .home
                appState.reinitializeBothSDKs()
            }
        }
    }

    private func cancelCall() {
        guard let sessionID = appState.outgoingSessionID else {
            appState.currentScreen = .home
            return
        }

        CometChat.rejectCall(sessionID: sessionID, status: .cancelled) { _ in
            DispatchQueue.main.async {
                appState.outgoingSessionID = nil
                appState.currentScreen = .home
                print("[OutgoingCallView] Call cancelled")
            }
        } onError: { error in
            DispatchQueue.main.async {
                appState.outgoingSessionID = nil
                appState.currentScreen = .home
                print("[OutgoingCallView] Cancel error: \(error?.errorDescription ?? "")")
            }
        }
    }
}
