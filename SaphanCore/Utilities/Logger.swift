import Foundation
import os.log

public enum Logger {
    private static let subsystem = Constants.bundleID
    public static let shared = SharedLogger()

    public enum Category: String {
        case general
        case app
        case network
        case translation
        case voice
        case auth
        case subscription
        case settings
        case storage
        case ui
    }

    private static func logger(for category: Category) -> OSLog {
        return OSLog(subsystem: subsystem, category: category.rawValue)
    }

    public static func debug(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: logger(for: category), type: .debug, message)
    }

    public static func info(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: logger(for: category), type: .info, message)
    }

    public static func warning(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: logger(for: category), type: .default, message)
    }

    public static func error(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: logger(for: category), type: .error, message)
    }

    public static func fault(_ message: String, category: Category = .general) {
        os_log("%{public}@", log: logger(for: category), type: .fault, message)
    }

    public static func network(_ message: String) {
        info(message, category: .network)
    }

    public static func translation(_ message: String) {
        info(message, category: .translation)
    }

    public static func voice(_ message: String) {
        info(message, category: .voice)
    }

    public static func auth(_ message: String) {
        info(message, category: .auth)
    }

    public static func subscription(_ message: String) {
        info(message, category: .subscription)
    }

    public static func storage(_ message: String) {
        info(message, category: .storage)
    }

    public static func ui(_ message: String) {
        info(message, category: .ui)
    }
}

public enum LoggerLevel {
    case debug
    case info
    case warning
    case error
    case fault
}

public final class SharedLogger {
    public func log(_ message: String, category: Logger.Category = .general, level: LoggerLevel = .info) {
        switch level {
        case .debug:
            Logger.debug(message, category: category)
        case .info:
            Logger.info(message, category: category)
        case .warning:
            Logger.warning(message, category: category)
        case .error:
            Logger.error(message, category: category)
        case .fault:
            Logger.fault(message, category: category)
        }
    }

    public func debug(_ message: String, category: Logger.Category = .general) {
        Logger.debug(message, category: category)
    }

    public func info(_ message: String, category: Logger.Category = .general) {
        Logger.info(message, category: category)
    }

    public func warning(_ message: String, category: Logger.Category = .general) {
        Logger.warning(message, category: category)
    }

    public func error(_ message: String, category: Logger.Category = .general) {
        Logger.error(message, category: category)
    }

    public func fault(_ message: String, category: Logger.Category = .general) {
        Logger.fault(message, category: category)
    }
}
