//
//  PurchaseDataModel.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  SwiftData models for purchase tracking - Local only, no CloudKit
//

import Foundation
import SwiftData

// MARK: - Purchase Transaction Model
@Model
class PurchaseTransaction {
    // Made all attributes optional with default values for CloudKit compatibility
    var id: String?
    var productID: String?
    var productName: String?
    var productDescription: String?
    var purchaseDate: Date?
    var amount: Double?
    var currency: String?
    var invoiceCount: Int?
    var isRestored: Bool?
    var isSubscription: Bool?
    var paymentMethodId: String?
    var externalOrderId: String?
    var authorizationCode: String?
    var status: String? // "completed", "pending", "failed", "refunded"
    
    // Relationships - Made optional for CloudKit compatibility
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
        externalOrderId: String? = nil,
        authorizationCode: String? = nil,
        status: String = "completed",
        subscriptionPlanId: Int? = nil,
        subscriptionEndDate: Date? = nil,
        billingCycle: String? = nil
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
        self.externalOrderId = externalOrderId
        self.authorizationCode = authorizationCode
        self.status = status
        self.subscriptionPlanId = subscriptionPlanId
        self.subscriptionEndDate = subscriptionEndDate
        self.billingCycle = billingCycle
    }
}

// MARK: - User Purchase Profile Model
@Model
class UserPurchaseProfile {
    // Made all attributes optional with default values for CloudKit compatibility
    var id: String?
    var companyId: String?
    var createdDate: Date?
    var lastUpdated: Date?
    
    // Current credit state
    var availableInvoices: Int?
    var totalPurchasedInvoices: Int?
    var totalSpent: Double?
    
    // Subscription state
    var hasActiveSubscription: Bool?
    var currentSubscriptionId: String?
    var subscriptionExpiryDate: Date?
    var subscriptionProductId: String?
    
    // Implementation fee tracking
    var hasImplementationFeePaid: Bool?
    var implementationFeePaidDate: Date?
    
    // Customer information (optional)
    var customerName: String?
    var customerEmail: String?
    var customerPhone: String?
    
    // Account type tracking
    var isTestAccount: Bool?
    
    // Relationships - Made optional arrays for CloudKit compatibility
    @Relationship(deleteRule: .cascade)
    var transactions: [PurchaseTransaction]?
    
    @Relationship(deleteRule: .cascade)
    var consumptions: [InvoiceConsumption]?
    
    init(
        id: String = "user_profile", // Single profile per user
        companyId: String = "",
        availableInvoices: Int = 0,
        totalPurchasedInvoices: Int = 0,
        totalSpent: Double = 0.0,
        hasActiveSubscription: Bool = false,
        hasImplementationFeePaid: Bool = false,
        isTestAccount: Bool = false
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
        self.isTestAccount = isTestAccount
        self.transactions = []
        self.consumptions = []
    }
    
    // MARK: - Computed Properties
    var canCreateInvoices: Bool {
        return isSubscriptionActive || (availableInvoices ?? 0) > 0
    }
    
    var isSubscriptionActive: Bool {
        guard hasActiveSubscription == true else { return false }
        
        if let expiryDate = subscriptionExpiryDate {
            return Date() < expiryDate
        }
        
        return hasActiveSubscription == true
    }
    
    var creditsText: String {
        if isSubscriptionActive {
            return "Facturas ilimitadas (Suscripción activa)"
        } else if hasActiveSubscription == true {
            return "Suscripción expirada"
        } else {
            return "\(availableInvoices ?? 0) facturas disponibles"
        }
    }
    
