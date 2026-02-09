import SwiftUI
import SaphanCore

struct SignUpView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case password
        case confirmPassword
    }

    var body: some View {
        ZStack {
            SaphanTheme.authBackgroundGradient()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [SaphanTheme.brandCoral, Color(red: 193/255, green: 162/255, blue: 139/255)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Join Saphan today")
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
                                .textContentType(.newPassword)
                                .submitLabel(.next)
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
                                    focusedField = .confirmPassword
                                }

                            SecureField("Confirm Password", text: $authViewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .submitLabel(.go)
                                .focused($focusedField, equals: .confirmPassword)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(focusedField == .confirmPassword ? SaphanTheme.brandCoral : Color.white.opacity(0.18), lineWidth: 1)
                                )
                                .onSubmit {
                                    guard !authViewModel.isLoading else { return }
                                    Task {
                                        await authViewModel.signUp()
                                    }
                                }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            PasswordRequirement(
                                text: "At least 8 characters",
                                isMet: authViewModel.password.count >= 8
                            )
                            PasswordRequirement(
                                text: "Passwords match",
                                isMet: !authViewModel.password.isEmpty && authViewModel.password == authViewModel.confirmPassword
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                        Button {
                            focusedField = nil
                            HapticManager.impact(.soft)
                            Task {
                                await authViewModel.signUp()
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign Up")
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
                            focusedField = nil
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Sign In")
                                    .foregroundColor(SaphanTheme.brandCoral)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .disabled(authViewModel.isLoading)
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(SaphanTheme.brandCoral)
                }
            }
        }
        .onDisappear {
            authViewModel.clearError()
        }
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isMet ? .green : .white.opacity(0.3))

            Text(text)
                .font(.subheadline)
                .foregroundColor(isMet ? .white : .white.opacity(0.5))
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
