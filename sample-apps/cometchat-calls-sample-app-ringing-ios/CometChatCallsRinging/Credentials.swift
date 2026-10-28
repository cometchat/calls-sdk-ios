import Foundation

/// The CometChat app credentials in use: the ones in `AppConstants` when they are filled in,
/// otherwise the ones entered on the credentials screen.
///
/// Static rather than part of `AppState` because the push SDK has to be set up in
/// `application(_:didFinishLaunchingWithOptions:)`, before any view or state object exists.
enum Credentials {

    private static let defaults = UserDefaults.standard
    private static let kAppID = "cc_app_id"
    private static let kRegion = "cc_region"
    private static let kAuthKey = "cc_auth_key"
    private static let kPushProviderID = "cc_push_provider_id"

    static var appID: String {
        AppConstants.hasValidConstants ? AppConstants.appID : defaults.string(forKey: kAppID) ?? ""
    }

    static var region: String {
        AppConstants.hasValidConstants ? AppConstants.region : defaults.string(forKey: kRegion) ?? ""
    }

    static var authKey: String {
        AppConstants.hasValidConstants ? AppConstants.authKey : defaults.string(forKey: kAuthKey) ?? ""
    }

    /// The push provider ID from the CometChat dashboard (Notifications → Push). Required: the
    /// Push Notifications SDK can't register the device's push tokens without it.
    static var pushProviderID: String {
        AppConstants.hasValidConstants ? AppConstants.pushProviderID : defaults.string(forKey: kPushProviderID) ?? ""
    }

    /// Without a push provider ID the app could sign in but never ring, so it counts as missing.
    static var isComplete: Bool {
        !appID.isEmpty && !region.isEmpty && !authKey.isEmpty &&
        !pushProviderID.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func save(appID: String, region: String, authKey: String, pushProviderID: String) {
        defaults.set(appID, forKey: kAppID)
        defaults.set(region, forKey: kRegion)
        defaults.set(authKey, forKey: kAuthKey)
        defaults.set(pushProviderID, forKey: kPushProviderID)
    }

    static func clear() {
        [kAppID, kRegion, kAuthKey, kPushProviderID].forEach(defaults.removeObject(forKey:))
    }
}
