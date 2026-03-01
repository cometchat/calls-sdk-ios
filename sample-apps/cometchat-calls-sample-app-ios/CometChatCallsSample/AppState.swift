import Foundation
import CometChatCallsSDK

/// Central app state managing navigation, credentials, and SDK initialization.
class AppState: ObservableObject {

    enum Screen {
        case splash, appCredentials, login, home
    }

    @Published var currentScreen: Screen = .splash
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Persisted credentials
    private let defaults = UserDefaults.standard
    private let kAppID = "cc_app_id"
    private let kRegion = "cc_region"
    private let kAuthKey = "cc_auth_key"

    var savedAppID: String { defaults.string(forKey: kAppID) ?? "" }
    var savedRegion: String { defaults.string(forKey: kRegion) ?? "" }
    var savedAuthKey: String { defaults.string(forKey: kAuthKey) ?? "" }

    var hasCredentials: Bool {
        !savedAppID.isEmpty && !savedAuthKey.isEmpty && !savedRegion.isEmpty
    }

    func saveCredentials(appID: String, region: String, authKey: String) {
        defaults.set(appID, forKey: kAppID)
        defaults.set(region, forKey: kRegion)
        defaults.set(authKey, forKey: kAuthKey)
    }

    func clearCredentials() {
        defaults.removeObject(forKey: kAppID)
        defaults.removeObject(forKey: kRegion)
        defaults.removeObject(forKey: kAuthKey)
    }

    // MARK: - SDK Init

    func initializeSDK(appID: String, region: String, completion: @escaping (Bool) -> Void) {
        let settings = CallAppSettingsBuilder()
            .set(appID: appID)
            .set(region: region)
            .build()

        CometChatCalls(callsAppSettings: settings) { success in
            print("[AppState] CometChatCalls initialized successfully")
            DispatchQueue.main.async { completion(true) }
        } onError: { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error?.errorDescription ?? "SDK init failed"
                print("[AppState] CometChatCalls init failed: \(error?.errorDescription ?? "unknown")")
                completion(false)
            }
        }
    }

    /// Called on launch to determine the starting screen.
    func bootstrap() {
        if AppConstants.hasValidConstants {
            initializeSDK(appID: AppConstants.appID, region: AppConstants.region) { success in
                self.navigateAfterInit(success: success)
            }
        } else if hasCredentials {
            initializeSDK(appID: savedAppID, region: savedRegion) { success in
                self.navigateAfterInit(success: success)
            }
        } else {
            currentScreen = .appCredentials
        }
    }

    private func navigateAfterInit(success: Bool) {
        if success {
            let loggedInUser = CometChatCalls.getLoggedInUser()
            print("[AppState] navigateAfterInit — loggedInUser: \(loggedInUser?.uid ?? "nil")")
            currentScreen = loggedInUser != nil ? .home : .login
        } else {
            currentScreen = .appCredentials
        }
    }

    func getAuthKey() -> String {
        if AppConstants.hasValidConstants { return AppConstants.authKey }
        return savedAuthKey
    }

    /// Re-initialize the SDK after a call session ends.
    /// The SDK's internal state can get cleared after a session, so this
    /// ensures subsequent calls work properly (matching CometChat Connect pattern).
    func reinitializeSDK() {
        let appID = AppConstants.hasValidConstants ? AppConstants.appID : savedAppID
        let region = AppConstants.hasValidConstants ? AppConstants.region : savedRegion
        guard !appID.isEmpty, !region.isEmpty else { return }

        initializeSDK(appID: appID, region: region) { success in
            print("[AppState] SDK re-initialized after call: \(success)")
        }
    }

    func logout() {
        CometChatCalls.logout { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentScreen = .login
            }
        } onError: { error in
            DispatchQueue.main.async {
                self.errorMessage = error.errorDescription
            }
        }
    }
}
