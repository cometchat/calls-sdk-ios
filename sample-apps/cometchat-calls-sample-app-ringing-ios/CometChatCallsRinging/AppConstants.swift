import Foundation

/// App credentials for CometChat Calls SDK (Ringing sample).
/// Replace these placeholder values with your CometChat app credentials from the dashboard.
///
/// Get your credentials at: https://app.cometchat.com
enum AppConstants {
    static let appID = ""       // Your App ID
    static let region = ""               // us, eu, or in
    static let authKey = ""    // Your Auth Key

    static let sampleUsersURL = "https://assets.cometchat.io/sampleapp/sampledata.json"

    static var hasValidConstants: Bool {
        !appID.isEmpty && appID != "YOUR_APP_ID" &&
        !authKey.isEmpty && authKey != "YOUR_AUTH_KEY" &&
        !region.isEmpty
    }
}
