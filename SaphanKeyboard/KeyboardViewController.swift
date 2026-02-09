import UIKit
import SwiftUI
import SaphanCore

class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<KeyboardView>?
    private let viewModel = KeyboardViewModel()
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        let totalHeight = Constants.UI.topBarHeight +
            Constants.UI.previewBarCollapsedHeight +
            Constants.UI.actionBarHeight +
            Constants.UI.keyboardHeight

        let inputView = UIInputView(
            frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: totalHeight),
            inputViewStyle: .keyboard
        )
        self.inputView = inputView

        setupKeyboardView(in: inputView)
        updateViewHeight(totalHeight: totalHeight, for: inputView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.setTextDocumentProxy(textDocumentProxy)
        viewModel.setFullAccess(granted: hasFullAccess)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let inputView = inputView {
            let totalHeight = Constants.UI.topBarHeight +
                Constants.UI.previewBarCollapsedHeight +
                Constants.UI.actionBarHeight +
                Constants.UI.keyboardHeight
            updateViewHeight(totalHeight: totalHeight, for: inputView)
            viewModel.setFullAccess(granted: hasFullAccess)
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        viewModel.setTextDocumentProxy(textDocumentProxy)
        viewModel.setFullAccess(granted: hasFullAccess)
    }

    private func setupKeyboardView(in containerView: UIView) {
        let keyboardView = KeyboardView(viewModel: viewModel) { [weak self] in
            self?.advanceToNextInputMode()
        }

        let hostingController = UIHostingController(rootView: keyboardView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.tintColor = UIColor(red: 224/255, green: 120/255, blue: 86/255, alpha: 1)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        containerView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        self.hostingController = hostingController
    }

    private func updateViewHeight(totalHeight: CGFloat, for containerView: UIView) {
        heightConstraint?.isActive = false
        let constraint = containerView.heightAnchor.constraint(equalToConstant: totalHeight)
        constraint.priority = .required
        constraint.isActive = true
        heightConstraint = constraint
    }
}
