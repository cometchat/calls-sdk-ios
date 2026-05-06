import Foundation
import CometChatSDK
import CometChatCallsSDK

/// Central app state managing navigation, credentials, and dual SDK initialization.
/// Uses CometChat (Chat SDK) for call signaling and CometChatCalls (Calls SDK) for sessions.
class AppState: ObservableObject {

    enum Screen: Equatable {
        case splash, appCredentials, login, home, incomingCall, outgoingCall
    }

    @Published var currentScreen: Screen = .splash
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Incoming call data (set by call listener)
    @Published var incomingSessionID: String?
    @Published var incomingCallerName: String?
    @Published var incomingCallerAvatar: String?
    @Published var incomingCallType: String?

    // Outgoing call data (set when initiating a call)
    @Published var outgoingSessionID: String?
    @Published var outgoingReceiverName: String?
    @Published var outgoingReceiverAvatar: String?
    @Published var outgoingCallType: String?

    // Active call session (set after accept/accepted, used by CallView)
    @Published var activeSessionID: String?

    // Persisted credentials
    private let defaults = UserDefaults.standard
    private let kAppID = "cc_app_id"
    private let kRegion = "cc_region"
    private let kAuthKey = "cc_auth_key"

    private let callListenerID = "global_call_listener"

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

    // MARK: - Dual SDK Initialization

    /// Initialize both CometChat (Chat SDK) and CometChatCalls (Calls SDK).
    func initializeBothSDKs(appID: String, region: String, completion: @escaping (Bool) -> Void) {
        // 1. Initialize Chat SDK first
        let chatSettings = AppSettings.AppSettingsBuilder()
            .subscribePresenceForAllUsers()
            .setRegion(region: region)
            .build()

        CometChat.init(appId: appID, appSettings: chatSettings) { [weak self] _ in
            print("[AppState] CometChat (Chat SDK) initialized")

            // 2. Initialize Calls SDK
            let callsSettings = CallAppSettingsBuilder()
                .set(appID: appID)
                .set(region: region)
                .build()

            CometChatCalls(callsAppSettings: callsSettings) { _ in
                print("[AppState] CometChatCalls (Calls SDK) initialized")
                DispatchQueue.main.async { completion(true) }
            } onError: { error in
                DispatchQueue.main.async {
                    self?.errorMessage = error?.errorDescription
                    print("[AppState] CometChatCalls init failed: \(error?.errorDescription ?? "unknown")")
                    completion(false)
                }
            }
        } onError: { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error.errorDescription
                print("[AppState] CometChat init failed: \(error.errorDescription)")
                completion(false)
            }
        }
    }

    // MARK: - Dual SDK Login

    /// Login to both Chat SDK and Calls SDK.
    func loginBothSDKs(uid: String, authKey: String, completion: @escaping (Bool) -> Void) {
        // 1. Login to Chat SDK
        CometChat.login(UID: uid, apiKey: authKey) { [weak self] chatUser in
            print("[AppState] Chat SDK login success: \(chatUser.uid ?? "")")

            // 2. Login to Calls SDK using UID and authKey
            CometChatCalls.login(UID: uid, authKey: authKey) { _ in
                print("[AppState] Calls SDK login success")
                DispatchQueue.main.async {
                    self?.registerCallListener()
                    completion(true)
                }
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
        if AppConstants.hasValidConstants {
            initializeBothSDKs(appID: AppConstants.appID, region: AppConstants.region) { success in
                self.navigateAfterInit(success: success)
            }
        } else if hasCredentials {
            initializeBothSDKs(appID: savedAppID, region: savedRegion) { success in
                self.navigateAfterInit(success: success)
            }
        } else {
            currentScreen = .appCredentials
        }
    }

    private func navigateAfterInit(success: Bool) {
        if success {
            let chatUser = CometChat.getLoggedInUser()
            let callsUser = CometChatCalls.getLoggedInUser()
            print("[AppState] navigateAfterInit — chatUser: \(chatUser?.uid ?? "nil"), callsUser: \(callsUser?.uid ?? "nil")")
            if chatUser != nil && callsUser != nil {
                registerCallListener()
                currentScreen = .home
            } else {
                currentScreen = .login
            }
        } else {
            currentScreen = .appCredentials
        }
    }

    func getAuthKey() -> String {
        if AppConstants.hasValidConstants { return AppConstants.authKey }
        return savedAuthKey
    }

    // MARK: - Re-initialize after call

    /// Re-initialize both SDKs after a call session ends.
    func reinitializeBothSDKs() {
        let appID = AppConstants.hasValidConstants ? AppConstants.appID : savedAppID
        let region = AppConstants.hasValidConstants ? AppConstants.region : savedRegion
        guard !appID.isEmpty, !region.isEmpty else { return }

        initializeBothSDKs(appID: appID, region: region) { success in
            print("[AppState] SDKs re-initialized after call: \(success)")
            if success { self.registerCallListener() }
        }
    }

    // MARK: - Logout

    func logout() {
        CometChat.removeCallListener(callListenerID)

        CometChat.logout { [weak self] _ in
            CometChatCalls.logout { _ in
                DispatchQueue.main.async {
                    self?.currentScreen = .login
                }
            } onError: { _ in
                DispatchQueue.main.async {
                    self?.currentScreen = .login
                }
            }
        } onError: { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error.errorDescription
            }
        }
    }

    // MARK: - Call Listener

    func registerCallListener() {
        CometChat.addCallListener(callListenerID, self)
        print("[AppState] Call listener registered")
    }
}