    // MARK: - Helper Methods
    func addTransaction(_ transaction: PurchaseTransaction) {
        print("🟢 UserPurchaseProfile.addTransaction: STARTING")
        print("👤 UserPurchaseProfile: Adding transaction \(transaction.productName ?? "Unknown")")
        print("📊 UserPurchaseProfile: BEFORE - Available invoices: \(availableInvoices ?? 0)")
        print("📊 UserPurchaseProfile: BEFORE - Total purchased: \(totalPurchasedInvoices ?? 0)")
        print("📊 UserPurchaseProfile: BEFORE - Total transactions: \(transactions?.count ?? 0)")
        print("🛍️ UserPurchaseProfile: Transaction invoice count: \(transaction.invoiceCount ?? 0)")
        print("🔄 UserPurchaseProfile: Is subscription: \(transaction.isSubscription ?? false)")
        print("🏭 UserPurchaseProfile: Product ID: \(transaction.productID ?? "Unknown")")
        print("💰 UserPurchaseProfile: Transaction amount: $\(transaction.amount ?? 0.0)")
        print("📅 UserPurchaseProfile: Transaction date: \(transaction.purchaseDate ?? Date())")
        print("🆔 UserPurchaseProfile: Transaction ID: \(transaction.id ?? "Unknown")")
        
        // Initialize arrays if nil
        if transactions == nil {
            transactions = []
        }
        
        // Add to transactions array
        print("📝 UserPurchaseProfile: Appending transaction to array...")
        transactions?.append(transaction)
        transaction.userProfile = self
        print("✅ UserPurchaseProfile: Transaction added to array, new count: \(transactions?.count ?? 0)")
        
        // Determine if we should add credits
        let isSubscription = transaction.isSubscription ?? false
        let productID = transaction.productID ?? ""
        let shouldAddCredits = !isSubscription && !productID.contains("implementation")
        print("🧮 UserPurchaseProfile: Should add credits: \(shouldAddCredits)")
        
        // Update credits with detailed logging
        if shouldAddCredits {
            let creditsBeforeAdd = availableInvoices ?? 0
            let totalBeforeAdd = totalPurchasedInvoices ?? 0
            let invoiceCount = transaction.invoiceCount ?? 0
            
            print("💰 UserPurchaseProfile: ADDING CREDITS - Before: \(creditsBeforeAdd)")
            print("💰 UserPurchaseProfile: ADDING CREDITS - Adding: \(invoiceCount)")
            
            availableInvoices = creditsBeforeAdd + invoiceCount
            totalPurchasedInvoices = totalBeforeAdd + invoiceCount
            
            print("💰 UserPurchaseProfile: ADDING CREDITS - After: \(availableInvoices ?? 0)")
            print("💰 UserPurchaseProfile: ADDING CREDITS - Total purchased after: \(totalPurchasedInvoices ?? 0)")
            
            // Verify the math
            let expectedCredits = creditsBeforeAdd + invoiceCount
            let expectedTotal = totalBeforeAdd + invoiceCount
            
            if (availableInvoices ?? 0) == expectedCredits {
                print("✅ UserPurchaseProfile: CREDIT MATH VERIFIED - Credits: \(availableInvoices ?? 0) = \(creditsBeforeAdd) + \(invoiceCount)")
            } else {
                print("❌ UserPurchaseProfile: CREDIT MATH ERROR - Expected: \(expectedCredits), Got: \(availableInvoices ?? 0)")
            }
            
            if (totalPurchasedInvoices ?? 0) == expectedTotal {
                print("✅ UserPurchaseProfile: TOTAL MATH VERIFIED - Total: \(totalPurchasedInvoices ?? 0) = \(totalBeforeAdd) + \(invoiceCount)")
            } else {
                print("❌ UserPurchaseProfile: TOTAL MATH ERROR - Expected: \(expectedTotal), Got: \(totalPurchasedInvoices ?? 0)")
            }
        } else {
            print("⏭️ UserPurchaseProfile: SKIPPING CREDIT ADDITION - Reason: \(isSubscription ? "subscription" : "implementation fee")")
        }
        
        // Handle implementation fee
        if productID.contains("implementation") {
            print("🏭 UserPurchaseProfile: IMPLEMENTATION FEE - Setting as paid")
            hasImplementationFeePaid = true
            implementationFeePaidDate = transaction.purchaseDate
            print("✅ UserPurchaseProfile: IMPLEMENTATION FEE - Date set: \(implementationFeePaidDate ?? Date())")
        }
        
        // Handle subscription
        if isSubscription {
            print("🔄 UserPurchaseProfile: SUBSCRIPTION - Setting up subscription")
            hasActiveSubscription = true
            currentSubscriptionId = transaction.externalOrderId
            subscriptionProductId = transaction.productID
            print("📋 UserPurchaseProfile: SUBSCRIPTION - ID: \(currentSubscriptionId ?? "none")")
            print("🏷️ UserPurchaseProfile: SUBSCRIPTION - Product ID: \(subscriptionProductId ?? "none")")
            
            // Set expiry based on billing cycle
            if let billingCycle = transaction.billingCycle {
                print("📅 UserPurchaseProfile: SUBSCRIPTION - Billing cycle: \(billingCycle)")
                switch billingCycle {
                case "monthly":
                    subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: transaction.purchaseDate ?? Date())
                case "yearly":
                    subscriptionExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: transaction.purchaseDate ?? Date())
                default:
                    subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: transaction.purchaseDate ?? Date())
                }
                print("📅 UserPurchaseProfile: SUBSCRIPTION - Expiry date: \(subscriptionExpiryDate ?? Date())")
            } else {
                print("⚠️ UserPurchaseProfile: SUBSCRIPTION - No billing cycle provided")
            }
        }
        
        // Update total spent
        let spentBefore = totalSpent ?? 0.0
        let amountToAdd = transaction.amount ?? 0.0
        totalSpent = spentBefore + amountToAdd
        print("💵 UserPurchaseProfile: TOTAL SPENT - Before: $\(spentBefore), After: $\(totalSpent ?? 0.0)")
        
        // Update timestamp
        lastUpdated = Date()
        print("⏰ UserPurchaseProfile: TIMESTAMP - Updated: \(lastUpdated ?? Date())")
        
        print("🎉 UserPurchaseProfile.addTransaction: COMPLETED SUCCESSFULLY!")
        print("📊 UserPurchaseProfile: FINAL STATE - Available invoices: \(availableInvoices ?? 0)")
        print("📊 UserPurchaseProfile: FINAL STATE - Total purchased: \(totalPurchasedInvoices ?? 0)")
        print("📊 UserPurchaseProfile: FINAL STATE - Total transactions: \(transactions?.count ?? 0)")
        print("💰 UserPurchaseProfile: FINAL STATE - Total spent: $\(totalSpent ?? 0.0)")
        print("🔄 UserPurchaseProfile: FINAL STATE - Has subscription: \(hasActiveSubscription ?? false)")
        print("🏭 UserPurchaseProfile: FINAL STATE - Implementation paid: \(hasImplementationFeePaid ?? false)")
        print("🚀 UserPurchaseProfile.addTransaction: ENDING")
    }
    
    func consumeInvoiceCredit(invoiceId: String) {
        guard canCreateInvoices else { return }
        
        if !isSubscriptionActive {
            let current = availableInvoices ?? 0
            availableInvoices = max(0, current - 1)
        }
        
        // Initialize consumptions array if nil
        if consumptions == nil {
            consumptions = []
        }
        
        // Record consumption
        let consumption = InvoiceConsumption(
            invoiceId: invoiceId,
            consumedDate: Date(),
            isFromSubscription: isSubscriptionActive
        )
        consumptions?.append(consumption)
        consumption.userProfile = self
        
        lastUpdated = Date()
    }
}

