import Foundation
import SwiftUI
import StoreKit
import RevenueCat
import SaphanCore

@MainActor
final class SubscriptionViewModel: NSObject, ObservableObject {
    @Published var isSubscribed = false
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var offerings: [SubscriptionOffering] = []
    @Published var error: String?
    @Published var selectedOffering: SubscriptionOffering?

    private var currentRevenueCatUserID: String?

    override init() {
        super.init()

        Task {
            await bootstrap()
        }
    }

    func bootstrap() async {
        do {
            try configureIfNeeded(appUserID: nil)
            try await refreshCustomerInfo()
            try await refreshOfferings()
        } catch {
            Logger.shared.log(
                "RevenueCat bootstrap failed: \(error.localizedDescription)",
                category: .subscription,
                level: .error
            )
            self.error = userFacingMessage(for: error)
        }
    }

    func syncForAuthenticatedUser(_ appUserID: String?) async {
        do {
            try configureIfNeeded(appUserID: appUserID)
            try await syncRevenueCatIdentity(with: appUserID)
            try await refreshCustomerInfo()
            try await refreshOfferings()
        } catch {
            Logger.shared.log(
                "Failed syncing RevenueCat user identity: \(error.localizedDescription)",
                category: .subscription,
                level: .error
            )
            self.error = userFacingMessage(for: error)
        }
    }

    func loadOfferings() async {
        do {
            try configureIfNeeded(appUserID: currentRevenueCatUserID)
            try await refreshOfferings()
        } catch {
            Logger.shared.log(
                "Loading offerings failed: \(error.localizedDescription)",
                category: .subscription,
                level: .error
            )
            self.error = userFacingMessage(for: error)
        }
    }

    func checkSubscriptionStatus() async {
        Logger.shared.log("Checking subscription status", category: .subscription, level: .info)

        do {
            try configureIfNeeded(appUserID: currentRevenueCatUserID)
            try await refreshCustomerInfo()
        } catch {
            Logger.shared.log(
                "Failed checking subscription status: \(error.localizedDescription)",
                category: .subscription,
                level: .error
            )
            self.error = userFacingMessage(for: error)
        }
    }

    func purchase(offering: SubscriptionOffering) async {
        isLoading = true
        error = nil

        Logger.shared.log("Initiating purchase for: \(offering.title)", category: .subscription, level: .info)

        do {
            try configureIfNeeded(appUserID: currentRevenueCatUserID)

            let purchaseResult = try await Purchases.shared.purchase(package: offering.package)
            applyCustomerInfo(purchaseResult.customerInfo)
            try await refreshOfferings()

            if purchaseResult.userCancelled {
                Logger.shared.log("Purchase canceled by user", category: .subscription, level: .info)
                return
            }

            guard isSubscribed else {
                throw SubscriptionError.entitlementNotActive
            }

            Logger.shared.log("Purchase successful", category: .subscription, level: .info)
        } catch {
            if isPurchaseCancelled(error) {
                Logger.shared.log("Purchase canceled by user", category: .subscription, level: .info)
                return
            }

            Logger.shared.log("Purchase failed: \(error.localizedDescription)", category: .subscription, level: .error)
            self.error = userFacingMessage(for: error)
        }

        isLoading = false
    }

    func restore() async {
        isLoading = true
        error = nil

        Logger.shared.log("Initiating restore purchases", category: .subscription, level: .info)

        do {
            try configureIfNeeded(appUserID: currentRevenueCatUserID)

            let customerInfo = try await Purchases.shared.restorePurchases()
            applyCustomerInfo(customerInfo)

            if isSubscribed {
                Logger.shared.log("Restore successful and entitlement active", category: .subscription, level: .info)
            } else {
                Logger.shared.log("Restore completed with no active entitlement", category: .subscription, level: .info)
                error = "No active subscription was found to restore."
            }
        } catch {
            Logger.shared.log("Restore failed: \(error.localizedDescription)", category: .subscription, level: .error)
            self.error = userFacingMessage(for: error)
        }

        isLoading = false
    }

    var proFeatures: [ProFeature] {
        [
            ProFeature(
                icon: "infinity",
                title: "Unlimited Voice Minutes",
                description: "No limits on translation time"
            ),
            ProFeature(
                icon: "wand.and.stars",
                title: "All Context Modes",
                description: "Access casual, formal, and emotional modes"
            ),
            ProFeature(
                icon: "keyboard.badge.ellipsis",
                title: "All Keyboard Tones",
                description: "Professional, empathetic, and more"
            ),
            ProFeature(
                icon: "bolt.fill",
                title: "Priority Support",
                description: "Get help faster when you need it"
            ),
            ProFeature(
                icon: "sparkles",
                title: "Early Access",
                description: "Be first to try new features"
            ),
            ProFeature(
                icon: "heart.fill",
                title: "Support Development",
                description: "Help us build better translation tools"
            )
        ]
    }

    // MARK: - RevenueCat Helpers

