import Foundation
import SwiftUI
import SaphanCore

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var isSubscribed = false
    @Published var isLoading = false
    @Published var offerings: [SubscriptionOffering] = []
    @Published var error: String?
    @Published var selectedOffering: SubscriptionOffering?

    init() {
        loadOfferings()
        checkSubscriptionStatus()
    }

    func loadOfferings() {
        Logger.shared.log("Loading subscription offerings", category: .subscription, level: .info)

        offerings = [
            SubscriptionOffering(
                id: "monthly_pro",
                title: "Monthly Pro",
                description: "Billed monthly",
                price: "$4.99",
                pricePerMonth: "$4.99",
                duration: .monthly,
                savings: nil
            ),
            SubscriptionOffering(
                id: "yearly_pro",
                title: "Yearly Pro",
                description: "Billed annually",
                price: "$49.99",
                pricePerMonth: "$4.17",
                duration: .yearly,
                savings: "Save 17%"
            )
        ]

        selectedOffering = offerings.first { $0.duration == .yearly }
    }

    func checkSubscriptionStatus() {
        Logger.shared.log("Checking subscription status", category: .subscription, level: .info)

        if let expirationDate = PreferencesService.shared.subscriptionExpirationDate {
            isSubscribed = expirationDate > Date()
            Logger.shared.log("Subscription active until: \(expirationDate)", category: .subscription, level: .info)
        } else {
            isSubscribed = false
            Logger.shared.log("No active subscription found", category: .subscription, level: .info)
        }
    }

    func purchase(offering: SubscriptionOffering) async {
        isLoading = true
        error = nil

        Logger.shared.log("Initiating purchase for: \(offering.title)", category: .subscription, level: .info)

        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)

            let expirationDate: Date
            switch offering.duration {
            case .monthly:
                expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
            case .yearly:
                expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
            }

            PreferencesService.shared.subscriptionExpirationDate = expirationDate
            isSubscribed = true

            Logger.shared.log("Purchase successful. Subscription active until: \(expirationDate)", category: .subscription, level: .info)
        } catch {
            Logger.shared.log("Purchase failed: \(error.localizedDescription)", category: .subscription, level: .error)
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func restore() async {
        isLoading = true
        error = nil

        Logger.shared.log("Initiating restore purchases", category: .subscription, level: .info)

        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)

            Logger.shared.log("No purchases to restore", category: .subscription, level: .info)
            error = "No previous purchases found"
        } catch {
            Logger.shared.log("Restore failed: \(error.localizedDescription)", category: .subscription, level: .error)
            self.error = error.localizedDescription
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
}

struct SubscriptionOffering: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let price: String
    let pricePerMonth: String
    let duration: SubscriptionDuration
    let savings: String?
}

enum SubscriptionDuration {
    case monthly
    case yearly
}

struct ProFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}
