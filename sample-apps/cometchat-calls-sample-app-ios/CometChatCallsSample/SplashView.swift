import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image("cometchat_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            ProgressView()
                .tint(.accentPurple)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { appState.bootstrap() }
    }
}