    private func configureIfNeeded(appUserID: String?) throws {
        if Purchases.isConfigured {
            Purchases.shared.delegate = self
            return
        }

        let apiKey = Constants.RevenueCat.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let entitlementID = Constants.RevenueCat.entitlementID.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasMissingConfig =
            apiKey.isEmpty ||
            entitlementID.isEmpty ||
            apiKey.contains("YOUR_REVENUECAT_API_KEY") ||
            entitlementID.contains("YOUR_REVENUECAT_ENTITLEMENT_ID") ||
            apiKey.hasPrefix("$(") ||
            entitlementID.hasPrefix("$(")

        guard !hasMissingConfig else {
            throw SubscriptionError.missingConfiguration
        }

#if DEBUG
        Purchases.logLevel = .debug
#endif

        let configuration = Configuration
            .builder(withAPIKey: apiKey)
            .with(appUserID: appUserID)
            .build()
        let purchases = Purchases.configure(with: configuration)
        purchases.delegate = self
        currentRevenueCatUserID = appUserID

        Logger.shared.log("RevenueCat configured", category: .subscription, level: .info)
    }

    private func syncRevenueCatIdentity(with appUserID: String?) async throws {
        guard Purchases.isConfigured else { return }

        // Link purchases to signed-in users and fall back to anonymous on sign-out.
        if let appUserID, !appUserID.isEmpty {
            guard appUserID != currentRevenueCatUserID else { return }

            let loginResult = try await Purchases.shared.logIn(appUserID)
            applyCustomerInfo(loginResult.customerInfo)
            currentRevenueCatUserID = appUserID
            Logger.shared.log("RevenueCat user linked: \(appUserID)", category: .subscription, level: .info)
            return
        }

        guard currentRevenueCatUserID != nil else { return }
        do {
            let customerInfo = try await Purchases.shared.logOut()
            applyCustomerInfo(customerInfo)
            currentRevenueCatUserID = nil
            Logger.shared.log("RevenueCat switched to anonymous user", category: .subscription, level: .info)
        } catch {
            // Log-out may fail when already anonymous. Keep this non-fatal.
            currentRevenueCatUserID = nil
            Logger.shared.log("RevenueCat logOut skipped: \(error.localizedDescription)", category: .subscription, level: .debug)
        }
    }

    private func refreshOfferings() async throws {
        isRefreshing = true
        defer { isRefreshing = false }

        Logger.shared.log("Loading subscription offerings", category: .subscription, level: .info)

        let fetchedOfferings = try await Purchases.shared.offerings()
        guard let currentOffering = fetchedOfferings.current else {
            offerings = []
            selectedOffering = nil
            throw SubscriptionError.noOfferingsAvailable
        }

        let packagesForDisplay = prioritizedPackages(from: currentOffering)
        let monthlyReference = packagesForDisplay.first(where: { $0.packageType == .monthly })
        let mappedOfferings = packagesForDisplay.map {
            makeOffering(from: $0, monthlyReferencePackage: monthlyReference)
        }

        offerings = mappedOfferings
        if let currentlySelected = selectedOffering,
           let updatedSelection = mappedOfferings.first(where: { $0.id == currentlySelected.id }) {
            selectedOffering = updatedSelection
        } else {
            selectedOffering =
                mappedOfferings.first(where: { $0.duration == .yearly }) ??
                mappedOfferings.first(where: { $0.duration == .monthly }) ??
                mappedOfferings.first
        }

        Logger.shared.log("Loaded \(mappedOfferings.count) offerings from RevenueCat", category: .subscription, level: .info)
    }

    private func refreshCustomerInfo() async throws {
        let customerInfo = try await Purchases.shared.customerInfo()
        applyCustomerInfo(customerInfo)
    }

    private func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        let entitlementID = Constants.RevenueCat.entitlementID
        let activeEntitlement = customerInfo.entitlements.active[entitlementID]
        isSubscribed = activeEntitlement != nil
        PreferencesService.shared.subscriptionExpirationDate = activeEntitlement?.expirationDate

