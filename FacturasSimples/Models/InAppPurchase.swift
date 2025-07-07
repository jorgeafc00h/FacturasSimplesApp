//
//  InAppPurchase.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//  Updated on 1/14/25 - Migrated from Apple StoreKit to N1CO Epay custom credit card payments
//

import Foundation

// MARK: - Purchase State (Legacy compatibility)
enum PurchaseState {
    case unknown
    case purchasing
    case purchased
    case failed
    case restored
}

// MARK: - User Purchase Credits (Legacy compatibility) 
struct UserPurchaseCredits: Codable {
    var availableInvoices: Int = 0
    var isSubscriptionActive: Bool = false
    var lastPurchaseDate: Date?
    var subscriptionExpirationDate: Date?
    
    init() {
        self.availableInvoices = 0
        self.isSubscriptionActive = false
        self.lastPurchaseDate = nil
        self.subscriptionExpirationDate = nil
    }
    
    // Helper properties for backward compatibility
    var creditsText: String {
        if isSubscriptionActive {
            return "Facturas ilimitadas (Suscripción activa)"
        } else {
            return "\(availableInvoices) facturas disponibles"
        }
    }
    
    var canCreateInvoices: Bool {
        return isSubscriptionActive || availableInvoices > 0
    }
}

// MARK: - Invoice Bundle (Legacy compatibility - now redirects to CustomPaymentProduct)
struct InvoiceBundle: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let invoiceCount: Int
    let basePrice: Decimal
    
    static let allBundles: [InvoiceBundle] = []
    static let allProductIDs: [String] = []
    
    // Convert from CustomPaymentProduct for backward compatibility
    init(from product: CustomPaymentProduct) {
        self.id = product.id
        self.name = product.name
        self.description = product.description
        self.invoiceCount = product.invoiceCount
        self.basePrice = Decimal(product.price)
    }
}

// MARK: - Stored Transaction (Legacy compatibility)
struct StoredTransaction: Identifiable, Codable {
    let id: String
    let productID: String
    let purchaseDate: Date
    let invoiceCount: Int
    let isRestored: Bool
    
    // Convert from CustomStoredTransaction for backward compatibility
    init(from transaction: CustomStoredTransaction) {
        self.id = transaction.id
        self.productID = transaction.productID
        self.purchaseDate = transaction.purchaseDate
        self.invoiceCount = transaction.invoiceCount
        self.isRestored = transaction.isRestored
    }
}
