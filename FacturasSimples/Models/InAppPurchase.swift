//
//  InAppPurchase.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//

import Foundation
import StoreKit

// MARK: - Product Types
enum ProductType {
    case consumable
    case subscription
}

// MARK: - Invoice Bundle Product
struct InvoiceBundle: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let invoiceCount: Int
    let price: Decimal
    let formattedPrice: String
    let isPopular: Bool
    let productType: ProductType
    let isImplementationFee: Bool 
    let subscriptionPeriod: String? // For subscriptions: "monthly", "yearly", etc.
    let specialOfferText: String? // For special discount offers like "AHORRA $200"
     
    
    // Helper property to check if this is an unlimited bundle
    var isUnlimited: Bool {
        return invoiceCount == -1
    }
    
    // Helper property to check if this is a subscription
    var isSubscription: Bool {
        return productType == .subscription
    }
    
    // Display text for invoice count
    var invoiceCountText: String {
        if isSubscription && isUnlimited {
            return "Facturas ilimitadas"
        } else if isUnlimited {
            return "Ilimitadas"
        } else {
            return "\(invoiceCount) facturas"
        }
    }
    
    // Display text for subscription period
    var subscriptionText: String {
        guard let period = subscriptionPeriod else { return "" }
        switch period {
        case "monthly":
            return "/mes"
        case "yearly":
            return "/año"
        default:
            return ""
        }
    }
    
    // Product identifiers - these should match your App Store Connect configuration
    static let bundle50 = InvoiceBundle(
        id: "com.kandangalabs.facturas.bundle50",
        name: "Paquete Inicial",
        description: "Perfecto para pequeñas empresas",
        invoiceCount: 50,
        price: 9.99,
        formattedPrice: "$9.99",
        isPopular: false,
        productType: .consumable,
        isImplementationFee: false,
        subscriptionPeriod: nil,
        specialOfferText: nil
    )
    
    static let bundle100 = InvoiceBundle(
        id: "com.kandangalabs.facturas.bundle100",
        name: "Paquete Profesional",
        description: "La mejor opción para empresas en crecimiento",
        invoiceCount: 100,
        price: 15.00,
        formattedPrice: "$15.00",
        isPopular: true,
        productType: .consumable,
        isImplementationFee: false,
        subscriptionPeriod: nil,
        specialOfferText: nil
    )
    
    static let bundle250 = InvoiceBundle(
        id: "com.kandangalabs.facturas.bundle250",
        name: "Paquete Empresarial",
        description: "Para empresas de alto volumen",
        invoiceCount: 250,
        price: 29.99,
        formattedPrice: "$29.99",
        isPopular: false,
        productType: .consumable,
        isImplementationFee: false,
        subscriptionPeriod: nil,
        specialOfferText: nil
    )
    
    static let enterpriseProUnlimited = InvoiceBundle(
        id: "com.kandangalabs.facturas.enterprise_pro_unlimited_monthly",
        name: "Enterprise Pro Unlimited",
        description: "Suscripción mensual con facturación ilimitada para empresas grandes",
        invoiceCount: -1, // -1 indicates unlimited
        price: 99.99,
        formattedPrice: "$99.99",
        isPopular: false,
        productType: .subscription,
        isImplementationFee: false,
        subscriptionPeriod: "monthly",
        specialOfferText: nil
    )

    static let enterpriseProAnual = InvoiceBundle(
        id: "com.kandangalabs.facturas.enterprise_pro_unlimited_anual",
        name: "Enterprise Pro Unlimited Anual",
        description: "Suscripción anual con facturación ilimitada para empresas grandes",
        invoiceCount: -1, // -1 indicates unlimited
        price: 999.99,
        formattedPrice: "$999.99",
        isPopular: false,
        productType: .subscription,
        isImplementationFee: false,
        subscriptionPeriod: "yearly",
        specialOfferText: "AHORRA HASTA $200"
    )
    
    static let implementationFee = InvoiceBundle(
        id: "com.kandangalabs.facturas.implementation_fee",
        name: "Costo de Implementación",
        description: "Tarifa única para activar cuenta de producción",
        invoiceCount: 0, // Special case: doesn't add invoice credits
        price: 250.00,
        formattedPrice: "$250.00",
        isPopular: false,
        productType: .consumable,
        isImplementationFee: true,
        subscriptionPeriod: nil,
        specialOfferText: nil
    )
    
    static let allBundles: [InvoiceBundle] = [bundle50, bundle100, bundle250, enterpriseProUnlimited, enterpriseProAnual,implementationFee]
    static let allProductIDs: Set<String> = Set(allBundles.map { $0.id })
}

// MARK: - Purchase State
enum PurchaseState: Equatable {
    case unknown
    case purchasing
    case purchased
    case failed(Error)
    case restored
    case deferred
    
    static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
             (.purchasing, .purchasing),
             (.purchased, .purchased),
             (.restored, .restored),
             (.deferred, .deferred):
            return true
        case (.failed, .failed):
            return true // Consider all failed states as equal for UI purposes
        default:
            return false
        }
    }
}

// MARK: - Purchase Transaction
struct PurchaseTransaction {
    let id: String
    let productID: String
    let purchaseDate: Date
    let invoiceCount: Int
    let isRestored: Bool
}

// MARK: - User Purchase Credits
struct UserPurchaseCredits: Codable {
    var availableInvoices: Int
    var totalPurchased: Int
    var hasActiveSubscription: Bool
    var subscriptionExpiryDate: Date?
    var subscriptionProductId: String?
    var transactions: [StoredTransaction]
    var hasImplementationFeePaid: Bool
    
    init() {
        self.availableInvoices = 0
        self.totalPurchased = 0
        self.hasActiveSubscription = false
        self.subscriptionExpiryDate = nil
        self.subscriptionProductId = nil
        self.transactions = []
        self.hasImplementationFeePaid = false
    }
    
    // Helper to check if user can create invoices
    var canCreateInvoices: Bool {
        return hasActiveSubscription || availableInvoices > 0
    }
    
    // Helper to check if subscription is still active
    var isSubscriptionActive: Bool {
        guard hasActiveSubscription else { return false }
        
        if let expiryDate = subscriptionExpiryDate {
            return Date() < expiryDate
        }
        
        return hasActiveSubscription
    }
    
    // Helper to get remaining credits text
    var creditsText: String {
        if isSubscriptionActive {
            return "Facturas ilimitadas (Suscripción activa)"
        } else if hasActiveSubscription {
            return "Suscripción expirada"
        } else {
            return "\(availableInvoices) facturas disponibles"
        }
    }
    
    // Helper to get subscription status text
    var subscriptionStatusText: String {
        guard hasActiveSubscription else { return "Sin suscripción" }
        
        if let expiryDate = subscriptionExpiryDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            if isSubscriptionActive {
                return "Activa hasta \(formatter.string(from: expiryDate))"
            } else {
                return "Expiró el \(formatter.string(from: expiryDate))"
            }
        }
        
        return "Activa"
    }
}

// MARK: - Stored Transaction
struct StoredTransaction: Codable, Identifiable {
    let id: String
    let productID: String
    let purchaseDate: Date
    let invoiceCount: Int
    let isRestored: Bool
    
    init(from transaction: PurchaseTransaction) {
        self.id = transaction.id
        self.productID = transaction.productID
        self.purchaseDate = transaction.purchaseDate
        self.invoiceCount = transaction.invoiceCount
        self.isRestored = transaction.isRestored
    }
}
