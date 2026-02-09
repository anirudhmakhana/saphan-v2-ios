import Foundation

public enum Constants {
    public static let appGroupID = "group.com.krsnalabs.saphan"
    public static let bundleID = "com.krsnalabs.saphan"
    public static let keyboardBundleID = "com.krsnalabs.saphan.keyboard"

    // Backend URLs
    public enum Backend {
        public static let baseURL: String = {
            #if DEBUG
            // Optional Xcode scheme override for local/staging testing.
            // Example: SAPHAN_API_BASE_URL=http://192.168.1.175:3000
            if let override = ProcessInfo.processInfo.environment["SAPHAN_API_BASE_URL"],
               !override.isEmpty {
                return override
            }
            #endif

            return "https://saphan-backend-production.up.railway.app"
        }()
    }

    // Supabase configuration
    public enum Supabase {
        public static let url = "YOUR_SUPABASE_URL"
        public static let anonKey = "YOUR_SUPABASE_ANON_KEY"
    }

    // RevenueCat configuration
    public enum RevenueCat {
        public static let apiKey = "YOUR_REVENUECAT_API_KEY"
        public static let entitlementID = "plus"
    }

    // Voice-specific constants
    public enum Voice {
        // Keep aligned with backend ephemeral token model.
        public static let realtimeModel = "gpt-realtime"
        public static let sampleRate: Double = 24000
        // WebRTC SDP handshake endpoint.
        public static let openAIRealtimeURL = "https://api.openai.com/v1/realtime/calls"
        public static let stunServers = ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302"]
    }

    // Usage limits
    public enum Limits {
        public static let freeMonthlyTranslations = 100
        public static let freeMonthlyVoiceMinutes = 5
        public static let proMonthlyVoiceMinutes = 60
        public static let maxCachedTranslations = 1000
        public static let maxConversationHistory = 50
    }

    // UI constants
    public enum UI {
        public static let topBarHeight: CGFloat = 44
        public static let previewBarCollapsedHeight: CGFloat = 60
        public static let previewBarExpandedHeight: CGFloat = 120
        public static let actionBarHeight: CGFloat = 44
        public static let keyboardHeight: CGFloat = 221
        public static let animationDuration: Double = 0.3
        public static let debounceDelay: TimeInterval = 0.5
        public static let minimumTapArea: CGFloat = 44
        public static let cornerRadius: CGFloat = 12
        public static let standardSpacing: CGFloat = 16
        public static let compactSpacing: CGFloat = 8
    }

    // API constants
    public enum API {
        public static let timeout: TimeInterval = 30
        public static let maxRetries = 3
        public static let retryDelay: TimeInterval = 1
    }

    // Subscription tiers
    public enum Subscription {
        public static let freeTier = "free"
        public static let plusTier = "plus"
        public static let productIDs = ["saphan_plus_monthly", "saphan_plus_yearly"]
    }

    // Privacy
    public enum Privacy {
        public static let dataRetentionDays = 30
        public static let enableAnalytics = false
        public static let enableCrashReporting = false
    }
}
