import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPro = false
    @Published var product: Product?
    @Published var isLoadingProduct = false
    @Published var productLoadFailed = false
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    @Published var trialActive = true

    private let productID = "com.quyenngo.janggi.pro"
    private var transactionListener: Task<Void, Never>?

    private let firstLaunchKey = "firstLaunchDate"
    private let trialDuration: TimeInterval = 7 * 24 * 60 * 60

    /// Days left in the 7-day free trial (0 once expired). Once it elapses,
    /// every difficulty locks behind the paywall — there is no permanently
    /// free tier.
    var trialDaysRemaining: Int {
        let defaults = UserDefaults.standard
        guard let firstLaunch = defaults.object(forKey: firstLaunchKey) as? Date else { return 7 }
        let remaining = trialDuration - Date().timeIntervalSince(firstLaunch)
        return max(0, Int(ceil(remaining / (24 * 60 * 60))))
    }

    init() {
        transactionListener = listenForTransactions()
        evaluateTrialStatus()
        Task {
            await updateEntitlementStatus()
        }
    }

    /// Reads (or sets, on first-ever launch) the trial start date and
    /// updates `trialActive`. Existing installs upgrading from a pre-trial
    /// build have no stored date yet, so this starts their 7-day clock
    /// rather than locking them out immediately.
    func evaluateTrialStatus() {
        let defaults = UserDefaults.standard
        let now = Date()
        let firstLaunch: Date
        if let stored = defaults.object(forKey: firstLaunchKey) as? Date {
            firstLaunch = stored
        } else {
            firstLaunch = now
            defaults.set(now, forKey: firstLaunchKey)
        }
        trialActive = Date().timeIntervalSince(firstLaunch) < trialDuration
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Product

    func loadProduct() async {
        isLoadingProduct = true
        productLoadFailed = false

        do {
            let products = try await withTimeout(seconds: 10) {
                try await Product.products(for: [self.productID])
            }
            product = products.first
            if product == nil {
                productLoadFailed = true
            }
        } catch {
            print("Failed to load product: \(error)")
            productLoadFailed = true
        }

        isLoadingProduct = false
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            guard let result = try await group.next() else {
                throw CancellationError()
            }
            group.cancelAll()
            return result
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else {
            purchaseError = L("purchase.error.not_available")
            return
        }

        isPurchasing = true
        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPro = true
            case .userCancelled:
                break
            case .pending:
                purchaseError = L("purchase.error.pending")
            @unknown default:
                purchaseError = L("purchase.error.unexpected")
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        isPurchasing = false
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil

        do {
            try await AppStore.sync()
        } catch {
            purchaseError = L("purchase.error.restore_failed")
            isPurchasing = false
            return
        }

        await updateEntitlementStatus()

        if !isPro {
            purchaseError = L("purchase.error.nothing_to_restore")
        }

        isPurchasing = false
    }

    // MARK: - Entitlement

    func updateEntitlementStatus() async {
        #if DEBUG
        isPro = ProcessInfo.processInfo.environment["JG_CAPTURE"] != "paywall"
        #else
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                isPro = true
                return
            }
        }
        isPro = false
        #endif
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.updateEntitlementStatus()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
