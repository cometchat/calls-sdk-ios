import SwiftUI
import AVFoundation

/// Wrapper to make a session ID identifiable for fullScreenCover(item:)
struct ActiveCallSession: Identifiable, Equatable {
    let id: String
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var sessionID = ""
    @State private var activeCall: ActiveCallSession?
    @State private var showLogoutMenu = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with logout avatar
                HStack {
                    Spacer()
                    logoutButton
                }
                .padding(.top, 10)
                .padding(.trailing, 16)

                Spacer()

                Image("cometchat_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .padding(.bottom, 32)

                meetingCard
                    .cardStyle()
                    .padding(.horizontal, 24)

                Spacer()
            }

            // Logout dropdown
            if showLogoutMenu {
                logoutOverlay
            }
        }
        .fullScreenCover(item: $activeCall) { session in
            CallView(sessionID: session.id)
        }
        .onChange(of: activeCall) { newValue in
            if newValue == nil { appState.reinitializeSDK() }
        }
        .onAppear { requestPermissions() }
        .alert("Error", isPresented: .init(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }

    // MARK: - Meeting Card

    private var meetingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Enter Session Id")
                .padding(.bottom, 8)

            TextField("Session ID", text: $sessionID)
                .textFieldStyle(RoundedTextFieldStyle())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            // Join Meeting — purple when ID entered, outlined when empty
            if sessionID.trimmingCharacters(in: .whitespaces).isEmpty {
                Button { joinMeeting() } label: {
                    Text("Join Meeting")
                }
                .buttonStyle(OutlinedButtonStyle())
                .padding(.top, 24)
            } else {
                Button { joinMeeting() } label: {
                    Text("Join Meeting")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 24)
            }

            // Show "Or" + instant meeting only when session ID is empty
            if sessionID.trimmingCharacters(in: .whitespaces).isEmpty {
                OrDivider()
                    .padding(.top, 16)

                Button {
                    startCall(UUID().uuidString)
                } label: {
                    Text("Start Instant Meeting")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 16)
            }
        }
    }


    // MARK: - Logout Button

    private var logoutButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { showLogoutMenu.toggle() }
        } label: {
            Circle()
                .fill(Color.accentPurple)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )
        }
    }

    // MARK: - Logout Overlay

    private var logoutOverlay: some View {
        ZStack {
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { showLogoutMenu = false }
                }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showLogoutMenu = false }
                        appState.logout()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14))
                            Text("Logout")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.textPrimary)
                        .padding(16)
                    }
                    .frame(width: 180)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.borderPrimary, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                    .padding(.trailing, 16)
                }
                .padding(.top, 54)
                Spacer()
            }
        }
    }

    // MARK: - Actions

    private func joinMeeting() {
        let id = sessionID.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else {
            appState.errorMessage = "Enter a Session ID"
            return
        }
        startCall(id)
    }

    private func startCall(_ id: String) {
        print("[HomeView] Starting call with sessionID: \(id)")
        activeCall = ActiveCallSession(id: id)
    }

    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { _ in }
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }
}
