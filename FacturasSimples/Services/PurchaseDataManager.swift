//
//  PurchaseDataManager.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  SwiftData manager for purchase tracking with CloudKit sync
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class PurchaseDataManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PurchaseDataManager()
    
    // MARK: - Properties
    @Published var userProfile: UserPurchaseProfile?
    @Published var recentTransactions: [PurchaseTransaction] = []
    @Published var savedPaymentMethods: [SavedPaymentMethod] = []
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    private init() {
        setupModelContext()
        loadUserProfile()
    }
    
    // MARK: - Setup
    private func setupModelContext() {
        // Use the existing DataModel container and add our purchase models
        do {
            let container = DataModel.shared.modelContainer
            modelContext = ModelContext(container)
        } catch {
            print("❌ Failed to setup ModelContext: \(error)")
        }
    }
    
    // MARK: - User Profile Management
    func loadUserProfile() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<UserPurchaseProfile>(
                predicate: #Predicate { $0.id == "user_profile" }
            )
            
            if let existingProfile = try context.fetch(descriptor).first {
                userProfile = existingProfile
            } else {
                // Create new profile
                let newProfile = UserPurchaseProfile()
                context.insert(newProfile)
                try context.save()
                userProfile = newProfile
            }
            
            loadRecentTransactions()
            loadSavedPaymentMethods()
            
        } catch {
            print("❌ Failed to load user profile: \(error)")
        }
    }
    
    private func loadRecentTransactions() {
        guard let context = modelContext else { return }
        
        do {
            var descriptor = FetchDescriptor<PurchaseTransaction>(
                sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
            )
            descriptor.fetchLimit = 50 // Last 50 transactions
            
            recentTransactions = try context.fetch(descriptor)
        } catch {
            print("❌ Failed to load transactions: \(error)")
        }
    }
    
    private func loadSavedPaymentMethods() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<SavedPaymentMethod>(
                predicate: #Predicate { $0.isActive == true },
                sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
            )
            
            savedPaymentMethods = try context.fetch(descriptor)
        } catch {
            print("❌ Failed to load payment methods: \(error)")
        }
    }
    
    // MARK: - Transaction Management
    func addTransaction(
        productID: String,
        productName: String,
        productDescription: String,
        amount: Double,
        invoiceCount: Int,
        isSubscription: Bool = false,
        n1coOrderId: String? = nil,
        authorizationCode: String? = nil,
        billingCycle: String? = nil
    ) {
        guard let context = modelContext,
              let profile = userProfile else { return }
        
        let transaction = PurchaseTransaction(
            productID: productID,
            productName: productName,
            productDescription: productDescription,
            amount: amount,
            invoiceCount: invoiceCount,
            isSubscription: isSubscription,
            n1coOrderId: n1coOrderId,
            authorizationCode: authorizationCode
        )
        
        if isSubscription {
            transaction.billingCycle = billingCycle
        }
        
        context.insert(transaction)
        profile.addTransaction(transaction)
        
        do {
            try context.save()
            loadRecentTransactions() // Refresh the list
            objectWillChange.send()
        } catch {
            print("❌ Failed to save transaction: \(error)")
        }
    }
    
    // MARK: - Credit Management
    func consumeInvoiceCredit(for invoiceId: String) {
        guard let context = modelContext,
              let profile = userProfile else { return }
        
        profile.consumeInvoiceCredit(invoiceId: invoiceId)
        
        do {
            try context.save()
            objectWillChange.send()
        } catch {
            print("❌ Failed to consume credit: \(error)")
        }
    }
    
    func canCreateInvoice() -> Bool {
        return userProfile?.canCreateInvoices ?? false
    }
    
    // MARK: - Payment Method Management
    func savePaymentMethod(
        n1coPaymentMethodId: String,
        cardLast4: String,
        cardBrand: String,
        cardholderName: String,
        expiryMonth: String,
        expiryYear: String,
        setAsDefault: Bool = false
    ) {
        guard let context = modelContext else { return }
        
        // If setting as default, remove default from others
        if setAsDefault {
            for method in savedPaymentMethods {
                method.isDefault = false
            }
        }
        
        let paymentMethod = SavedPaymentMethod(
            n1coPaymentMethodId: n1coPaymentMethodId,
            cardLast4: cardLast4,
            cardBrand: cardBrand,
            cardholderName: cardholderName,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            isDefault: setAsDefault || savedPaymentMethods.isEmpty
        )
        
        context.insert(paymentMethod)
        
        do {
            try context.save()
            loadSavedPaymentMethods()
        } catch {
            print("❌ Failed to save payment method: \(error)")
        }
    }
    
    func deletePaymentMethod(_ paymentMethod: SavedPaymentMethod) {
        guard let context = modelContext else { return }
        
        paymentMethod.isActive = false
        
        do {
            try context.save()
            loadSavedPaymentMethods()
        } catch {
            print("❌ Failed to delete payment method: \(error)")
        }
    }
    
    // MARK: - Subscription Management
    func updateSubscriptionStatus(isActive: Bool, expiryDate: Date? = nil) {
        guard let profile = userProfile else { return }
        
        profile.hasActiveSubscription = isActive
        profile.subscriptionExpiryDate = expiryDate
        profile.lastUpdated = Date()
        
        do {
            try modelContext?.save()
            objectWillChange.send()
        } catch {
            print("❌ Failed to update subscription: \(error)")
        }
    }
    
    // MARK: - Analytics & Reporting
    func getTotalSpent() -> Double {
        return userProfile?.totalSpent ?? 0.0
    }
    
    func getTransactionHistory(limit: Int = 100) -> [PurchaseTransaction] {
        guard let context = modelContext else { return [] }
        
        do {
            var descriptor = FetchDescriptor<PurchaseTransaction>(
                sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
            )
            descriptor.fetchLimit = limit
            
            return try context.fetch(descriptor)
        } catch {
            print("❌ Failed to get transaction history: \(error)")
            return []
        }
    }
    
    func getMonthlySpending() -> [(month: String, amount: Double)] {
        let transactions = getTransactionHistory(limit: 365) // Last year
        let grouped = Dictionary(grouping: transactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: transaction.purchaseDate)
        }
        
        return grouped.map { (month: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.month > $1.month }
    }
    
    // MARK: - Migration from UserDefaults
    func migrateFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "N1COUserCredits"),
              let oldCredits = try? JSONDecoder().decode(LegacyUserCredits.self, from: data),
              let profile = userProfile else { return }
        
        // Migrate basic data
        profile.availableInvoices = oldCredits.availableInvoices
        profile.hasActiveSubscription = oldCredits.hasActiveSubscription
        profile.subscriptionExpiryDate = oldCredits.subscriptionExpiryDate
        profile.hasImplementationFeePaid = oldCredits.hasImplementationFeePaid
        
        // Migrate transactions if any
        for oldTransaction in oldCredits.transactions {
            let transaction = PurchaseTransaction(
                id: oldTransaction.id,
                productID: oldTransaction.productID,
                productName: "Migrated Purchase",
                productDescription: "Migrated from previous version",
                purchaseDate: oldTransaction.purchaseDate,
                amount: oldTransaction.amount,
                invoiceCount: oldTransaction.invoiceCount,
                isRestored: oldTransaction.isRestored
            )
            
            profile.addTransaction(transaction)
        }
        
        do {
            try modelContext?.save()
            // Remove old UserDefaults data
            UserDefaults.standard.removeObject(forKey: "N1COUserCredits")
            print("✅ Successfully migrated purchase data to SwiftData")
        } catch {
            print("❌ Failed to migrate data: \(error)")
        }
    }
}

