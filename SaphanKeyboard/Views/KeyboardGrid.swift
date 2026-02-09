import SwiftUI
import SaphanCore

struct KeyboardGrid: View {
    @ObservedObject var viewModel: KeyboardViewModel
    let onGlobeTapped: () -> Void

    @State private var isShifted = false
    @State private var isCapsLock = false
    @State private var showNumbers = false
    @State private var deleteTimer: Timer?

    @Environment(\.colorScheme) private var colorScheme

    private let letterRows = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    private let numberRows = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
        [".", ",", "?", "!", "'"]
    ]

    var body: some View {
        GeometryReader { proxy in
            let layout = KeyboardLayout(width: proxy.size.width)

            VStack(spacing: layout.rowSpacing) {
                if showNumbers {
                    numberKeyboard(layout: layout)
                } else {
                    letterKeyboard(layout: layout)
                }

                bottomRow(layout: layout)
            }
            .padding(.horizontal, layout.sidePadding)
            .padding(.vertical, layout.verticalPadding)
        }
        .frame(height: Constants.UI.keyboardHeight)
    }

    private func letterKeyboard(layout: KeyboardLayout) -> some View {
        VStack(spacing: layout.rowSpacing) {
            keyRow(keys: letterRows[0], keyWidth: layout.keyWidth, layout: layout)
            keyRow(
                keys: letterRows[1],
                keyWidth: layout.keyWidth,
                layout: layout,
                leadingInset: layout.rowIndent,
                trailingInset: layout.rowIndent
            )

            HStack(spacing: layout.keySpacing) {
                shiftButton(height: layout.keyHeight)
                    .frame(width: layout.specialKeyWidth, height: layout.keyHeight)
                ForEach(letterRows[2], id: \.self) { key in
                    KeyboardButton(
                        title: displayKey(key),
                        style: .character,
                        height: layout.keyHeight
                    ) {
                        viewModel.insertCharacter(displayKey(key))
                        HapticManager.impact(.light)
                        if isShifted && !isCapsLock {
                            isShifted = false
                        }
                    }
                    .frame(width: layout.keyWidth)
                }
                deleteButton(height: layout.keyHeight)
                    .frame(width: layout.specialKeyWidth, height: layout.keyHeight)
            }
        }
    }

    private func numberKeyboard(layout: KeyboardLayout) -> some View {
        VStack(spacing: layout.rowSpacing) {
            keyRow(keys: numberRows[0], keyWidth: layout.keyWidth, layout: layout)
            keyRow(keys: numberRows[1], keyWidth: layout.keyWidth, layout: layout)

            HStack(spacing: layout.keySpacing) {
                symbolToggleButton(height: layout.keyHeight)
                    .frame(width: layout.specialKeyWidth, height: layout.keyHeight)
                ForEach(numberRows[2], id: \.self) { key in
                    KeyboardButton(
                        title: key,
                        style: .character,
                        height: layout.keyHeight
                    ) {
                        viewModel.insertCharacter(key)
                        HapticManager.impact(.light)
                    }
                    .frame(width: layout.keyWidth)
                }
                deleteButton(height: layout.keyHeight)
                    .frame(width: layout.specialKeyWidth, height: layout.keyHeight)
            }
        }
    }

    private func keyRow(
        keys: [String],
        keyWidth: CGFloat,
        layout: KeyboardLayout,
        leadingInset: CGFloat = 0,
        trailingInset: CGFloat = 0
    ) -> some View {
        HStack(spacing: layout.keySpacing) {
            if leadingInset > 0 {
                Spacer()
                    .frame(width: leadingInset)
            }

            ForEach(keys, id: \.self) { key in
                KeyboardButton(
                    title: displayKey(key),
                    style: .character,
                    height: layout.keyHeight
                ) {
                    viewModel.insertCharacter(displayKey(key))
                    HapticManager.impact(.light)
                    if isShifted && !isCapsLock {
                        isShifted = false
                    }
                }
                .frame(width: keyWidth)
            }

            if trailingInset > 0 {
                Spacer()
                    .frame(width: trailingInset)
            }
        }
    }

    private func displayKey(_ key: String) -> String {
        (isShifted || isCapsLock) ? key.uppercased() : key
    }

    private func shiftButton(height: CGFloat) -> some View {
        KeyboardButton(
            icon: isCapsLock ? "capslock.fill" : (isShifted ? "shift.fill" : "shift"),
            style: isShifted || isCapsLock ? .highlighted : .special,
            height: height
        ) {
            if isShifted {
                isCapsLock = true
                isShifted = false
                HapticManager.impact(.medium)
            } else if isCapsLock {
                isCapsLock = false
                isShifted = false
                HapticManager.impact(.light)
            } else {
                isShifted = true
                HapticManager.impact(.light)
            }
        }
    }

    private func deleteButton(height: CGFloat) -> some View {
        KeyboardButton(
            icon: "delete.left",
            style: .special,
            height: height
        ) {
            viewModel.deleteBackward()
            HapticManager.impact(.light)
        }
        .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 50, pressing: { pressing in
            if pressing {
                startDeleteRepeat()
            } else {
                stopDeleteRepeat()
            }
        }, perform: {})
    }

    private func symbolToggleButton(height: CGFloat) -> some View {
        KeyboardButton(
            title: "ABC",
            style: .special,
            height: height
        ) {
            showNumbers = false
            HapticManager.impact(.light)
        }
    }

    private func startDeleteRepeat() {
        stopDeleteRepeat()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            Task { @MainActor in
                viewModel.deleteBackward()
            }
        }
    }

    private func stopDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    private func bottomRow(layout: KeyboardLayout) -> some View {
        HStack(spacing: layout.keySpacing) {
            KeyboardButton(
                title: "123",
                style: .special,
                height: layout.keyHeight
            ) {
                showNumbers.toggle()
                HapticManager.impact(.light)
            }
            .frame(width: layout.bottomKeyWidth)

            KeyboardButton(
                icon: "globe",
                style: .special,
                height: layout.keyHeight
            ) {
                onGlobeTapped()
                HapticManager.impact(.light)
            }
            .frame(width: layout.bottomKeyWidth)

            KeyboardButton(
                title: "space",
                style: .space,
                height: layout.keyHeight
            ) {
                viewModel.insertCharacter(" ")
                HapticManager.impact(.light)
            }
            .frame(width: layout.spaceKeyWidth)

            KeyboardButton(
                title: "return",
                style: .special,
                height: layout.keyHeight
            ) {
                viewModel.insertCharacter("\n")
                HapticManager.impact(.light)
            }
            .frame(width: layout.returnKeyWidth)
        }
    }
}

private struct KeyboardLayout {
    let sidePadding: CGFloat = 3
    let verticalPadding: CGFloat = 10
    let keySpacing: CGFloat = 6
    let rowSpacing: CGFloat = 11
    let keyHeight: CGFloat = 42
    let keyWidth: CGFloat
    let specialKeyWidth: CGFloat
    let rowIndent: CGFloat
    let bottomKeyWidth: CGFloat
    let returnKeyWidth: CGFloat
    let spaceKeyWidth: CGFloat

    init(width: CGFloat) {
        let availableWidth = width - (sidePadding * 2)
        keyWidth = (availableWidth - (keySpacing * 9)) / 10
        specialKeyWidth = keyWidth * 1.6
        rowIndent = keyWidth * 0.5
        bottomKeyWidth = keyWidth * 1.3
        returnKeyWidth = keyWidth * 1.6

        let fixed = (bottomKeyWidth * 2) + returnKeyWidth
        let remaining = availableWidth - fixed - (keySpacing * 3)
        spaceKeyWidth = max(remaining, 0)
    }
}

#Preview {
    KeyboardGrid(viewModel: KeyboardViewModel()) {}
        .frame(height: 216)
        .background(Color(.systemGray5))
}
