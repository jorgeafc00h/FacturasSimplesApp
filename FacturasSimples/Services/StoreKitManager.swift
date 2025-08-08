//
//  StoreKitManager.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/30/25.
//  App Store compliant In-App Purchase manager
//

import Foundation
import StoreKit

@MainActor
class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [SKProduct] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let productIdentifiers: Set<String> = [
        "com.facturassimples.paquete_inicial",      // 50 facturas - $9.99
        "com.facturassimples.paquete_profesional",   // 100 facturas - $15.00
        "com.facturassimples.paquete_empresarial",   // 250 facturas - $29.99
        "com.facturassimples.subscription_unlimited" // Unlimited - $99.99/month
    ]
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        loadPurchasedProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func requestProducts() async {
        isLoading = true
        errorMessage = nil
        
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    func purchase(_ product: SKProduct) async {
        guard SKPaymentQueue.canMakePayments() else {
            errorMessage = "No se pueden realizar compras en este dispositivo"
            return
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() async {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    private func loadPurchasedProducts() {
        let purchased = UserDefaults.standard.object(forKey: "PurchasedProducts") as? [String] ?? []
        purchasedProducts = Set(purchased)
    }
    
    private func savePurchasedProducts() {
        UserDefaults.standard.set(Array(purchasedProducts), forKey: "PurchasedProducts")
    }
    
    private func unlockProduct(_ productIdentifier: String) {
        purchasedProducts.insert(productIdentifier)
        savePurchasedProducts()
        
        // Update user's package quota based on purchase
        updateUserQuota(for: productIdentifier)
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: NSNotification.Name("ProductPurchased"),
            object: productIdentifier
        )
    }
    
    private func updateUserQuota(for productIdentifier: String) {
        let currentQuota = UserDefaults.standard.integer(forKey: "InvoiceQuota")
        
        switch productIdentifier {
        case "com.facturassimples.paquete_inicial":
            UserDefaults.standard.set(currentQuota + 50, forKey: "InvoiceQuota")
        case "com.facturassimples.paquete_profesional":
            UserDefaults.standard.set(currentQuota + 100, forKey: "InvoiceQuota")
        case "com.facturassimples.paquete_empresarial":
            UserDefaults.standard.set(currentQuota + 250, forKey: "InvoiceQuota")
        case "com.facturassimples.subscription_unlimited":
            UserDefaults.standard.set(-1, forKey: "InvoiceQuota") // -1 means unlimited
            UserDefaults.standard.set(Date().addingTimeInterval(30 * 24 * 60 * 60), forKey: "SubscriptionExpiry") // 30 days
        default:
            break
        }
    }
    
    private func validateReceipt() {
        // Implement server-side receipt validation here
        // This is crucial for security and preventing fraud
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            return
        }
        
        // Send receiptData to your server for validation
        // Your server should validate with Apple's servers
        // For now, we'll do basic local validation (not recommended for production)
        print("Receipt validation should be implemented server-side")
    }
}

// MARK: - SKProductsRequestDelegate
extension StoreKitManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products.sorted { product1, product2 in
                // Sort by price ascending
                product1.price.doubleValue < product2.price.doubleValue
            }
            self.isLoading = false
        }
        
        if !response.invalidProductIdentifiers.isEmpty {
            print("Invalid product identifiers: \(response.invalidProductIdentifiers)")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Error cargando productos: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}

// MARK: - SKPaymentTransactionObserver
extension StoreKitManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                // Transaction is being processed
                break
            case .purchased:
                // Transaction completed successfully
                unlockProduct(transaction.payment.productIdentifier)
                validateReceipt()
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                // Transaction failed
                if let error = transaction.error as? SKError {
                    switch error.code {
                    case .paymentCancelled:
                        errorMessage = "Compra cancelada"
                    case .paymentNotAllowed:
                        errorMessage = "Compras no permitidas en este dispositivo"
                    default:
                        errorMessage = "Error en la compra: \(error.localizedDescription)"
                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                // Transaction was restored
                unlockProduct(transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .deferred:
                // Transaction is pending (e.g., parental approval)
                errorMessage = "Compra pendiente de aprobación"
            @unknown default:
                break
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        errorMessage = "Error restaurando compras: \(error.localizedDescription)"
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if queue.transactions.isEmpty {
            errorMessage = "No hay compras para restaurar"
        }
    }
}
