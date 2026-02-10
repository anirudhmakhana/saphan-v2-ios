import Foundation
import Security

public class KeychainService {
    private let serviceName: String
    private let accessGroup: String?

    public init(serviceName: String = Constants.bundleID, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup ?? KeychainService.defaultAccessGroup()
    }

    private enum Keys {
        static let authToken = "authToken"
        static let userID = "userID"
        static let refreshToken = "refreshToken"
        static let userData = "userData"
    }

    public func setAuthToken(_ token: String) -> Bool {
        return save(key: Keys.authToken, value: token)
    }

    public func saveAuthToken(_ token: String) -> Bool {
        return setAuthToken(token)
    }

    public func getAuthToken() -> String? {
        return retrieve(key: Keys.authToken)
    }

    public func deleteAuthToken() -> Bool {
        return delete(key: Keys.authToken)
    }

    public func setUserID(_ userID: String) -> Bool {
        return save(key: Keys.userID, value: userID)
    }

    public func getUserID() -> String? {
        return retrieve(key: Keys.userID)
    }

    public func deleteUserID() -> Bool {
        return delete(key: Keys.userID)
    }

    public func setRefreshToken(_ token: String) -> Bool {
        return save(key: Keys.refreshToken, value: token)
    }

    public func getRefreshToken() -> String? {
        return retrieve(key: Keys.refreshToken)
    }

    public func deleteRefreshToken() -> Bool {
        return delete(key: Keys.refreshToken)
    }

    public func saveUserData(_ user: User) -> Bool {
        guard let data = try? JSONEncoder().encode(user) else { return false }
        return saveData(key: Keys.userData, value: data)
    }

    public func getUserData() -> User? {
        guard let data = retrieveData(key: Keys.userData) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    public func deleteUserData() -> Bool {
        return delete(key: Keys.userData)
    }

    public func clearAll() -> Bool {
        var success = true
        success = deleteAuthToken() && success
        success = deleteUserID() && success
        success = deleteRefreshToken() && success
        success = deleteUserData() && success
        return success
    }

    private func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return saveData(key: key, value: data)
    }

    private func retrieve(key: String) -> String? {
        guard let data = retrieveData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) -> Bool {
        let primaryStatus = SecItemDelete(baseQuery(for: key, includeAccessGroup: true) as CFDictionary)
        let fallbackStatus = SecItemDelete(baseQuery(for: key, includeAccessGroup: false) as CFDictionary)

        let primaryOK = primaryStatus == errSecSuccess || primaryStatus == errSecItemNotFound || accessGroup == nil
        let fallbackOK = fallbackStatus == errSecSuccess || fallbackStatus == errSecItemNotFound

        return primaryOK && fallbackOK
    }

    private func saveData(key: String, value: Data) -> Bool {
        // Remove both shared and legacy entries before saving.
        _ = SecItemDelete(baseQuery(for: key, includeAccessGroup: true) as CFDictionary)
        _ = SecItemDelete(baseQuery(for: key, includeAccessGroup: false) as CFDictionary)

        let primaryStatus = SecItemAdd(saveQuery(for: key, value: value, includeAccessGroup: true) as CFDictionary, nil)
        if primaryStatus == errSecSuccess {
            return true
        }

        // Fallback for environments where shared group resolution is unavailable.
        let fallbackStatus = SecItemAdd(saveQuery(for: key, value: value, includeAccessGroup: false) as CFDictionary, nil)
        return fallbackStatus == errSecSuccess
    }

    private func retrieveData(key: String) -> Data? {
        var result: AnyObject?
        let primaryStatus = SecItemCopyMatching(readQuery(for: key, includeAccessGroup: true) as CFDictionary, &result)

        if primaryStatus == errSecSuccess, let data = result as? Data {
            return data
        }

        result = nil
        let fallbackStatus = SecItemCopyMatching(readQuery(for: key, includeAccessGroup: false) as CFDictionary, &result)
        guard fallbackStatus == errSecSuccess, let data = result as? Data else {
            return nil
        }

        // Opportunistic migration to shared keychain so extensions can read tokens.
        if accessGroup != nil {
            _ = saveData(key: key, value: data)
        }

        return data
    }

    private static func defaultAccessGroup() -> String? {
        if let prefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String, !prefix.isEmpty {
            let normalizedPrefix = prefix.hasSuffix(".") ? prefix : "\(prefix)."
            return "\(normalizedPrefix)\(Constants.bundleID)"
        }

        if let prefixes = Bundle.main.object(forInfoDictionaryKey: "ApplicationIdentifierPrefix") as? [String],
           let prefix = prefixes.first,
           !prefix.isEmpty {
            let normalizedPrefix = prefix.hasSuffix(".") ? prefix : "\(prefix)."
            return "\(normalizedPrefix)\(Constants.bundleID)"
        }

        return nil
    }

    private func baseQuery(for key: String, includeAccessGroup: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        if includeAccessGroup, let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    private func saveQuery(for key: String, value: Data, includeAccessGroup: Bool) -> [String: Any] {
        var query = baseQuery(for: key, includeAccessGroup: includeAccessGroup)
        query[kSecValueData as String] = value
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return query
    }

    private func readQuery(for key: String, includeAccessGroup: Bool) -> [String: Any] {
        var query = baseQuery(for: key, includeAccessGroup: includeAccessGroup)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }
}
