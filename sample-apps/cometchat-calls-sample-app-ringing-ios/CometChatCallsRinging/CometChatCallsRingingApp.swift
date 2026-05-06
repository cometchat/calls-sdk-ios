import SwiftUI
import UIKit

/// AppDelegate needed because CometChatSDK accesses UIApplication.shared.delegate?.window internally.
class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
}

@main
struct CometChatCallsRingingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
