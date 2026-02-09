import SwiftUI
import SaphanCore

struct KeyboardView: View {
    @ObservedObject var viewModel: KeyboardViewModel
    let onGlobeTapped: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            TopBar(viewModel: viewModel)

            PreviewBar(viewModel: viewModel)

            ActionBar(viewModel: viewModel)

            KeyboardGrid(viewModel: viewModel, onGlobeTapped: onGlobeTapped)
        }
        .background(keyboardBackground)
        .ignoresSafeArea(.all)
    }

    private var keyboardBackground: Color {
        colorScheme == .dark
            ? Color(uiColor: UIColor(white: 0.1, alpha: 1))
            : Color(uiColor: UIColor(white: 0.85, alpha: 1))
    }
}

#Preview {
    KeyboardView(viewModel: KeyboardViewModel()) {}
        .frame(height: 364)
}
