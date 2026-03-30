import Foundation
import Security

protocol SessionStoreProtocol: AnyObject {
    var sessionToken: String? { get set }
    var baseURL: String { get set }
    func clearSession()
    func loadMealQuickPresets(for userId: String) -> [StoredMealQuickPreset]
    func upsertMealQuickPreset(_ preset: StoredMealQuickPreset, maxPerUser: Int)
}

final class SessionStore: SessionStoreProtocol {
    private enum Keys {
        static let sessionToken = "macrolicious.sessionToken"
        static let baseURL = "macrolicious.baseURL"
        static let mealQuickPresets = "macrolicious.mealQuickPresets"
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

    func loadMealQuickPresets(for userId: String) -> [StoredMealQuickPreset] {
        readMealQuickPresets()
            .filter { $0.userId == userId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func upsertMealQuickPreset(_ preset: StoredMealQuickPreset, maxPerUser: Int = 24) {
        var allPresets = readMealQuickPresets()

        allPresets.removeAll {
            $0.userId == preset.userId &&
            $0.mealTypeRawValue == preset.mealTypeRawValue &&
            $0.ingredientId == preset.ingredientId
        }

        allPresets.append(preset)

        let otherUsers = allPresets.filter { $0.userId != preset.userId }
        let currentUserPresets = allPresets
            .filter { $0.userId == preset.userId }
            .sorted { $0.updatedAt > $1.updatedAt }

        let trimmedCurrentUserPresets = Array(currentUserPresets.prefix(maxPerUser))
        writeMealQuickPresets(otherUsers + trimmedCurrentUserPresets)
    }

    private func readMealQuickPresets() -> [StoredMealQuickPreset] {
        guard let data = defaults.data(forKey: Keys.mealQuickPresets) else {
            return []
        }

        do {
            return try JSONDecoder().decode([StoredMealQuickPreset].self, from: data)
        } catch {
            return []
        }
    }

    private func writeMealQuickPresets(_ presets: [StoredMealQuickPreset]) {
        do {
            let data = try JSONEncoder().encode(presets)
            defaults.set(data, forKey: Keys.mealQuickPresets)
        } catch {
            defaults.removeObject(forKey: Keys.mealQuickPresets)
        }
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

struct StoredMealQuickPreset: Codable, Equatable {
    let userId: String
    let mealTypeRawValue: String
    let ingredientId: String
    let ingredientName: String
    let quantityValue: Double
    let quantityUnitRawValue: String
    let updatedAt: Date
}
