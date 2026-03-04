import SwiftUI
import StoreKit

struct PaywallView: View {
    let feature: PremiumFeature
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var purchaseError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Feature highlights
                    featureHighlights

                    // Product cards
                    productCards

                    // Error
                    if let error = purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Restore
                    Button(String(localized: "Restore Purchases")) {
                        Task {
                            await subscriptionManager.restorePurchases()
                            if subscriptionManager.isPremium {
                                dismiss()
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Footer
                    footerLinks
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Close")) { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow.gradient)

            Text(String(localized: "Upgrade to Premium"))
                .font(.title.bold())

            Text(feature.contextualCopy)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Features

    private var featureHighlights: some View {
        VStack(spacing: 12) {
            ForEach(PremiumFeature.allCases, id: \.self) { feat in
                HStack(spacing: 12) {
                    Image(systemName: feat.icon)
                        .font(.title3)
                        .foregroundStyle(feat == feature ? .blue : .secondary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feat.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(feat == feature ? .primary : .secondary)
                        Text(feat.subtitle)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    if feat == feature {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Product Cards

    private var productCards: some View {
        VStack(spacing: 12) {
            if let monthly = subscriptionManager.monthlyProduct {
                productCard(
                    product: monthly,
                    label: String(localized: "Monthly"),
                    badge: nil
                )
            }

            if let yearly = subscriptionManager.yearlyProduct {
                productCard(
                    product: yearly,
                    label: String(localized: "Yearly"),
                    badge: String(localized: "Save 50%")
                )
            }

            if subscriptionManager.availableProducts.isEmpty {
                Text(String(localized: "Loading subscription options..."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    private func productCard(product: Product, label: String, badge: String?) -> some View {
        Button {
            Task {
                isPurchasing = true
                purchaseError = nil
                do {
                    try await subscriptionManager.purchase(product)
                    if subscriptionManager.isPremium {
                        dismiss()
                    }
                } catch {
                    purchaseError = error.localizedDescription
                }
                isPurchasing = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(label)
                            .font(.headline)

                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }

                    Text(product.displayPrice + " / " + (label == String(localized: "Monthly") ? String(localized: "month") : String(localized: "year")))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isPurchasing {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(badge != nil ? Color.blue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(badge != nil ? Color.blue.opacity(0.3) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Link(String(localized: "Terms of Use"), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Text("|").foregroundStyle(.tertiary)
            Link(String(localized: "Privacy Policy"), destination: URL(string: "https://fitpulse.app/privacy")!)
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .padding(.bottom)
    }
}

// MARK: - Premium Feature

enum PremiumFeature: CaseIterable {
    case analytics
    case unlimitedPlans
    case recoveryInsights
    case exportReports

    var title: String {
        switch self {
        case .analytics: return String(localized: "Analytics Dashboard")
        case .unlimitedPlans: return String(localized: "Unlimited Plans")
        case .recoveryInsights: return String(localized: "Recovery Insights")
        case .exportReports: return String(localized: "Export Reports")
        }
    }

    var subtitle: String {
        switch self {
        case .analytics: return String(localized: "Workout, nutrition & weight trends")
        case .unlimitedPlans: return String(localized: "Generate unlimited workout & meal plans")
        case .recoveryInsights: return String(localized: "AI-powered recovery analysis")
        case .exportReports: return String(localized: "Export progress as PDF")
        }
    }

    var icon: String {
        switch self {
        case .analytics: return "chart.bar.xaxis.ascending"
        case .unlimitedPlans: return "infinity"
        case .recoveryInsights: return "heart.text.square"
        case .exportReports: return "square.and.arrow.up"
        }
    }

    var contextualCopy: String {
        switch self {
        case .analytics:
            return String(localized: "Unlock detailed charts and trends to track your fitness journey.")
        case .unlimitedPlans:
            return String(localized: "You've used your free plans this month. Upgrade for unlimited AI-generated plans.")
        case .recoveryInsights:
            return String(localized: "Get AI-powered recovery analysis based on your health data.")
        case .exportReports:
            return String(localized: "Export your progress reports as beautiful PDFs to share or keep.")
        }
    }
}

#Preview {
    PaywallView(feature: .analytics)
        .environmentObject(SubscriptionManager.shared)
}
