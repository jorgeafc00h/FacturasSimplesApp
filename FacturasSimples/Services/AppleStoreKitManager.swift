//
//  AppleStoreKitManager.swift
//  FacturasSimples
//
//  Created by AI Assistant
//  Handles Apple In-App Purchases using StoreKit 1
//

import Foundation
import StoreKit
import SwiftUI

class AppleStoreKitManager: NSObject, ObservableObject {
    static let shared = AppleStoreKitManager()
    
    @Published var availableProducts: [SKProduct] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseState: ApplePurchaseState = .idle
    
    // Product IDs that match our StoreKit configuration
    private let productIDs: Set<String> = [
        "com.kandangalabs.facturas.bundle25",              // Paquete Esencial
        "com.kandangalabs.facturas.bundle50",              // Paquete Inicial  
        "com.kandangalabs.facturas.bundle100",             // Paquete Profesional
        "com.kandangalabs.facturas.bundle250",             // Paquete Empresarial
        "com.kandangalabs.facturas.implementation_fee",    // Implementation Fee
        "com.kandangalabs.facturas.enterprise_pro_unlimited_monthly",  // Enterprise Pro Monthly
        "com.kandangalabs.facturas.enterprise_pro_unlimited_anual"     // Enterprise Pro Yearly
    ]
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        requestProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - StoreKit Integration
    
    func requestProducts() {
        isLoading = true
        errorMessage = nil
        
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func purchase(_ product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            errorMessage = "Las compras dentro de la app están deshabilitadas"
            return
        }
        
        purchaseState = .processing
        errorMessage = nil
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - Helper Methods
    
    /// Get a Product by its ID
    func product(for id: String) -> SKProduct? {
        return availableProducts.first { $0.productIdentifier == id }
    }
    
    /// Convert StoreKit Product to CustomPaymentProduct for unified UI
    func customPaymentProduct(from product: SKProduct) -> CustomPaymentProduct? {
        // Map StoreKit product to our custom product model
        let invoiceCount: Int
        let productType: CustomProductType
        let subscriptionPeriod: String?
        let isImplementationFee: Bool
        let specialOfferText: String?
        let name: String
        let description: String
        
        switch product.productIdentifier {
        case "com.kandangalabs.facturas.bundle25":
            invoiceCount = 25
            productType = .consumable
            subscriptionPeriod = nil
            isImplementationFee = false
            specialOfferText = nil
            name = "Paquete Esencial"
            description = "Ideal para emprendedores y pequeños negocios"
            
        case "com.kandangalabs.facturas.bundle50":
            invoiceCount = 50
            productType = .consumable
            subscriptionPeriod = nil
            isImplementationFee = false
            specialOfferText = "Popular"
            name = "Paquete Inicial"
            description = "Perfecto para pequeñas empresas"
            
        case "com.kandangalabs.facturas.bundle100":
            invoiceCount = 100
            productType = .consumable
            subscriptionPeriod = nil
            isImplementationFee = false
            specialOfferText = nil
            name = "Paquete Profesional"
            description = "La mejor opción para empresas en crecimiento"
            
        case "com.kandangalabs.facturas.bundle250":
            invoiceCount = 250
            productType = .consumable
            subscriptionPeriod = nil
            isImplementationFee = false
            specialOfferText = nil
            name = "Paquete Empresarial"
            description = "Para empresas de alto volumen"
            
        case "com.kandangalabs.facturas.implementation_fee":
            invoiceCount = 0
            productType = .consumable
            subscriptionPeriod = nil
            isImplementationFee = true
            specialOfferText = nil
            name = "Costo de Implementación"
            description = "Tarifa única para activar cuenta de producción"
            
        case "com.kandangalabs.facturas.enterprise_pro_unlimited_monthly":
            invoiceCount = -1
            productType = .subscription
            subscriptionPeriod = "monthly"
            isImplementationFee = false
            specialOfferText = "Mejor Valor"
            name = "Enterprise Pro"
            description = "Suscripción mensual con facturación ilimitada para empresas grandes"
            
        case "com.kandangalabs.facturas.enterprise_pro_unlimited_anual":
            invoiceCount = -1
            productType = .subscription
            subscriptionPeriod = "yearly"
            isImplementationFee = false
            specialOfferText = "Ahorra $200 vs plan mensual"
            name = "Enterprise Pro Anual"
            description = "Suscripción anual con facturación ilimitada para empresas grandes"
            
        default:
            return nil
        }
        
        // Format price
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let formattedPrice = formatter.string(from: product.price) ?? "$\(product.price)"
        
        return CustomPaymentProduct(
            id: product.productIdentifier,
            name: name,
            description: description,
            invoiceCount: invoiceCount,
            price: product.price.doubleValue,
            formattedPrice: formattedPrice,
            isPopular: specialOfferText == "Popular",
            productType: productType,
            isImplementationFee: isImplementationFee,
            subscriptionPeriod: subscriptionPeriod,
            specialOfferText: specialOfferText
        )
    }
}

// MARK: - SKProductsRequestDelegate

extension AppleStoreKitManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.availableProducts = response.products
            self.isLoading = false
            
