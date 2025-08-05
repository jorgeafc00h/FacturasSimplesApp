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

// MARK: - Applied Discount Model
struct AppliedDiscount {
    let couponCode: String
    let discountPercentage: Double
    let discountedPrice: String
    let discountedPriceFormatted: String?
    let savings: String
    let savingsFormatted: String?
    let applicableProductIds: [String]
    let expirationDate: Date?
}

class AppleStoreKitManager: NSObject, ObservableObject {
    static let shared = AppleStoreKitManager()
    
    @Published var availableProducts: [SKProduct] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseState: ApplePurchaseState = .idle
    
    // Coupon and promotional offer support
    @Published var currentCouponCode: String = ""
    @Published var appliedDiscount: AppliedDiscount?
    @Published var discountValidationState: DiscountValidationState = .idle
    
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
        purchase(product, withPromotionalOffer: nil)
    }
    
    func purchase(_ product: SKProduct, withPromotionalOffer discount: SKProductDiscount?) {
        guard SKPaymentQueue.canMakePayments() else {
            errorMessage = "Las compras dentro de la app están deshabilitadas"
            return
        }
        
        purchaseState = .processing
        errorMessage = nil
        
        let payment: SKMutablePayment
        
        if let discount = discount {
            // Create payment with promotional offer
            payment = SKMutablePayment(product: product)
            payment.paymentDiscount = SKPaymentDiscount(identifier: discount.identifier ?? "", 
                                                      keyIdentifier: discount.paymentMode.rawValue.description, 
                                                      nonce: UUID(), 
                                                      signature: "", 
                                                      timestamp: NSNumber(value: Date().timeIntervalSince1970))
        } else {
            payment = SKMutablePayment(product: product)
        }
        
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - Coupon Code and Promotional Offers
    
    func validateCouponCode(_ code: String, for product: SKProduct) {
        guard !code.isEmpty else {
            discountValidationState = .idle
            currentCouponCode = ""
            appliedDiscount = nil
            return
        }
        
        discountValidationState = .validating
        currentCouponCode = code
        
        // Demo validation logic - in production, validate against your server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            if let discount = self.createDiscountForCode(code, product: product) {
                self.appliedDiscount = discount
                self.discountValidationState = .valid
            } else {
                self.appliedDiscount = nil
                self.discountValidationState = .invalid
            }
        }
    }
    
    private func createDiscountForCode(_ code: String, product: SKProduct) -> AppliedDiscount? {
        // Demo validation logic - replace with your server API call
        let validCodes: [String: Double] = [
            "DEMO10": 0.10,    // 10% off
            "SAVE20": 0.20,    // 20% off  
            "WELCOME25": 0.25, // 25% off
            "PROMO50": 0.50,   // 50% off
            "SPECIAL30": 0.30  // 30% off
        ]
        
        guard let discountPercentage = validCodes[code.uppercased()] else {
            return nil
        }
        
        let originalPrice = product.price.doubleValue
        let discountAmount = originalPrice * discountPercentage
        let discountedPrice = originalPrice - discountAmount
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        
        let discountedPriceFormatted = formatter.string(from: NSDecimalNumber(value: discountedPrice))
        let savingsFormatted = formatter.string(from: NSDecimalNumber(value: discountAmount))
        
        return AppliedDiscount(
            couponCode: code,
            discountPercentage: discountPercentage * 100, // Convert to percentage
            discountedPrice: "$\(String(format: "%.2f", discountedPrice))",
            discountedPriceFormatted: discountedPriceFormatted,
            savings: "$\(String(format: "%.2f", discountAmount))",
            savingsFormatted: savingsFormatted,
            applicableProductIds: [], // Empty means applies to all products
            expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) // 30 days from now
        )
    }
    
    func clearCouponCode() {
        currentCouponCode = ""
        appliedDiscount = nil
        discountValidationState = .idle
    }
    
    // MARK: - Helper Methods
    
    /// Get a Product by its ID
    func product(for id: String) -> SKProduct? {
        return availableProducts.first { $0.productIdentifier == id }
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
        // Find the corresponding product
        guard let product = availableProducts.first(where: { $0.productIdentifier == productId }) else {
            print("❌ AppleStoreKit: Could not find product details for \(productId)")
            return
        }
        
        // Map product ID to invoice count
        let invoiceCount: Int
        let isImplementationFee: Bool
        
        switch productId {
        case "com.kandangalabs.facturas.bundle25":
            invoiceCount = 25
            isImplementationFee = false
        case "com.kandangalabs.facturas.bundle50":
            invoiceCount = 50
            isImplementationFee = false
        case "com.kandangalabs.facturas.bundle100":
            invoiceCount = 100
            isImplementationFee = false
        case "com.kandangalabs.facturas.bundle250":
            invoiceCount = 250
            isImplementationFee = false
        case "com.kandangalabs.facturas.implementation_fee":
            invoiceCount = 0
            isImplementationFee = true
        case "com.kandangalabs.facturas.enterprise_pro_unlimited_monthly",
             "com.kandangalabs.facturas.enterprise_pro_unlimited_anual":
            // Subscriptions don't add credits
            print("🔄 AppleStoreKit: No credits to add for subscription product")
            return
        default:
            print("❌ AppleStoreKit: Unknown product ID \(productId)")
            return
        }
        
        // Don't add credits for implementation fees
        guard !isImplementationFee else {
            print("🔄 AppleStoreKit: No credits to add for implementation fee")
            return
        }
        
        // Add credits to user's account
        let creditsToAdd = invoiceCount
        let purchaseManager = PurchaseDataManager.shared
        
        Task { @MainActor in
            purchaseManager.addCredits(creditsToAdd, from: transactionId ?? "apple_\(productId)_\(Date().timeIntervalSince1970)")
            
            // Refresh user profile to reflect the changes
            await purchaseManager.loadUserProfile()
            
            print("💰 AppleStoreKit: Added \(creditsToAdd) credits for purchase of \(productId)")
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

enum DiscountValidationState: Equatable {
    case idle
    case validating
    case valid
    case invalid
    case expired
}

extension ApplePurchaseResult {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

extension AppleStoreKitManager {
    // MARK: - Discount Helpers
    
    /// Checks if the applied discount is valid for a specific product
    func isDiscountValidForProduct(_ productId: String) -> Bool {
        guard let discount = appliedDiscount else { return false }
        
        // If no specific products are defined, discount applies to all
        if discount.applicableProductIds.isEmpty {
            return true
        }
        
        return discount.applicableProductIds.contains(productId)
    }
    
    /// Gets the discounted price for a specific product
    func getDiscountedPrice(for product: SKProduct) -> String? {
        guard let discount = appliedDiscount,
              isDiscountValidForProduct(product.productIdentifier) else {
            return nil
        }
        
        return discount.discountedPriceFormatted
    }
    
    /// Gets the savings amount for a specific product
    func getSavings(for product: SKProduct) -> String? {
        guard let discount = appliedDiscount,
              isDiscountValidForProduct(product.productIdentifier) else {
            return nil
        }
        
        return discount.savingsFormatted
    }
    
    /// Clears the currently applied discount
    func clearAppliedDiscount() {
        appliedDiscount = nil
        currentCouponCode = ""
        discountValidationState = .idle
    }
}
