import Foundation
import UIKit
import Combine
import SaphanCore

// Keyboard-specific TranslationMode (different from SaphanCore's TranslationMode)
enum KeyboardTranslationMode {
    case understand
    case reply
}

enum KeyboardState {
    case idle
    case typing
    case loading
    case ready
    case error
    case fullAccessRequired
}

@MainActor
final class KeyboardViewModel: ObservableObject {
    @Published var mode: KeyboardTranslationMode = .reply {
        didSet {
            if mode != oldValue {
                handleModeChange()
            }
        }
    }
    @Published var languagePair: LanguagePair {
        didSet {
            if languagePair != oldValue {
                handleLanguageChange()
            }
        }
    }
    @Published var tone: Tone {
        didSet {
            if tone != oldValue {
                handleToneChange()
            }
        }
    }
    @Published var state: KeyboardState = .idle
    @Published var inputText: String = ""
    @Published var translationPreview: String?
    @Published var errorMessage: String?

    var canInsert: Bool {
        state == .ready && translationPreview != nil && !translationPreview!.isEmpty
    }

    var canCopy: Bool {
        translationPreview != nil && !translationPreview!.isEmpty
    }

    var canClear: Bool {
        !inputText.isEmpty || translationPreview != nil
    }

    var canTranslate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            state != .loading &&
            state != .fullAccessRequired
    }

    var canPaste: Bool {
        state != .loading && state != .fullAccessRequired
    }

    private weak var textDocumentProxy: UITextDocumentProxy?
    private let translationService: TranslationService
    private let preferences: PreferencesService
    private let debouncer: Debouncer
    private var currentTranslationTask: Task<Void, Never>?
    private var pasteboardChangeCount: Int = 0
    private var fullAccessGranted = false

    init() {
        let userDefaults = UserDefaults(suiteName: Constants.appGroupID) ?? .standard
        self.preferences = PreferencesService(userDefaults: userDefaults)
        self.translationService = TranslationService()
        self.debouncer = Debouncer(delay: Constants.UI.debounceDelay)

        // Create language pair from preferences
        self.languagePair = LanguagePair(
            source: preferences.sourceLanguage,
            target: preferences.targetLanguage
        )
        self.tone = preferences.defaultTone
    }

    func setTextDocumentProxy(_ proxy: UITextDocumentProxy?) {
        self.textDocumentProxy = proxy
        checkForPaste()
    }

    func setFullAccess(granted: Bool) {
        fullAccessGranted = granted

        if granted {
            if state == .fullAccessRequired {
                state = inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .idle : .typing
            }
            errorMessage = nil
        } else {
            state = .fullAccessRequired
        }
    }

    func insertCharacter(_ char: String) {
        textDocumentProxy?.insertText(char)
        inputText += char

        if state == .fullAccessRequired {
            return
        }

        markNeedsTranslation()
    }

    func deleteBackward() {
        textDocumentProxy?.deleteBackward()

        if !inputText.isEmpty {
            inputText.removeLast()
        }

        if inputText.isEmpty {
            clear()
        } else {
            markNeedsTranslation()
        }
    }

    func paste() {
        guard fullAccessGranted else {
            state = .fullAccessRequired
            errorMessage = "Enable Full Access to paste from clipboard"
            return
        }

        guard let pasteText = UIPasteboard.general.string, !pasteText.isEmpty else {
            return
        }

        inputText = pasteText
        mode = .understand

        markNeedsTranslation()
    }

    func clear() {
        inputText = ""
        translationPreview = nil
        errorMessage = nil
        state = .idle

        currentTranslationTask?.cancel()
        debouncer.cancel()
    }

    func copyTranslation() {
        guard let translation = translationPreview else { return }
        UIPasteboard.general.string = translation
    }

    func insertTranslation() {
        guard let translation = translationPreview else { return }

        for _ in 0..<inputText.count {
            textDocumentProxy?.deleteBackward()
        }

        textDocumentProxy?.insertText(translation)

        incrementTranslationCount()

        clear()
    }

    func retry() {
        requestTranslation()
    }

    func swapLanguages() {
        languagePair = languagePair.reversed
        saveLanguagePair(languagePair)
    }

    private func handleModeChange() {
        if mode == .understand {
            languagePair = languagePair.reversed
        }

        if !inputText.isEmpty {
            markNeedsTranslation()
        }
    }

    private func handleLanguageChange() {
        saveLanguagePair(languagePair)

        if !inputText.isEmpty && state != .idle {
            markNeedsTranslation()
        }
    }

    private func handleToneChange() {
        preferences.defaultTone = tone

        if !inputText.isEmpty && state != .idle && mode == .reply {
            markNeedsTranslation()
        }
    }

    private func checkForPaste() {
        let currentCount = UIPasteboard.general.changeCount
        if currentCount != pasteboardChangeCount && mode == .understand {
            pasteboardChangeCount = currentCount
        }
    }

    private func debouncedTranslate() {
        debouncer.debounceAsync { [weak self] in
            await self?.performTranslation()
        }
    }

    func requestTranslation() {
        guard fullAccessGranted else {
            state = .fullAccessRequired
            errorMessage = "Enable Full Access to translate"
            return
        }

        guard canTranslate else { return }
        translateImmediately()
    }

    private func translateImmediately() {
        debouncer.cancel()
        currentTranslationTask?.cancel()

        currentTranslationTask = Task { [weak self] in
            await self?.performTranslation()
        }
    }

    private func performTranslation() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            state = .idle
            translationPreview = nil
            return
        }

        state = .loading
        errorMessage = nil

        // Map keyboard mode to tone string for the API
        let toneString = mode == .reply ? tone.rawValue : "neutral"

        let request = TranslationRequest(
            text: text,
            sourceLanguage: languagePair.source.code,
            targetLanguage: languagePair.target.code,
            tone: toneString,
            mode: .standard
        )

        do {
            let response = try await translationService.translate(request)

            guard !Task.isCancelled else { return }

            setFullAccess(granted: true)

            translationPreview = response.translatedText
            state = .ready
        } catch is CancellationError {
            return
        } catch let error as TranslationError {
            guard !Task.isCancelled else { return }

            handleTranslationError(error)
        } catch {
            guard !Task.isCancelled else { return }

            errorMessage = error.localizedDescription
            state = .error
        }
    }

    private func handleTranslationError(_ error: TranslationError) {
        switch error {
        case .unauthorized:
            state = .fullAccessRequired
        case .invalidInput:
            state = .idle
        default:
            errorMessage = error.errorDescription
            state = .error
        }
    }

    private func markNeedsTranslation() {
        currentTranslationTask?.cancel()
        debouncer.cancel()
        translationPreview = nil
        errorMessage = nil

        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state = .idle
        } else {
            state = .typing
        }
    }

    // Helper methods to work with the new PreferencesService
    private func saveLanguagePair(_ pair: LanguagePair) {
        preferences.sourceLanguage = pair.source
        preferences.targetLanguage = pair.target
    }

    private func incrementTranslationCount() {
        // This functionality should be implemented in PreferencesService if needed
        // For now, we'll leave it as a placeholder
    }
}
