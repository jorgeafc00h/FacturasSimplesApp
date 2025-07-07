//
//  PurchaseDataModel.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  SwiftData models for N1CO purchase tracking with CloudKit sync
//

import Foundation
import SwiftData
import CloudKit

// MARK: - Purchase Transaction Model
@Model
class PurchaseTransaction {
    @Attribute(.unique) var id: String
    var productID: String
    var productName: String
    var productDescription: String
    var purchaseDate: Date
    var amount: Double
    var currency: String
    var invoiceCount: Int
    var isRestored: Bool
    var isSubscription: Bool
    var paymentMethodId: String?
    var n1coOrderId: String?
    var authorizationCode: String?
    var status: String // "completed", "pending", "failed", "refunded"
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \UserPurchaseProfile.transactions)
    var userProfile: UserPurchaseProfile?
    
    // Subscription-specific data
    var subscriptionPlanId: Int?
    var subscriptionEndDate: Date?
    var billingCycle: String? // "monthly", "yearly"
    
    init(
        id: String = UUID().uuidString,
        productID: String,
        productName: String,
        productDescription: String,
        purchaseDate: Date = Date(),
        amount: Double,
        currency: String = "USD",
        invoiceCount: Int,
        isRestored: Bool = false,
        isSubscription: Bool = false,
        paymentMethodId: String? = nil,
        n1coOrderId: String? = nil,
        authorizationCode: String? = nil,
        status: String = "completed"
    ) {
        self.id = id
        self.productID = productID
        self.productName = productName
        self.productDescription = productDescription
        self.purchaseDate = purchaseDate
        self.amount = amount
        self.currency = currency
        self.invoiceCount = invoiceCount
        self.isRestored = isRestored
        self.isSubscription = isSubscription
        self.paymentMethodId = paymentMethodId
        self.n1coOrderId = n1coOrderId
        self.authorizationCode = authorizationCode
        self.status = status
    }
}

// MARK: - User Purchase Profile Model
@Model
class UserPurchaseProfile {
    @Attribute(.unique) var id: String
    var companyId: String
    var createdDate: Date
    var lastUpdated: Date
    
    // Current credit state
    var availableInvoices: Int
    var totalPurchasedInvoices: Int
    var totalSpent: Double
    
    // Subscription state
    var hasActiveSubscription: Bool
    var currentSubscriptionId: String?
    var subscriptionExpiryDate: Date?
    var subscriptionProductId: String?
    
    // Implementation fee tracking
    var hasImplementationFeePaid: Bool
    var implementationFeePaidDate: Date?
    
    // Customer information (for N1CO)
    var customerName: String?
    var customerEmail: String?
    var customerPhone: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var transactions: [PurchaseTransaction] = []
    
    @Relationship(deleteRule: .cascade)
    var consumptions: [InvoiceConsumption] = []
    
    init(
        id: String = "user_profile", // Single profile per user
        companyId: String = "",
        availableInvoices: Int = 0,
        totalPurchasedInvoices: Int = 0,
        totalSpent: Double = 0.0,
        hasActiveSubscription: Bool = false,
        hasImplementationFeePaid: Bool = false
    ) {
        self.id = id
        self.companyId = companyId
        self.createdDate = Date()
        self.lastUpdated = Date()
        self.availableInvoices = availableInvoices
        self.totalPurchasedInvoices = totalPurchasedInvoices
        self.totalSpent = totalSpent
        self.hasActiveSubscription = hasActiveSubscription
        self.hasImplementationFeePaid = hasImplementationFeePaid
    }
    
    // MARK: - Computed Properties
    var canCreateInvoices: Bool {
        return isSubscriptionActive || availableInvoices > 0
    }
    
    var isSubscriptionActive: Bool {
        guard hasActiveSubscription else { return false }
        
        if let expiryDate = subscriptionExpiryDate {
            return Date() < expiryDate
        }
        
        return hasActiveSubscription
    }
    
