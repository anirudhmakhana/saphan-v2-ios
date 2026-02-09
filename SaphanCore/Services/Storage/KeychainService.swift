import Foundation
import Security

public class KeychainService {
    private let serviceName: String

    public init(serviceName: String = Constants.bundleID) {
        self.serviceName = serviceName
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

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func retrieve(key: String) -> String? {
        guard let data = retrieveData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private func saveData(key: String, value: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func retrieveData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return data
    }
}
