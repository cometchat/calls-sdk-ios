import SwiftUI
import UIKit
import CometChatPushNotificationsSwift
import CometChatPushNotificationsCalls

/// AppDelegate needed because CometChatSDK accesses UIApplication.shared.delegate?.window internally,
/// and because the push SDK has to be set up before `didFinishLaunching` returns.
class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // From here specifically: the push SDK creates the PushKit registry inside `initialize`,
        // and iOS only delivers the VoIP push that launched the app if that registry exists by the
        // time this method returns.
        PushSetup.initializeIfNeeded()
        return true
    }
}

// MARK: - PushSetup

/// Sets up the Push Notifications SDK, which owns the incoming side of a call: it receives the
/// VoIP push, rings CallKit, prepares the session while the phone rings, and answers or declines
/// it. The app is only asked to show its call screen (`CallPushDelegate.presentCall(_:)`).
enum PushSetup {

    /// The push SDK holds its delegate weakly, so it is kept here for the life of the process.
    private static let delegate = CallPushDelegate()

    private static var initializedAppID: String?

    /// Initializes the push SDK once the app's credentials are known: at launch when they are
    /// saved or in `AppConstants`, otherwise right after they are entered. The configuration is
    /// fixed for the life of the process, so switching to another app needs a relaunch to ring.
    static func initializeIfNeeded() {
        guard Credentials.isComplete else { return }
        if let initializedAppID {
            if initializedAppID != Credentials.appID {
                print("[PushSetup] Push is set up for \(initializedAppID); relaunch to receive calls for \(Credentials.appID)")
            }
            return
        }

        let providerID = Credentials.pushProviderID
        CometChatPushNotifications.shared.delegate = delegate
        CometChatPushNotifications.shared.initialize(
            config: PNConfiguration.builder(appId: Credentials.appID, region: Credentials.region)
                .providerId(providerID.isEmpty ? nil : providerID)
                // Calls ring through CallKit and need no notification permission, so only the
                // VoIP token is registered. The SDK registers it at login and removes it at logout.
                .requestNotificationPermission(false)
                .callKit(
                    name: "CometChat Calls",
                    iconTemplateImageName: nil,
                    ringtone: nil,
                    includeInRecents: true,
                    supportsVideo: true
                )
                .build()
        )
        initializedAppID = Credentials.appID
        print("[PushSetup] Push Notifications SDK initialized")
    }
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
