import Foundation
import CometChatSDK
import CometChatCallsSDK
import CometChatPushNotificationsSwift

/// Central app state managing navigation, credentials, and SDK initialization.
///
/// The Calls SDK places and ends calls (`initiateCall` / `endCall`); the Push Notifications SDK
/// rings the callee through CallKit (`PushSetup`). The Chat SDK is only used for the user list.
class AppState: ObservableObject {

    enum Screen: Equatable {
        case splash, appCredentials, login, home
    }

    @Published var currentScreen: Screen = .splash
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// The call being placed, shown over the home screen while it is non-nil.
    @Published var outgoingCall: OutgoingCallViewModel?

    // MARK: - Placing a Call

    /// Opens the outgoing call screen for a user or a group, which places the call.
    /// `initiateCall` prepares the media session straight away, so the microphone (and the
    /// camera for a video call) must be granted first.
    func startCall(receiverID: String, name: String, avatarURL: String?, callType: String, isGroup: Bool) {
        guard outgoingCall == nil else { return } // a second tap while the first is in flight
        let isVideo = callType == CallSessionType.video
        CallPermissions.request(video: isVideo) { [weak self] granted in
            guard let self, self.outgoingCall == nil else { return }
            guard granted else {
                self.errorMessage = isVideo
                    ? "Allow microphone and camera access in Settings to make video calls."
                    : "Allow microphone access in Settings to make calls."
                return
            }
            self.outgoingCall = OutgoingCallViewModel(
                calleeUID: receiverID,
                calleeName: name,
                calleeAvatarURL: avatarURL,
                callType: callType,
                isGroup: isGroup
            )
        }
    }

    var hasCredentials: Bool { Credentials.isComplete }

    func saveCredentials(appID: String, region: String, authKey: String, pushProviderID: String) {
        Credentials.save(appID: appID, region: region, authKey: authKey, pushProviderID: pushProviderID)
    }

    func clearCredentials() {
        Credentials.clear()
    }

    // MARK: - SDK Initialization

    /// Initialize both CometChat (Chat SDK) and CometChatCalls (Calls SDK).
    func initializeBothSDKs(appID: String, region: String, completion: @escaping (Bool) -> Void) {
        let chatSettings = AppSettings.AppSettingsBuilder()
            .subscribePresenceForAllUsers()
            .setRegion(region: region)
            .build()

        CometChat.init(appId: appID, appSettings: chatSettings) { [weak self] _ in
            print("[AppState] CometChat (Chat SDK) initialized")
            AppState.initializeCallsSDK(appID: appID, region: region) { success in
                if !success { self?.errorMessage = "Calls SDK initialization failed" }
                completion(success)
            }
        } onError: { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error.errorDescription
                print("[AppState] CometChat init failed: \(error.errorDescription)")
                completion(false)
            }
        }
    }

    /// Initialize the Calls SDK. Also run after every call, so the next one starts clean.
    static func initializeCallsSDK(
        appID: String = Credentials.appID,
        region: String = Credentials.region,
        completion: @escaping (Bool) -> Void
    ) {
        let callsSettings = CallAppSettingsBuilder()
            .set(appID: appID)
            .set(region: region)
            .build()

        CometChatCalls(callsAppSettings: callsSettings) { _ in
            print("[AppState] CometChatCalls (Calls SDK) initialized")
            DispatchQueue.main.async { completion(true) }
        } onError: { error in
            print("[AppState] CometChatCalls init failed: \(error?.errorDescription ?? "unknown")")
            DispatchQueue.main.async { completion(false) }
        }
    }

    // MARK: - Login

    /// Login to both Chat SDK and Calls SDK. The push SDK registers this device's VoIP token
    /// for the user once they are logged in.
    func loginBothSDKs(uid: String, authKey: String, completion: @escaping (Bool) -> Void) {
        CometChat.login(UID: uid, apiKey: authKey) { [weak self] chatUser in
            print("[AppState] Chat SDK login success: \(chatUser.uid ?? "")")

            CometChatCalls.login(UID: uid, authKey: authKey) { _ in
                print("[AppState] Calls SDK login success")
                DispatchQueue.main.async { completion(true) }
            } onError: { error in
                DispatchQueue.main.async {
                    self?.errorMessage = error.errorDescription
                    print("[AppState] Calls SDK login failed: \(error.errorDescription)")
                    completion(false)
                }
            }
        } onError: { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error.errorDescription
                print("[AppState] Chat SDK login failed: \(error.errorDescription)")
                completion(false)
            }
        }
    }

    // MARK: - Bootstrap

    /// Called on launch to determine the starting screen.
    func bootstrap() {
        guard hasCredentials else {
            currentScreen = .appCredentials
            return
        }
        initializeBothSDKs(appID: Credentials.appID, region: Credentials.region) { success in
            self.navigateAfterInit(success: success)
        }
    }

    private func navigateAfterInit(success: Bool) {
        guard success else {
            currentScreen = .appCredentials
            return
        }
        let chatUser = CometChat.getLoggedInUser()
        let callsUser = CometChatCalls.getLoggedInUser()
        print("[AppState] navigateAfterInit — chatUser: \(chatUser?.uid ?? "nil"), callsUser: \(callsUser?.uid ?? "nil")")
        currentScreen = chatUser != nil && callsUser != nil ? .home : .login
    }

    func getAuthKey() -> String {
        Credentials.authKey
    }

    // MARK: - Logout

    /// Set when this device's push tokens could not be unregistered. Signing out stops there, and
    /// the user retries (`logout()`) or signs out anyway (`logOutOfSDKs()`).
    @Published var tokenUnregisterFailed = false

    /// Unregisters this device's push tokens, then logs out of both SDKs.
    ///
    /// The unregister has to finish *before* the logout, not merely start: it is authenticated
    /// by the session being torn down, and without it this device keeps ringing for the user
    /// who just left. So a failed unregister does not log out.
    func logout() {
        isLoading = true
        CometChatPushNotifications.shared.unregisterTokens(completion: { [weak self] (result: PNResult<Void>) in
            DispatchQueue.main.async {
                guard let self else { return }
                if case .failure(let error) = result {
                    print("[AppState] Push token unregistration failed: \(error)")
                    self.isLoading = false
                    self.tokenUnregisterFailed = true
                    return
                }
                self.logOutOfSDKs()
            }
        })
    }

    /// Logs out of both SDKs. Called on its own only when the user signs out although this
    /// device's push tokens are still registered.
    func logOutOfSDKs() {
        isLoading = true
        CometChatCalls.logout { _ in
            print("[AppState] Calls SDK logout success")
        } onError: { error in
            print("[AppState] Calls SDK logout failed: \(error.errorDescription)")
        }
        CometChat.logout { [weak self] _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.currentScreen = .login
            }
        } onError: { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.errorMessage = error.errorDescription
            }
        }
    }
}
