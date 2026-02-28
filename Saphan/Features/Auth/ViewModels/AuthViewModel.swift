import Foundation
import AuthenticationServices
import CryptoKit
import Security
import SwiftUI
import UIKit
import GoogleSignIn
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
        defer { isLoading = false }

        Logger.shared.log("Sign in with Google initiated", category: .auth, level: .info)

        do {
            let configuration = try googleSignInConfiguration()
            guard let presentingViewController = Self.presentingViewController() else {
                throw AuthError.serverError("Unable to present Google Sign-In. Please try again.")
            }

            GIDSignIn.sharedInstance.configuration = configuration

            let signInResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
                GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, signInError in
                    if let signInError {
                        continuation.resume(throwing: signInError)
                        return
                    }

                    guard let result else {
                        continuation.resume(throwing: AuthError.serverError("Google Sign-In did not return a result."))
                        return
                    }

                    continuation.resume(returning: result)
                }
            }

            try await signInWithGoogleResult(signInResult)

        } catch {
            if isGoogleSignInCancelled(error) {
                Logger.shared.log("Sign in with Google canceled by user", category: .auth, level: .info)
                return
            }

            Logger.shared.log("Sign in with Google error: \(error.localizedDescription)", category: .auth, level: .error)
            self.error = error.localizedDescription
        }
    }

    func signOut() {
        Logger.shared.log("User signing out", category: .auth, level: .info)

        _ = keychainService.deleteAuthToken()
        _ = keychainService.deleteRefreshToken()
        _ = keychainService.deleteUserData()
        GIDSignIn.sharedInstance.signOut()

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

        try persistSupabaseSession(
            session: session,
            fallbackEmail: credential.email,
            fallbackName: formattedName(from: credential.fullName)
        )

        Logger.shared.log("Sign in with Apple successful", category: .auth, level: .info)
    }

    private func signInWithGoogleResult(_ signInResult: GIDSignInResult) async throws {
        guard let idToken = signInResult.user.idToken?.tokenString, !idToken.isEmpty else {
            throw AuthError.serverError("Google Sign-In did not return a valid identity token.")
        }

        let accessToken = signInResult.user.accessToken.tokenString
        let session = try await supabaseClient().auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )

        try persistSupabaseSession(
            session: session,
            fallbackEmail: signInResult.user.profile?.email,
            fallbackName: signInResult.user.profile?.name
        )

        Logger.shared.log("Sign in with Google successful", category: .auth, level: .info)
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

    private func googleSignInConfiguration() throws -> GIDConfiguration {
        let clientID = Constants.GoogleSignIn.clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawServerClientID = Constants.GoogleSignIn.serverClientID.trimmingCharacters(in: .whitespacesAndNewlines)

        let invalidClientID =
            clientID.isEmpty ||
            clientID.contains("YOUR_GOOGLE_CLIENT_ID") ||
            clientID.hasPrefix("$(")

        guard !invalidClientID else {
            throw AuthError.serverError(
                "Google Sign-In is not configured. Set SAPHAN_GOOGLE_CLIENT_ID and URL scheme values."
            )
        }

        let serverClientID: String? = {
            guard !rawServerClientID.isEmpty,
                  !rawServerClientID.contains("YOUR_"),
                  !rawServerClientID.hasPrefix("$(") else {
                return nil
            }
            return rawServerClientID
        }()

        return GIDConfiguration(clientID: clientID, serverClientID: serverClientID)
    }

    private func persistSupabaseSession(
        session: Session,
        fallbackEmail: String?,
        fallbackName: String?
    ) throws {
        let resolvedEmail = (session.user.email ?? fallbackEmail ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedEmail.isEmpty else {
            throw AuthError.serverError("Unable to retrieve your account email from sign-in.")
        }

        let trimmedName = fallbackName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let mappedUser = SaphanCore.User(
            id: session.user.id.uuidString,
            email: resolvedEmail,
            name: (trimmedName?.isEmpty == true) ? nil : trimmedName,
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
    }

    private func isGoogleSignInCancelled(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == kGIDSignInErrorDomain &&
            nsError.code == -5
    }

    private static func presentingViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? scenes.first?.windows.first

        return topViewController(from: keyWindow?.rootViewController)
    }

    private static func topViewController(from root: UIViewController?) -> UIViewController? {
        if let navigation = root as? UINavigationController {
            return topViewController(from: navigation.visibleViewController)
        }

        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }

        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }

        return root
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
