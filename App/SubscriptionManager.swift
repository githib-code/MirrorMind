import StoreKit
import Combine
import os.log

class SubscriptionManager: NSObject, ObservableObject {
    @Published var isSubscribed = false
    @Published var products: [SKProduct] = []
    @Published var isLoading = false
    @Published var subscriptionError: SubscriptionError?
    
    private let productID = "mirrormind_monthly"
    private var updates: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.you.MirrorMind", category: "subscription")
    
    enum SubscriptionError: Error, Identifiable {
        case purchaseFailed(String)
        case restoreFailed(String)
        case productsLoadFailed
        
        var id: String { localizedDescription }
        var localizedDescription: String {
            switch self {
            case .purchaseFailed(let msg): return "Purchase failed: \(msg)"
            case .restoreFailed(let msg): return "Restore failed: \(msg)"
            case .productsLoadFailed: return "Failed to load products"
            }
        }
    }
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        updates = observeTransactionUpdates()
        loadProducts()
        checkSubscriptionStatus()
    }
    
    deinit {
        updates?.cancel()
    }
    
    private func loadProducts() {
        isLoading = true
        let productIDs = Set([productID])
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func purchase(product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            subscriptionError = .purchaseFailed("Payments not allowed")
            return
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    private func checkSubscriptionStatus() {
        Task {
            await updateSubscriptionStatus()
        }
    }
    
    @MainActor
    private func updateSubscriptionStatus() async {
        var isActive = false
        
        for await verificationResult in Transaction.currentEntitlements {
            if case .verified(let transaction) = verificationResult {
                if transaction.productID == productID {
                    if let expirationDate = transaction.expirationDate,
                       expirationDate.timeIntervalSinceNow > 0 {
                        isActive = true
                    } else if transaction.expirationDate == nil {
                        // Non-expiring product
                        isActive = true
                    }
                }
            }
        }
        
        isSubscribed = isActive
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await verificationResult in Transaction.updates {
                await self?.handle(verificationResult: verificationResult)
            }
        }
    }
    
    @MainActor
    private func handle(verificationResult: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = verificationResult {
            if transaction.productID == productID {
                switch transaction.transactionState {
                case .purchased, .restored:
                    await updateSubscriptionStatus()
                    await transaction.finish()
                case .failed(let error):
                    subscriptionError = .purchaseFailed(error?.localizedDescription ?? "Unknown error")
                    await transaction.finish()
                default: break
                }
            }
        }
    }
}

extension SubscriptionManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
            self.isLoading = false
            if response.products.isEmpty {
                self.subscriptionError = .productsLoadFailed
                self.logger.error("No products available")
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.subscriptionError = .productsLoadFailed
            self.logger.error("Product request failed: \(error.localizedDescription)")
        }
    }
}

extension SubscriptionManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .restored:
                Task {
                    await updateSubscriptionStatus()
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .purchased:
                // Already handled in Transaction.updates
                break
            case .failed(let error):
                subscriptionError = .purchaseFailed(error?.localizedDescription ?? "Unknown error")
                SKPaymentQueue.default().finishTransaction(transaction)
            default: break
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        subscriptionError = .restoreFailed(error.localizedDescription)
    }
}