        if let expirationDate = activeEntitlement?.expirationDate {
            Logger.shared.log("Subscription active until: \(expirationDate)", category: .subscription, level: .info)
        } else {
            Logger.shared.log("No active subscription found", category: .subscription, level: .info)
        }
    }

    private func prioritizedPackages(from offering: Offering) -> [Package] {
        var preferredPackages: [Package] = []
        if let weekly = offering.weekly {
            preferredPackages.append(weekly)
        }
        if let monthly = offering.monthly {
            preferredPackages.append(monthly)
        }
        if let annual = offering.annual {
            preferredPackages.append(annual)
        }

        let packages = preferredPackages.isEmpty ? offering.availablePackages : preferredPackages
        return packages.sorted { lhs, rhs in
            packagePriority(lhs) < packagePriority(rhs)
        }
    }

    private func packagePriority(_ package: Package) -> Int {
        switch package.packageType {
        case .weekly: return 0
        case .monthly: return 1
        case .annual: return 2
        case .threeMonth: return 3
        case .sixMonth: return 4
        case .twoMonth: return 5
        case .lifetime: return 6
        case .custom: return 7
        case .unknown: return 8
        }
    }

    private func makeOffering(from package: Package, monthlyReferencePackage: Package?) -> SubscriptionOffering {
        let duration = duration(for: package)
        let pricePerMonth = package.storeProduct.localizedPricePerMonth ?? package.localizedPriceString

        let savings: String? = {
            guard let monthlyReferencePackage,
                  monthlyReferencePackage.identifier != package.identifier,
                  let referenceMonthly = monthlyPrice(for: monthlyReferencePackage),
                  let packageMonthly = monthlyPrice(for: package),
                  referenceMonthly > 0,
                  packageMonthly < referenceMonthly else {
                return nil
            }

            let savingsRatio = (referenceMonthly - packageMonthly) / referenceMonthly
            let percent = Int((savingsRatio * 100).rounded())
            return percent >= 5 ? "Save \(percent)%" : nil
        }()

        return SubscriptionOffering(
            id: package.storeProduct.productIdentifier,
            package: package,
            title: title(for: package),
            description: description(for: duration),
            price: package.localizedPriceString,
            pricePerMonth: pricePerMonth,
            duration: duration,
            savings: savings
        )
    }

    private func title(for package: Package) -> String {
        switch duration(for: package) {
        case .weekly:
            return "Weekly Pro"
        case .monthly:
            return "Monthly Pro"
        case .yearly:
            return "Yearly Pro"
        case .other:
            return package.storeProduct.localizedTitle.isEmpty ? "Pro Plan" : package.storeProduct.localizedTitle
        }
    }

    private func description(for duration: SubscriptionDuration) -> String {
        switch duration {
        case .weekly:
            return "Billed weekly"
        case .monthly:
            return "Billed monthly"
        case .yearly:
            return "Billed annually"
        case .other:
            return "Auto-renewing subscription"
        }
    }

    private func duration(for package: Package) -> SubscriptionDuration {
        switch package.packageType {
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        case .annual:
            return .yearly
        default:
            if let period = package.storeProduct.subscriptionPeriod {
                switch period.unit {
                case .day, .week:
                    return .weekly
                case .month:
                    return period.value >= 12 ? .yearly : .monthly
                case .year:
                    return .yearly
                @unknown default:
                    return .other
                }
            }
            return .other
        }
    }

    private func monthlyPrice(for package: Package) -> Double? {
        if let pricePerMonth = package.storeProduct.pricePerMonth {
            return pricePerMonth.doubleValue
        }

        if duration(for: package) == .monthly {
            return NSDecimalNumber(decimal: package.storeProduct.price).doubleValue
        }

        return nil
    }

    private func isPurchaseCancelled(_ error: Error) -> Bool {
        let nsError = error as NSError
        if let errorCode = ErrorCode(rawValue: nsError.code), errorCode == .purchaseCancelledError {
            return true
        }

        return (nsError.domain == SKErrorDomain && nsError.code == SKError.paymentCancelled.rawValue) ||
            error is CancellationError
    }

    private func userFacingMessage(for error: Error) -> String {
        let nsError = error as NSError
        if let errorCode = ErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .networkError, .offlineConnectionError:
                return "Couldn't reach the App Store. Check your connection and try again."
            case .purchaseNotAllowedError:
                return "Purchases are disabled on this device."
            case .productNotAvailableForPurchaseError:
                return "This plan is currently unavailable."
            case .paymentPendingError:
                return "Payment is pending approval."
            case .configurationError:
                return "Subscription setup is incomplete. Please contact support."
            case .purchaseCancelledError:
                return ""
            default:
                return nsError.localizedDescription
            }
        }

        return nsError.localizedDescription
    }
}

struct SubscriptionOffering: Identifiable, Equatable {
    let id: String
    let package: Package
    let title: String
    let description: String
    let price: String
    let pricePerMonth: String
    let duration: SubscriptionDuration
    let savings: String?

    static func == (lhs: SubscriptionOffering, rhs: SubscriptionOffering) -> Bool {
        lhs.id == rhs.id
    }
}

enum SubscriptionDuration {
    case weekly
    case monthly
    case yearly
    case other
}

struct ProFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

private enum SubscriptionError: LocalizedError {
    case missingConfiguration
    case noOfferingsAvailable
    case entitlementNotActive

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Subscriptions are not configured. Set SAPHAN_REVENUECAT_API_KEY and entitlement settings."
        case .noOfferingsAvailable:
            return "No subscription plans are available right now. Please try again shortly."
        case .entitlementNotActive:
            return "Purchase completed, but premium access is not active yet. Pull to refresh or restore purchases."
        }
    }
}

extension SubscriptionViewModel: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.applyCustomerInfo(customerInfo)
        }
    }
}
