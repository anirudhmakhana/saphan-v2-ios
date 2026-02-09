import Foundation
import SwiftUI
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
    @Published var currentUser: User?

    private let keychainService = KeychainService()
    private let authService = AuthService()

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

    func signInWithApple() async {
        isLoading = true
        error = nil

        Logger.shared.log("Sign in with Apple initiated", category: .auth, level: .info)

        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)

            error = "Sign in with Apple will be available soon"

            Logger.shared.log("Sign in with Apple not yet implemented", category: .auth, level: .warning)
        } catch {
            Logger.shared.log("Sign in with Apple error: \(error.localizedDescription)", category: .auth, level: .error)
            self.error = error.localizedDescription
        }

        isLoading = false
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

        currentUser = User(
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
}
