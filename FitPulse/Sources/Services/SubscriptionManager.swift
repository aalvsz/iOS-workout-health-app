import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Published Properties
    @Published var isPremium: Bool = false
    @Published var availableProducts: [Product] = []

    // MARK: - Product IDs
    static let monthlyID = "com.fitpulse.premium.monthly"
    static let yearlyID = "com.fitpulse.premium.yearly"
    private let productIDs: Set<String> = [monthlyID, yearlyID]

    // MARK: - Plan Generation Limits
    private let freeMonthlyLimit = 3

    private init() {
        Task {
            await checkEntitlement()
            await loadProducts()
            listenForTransactions()
        }
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: productIDs)
            availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    var monthlyProduct: Product? {
        availableProducts.first { $0.id == Self.monthlyID }
    }

    var yearlyProduct: Product? {
        availableProducts.first { $0.id == Self.yearlyID }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkEntitlement()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlement()
    }

    // MARK: - Entitlement

    func checkEntitlement() async {
        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if productIDs.contains(transaction.productID) {
                    hasPremium = true
                }
            }
        }

        isPremium = hasPremium
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.checkEntitlement()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    // MARK: - Plan Generation Counter

    private var currentMonthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "planGenerationsCount_\(formatter.string(from: Date()))"
    }

    var planGenerationsThisMonth: Int {
        UserDefaults.standard.integer(forKey: currentMonthKey)
    }

    var canGeneratePlan: Bool {
        isPremium || planGenerationsThisMonth < freeMonthlyLimit
    }

    var remainingFreePlans: Int {
        max(0, freeMonthlyLimit - planGenerationsThisMonth)
    }

    func recordPlanGeneration() {
        let count = planGenerationsThisMonth + 1
        UserDefaults.standard.set(count, forKey: currentMonthKey)
    }

    // MARK: - Errors

    enum StoreError: Error, LocalizedError {
        case failedVerification

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Transaction verification failed."
            }
        }
    }
}
