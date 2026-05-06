import SwiftUI
import AVFoundation

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutMenu = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Image("cometchat_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                    Spacer()
                    logoutButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Tab content
                TabView(selection: $selectedTab) {
                    UsersView()
                        .tag(0)
                    CallLogsView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom tab bar
                HStack(spacing: 0) {
                    TabBarButton(icon: "person.2.fill", title: "Users", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabBarButton(icon: "clock.fill", title: "Call Logs", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color.cardBackground)
            }

            // Logout dropdown
            if showLogoutMenu {
                logoutOverlay
            }
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

    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { _ in }
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }
}

// MARK: - Tab Bar Button

private struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .accentPurple : .textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
