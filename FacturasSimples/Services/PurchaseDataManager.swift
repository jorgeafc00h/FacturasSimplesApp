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

// MARK: - Import Purchase Models
// Ensure the purchase models are compiled and available at runtime
fileprivate let _forceLoadModels: Bool = {
    // Force evaluation of model types at load time
    let _ = PurchaseTransaction.self
    let _ = UserPurchaseProfile.self
    let _ = InvoiceConsumption.self
    let _ = SavedPaymentMethod.self
    print("🔍 PurchaseDataManager: Force-loaded model types")
    return true
}()

@MainActor
class PurchaseDataManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PurchaseDataManager()
    
    // MARK: - Properties
    @Published var userProfile: UserPurchaseProfile?
    @Published var recentTransactions: [PurchaseTransaction] = []
    @Published var savedPaymentMethods: [SavedPaymentMethod] = []
    @Published var isInitialized: Bool = false
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    private init() {
        // Defer initialization to prevent blocking app startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performInitialization()
        }
    }
    
    private func performInitialization() {
        setupModelContext()
        if modelContext != nil {
            loadUserProfile()
            isInitialized = true
            print("✅ PurchaseDataManager: Fully initialized")
        } else {
            print("❌ PurchaseDataManager: Failed to initialize - no modelContext")
            // Retry initialization after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                print("🔄 PurchaseDataManager: Retrying initialization...")
                self?.performInitialization()
            }
        }
    }
    
    // MARK: - Setup
    private func setupModelContext() {
        print("🚀 PurchaseDataManager: Setting up ModelContext...")
        
        // Use the separate purchase container to avoid CloudKit issues
        do {
            let purchaseContainer = DataModel.shared.purchaseContainer
            modelContext = ModelContext(purchaseContainer)
            modelContext?.autosaveEnabled = true
            print("✅ PurchaseDataManager: Successfully using separate purchase container")
            
            // Test the context with a simple query
            if let context = modelContext {
                do {
                    let testQuery = FetchDescriptor<UserPurchaseProfile>()
                    let _ = try context.fetch(testQuery)
                    print("✅ PurchaseDataManager: Context test query successful")
                } catch {
                    print("⚠️ PurchaseDataManager: Context test query failed: \(error)")
                }
            }
            
        } catch {
            print("❌ PurchaseDataManager: Failed to use purchase container: \(error)")
            // Create fallback in-memory container
            createInMemoryFallback()
        }
    }
    
    private func createInMemoryFallback() {
        print("🔄 PurchaseDataManager: Attempting in-memory fallback...")
        
        // First, try with a minimal schema to test if SwiftData works at all
        do {
            print("🧪 PurchaseDataManager: Testing minimal SwiftData functionality...")
            
            // Test if we can create any SwiftData container at all
            let testSchema = Schema([PurchaseTransaction.self])
            let testConfig = ModelConfiguration(
                "TestContainer",
                schema: testSchema,
                isStoredInMemoryOnly: true
            )
            let testContainer = try ModelContainer(for: PurchaseTransaction.self, configurations: testConfig)
            print("✅ PurchaseDataManager: Basic SwiftData functionality confirmed")
            
            // Now try the full schema
            let memorySchema = Schema([
                PurchaseTransaction.self,
                UserPurchaseProfile.self,
                InvoiceConsumption.self,
                SavedPaymentMethod.self
            ])
            
            print("🔨 PurchaseDataManager: Creating in-memory schema with \(memorySchema.entities.count) entities")
            
            let memoryConfiguration = ModelConfiguration(
                "PurchaseMemoryData",
                schema: memorySchema,
                isStoredInMemoryOnly: true
            )
            
            let memoryContainer = try ModelContainer(
                for: PurchaseTransaction.self, UserPurchaseProfile.self, InvoiceConsumption.self, SavedPaymentMethod.self,
                configurations: memoryConfiguration
            )
            
            modelContext = ModelContext(memoryContainer)
            modelContext?.autosaveEnabled = true
            
            print("✅ PurchaseDataManager: Created in-memory purchase container as fallback")
            
        } catch {
            print("❌ PurchaseDataManager: Failed to create even in-memory container: \(error)")
            print("❌ PurchaseDataManager: In-memory error details: \(error.localizedDescription)")
            print("❌ PurchaseDataManager: Error type: \(type(of: error))")
            
            // Check if it's a model loading issue
            if let swiftDataError = error as? any LocalizedError {
                print("❌ PurchaseDataManager: SwiftData error description: \(swiftDataError.errorDescription ?? "N/A")")
                print("❌ PurchaseDataManager: SwiftData failure reason: \(swiftDataError.failureReason ?? "N/A")")
                print("❌ PurchaseDataManager: SwiftData recovery suggestion: \(swiftDataError.recoverySuggestion ?? "N/A")")
            }
            
            // Final attempt - try to create a completely empty container just to test SwiftData
            do {
                print("🆘 PurchaseDataManager: Last resort - trying empty container...")
                let emptyContainer = try ModelContainer(for: PurchaseTransaction.self)
                print("✅ PurchaseDataManager: Empty container created - SwiftData is working")
                modelContext = ModelContext(emptyContainer)
            } catch {
                print("💀 PurchaseDataManager: Even empty container failed - SwiftData completely broken: \(error)")
                modelContext = nil
            }
        }
    }
    
    // MARK: - Data Loading
    func loadUserProfile() {
        guard let modelContext = modelContext else {
            print("❌ PurchaseDataManager: No modelContext available for loadUserProfile - initialization may still be in progress")
            return
        }
        
        do {
            let profiles = try modelContext.fetch(FetchDescriptor<UserPurchaseProfile>())
            if let profile = profiles.first {
                userProfile = profile
                print("✅ PurchaseDataManager: Loaded existing profile for company: \(profile.companyId)")
            } else {
                print("ℹ️ PurchaseDataManager: No profile found, will create when needed")
            }
        } catch {
            print("❌ PurchaseDataManager: Failed to load user profile: \(error)")
        }
    }
    
    // MARK: - Credit Operations
    
    /// Validates that user has sufficient credits before invoice sync
    func validateCreditsBeforeInvoiceSync(for companyId: String) -> Bool {
        guard isInitialized else {
            print("⚠️ PurchaseDataManager: Not yet initialized for credit validation")
            // For safety, allow the operation if we're not initialized yet
            // This prevents blocking invoice sync due to initialization issues
            return true
        }
        
        guard let profile = getCurrentOrCreateProfile() else {
            print("❌ PurchaseDataManager: Cannot validate credits - no profile")
            return false
        }
        
        let availableCredits = profile.availableInvoices ?? 0
        print("💰 PurchaseDataManager: Available credits: \(availableCredits)")
        
        if availableCredits <= 0 {
            print("❌ PurchaseDataManager: Insufficient credits for sync")
            return false
        }
        
        return true
    }
    
    /// Consumes a credit when an invoice sync is completed successfully
    func consumeCreditForCompletedInvoice(_ invoiceId: String, companyId: String) {
        guard isInitialized else {
            print("⚠️ PurchaseDataManager: Not yet initialized for credit consumption")
            return
        }
        
        guard let modelContext = modelContext else {
            print("❌ PurchaseDataManager: No modelContext for credit consumption")
            return
        }
        
        guard let profile = getCurrentOrCreateProfile() else {
            print("❌ PurchaseDataManager: Cannot consume credit - no profile")
            return
        }
        
        // Check if we already consumed credit for this invoice
        let existingConsumptions = (try? modelContext.fetch(
            FetchDescriptor<InvoiceConsumption>(
                predicate: #Predicate<InvoiceConsumption> { $0.invoiceId == invoiceId }
            )
        )) ?? []
        
        if !existingConsumptions.isEmpty {
            print("⚠️ PurchaseDataManager: Credit already consumed for invoice: \(invoiceId)")
            return
        }
        
        if (profile.availableInvoices ?? 0) > 0 {
            // Consume the credit
            let currentCredits = profile.availableInvoices ?? 0
            let totalPurchased = profile.totalPurchasedInvoices ?? 0
            
            profile.availableInvoices = currentCredits - 1
            profile.totalPurchasedInvoices = totalPurchased + 1
            
            // Record the consumption
            let consumptionId = "consumption_\(invoiceId)_\(Int(Date().timeIntervalSince1970))"
            
            // Check if consumption already exists to avoid duplicates
            if !consumptionExists(withId: consumptionId) {
                let consumption = InvoiceConsumption(
                    id: consumptionId,
                    invoiceId: invoiceId,
                    consumedDate: Date(),
                    isFromSubscription: false
                )
                
                modelContext.insert(consumption)
                print("✅ PurchaseDataManager: Added consumption record: \(consumptionId)")
            } else {
                print("ℹ️ PurchaseDataManager: Consumption \(consumptionId) already exists, skipping")
            }
            
            do {
                try modelContext.save()
                print("✅ PurchaseDataManager: Credit consumed for invoice: \(invoiceId)")
                print("💰 PurchaseDataManager: Remaining credits: \(profile.availableInvoices ?? 0)")
                
                // Update published property
                DispatchQueue.main.async {
                    self.userProfile = profile
                }
            } catch {
                print("❌ PurchaseDataManager: Failed to save credit consumption: \(error)")
            }
        } else {
            print("❌ PurchaseDataManager: No credits available to consume")
        }
    }
    
    // MARK: - Uniqueness Helpers (Manual implementation since we removed @Attribute(.unique))
    
    /// Checks if a transaction with the given ID already exists
    private func transactionExists(withId id: String) -> Bool {
        guard let modelContext = modelContext else { return false }
        
        do {
            let descriptor = FetchDescriptor<PurchaseTransaction>(
                predicate: #Predicate { transaction in
                    transaction.id == id
                }
            )
            let results = try modelContext.fetch(descriptor)
            return !results.isEmpty
        } catch {
            print("❌ PurchaseDataManager: Error checking transaction existence: \(error)")
            return false
        }
    }
    
    /// Checks if a payment method with the given ID already exists
    private func paymentMethodExists(withId id: String) -> Bool {
        guard let modelContext = modelContext else { return false }
        
        do {
            let descriptor = FetchDescriptor<SavedPaymentMethod>(
                predicate: #Predicate { paymentMethod in
                    paymentMethod.id == id
                }
            )
            let results = try modelContext.fetch(descriptor)
            return !results.isEmpty
        } catch {
            print("❌ PurchaseDataManager: Error checking payment method existence: \(error)")
            return false
        }
    }
    
    /// Checks if an invoice consumption with the given ID already exists
    private func consumptionExists(withId id: String) -> Bool {
        guard let modelContext = modelContext else { return false }
        
        do {
            let descriptor = FetchDescriptor<InvoiceConsumption>(
                predicate: #Predicate { consumption in
                    consumption.id == id
                }
            )
            let results = try modelContext.fetch(descriptor)
            return !results.isEmpty
        } catch {
            print("❌ PurchaseDataManager: Error checking consumption existence: \(error)")
            return false
        }
    }

    // MARK: - Profile Management
    
    private func getCurrentOrCreateProfile() -> UserPurchaseProfile? {
        if let existing = userProfile {
            return existing
        }
        
        return createUserProfile()
    }
    
    private func createUserProfile() -> UserPurchaseProfile? {
        guard let modelContext = modelContext else {
            print("❌ PurchaseDataManager: No modelContext for profile creation")
            return nil
        }
        
        // Use a default company ID (in a real app, this would come from the current selected company)
        let companyId = "default_company"
        
        let profile = UserPurchaseProfile(
            companyId: companyId,
            isTestAccount: false
        )
        
        modelContext.insert(profile)
        
        do {
            try modelContext.save()
            userProfile = profile
            print("✅ PurchaseDataManager: Created new user profile")
            return profile
        } catch {
            print("❌ PurchaseDataManager: Failed to create user profile: \(error)")
            return nil
        }
    }
    
    // MARK: - Credit Balance Management
    
    func addCredits(_ amount: Int, from transaction: String? = nil) {
        guard let modelContext = modelContext else {
            print("❌ PurchaseDataManager: No modelContext for adding credits")
            return
        }
        
        guard let profile = getCurrentOrCreateProfile() else {
            print("❌ PurchaseDataManager: Cannot add credits - no profile")
            return
        }
        
        profile.availableInvoices = (profile.availableInvoices ?? 0) + amount
        
        if let transactionId = transaction {
            // Check if transaction already exists to avoid duplicates
            if !transactionExists(withId: transactionId) {
                let purchaseTransaction = PurchaseTransaction(
                    id: transactionId, // Use provided transaction ID
                    productID: "credit_pack",
                    productName: "Credit Pack",
                    productDescription: "Invoice credits pack",
                    amount: Double(amount),
                    currency: "USD",
                    invoiceCount: amount,
                    status: "completed"
                )
                
                modelContext.insert(purchaseTransaction)
                print("✅ PurchaseDataManager: Added new transaction: \(transactionId)")
            } else {
                print("ℹ️ PurchaseDataManager: Transaction \(transactionId) already exists, skipping")
            }
        }
        
        do {
            try modelContext.save()
            print("✅ PurchaseDataManager: Added \(amount) credits")
            print("💰 PurchaseDataManager: New balance: \(profile.availableInvoices ?? 0)")
            
            // Update published property
            DispatchQueue.main.async {
                self.userProfile = profile
            }
        } catch {
            print("❌ PurchaseDataManager: Failed to add credits: \(error)")
        }
    }
    
    func getCreditBalance() -> Int {
        return userProfile?.availableInvoices ?? 0
    }
    
    // MARK: - Transaction History
    
    func loadRecentTransactions() {
        guard let modelContext = modelContext else {
            print("❌ PurchaseDataManager: No modelContext for loading transactions")
            return
        }
        
        guard let profile = userProfile else {
            print("ℹ️ PurchaseDataManager: No profile, skipping transaction load")
            return
        }
        
        do {
            var descriptor = FetchDescriptor<PurchaseTransaction>(
                sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
            )
            descriptor.fetchLimit = 10
            
            let transactions = try modelContext.fetch(descriptor)
            
            DispatchQueue.main.async {
                self.recentTransactions = transactions
            }
            
            print("✅ PurchaseDataManager: Loaded \(transactions.count) recent transactions")
        } catch {
            print("❌ PurchaseDataManager: Failed to load transactions: \(error)")
        }
    }
    
    // MARK: - Payment Methods
    
    func loadSavedPaymentMethods() {
        guard let modelContext = modelContext else {
            print("❌ PurchaseDataManager: No modelContext for loading payment methods")
            return
        }
        
        guard let profile = userProfile else {
            print("ℹ️ PurchaseDataManager: No profile, skipping payment methods load")
            return
        }
        
        do {
            let descriptor = FetchDescriptor<SavedPaymentMethod>()
            
            let methods = try modelContext.fetch(descriptor)
            
            DispatchQueue.main.async {
                self.savedPaymentMethods = methods
            }
            
            print("✅ PurchaseDataManager: Loaded \(methods.count) saved payment methods")
        } catch {
            print("❌ PurchaseDataManager: Failed to load payment methods: \(error)")
        }
    }
    
    func savePaymentMethod(_ method: SavedPaymentMethod) {
        guard let modelContext = modelContext else {
            print("❌ PurchaseDataManager: No modelContext for saving payment method")
            return
        }
        
        modelContext.insert(method)
        
        do {
            try modelContext.save()
            loadSavedPaymentMethods() // Refresh the list
            print("✅ PurchaseDataManager: Saved payment method")
        } catch {
            print("❌ PurchaseDataManager: Failed to save payment method: \(error)")
        }
    }
    
    // MARK: - Transaction Management (N1CO Compatibility)
    
    func addTransaction(
        productID: String, 
        productName: String, 
        productDescription: String? = nil,
        amount: Double, 
        currency: String = "USD",
        invoiceCount: Int, 
        isSubscription: Bool = false,
        n1coOrderId: String? = nil,
        authorizationCode: String? = nil,
        billingCycle: String? = nil,
        status: String = "completed"
    ) {
        guard let modelContext = modelContext else {
            print("❌ PurchaseDataManager: No modelContext for adding transaction")
            return
        }
        
        // Generate a unique transaction ID
        let transactionId = n1coOrderId ?? UUID().uuidString
        
        // Check if transaction already exists to avoid duplicates
        if transactionExists(withId: transactionId) {
            print("ℹ️ PurchaseDataManager: Transaction \(transactionId) already exists, skipping")
            return
        }
        
        let transaction = PurchaseTransaction(
            id: transactionId,
            productID: productID,
            productName: productName,
            productDescription: productDescription ?? "Transaction from N1CO",
            amount: amount,
            currency: currency,
            invoiceCount: invoiceCount,
            isSubscription: isSubscription,
            n1coOrderId: n1coOrderId,
            authorizationCode: authorizationCode,
            status: status,
            billingCycle: billingCycle
        )
        
        modelContext.insert(transaction)
        
        // If this is a completed purchase, add credits
        if status == "completed" {
            addCredits(invoiceCount)
        }
        
        do {
            try modelContext.save()
            print("✅ PurchaseDataManager: Added transaction: \(productName)")
        } catch {
            print("❌ PurchaseDataManager: Failed to add transaction: \(error)")
        }
    }
    
    func consumeInvoiceCredit(for invoiceId: String) {
        // This is an alias for the existing method with default company
        let companyId = userProfile?.companyId ?? "default_company"
        consumeCreditForCompletedInvoice(invoiceId, companyId: companyId)
    }
    
    // MARK: - Statistics (For InAppPurchaseView)
    
    func getTotalSpent() -> Double {
        return recentTransactions.reduce(0) { total, transaction in
            total + (transaction.amount ?? 0.0)
        }
    }
    
    // MARK: - Credit Availability (Legacy Compatibility)
    
    func canCreateInvoice() -> Bool {
        return getCreditBalance() > 0
    }
    
    // MARK: - Debugging
    
    func printDebugInfo() {
        print("=== PurchaseDataManager Debug Info ===")
        print("ModelContext: \(modelContext != nil ? "✅" : "❌")")
        print("UserProfile: \(userProfile != nil ? "✅" : "❌")")
        if let profile = userProfile {
            print("Credit Balance: \(profile.availableInvoices)")
            print("Total Used: \(profile.totalPurchasedInvoices)")
        }
        print("Recent Transactions: \(recentTransactions.count)")
        print("Saved Payment Methods: \(savedPaymentMethods.count)")
        print("=====================================")
    }
}
