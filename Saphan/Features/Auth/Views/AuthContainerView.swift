import SwiftUI
import SaphanCore

struct AuthContainerView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingSignUp = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SaphanTheme.authBackgroundGradient()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            Image(systemName: "waveform.badge.mic")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [SaphanTheme.brandCoral, Color(red: 193/255, green: 162/255, blue: 139/255)],
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
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .submitLabel(.next)
                                    .focused($focusedField, equals: .email)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(focusedField == .email ? SaphanTheme.brandCoral : Color.white.opacity(0.18), lineWidth: 1)
                                    )
                                    .onSubmit {
                                        focusedField = .password
                                    }

                                SecureField("Password", text: $authViewModel.password)
                                    .textContentType(.password)
                                    .submitLabel(.go)
                                    .focused($focusedField, equals: .password)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(focusedField == .password ? SaphanTheme.brandCoral : Color.white.opacity(0.18), lineWidth: 1)
                                    )
                                    .onSubmit {
                                        guard !authViewModel.isLoading else { return }
                                        Task {
                                            await authViewModel.signIn()
                                        }
                                    }
                            }

                            Button {
                                focusedField = nil
                                HapticManager.impact(.soft)
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
                            .background(SaphanTheme.primaryCTA(for: .dark))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .buttonStyle(SaphanPressableStyle(scale: 0.98))
                            .disabled(authViewModel.isLoading)

                            Button {
                                showingSignUp = true
                                HapticManager.selection()
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Don't have an account?")
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("Sign Up")
                                        .foregroundColor(SaphanTheme.brandCoral)
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
                                focusedField = nil
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
                            .buttonStyle(SaphanPressableStyle(scale: 0.98))
                            .disabled(authViewModel.isLoading)

                            Button {
                                focusedField = nil
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
                            .buttonStyle(SaphanPressableStyle(scale: 0.98))
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
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    focusedField = nil
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
