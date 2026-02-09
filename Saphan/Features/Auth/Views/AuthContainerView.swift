import SwiftUI
import SaphanCore

struct AuthContainerView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            Image(systemName: "waveform.badge.mic")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Saphan")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)

                            Text("Sign in to get started")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 60)

                        VStack(spacing: 20) {
                            if let error = authViewModel.error {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error)
                                        .font(.subheadline)
                                }
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }

                            VStack(spacing: 16) {
                                TextField("Email", text: $authViewModel.email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)

                                SecureField("Password", text: $authViewModel.password)
                                    .textContentType(.password)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }

                            Button {
                                Task {
                                    await authViewModel.signIn()
                                }
                            } label: {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(authViewModel.isLoading)

                            Button {
                                showingSignUp = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Don't have an account?")
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("Sign Up")
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                            }
                            .disabled(authViewModel.isLoading)

                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)

                                Text("or")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)

                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)

                            Button {
                                Task {
                                    await authViewModel.signInWithApple()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 18))
                                    Text("Sign in with Apple")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .disabled(authViewModel.isLoading)

                            Button {
                                Task {
                                    await authViewModel.signInWithGoogle()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "g.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Sign in with Google")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .disabled(authViewModel.isLoading)

                            Button {
                                authViewModel.continueAsGuest()
                            } label: {
                                Text("Continue as Guest")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.7))
                                    .underline()
                            }
                            .disabled(authViewModel.isLoading)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)

                        Spacer()
                    }
                }
            }
            .navigationDestination(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
}

#Preview {
    AuthContainerView()
        .environmentObject(AuthViewModel())
}