// MARK: - CometChatCallDelegate

extension AppState: CometChatCallDelegate {

    func onIncomingCallReceived(incomingCall: CometChatSDK.Call?, error: CometChatException?) {
        guard let call = incomingCall else { return }
        DispatchQueue.main.async {
            self.incomingSessionID = call.sessionID
            self.incomingCallerName = call.sender?.name ?? "Unknown"
            self.incomingCallerAvatar = call.sender?.avatar ?? ""
            self.incomingCallType = call.callType == .audio ? "audio" : "video"
            self.currentScreen = .incomingCall
            print("[AppState] Incoming call from \(call.sender?.name ?? "unknown"), session: \(call.sessionID ?? "")")
        }
    }

    func onOutgoingCallAccepted(acceptedCall: CometChatSDK.Call?, error: CometChatException?) {
        guard let call = acceptedCall else { return }
        DispatchQueue.main.async {
            self.activeSessionID = call.sessionID
            print("[AppState] Outgoing call accepted, session: \(call.sessionID ?? "")")
        }
    }

    func onOutgoingCallRejected(rejectedCall: CometChatSDK.Call?, error: CometChatException?) {
        DispatchQueue.main.async {
            let status = rejectedCall?.callStatus
            if status == .busy {
                self.errorMessage = "User is busy"
            }
            self.outgoingSessionID = nil
            self.currentScreen = .home
            print("[AppState] Outgoing call rejected")
        }
    }

    func onIncomingCallCancelled(cancelledCall: CometChatSDK.Call?, error: CometChatException?) {
        DispatchQueue.main.async {
            self.incomingSessionID = nil
            self.currentScreen = .home
            print("[AppState] Incoming call cancelled")
        }
    }

    func onCallEndedMessageReceived(endedCall: CometChatSDK.Call?, error: CometChatException?) {
        print("[AppState] Call ended by other party, session: \(endedCall?.sessionID ?? "")")
        // Leave the Calls SDK session if active
        let session = CometChatCallsSDK.CallSession.shared
        session.leaveSession()
        DispatchQueue.main.async {
            self.activeSessionID = nil
            self.currentScreen = .home
            self.reinitializeBothSDKs()
        }
    }
}