// MARK: - Invoice Consumption Tracking
@Model
class InvoiceConsumption {
    // Made all attributes optional with default values for CloudKit compatibility
    var id: String?
    var invoiceId: String?
    var consumedDate: Date?
    var isFromSubscription: Bool?
    
    // Relationship - Made optional for CloudKit compatibility
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
    // Made all attributes optional with default values for CloudKit compatibility
    var id: String?
    var externalPaymentMethodId: String?
    var cardLast4: String?
    var cardBrand: String?
    var cardholderName: String?
    var expiryMonth: String?
    var expiryYear: String?
    var isDefault: Bool?
    var createdDate: Date?
    var isActive: Bool?
    
    init(
        id: String = UUID().uuidString,
        externalPaymentMethodId: String,
        cardLast4: String,
        cardBrand: String,
        cardholderName: String,
        expiryMonth: String,
        expiryYear: String,
        isDefault: Bool = false
    ) {
        self.id = id
        self.externalPaymentMethodId = externalPaymentMethodId
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
        let brand = cardBrand ?? "Card"
        let last4 = cardLast4 ?? "****"
        return "\(brand) •••• \(last4)"
    }
    
    var isExpired: Bool {
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        guard let expiryYearString = expiryYear,
              let expiryMonthString = expiryMonth,
              let expYear = Int(expiryYearString),
              let expMonth = Int(expiryMonthString) else {
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
