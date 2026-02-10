import Foundation
import AuthenticationServices
import CryptoKit
import Security
import SwiftUI
import Supabase
import SaphanCore

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var error: String?
    @Published var showSignUp = false
    @Published var currentUser: SaphanCore.User?

    private let keychainService = KeychainService()
    private let authService = AuthService()
    private var appleSignInNonce: String?
    private var cachedSupabaseClient: SupabaseClient?

    init() {
        checkExistingSession()
    }

    func checkExistingSession() {
        isLoading = true

        if keychainService.getAuthToken() != nil {
            Logger.shared.log("Found existing auth token", category: .auth, level: .info)
            isAuthenticated = true

            if let userData = keychainService.getUserData() {
                Logger.shared.log("Restored user data from keychain", category: .auth, level: .info)
                currentUser = userData
            }
        } else {
            Logger.shared.log("No existing auth token found", category: .auth, level: .info)
        }

        isLoading = false
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter both email and password"
            return
        }

        guard email.contains("@") else {
            error = "Please enter a valid email address"
            return
        }

        isLoading = true
        error = nil

        do {
            Logger.shared.log("Attempting sign in for: \(email)", category: .auth, level: .info)

            let response = try await authService.signIn(email: email, password: password)

            if keychainService.saveAuthToken(response.token) {
                Logger.shared.log("Auth token saved to keychain", category: .auth, level: .info)
            }

            if keychainService.saveUserData(response.user) {
                Logger.shared.log("User data saved to keychain", category: .auth, level: .info)
            }

            currentUser = response.user
            isAuthenticated = true

            email = ""
            password = ""

            Logger.shared.log("Sign in successful", category: .auth, level: .info)
        } catch {
            Logger.shared.log("Sign in failed: \(error.localizedDescription)", category: .auth, level: .error)
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            error = "Please fill in all fields"
            return
        }

        guard email.contains("@") else {
            error = "Please enter a valid email address"
            return
        }

        guard password.count >= 8 else {
            error = "Password must be at least 8 characters"
            return
        }

        guard password == confirmPassword else {
            error = "Passwords do not match"
            return
        }

        isLoading = true
        error = nil

        do {
            Logger.shared.log("Attempting sign up for: \(email)", category: .auth, level: .info)

            let response = try await authService.signUp(email: email, password: password)

            if keychainService.saveAuthToken(response.token) {
                Logger.shared.log("Auth token saved to keychain", category: .auth, level: .info)
            }

            if keychainService.saveUserData(response.user) {
                Logger.shared.log("User data saved to keychain", category: .auth, level: .info)
            }

            currentUser = response.user
            isAuthenticated = true

            email = ""
            password = ""
            confirmPassword = ""

            Logger.shared.log("Sign up successful", category: .auth, level: .info)
        } catch {
            Logger.shared.log("Sign up failed: \(error.localizedDescription)", category: .auth, level: .error)
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        appleSignInNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        Logger.shared.log("Sign in with Apple initiated", category: .auth, level: .info)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil
        defer {
            isLoading = false
            appleSignInNonce = nil
        }

        do {
            switch result {
            case .failure(let signInError):
                if let authError = signInError as? ASAuthorizationError, authError.code == .canceled {
                    Logger.shared.log("Sign in with Apple canceled by user", category: .auth, level: .info)
                    return
                }
                throw signInError

            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    throw AuthError.serverError("Invalid Sign in with Apple credential.")
                }
                try await signInWithAppleCredential(credential)
            }
        } catch {
            Logger.shared.log("Sign in with Apple error: \(error.localizedDescription)", category: .auth, level: .error)
            self.error = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        error = nil

        Logger.shared.log("Sign in with Google initiated", category: .auth, level: .info)

        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)

            error = "Sign in with Google will be available soon"

            Logger.shared.log("Sign in with Google not yet implemented", category: .auth, level: .warning)
        } catch {
            Logger.shared.log("Sign in with Google error: \(error.localizedDescription)", category: .auth, level: .error)
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func continueAsGuest() {
        Logger.shared.log("User continuing as guest", category: .auth, level: .info)

        currentUser = SaphanCore.User(
            id: "guest_\(UUID().uuidString)",
            email: "guest@saphan.app",
            name: "Guest User",
            isGuest: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        isAuthenticated = true
    }

    func signOut() {
        Logger.shared.log("User signing out", category: .auth, level: .info)

        _ = keychainService.deleteAuthToken()
        _ = keychainService.deleteUserData()

        currentUser = nil
        isAuthenticated = false
        email = ""
        password = ""
        confirmPassword = ""
        error = nil

        Logger.shared.log("Sign out complete", category: .auth, level: .info)
    }

    func clearError() {
        error = nil
    }

    private func signInWithAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              !idToken.isEmpty else {
            throw AuthError.serverError("Sign in with Apple did not return a valid identity token.")
        }

        guard let nonce = appleSignInNonce, !nonce.isEmpty else {
            throw AuthError.serverError("Apple sign-in nonce is missing. Please try again.")
        }

        let session = try await supabaseClient().auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        let resolvedEmail = (session.user.email ?? credential.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedEmail.isEmpty else {
            throw AuthError.serverError("Unable to retrieve your email from Apple Sign-In.")
        }

        let resolvedName = formattedName(from: credential.fullName)
        let mappedUser = SaphanCore.User(
            id: session.user.id.uuidString,
            email: resolvedEmail,
            name: resolvedName,
            isGuest: false,
            createdAt: session.user.createdAt,
            updatedAt: session.user.updatedAt
        )

        if keychainService.saveAuthToken(session.accessToken) {
            Logger.shared.log("Auth token saved to keychain", category: .auth, level: .info)
        }

        if keychainService.setRefreshToken(session.refreshToken) {
            Logger.shared.log("Refresh token saved to keychain", category: .auth, level: .info)
        }

        if keychainService.saveUserData(mappedUser) {
            Logger.shared.log("User data saved to keychain", category: .auth, level: .info)
        }

        currentUser = mappedUser
        isAuthenticated = true
        email = ""
        password = ""
        confirmPassword = ""

        Logger.shared.log("Sign in with Apple successful", category: .auth, level: .info)
    }

    private func supabaseClient() throws -> SupabaseClient {
        if let cachedSupabaseClient {
            return cachedSupabaseClient
        }

        let supabaseURLString = Constants.Supabase.url.trimmingCharacters(in: .whitespacesAndNewlines)
        let supabaseAnonKey = Constants.Supabase.anonKey.trimmingCharacters(in: .whitespacesAndNewlines)

        let hasMissingConfig =
            supabaseURLString.isEmpty ||
            supabaseAnonKey.isEmpty ||
            supabaseURLString.contains("YOUR_SUPABASE_URL") ||
            supabaseAnonKey.contains("YOUR_SUPABASE_ANON_KEY") ||
            supabaseURLString.hasPrefix("$(") ||
            supabaseAnonKey.hasPrefix("$(")

        guard !hasMissingConfig else {
            throw AuthError.serverError(
                "Supabase auth is not configured. Set SAPHAN_SUPABASE_URL and SAPHAN_SUPABASE_ANON_KEY."
            )
        }

        guard let supabaseURL = URL(string: supabaseURLString) else {
            throw AuthError.serverError("Supabase URL is invalid.")
        }

        let client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
        cachedSupabaseClient = client
        return client
    }

    private func formattedName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let value = PersonNameComponentsFormatter().string(from: components)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce for Apple sign-in. OSStatus: \(status)")
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
