import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            AppLogo(size: 30)
            ProgressView()
                .tint(.accentPurple)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { appState.bootstrap() }
    }
}
