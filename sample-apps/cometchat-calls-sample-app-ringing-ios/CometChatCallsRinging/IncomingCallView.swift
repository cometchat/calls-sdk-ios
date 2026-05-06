import SwiftUI
import CometChatSDK

struct IncomingCallView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCallView = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Avatar
                AsyncImage(url: URL(string: appState.incomingCallerAvatar ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.borderPrimary)
                        .overlay(
                            Text(String((appState.incomingCallerName ?? "U").prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.textSecondary)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .padding(.bottom, 20)

                // Caller name
                Text(appState.incomingCallerName ?? "Unknown")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .padding(.bottom, 8)

                // Incoming call label
                Text("Incoming Call")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)

                // Call type indicator
                HStack(spacing: 6) {
                    Image(systemName: appState.incomingCallType == "audio" ? "phone.fill" : "video.fill")
                        .font(.system(size: 14))
                    Text(appState.incomingCallType == "audio" ? "Audio Call" : "Video Call")
                        .font(.system(size: 14))
                }
                .foregroundColor(.textTertiary)
                .padding(.top, 8)

                Spacer()

                // Accept / Reject buttons
                HStack(spacing: 60) {
                    // Reject
                    Button {
                        rejectCall()
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
                            Text("Reject")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    // Accept
                    Button {
                        acceptCall()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 64, height: 64)
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            Text("Accept")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        }
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
        .onChange(of: showCallView) { showing in
            if !showing {
                // Call ended — return to home
                appState.activeSessionID = nil
                appState.incomingSessionID = nil
                appState.currentScreen = .home
                appState.reinitializeBothSDKs()
            }
        }
    }

    private func acceptCall() {
        guard let sessionID = appState.incomingSessionID else {
            appState.currentScreen = .home
            return
        }

        CometChat.acceptCall(sessionID: sessionID) { call in
            DispatchQueue.main.async {
                appState.activeSessionID = call?.sessionID ?? sessionID
                showCallView = true
                print("[IncomingCallView] Call accepted, session: \(call?.sessionID ?? "")")
            }
        } onError: { error in
            DispatchQueue.main.async {
                appState.errorMessage = "Accept failed: \(error?.errorDescription ?? "")"
                appState.incomingSessionID = nil
                appState.currentScreen = .home
                print("[IncomingCallView] Accept error: \(error?.errorDescription ?? "")")
            }
        }
    }

    private func rejectCall() {
        guard let sessionID = appState.incomingSessionID else {
            appState.currentScreen = .home
            return
        }

        CometChat.rejectCall(sessionID: sessionID, status: .rejected) { _ in
            DispatchQueue.main.async {
                appState.incomingSessionID = nil
                appState.currentScreen = .home
                print("[IncomingCallView] Call rejected")
            }
        } onError: { error in
            DispatchQueue.main.async {
                appState.incomingSessionID = nil
                appState.currentScreen = .home
                print("[IncomingCallView] Reject error: \(error?.errorDescription ?? "")")
            }
        }
    }
}