    var creditsText: String {
        if isSubscriptionActive {
            return "Facturas ilimitadas (Suscripción activa)"
        } else if hasActiveSubscription {
            return "Suscripción expirada"
        } else {
            return "\(availableInvoices) facturas disponibles"
        }
    }
    
    // MARK: - Helper Methods
    func addTransaction(_ transaction: PurchaseTransaction) {
        transactions.append(transaction)
        transaction.userProfile = self
        
        // Update credits
        if !transaction.isSubscription && !transaction.productID.contains("implementation") {
            availableInvoices += transaction.invoiceCount
            totalPurchasedInvoices += transaction.invoiceCount
        }
        
        if transaction.productID.contains("implementation") {
            hasImplementationFeePaid = true
            implementationFeePaidDate = transaction.purchaseDate
        }
        
        if transaction.isSubscription {
            hasActiveSubscription = true
            currentSubscriptionId = transaction.n1coOrderId
            subscriptionProductId = transaction.productID
            
            // Set expiry based on billing cycle
            if let billingCycle = transaction.billingCycle {
                switch billingCycle {
                case "monthly":
                    subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: transaction.purchaseDate)
                case "yearly":
                    subscriptionExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: transaction.purchaseDate)
                default:
                    subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: transaction.purchaseDate)
                }
            }
        }
        
        totalSpent += transaction.amount
        lastUpdated = Date()
    }
    
    func consumeInvoiceCredit(invoiceId: String) {
        guard canCreateInvoices else { return }
        
        if !isSubscriptionActive {
            availableInvoices = max(0, availableInvoices - 1)
        }
        
        // Record consumption
        let consumption = InvoiceConsumption(
            invoiceId: invoiceId,
            consumedDate: Date(),
            isFromSubscription: isSubscriptionActive
        )
        consumptions.append(consumption)
        consumption.userProfile = self
        
        lastUpdated = Date()
    }
}

// MARK: - Invoice Consumption Tracking
@Model
class InvoiceConsumption {
    @Attribute(.unique) var id: String
    var invoiceId: String
    var consumedDate: Date
    var isFromSubscription: Bool
    
    // Relationship
    @Relationship(deleteRule: .nullify, inverse: \UserPurchaseProfile.consumptions)
    var userProfile: UserPurchaseProfile?
    
    init(
        id: String = UUID().uuidString,
        invoiceId: String,
        consumedDate: Date = Date(),
        isFromSubscription: Bool = false
    ) {
        self.id = id
        self.invoiceId = invoiceId
        self.consumedDate = consumedDate
        self.isFromSubscription = isFromSubscription
    }
}

// MARK: - Payment Method (for storing tokenized cards)
@Model
class SavedPaymentMethod {
    @Attribute(.unique) var id: String
    var n1coPaymentMethodId: String
    var cardLast4: String
    var cardBrand: String
    var cardholderName: String
    var expiryMonth: String
    var expiryYear: String
    var isDefault: Bool
    var createdDate: Date
    var isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        n1coPaymentMethodId: String,
        cardLast4: String,
        cardBrand: String,
        cardholderName: String,
        expiryMonth: String,
        expiryYear: String,
        isDefault: Bool = false
    ) {
        self.id = id
        self.n1coPaymentMethodId = n1coPaymentMethodId
        self.cardLast4 = cardLast4
        self.cardBrand = cardBrand
        self.cardholderName = cardholderName
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.isDefault = isDefault
        self.createdDate = Date()
        self.isActive = true
    }
    
    var displayName: String {
        return "\(cardBrand) •••• \(cardLast4)"
    }
    
    var isExpired: Bool {
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        guard let expYear = Int(expiryYear), let expMonth = Int(expiryMonth) else {
            return true
        }
        
        if expYear < currentYear {
            return true
        } else if expYear == currentYear && expMonth < currentMonth {
            return true
        }
        
        return false
    }
}