// MARK: - Legacy Models for Migration
private struct LegacyUserCredits: Codable {
    var availableInvoices: Int = 0
    var totalPurchased: Int = 0
    var hasActiveSubscription: Bool = false
    var subscriptionExpiryDate: Date?
    var subscriptionId: String?
    var transactions: [LegacyStoredTransaction] = []
    var hasImplementationFeePaid: Bool = false
}

private struct LegacyStoredTransaction: Codable {
    let id: String
    let productID: String
    let purchaseDate: Date
    let invoiceCount: Int
    let amount: Double
    let isRestored: Bool
}

// MARK: - Implementation Fee Management
extension PurchaseDataManager {
    func requiresImplementationFee(for company: Company) -> Bool {
        guard !company.isTestAccount else { return false }
        
        // Check if company has made any purchases (implementation fee is one-time)
        let hasAnyPurchases = !getTransactionHistory(companyId: company.id, limit: 1).isEmpty
        return !hasAnyPurchases
    }
    
    func getTransactionHistory(companyId: String? = nil, limit: Int = 100) -> [PurchaseTransaction] {
        guard let context = modelContext else { return [] }
        
        do {
            var descriptor: FetchDescriptor<PurchaseTransaction>
            
            if let companyId = companyId {
                descriptor = FetchDescriptor<PurchaseTransaction>(
                    predicate: #Predicate<PurchaseTransaction> { transaction in
                        transaction.userProfile?.companyId == companyId
                    },
                    sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
                )
            } else {
                descriptor = FetchDescriptor<PurchaseTransaction>(
                    sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
                )
            }
            
            let transactions = try context.fetch(descriptor)
            return Array(transactions.prefix(limit))
        } catch {
            print("❌ Error fetching transaction history: \(error)")
            return []
        }
    }
}
