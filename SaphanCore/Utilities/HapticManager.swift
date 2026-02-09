import UIKit

public enum HapticManager {
    private static let impactGenerator = UIImpactFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    public static let shared = SharedHapticManager()

    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }

    public static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    public static func light() {
        impact(.light)
    }

    public static func medium() {
        impact(.medium)
    }

    public static func heavy() {
        impact(.heavy)
    }

    public static func soft() {
        if #available(iOS 13.0, *) {
            impact(.soft)
        } else {
            impact(.light)
        }
    }

    public static func rigid() {
        if #available(iOS 13.0, *) {
            impact(.rigid)
        } else {
            impact(.heavy)
        }
    }

    public static func success() {
        notification(.success)
    }

    public static func warning() {
        notification(.warning)
    }

    public static func error() {
        notification(.error)
    }
}

public final class SharedHapticManager {
    public func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        HapticManager.impact(style)
    }

    public func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        HapticManager.notification(type)
    }

    public func selection() {
        HapticManager.selection()
    }

    public func success() {
        HapticManager.success()
    }

    public func warning() {
        HapticManager.warning()
    }

    public func error() {
        HapticManager.error()
    }
}
