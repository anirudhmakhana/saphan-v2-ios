import SwiftUI
import SaphanCore

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    @State private var selectedContextMode: ContextMode? = nil
    @State private var selectedTargetLanguage: Language? = nil
    @State private var selectedInputMode: String? = nil
    @State private var showAllLanguages = false

    let onCompleted: (() -> Void)?

    private let quickLanguageIDs = ["es", "fr", "de", "ja", "zh-cmn", "th"]

    init(onCompleted: (() -> Void)? = nil) {
        self.onCompleted = onCompleted
    }

    var body: some View {
        ZStack {
            SaphanTheme.authBackgroundGradient()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PageIndicator(currentPage: currentPage, totalPages: 3)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                TabView(selection: $currentPage) {
                    useCasePage
                        .tag(0)
                    languagePage
                        .tag(1)
                    inputModePage
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(SaphanMotion.quickSpring, value: currentPage)
            }
        }
        .onChange(of: currentPage) { _ in
            HapticManager.selection()
        }
    }

    // MARK: - Page 1: Use Case

    private var useCasePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("What brings you to Saphan?")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("We'll tailor translations to your style.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)

            VStack(spacing: 14) {
                useCaseCard(emoji: "✈️", label: "Travel & Adventure", mode: .travel)
                useCaseCard(emoji: "💬", label: "Relationships & Dating", mode: .dating)
                useCaseCard(emoji: "💼", label: "Work & Business", mode: .business)
                useCaseCard(emoji: "📚", label: "Learning & Culture", mode: .social)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func useCaseCard(emoji: String, label: String, mode: ContextMode) -> some View {
        let isSelected = selectedContextMode?.id == mode.id

        return Button {
            HapticManager.selection()
            selectedContextMode = mode
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(SaphanMotion.quickSpring) {
                    currentPage = 1
                }
            }
        } label: {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(label)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(SaphanTheme.brandCoral)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? SaphanTheme.brandCoral.opacity(0.18) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? SaphanTheme.brandCoral : Color.white.opacity(0.14), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.97))
        .animation(SaphanMotion.quickSpring, value: isSelected)
    }

    // MARK: - Page 2: Language

    private var languagePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Which language do you need most?")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("You can change this anytime in settings.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 32)

            // Quick chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickLanguages, id: \.id) { language in
                        selectionChip(
                            title: "\(language.flag) \(language.name)",
                            isSelected: selectedTargetLanguage?.id == language.id
                        ) {
                            selectedTargetLanguage = language
                        }
                    }
                }
                .padding(.horizontal, 28)
            }

            // Expand to full list
            Button {
                withAnimation(SaphanMotion.quickSpring) {
                    showAllLanguages.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(showAllLanguages ? "Fewer languages" : "More languages →")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SaphanTheme.brandCoral)
                }
            }
            .padding(.top, 16)
            .buttonStyle(SaphanPressableStyle(scale: 0.97))

            if showAllLanguages {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(allNonQuickLanguages, id: \.id) { language in
                            Button {
                                HapticManager.selection()
                                selectedTargetLanguage = language
                                withAnimation(SaphanMotion.quickSpring) {
                                    showAllLanguages = false
                                }
                            } label: {
                                HStack {
                                    Text("\(language.flag) \(language.name)")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedTargetLanguage?.id == language.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(SaphanTheme.brandCoral)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    selectedTargetLanguage?.id == language.id
                                        ? SaphanTheme.brandCoral.opacity(0.12)
                                        : Color.clear
                                )
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 28)
                }
                .frame(maxHeight: 220)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            Button {
                withAnimation(SaphanMotion.quickSpring) {
                    currentPage = 2
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        selectedTargetLanguage != nil
                            ? AnyShapeStyle(SaphanTheme.primaryCTA(for: .dark))
                            : AnyShapeStyle(Color.white.opacity(0.15))
                    )
                    .cornerRadius(12)
            }
            .buttonStyle(SaphanPressableStyle(scale: 0.985))
            .disabled(selectedTargetLanguage == nil)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Page 3: Input Mode

    private var inputModePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("How do you mostly communicate?")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("We'll set up the experience to match.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)

            VStack(spacing: 14) {
                inputModeCard(emoji: "🎙️", label: "Voice", subtitle: "Speak and hear translations in real time", key: "voice")
                inputModeCard(emoji: "⌨️", label: "Keyboard", subtitle: "Translate while typing in any app", key: "keyboard")
                inputModeCard(emoji: "↕️", label: "Both", subtitle: "I use whatever works", key: "both")
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func inputModeCard(emoji: String, label: String, subtitle: String, key: String) -> some View {
        let isSelected = selectedInputMode == key

        return Button {
            HapticManager.selection()
            selectedInputMode = key
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completeOnboarding()
            }
        } label: {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.60))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(SaphanTheme.brandCoral)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? SaphanTheme.brandCoral.opacity(0.18) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? SaphanTheme.brandCoral : Color.white.opacity(0.14), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.97))
        .animation(SaphanMotion.quickSpring, value: isSelected)
    }

    // MARK: - Helpers

    private var quickLanguages: [Language] {
        Language.allLanguages.filter { quickLanguageIDs.contains($0.id) }
    }

    private var allNonQuickLanguages: [Language] {
        Language.allLanguages.filter { !quickLanguageIDs.contains($0.id) }
    }

    private func selectionChip(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            onTap()
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? SaphanTheme.brandCoral.opacity(0.85)
                        : Color.white.opacity(0.12)
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? SaphanTheme.brandCoral : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.97))
    }

    private func completeOnboarding() {
        if let mode = selectedContextMode {
            PreferencesService.shared.defaultContextMode = mode
        }
        if let lang = selectedTargetLanguage {
            PreferencesService.shared.targetLanguage = lang
        }
        if let inputMode = selectedInputMode {
            PreferencesService.shared.preferredInputMode = inputMode
        }
        onCompleted?()
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? SaphanTheme.brandCoral : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
}
