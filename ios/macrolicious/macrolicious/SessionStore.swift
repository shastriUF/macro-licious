import Foundation

final class SessionStore {
    private enum Keys {
        static let sessionToken = "macrolicious.sessionToken"
        static let baseURL = "macrolicious.baseURL"
    }

    private let defaults = UserDefaults.standard

    var sessionToken: String? {
        get { defaults.string(forKey: Keys.sessionToken) }
        set { defaults.set(newValue, forKey: Keys.sessionToken) }
    }

    var baseURL: String {
        get { defaults.string(forKey: Keys.baseURL) ?? "http://127.0.0.1:4000" }
        set { defaults.set(newValue, forKey: Keys.baseURL) }
    }

    func clearSession() {
        defaults.removeObject(forKey: Keys.sessionToken)
    }
}