            print("🛒 AppleStoreKit: Loaded \(self.availableProducts.count) products")
            
            for product in self.availableProducts {
                print("📦 Product: \(product.productIdentifier) - \(product.localizedTitle) - \(product.price)")
            }
            
            if !response.invalidProductIdentifiers.isEmpty {
                print("❌ Invalid product identifiers: \(response.invalidProductIdentifiers)")
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Error al cargar productos: \(error.localizedDescription)"
            print("❌ AppleStoreKit: Error loading products: \(error)")
        }
    }
}

// MARK: - SKPaymentTransactionObserver

extension AppleStoreKitManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchased(transaction)
            case .failed:
                handleFailed(transaction)
            case .restored:
                handleRestored(transaction)
            case .deferred:
                handleDeferred(transaction)
            case .purchasing:
                handlePurchasing(transaction)
            @unknown default:
                break
            }
        }
    }
    
    private func handlePurchased(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            self.purchaseState = .success
            print("✅ AppleStoreKit: Purchase successful for \(transaction.payment.productIdentifier)")
            
            // Add credits to user's account based on the purchased product
            self.processCreditsForPurchase(productId: transaction.payment.productIdentifier, transactionId: transaction.transactionIdentifier)
        }
        
        // Finish the transaction
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    // MARK: - Credit Processing
    
    private func processCreditsForPurchase(productId: String, transactionId: String?) {
        // Find the corresponding product to get invoice count
        guard let product = availableProducts.first(where: { $0.productIdentifier == productId }),
              let customProduct = customPaymentProduct(from: product) else {
            print("❌ AppleStoreKit: Could not find product details for \(productId)")
            return
        }
        
        // Don't add credits for subscriptions or implementation fees
        guard customProduct.productType == .consumable && !customProduct.isImplementationFee else {
            print("🔄 AppleStoreKit: No credits to add for \(customProduct.name) (subscription or implementation fee)")
            return
        }
        
        // Add credits to user's account
        let creditsToAdd = customProduct.invoiceCount
        let purchaseManager = PurchaseDataManager.shared
        
        Task { @MainActor in
            purchaseManager.addCredits(creditsToAdd, from: transactionId ?? "apple_\(productId)_\(Date().timeIntervalSince1970)")
            
            // Refresh user profile to reflect the changes
            await purchaseManager.loadUserProfile()
            
            print("💰 AppleStoreKit: Added \(creditsToAdd) credits for purchase of \(customProduct.name)")
        }
    }
    
    private func handleFailed(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            if let error = transaction.error as? SKError {
                switch error.code {
                case .paymentCancelled:
                    self.purchaseState = .cancelled
                    print("🚫 AppleStoreKit: User cancelled purchase")
                case .paymentNotAllowed:
                    self.purchaseState = .failed("Pagos no permitidos")
                    self.errorMessage = "Los pagos están deshabilitados en este dispositivo"
                default:
                    self.purchaseState = .failed(error.localizedDescription)
                    self.errorMessage = "Error en la compra: \(error.localizedDescription)"
                }
            } else {
                self.purchaseState = .failed("Error desconocido")
                self.errorMessage = "Error desconocido en la compra"
            }
            
            print("❌ AppleStoreKit: Purchase failed: \(transaction.error?.localizedDescription ?? "Unknown error")")
        }
        
        // Finish the transaction
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleRestored(_ transaction: SKPaymentTransaction) {
        print("🔄 AppleStoreKit: Transaction restored for \(transaction.payment.productIdentifier)")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleDeferred(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            self.purchaseState = .pending
            print("⏳ AppleStoreKit: Purchase deferred")
        }
    }
    
    private func handlePurchasing(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            self.purchaseState = .processing
            print("🔄 AppleStoreKit: Purchase in progress for \(transaction.payment.productIdentifier)")
        }
    }
}

// MARK: - Purchase State & Results (Apple-specific to avoid conflicts)

enum ApplePurchaseState: Equatable {
    case idle
    case processing
    case success
    case cancelled
    case pending
    case failed(String)
}

enum ApplePurchaseResult: Equatable {
    case success
    case cancelled
    case pending
    case failed(String)
}

extension ApplePurchaseResult {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}
