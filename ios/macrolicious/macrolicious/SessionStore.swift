import Foundation
import Security

final class SessionStore {
    private enum Keys {
        static let sessionToken = "macrolicious.sessionToken"
        static let baseURL = "macrolicious.baseURL"
    }

    private let defaults = UserDefaults.standard
    private let keychainService = "com.aniruddha.macrolicious"

    var sessionToken: String? {
        get { readTokenFromKeychain() }
        set {
            if let newValue {
                saveTokenToKeychain(newValue)
            } else {
                deleteTokenFromKeychain()
            }
        }
    }

    var baseURL: String {
        get { defaults.string(forKey: Keys.baseURL) ?? "http://127.0.0.1:4000" }
        set { defaults.set(newValue, forKey: Keys.baseURL) }
    }

    func clearSession() {
        deleteTokenFromKeychain()
    }

    private func saveTokenToKeychain(_ token: String) {
        guard let data = token.data(using: .utf8) else {
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: Keys.sessionToken
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func readTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: Keys.sessionToken,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return token
    }

    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: Keys.sessionToken
        ]

        SecItemDelete(query as CFDictionary)
    }
}
