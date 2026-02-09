import SwiftUI
import SaphanCore

struct PaywallView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SaphanTheme.authBackgroundGradient()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(SaphanPressableStyle(scale: 0.9))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [SaphanTheme.brandCoral, Color(red: 193/255, green: 162/255, blue: 139/255)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Go Pro")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)

                            Text("Unlock unlimited translation power")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 40)

                        VStack(spacing: 16) {
                            ForEach(viewModel.proFeatures) { feature in
                                ProFeatureRow(feature: feature)
                            }
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 16) {
                            Text("Choose Your Plan")
                                .font(.headline)
                                .foregroundColor(.white)

                            ForEach(viewModel.offerings) { offering in
                                OfferingCard(
                                    offering: offering,
                                    isSelected: viewModel.selectedOffering?.id == offering.id,
                                    onSelect: {
                                        viewModel.selectedOffering = offering
                                        HapticManager.selection()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        if let error = viewModel.error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }

                        VStack(spacing: 12) {
                            Button {
                                guard let offering = viewModel.selectedOffering else { return }
                                HapticManager.impact(.soft)
                                Task {
                                    await viewModel.purchase(offering: offering)
                                    if viewModel.isSubscribed {
                                        dismiss()
                                    }
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Subscribe Now")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(SaphanTheme.primaryCTA(for: .dark))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .buttonStyle(SaphanPressableStyle(scale: 0.985))
                            .disabled(viewModel.isLoading || viewModel.selectedOffering == nil)

                            Button {
                                Task {
                                    await viewModel.restore()
                                }
                            } label: {
                                Text("Restore Purchases")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(SaphanPressableStyle(scale: 0.97))
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 8) {
                            Text("Auto-renewable subscription. Cancel anytime.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Link("Privacy Policy", destination: URL(string: "https://saphan.app/privacy")!)
                                    .font(.caption)
                                    .foregroundColor(SaphanTheme.brandCoral)

                                Link("Terms of Service", destination: URL(string: "https://saphan.app/terms")!)
                                    .font(.caption)
                                    .foregroundColor(SaphanTheme.brandCoral)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .animation(SaphanMotion.quickSpring, value: viewModel.selectedOffering?.id)
    }
}

struct ProFeatureRow: View {
    let feature: ProFeature

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SaphanTheme.brandCoral, Color(red: 193/255, green: 162/255, blue: 139/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct OfferingCard: View {
    let offering: SubscriptionOffering
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(offering.title)
                                .font(.headline)
                                .foregroundColor(.white)

                            if let savings = offering.savings {
                                Text(savings)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 52/255, green: 199/255, blue: 89/255), SaphanTheme.brandCoral],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(6)
                            }
                        }

                        Text(offering.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(offering.price)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(offering.pricePerMonth + "/mo")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                if isSelected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(SaphanTheme.brandCoral)
                        Text("Selected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(SaphanTheme.brandCoral)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                isSelected
                    ? SaphanTheme.brandCoral.opacity(0.2)
                    : Color.white.opacity(0.05)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? SaphanTheme.brandCoral : Color.clear,
                        lineWidth: 2
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.985))
    }
}

#Preview {
    PaywallView()
}
