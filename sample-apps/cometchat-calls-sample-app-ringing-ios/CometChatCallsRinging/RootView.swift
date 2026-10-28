import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.currentScreen {
            case .splash:
                SplashView()
            case .appCredentials:
                AppCredentialsView()
            case .login:
                LoginView()
            case .home:
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.currentScreen)
    }
}
