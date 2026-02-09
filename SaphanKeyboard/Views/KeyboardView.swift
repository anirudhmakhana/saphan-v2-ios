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
        .animation(.spring(response: 0.26, dampingFraction: 0.84), value: viewModel.state)
    }

    private var keyboardBackground: LinearGradient {
        let colors: [Color] = colorScheme == .dark
            ? [Color(uiColor: UIColor(white: 0.12, alpha: 1)), Color(uiColor: UIColor(white: 0.08, alpha: 1))]
            : [Color(uiColor: UIColor(white: 0.9, alpha: 1)), Color(uiColor: UIColor(white: 0.83, alpha: 1))]

        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}

#Preview {
    KeyboardView(viewModel: KeyboardViewModel()) {}
        .frame(height: 364)
}
