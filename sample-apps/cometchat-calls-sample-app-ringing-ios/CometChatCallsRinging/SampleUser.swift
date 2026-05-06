import Foundation

struct SampleUser: Identifiable, Equatable {
    let id: String
    let uid: String
    let name: String
    let avatar: String

    init(uid: String, name: String, avatar: String = "") {
        self.id = uid
        self.uid = uid
        self.name = name
        self.avatar = avatar
    }
}

/// Fetches sample users from CometChat's sample data endpoint.
enum SampleUserService {

    static func fetch() async -> [SampleUser] {
        guard let url = URL(string: AppConstants.sampleUsersURL) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let usersArray = json["users"] as? [[String: Any]] else { return [] }
            return usersArray.compactMap { dict in
                guard let uid = dict["uid"] as? String,
                      let name = dict["name"] as? String else { return nil }
                return SampleUser(uid: uid, name: name, avatar: dict["avatar"] as? String ?? "")
            }
        } catch {
            return []
        }
    }
}
