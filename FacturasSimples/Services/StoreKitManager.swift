//
//  StoreKitManager.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//
// COMMENTED OUT FOR APP SUBMISSION - REMOVE StoreKit DEPENDENCY
// Uncomment this entire file to re-enable in-app purchases

import Foundation
// import StoreKit // COMMENTED OUT - Remove StoreKit dependency
import SwiftUI

/*
@MainActor
@Observable
class StoreKitManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    var products: [StoreKit.Product] = []
    var purchaseState: PurchaseState = .unknown
    var userCredits = UserPurchaseCredits()
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Promo Code Integration
    var promoCodeService = PromoCodeService()
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>? = nil
    private let creditsKey = "user_invoice_credits"
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load saved credits
        loadUserCredits()
        
        // Load products
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        Task { @MainActor in
            updateListenerTask?.cancel()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load available products from the App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await StoreKit.Product.products(for: Set(InvoiceBundle.allProductIDs))
            
            // Sort products by price
            products = storeProducts.sorted { product1, product2 in
                product1.price < product2.price
            }
            
            print("✅ Loaded \(products.count) products from App Store")
            
        } catch {
            print("❌ Failed to load products: \(error)")
            errorMessage = "Error al cargar productos: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Purchase a specific product
    func purchase(_ product: StoreKit.Product) async {
        await purchase(product, for: nil)
    }
    
    /// Purchase a specific product for a specific company (needed for implementation fee)
    func purchase(_ product: StoreKit.Product, for company: Company?) async {
        purchaseState = .purchasing
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction: StoreKit.Transaction = try await checkVerified(verification)
                await handlePurchase(transaction: transaction, isRestored: false, for: company)
                purchaseState = .purchased
                
            case .userCancelled:
                purchaseState = .unknown
                
            case .pending:
                purchaseState = .deferred
                
            @unknown default:
                purchaseState = .failed(StoreError.unknownError)
            }
            
        } catch {
            print("❌ Purchase failed: \(error)")
            purchaseState = .failed(error)
            errorMessage = error.localizedDescription
        }
    }
    
    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            
            var restoredCount = 0
            
            for await result in StoreKit.Transaction.currentEntitlements {
                do {
                    let transaction: StoreKit.Transaction = try await checkVerified(result)
                    await handlePurchase(transaction: transaction, isRestored: true, for: nil)
                    restoredCount += 1
                } catch {
                    print("❌ Failed to verify restored transaction: \(error)")
                }
            }
            
            if restoredCount > 0 {
                purchaseState = .restored
                print("✅ Restored \(restoredCount) purchases")
            } else {
                errorMessage = "No se encontraron compras anteriores para restaurar"
            }
            
        } catch {
            print("❌ Restore failed: \(error)")
            errorMessage = "Error al restaurar: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Use one invoice credit (checking promo benefits first, then subscription, then paid credits)
    func useInvoiceCredit() -> Bool {
        // When IAP is disabled, don't consume credits
        if FeatureFlags.shouldProvideUnlimitedCredits {
            return true
        }
        
        // First, check if user has promotional subscription active
        if promoCodeService.hasActivePromotionalSubscription() {
            return true
        }
        
        // Second, check if user has paid subscription active
        if userCredits.isSubscriptionActive {
            return true
        }
        
        // Third, check if user has free invoices from promo codes
        if promoCodeService.usePromoInvoiceCredit() {
            return true
        }
        
        // Finally, check available purchased credits
        guard userCredits.availableInvoices > 0 else {
            return false
        }
        
        userCredits.availableInvoices -= 1
        saveUserCredits()
        return true
    }
    
    /// Use invoice credit with company awareness
    func useInvoiceCredit(for company: Company?) -> Bool {
        // When IAP is disabled, don't consume credits
        if FeatureFlags.shouldProvideUnlimitedCredits {
            return true
        }
        
        guard let company = company else {
            return useInvoiceCredit()
        }
        
        // Test accounts don't consume credits
        if company.isTestAccount {
            return true
        }
        
        // For production accounts, try company credits first, then global credits
        return company.useInvoiceCredit() || useInvoiceCredit()
    }
    
    /// Check if user has available invoice credits (including promo benefits)
    func hasAvailableCredits() -> Bool {
        // When IAP is disabled, provide unlimited credits
        if FeatureFlags.shouldProvideUnlimitedCredits {
            return true
        }
        
        return promoCodeService.hasActivePromotionalSubscription() ||
               userCredits.isSubscriptionActive || 
               promoCodeService.canCreateInvoicesWithPromo() ||
               userCredits.availableInvoices > 0
    }
    
    /// Check if user has available credits for a specific company
    func hasAvailableCredits(for company: Company?) -> Bool {
        // When IAP is disabled, provide unlimited credits
        if FeatureFlags.shouldProvideUnlimitedCredits {
            return true
        }
        
        guard let company = company else {
            return hasAvailableCredits()
        }
        
        // Test accounts always have unlimited credits
        if company.isTestAccount {
            return true
        }
        
        // Production accounts need either company credits or global credits
        return company.canCreateInvoices || hasAvailableCredits()
    }
    
    /// Get total available credits text (including promo benefits)
    func getTotalCreditsText() -> String {
        // When IAP is disabled, show unlimited credits
        if FeatureFlags.shouldProvideUnlimitedCredits {
            return "Créditos ilimitados (IAP deshabilitado)"
        }
        
        var creditSources: [String] = []
        
        if promoCodeService.hasActivePromotionalSubscription() {
            creditSources.append("Suscripción promocional (ilimitadas)")
        } else if userCredits.isSubscriptionActive {
            creditSources.append("Suscripción activa (ilimitadas)")
        }
        
        if promoCodeService.userPromoBenefits.freeInvoicesFromPromos > 0 {
            creditSources.append("\(promoCodeService.userPromoBenefits.freeInvoicesFromPromos) facturas promocionales")
        }
        
        if userCredits.availableInvoices > 0 {
            creditSources.append("\(userCredits.availableInvoices) facturas compradas")
        }
        
        return creditSources.isEmpty ? "Sin créditos disponibles" : creditSources.joined(separator: " + ")
    }
    
    /// Calculate discounted price if user has active discount promo
    func getDiscountedPrice(for product: StoreKit.Product) -> (originalPrice: Decimal, discountedPrice: Decimal?, discountPercent: Int?) {
        let originalPrice = product.price
        
        guard let discountPercent = promoCodeService.getCurrentDiscountPercentage() else {
            return (originalPrice, nil, nil)
        }
        
        let discountMultiplier = Decimal(100 - discountPercent) / 100
        let discountedPrice = originalPrice * discountMultiplier
        
        return (originalPrice, discountedPrice, discountPercent)
    }
    
    /// Check subscription status and update if needed
    func checkSubscriptionStatus() async {
        guard let subscriptionProductId = userCredits.subscriptionProductId else { return }
        
        // Check current entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction: StoreKit.Transaction = try await checkVerified(result)
                
                if transaction.productID == subscriptionProductId {
                    // Update subscription status based on current transaction
                    if let expirationDate = transaction.expirationDate {
                        userCredits.subscriptionExpiryDate = expirationDate
                        userCredits.hasActiveSubscription = Date() < expirationDate
                    } else {
                        userCredits.hasActiveSubscription = true
                    }
                    
                    saveUserCredits()
                    print("✅ Updated subscription status: active=\(userCredits.hasActiveSubscription)")
                    return
                }
            } catch {
                print("❌ Failed to verify subscription transaction: \(error)")
            }
        }
        
        // If we get here, no active subscription was found
        userCredits.hasActiveSubscription = false
        saveUserCredits()
        print("✅ No active subscription found")
    }
    
    /// Get invoice bundle by product ID
    func getInvoiceBundle(for productID: String) -> InvoiceBundle? {
        return InvoiceBundle.allBundles.first { $0.id == productID }
    }
    
    /// Get product by bundle
    func getProduct(for bundle: InvoiceBundle) -> StoreKit.Product? {
        return products.first { product in
            product.id == bundle.id
        }
    }
    
    /// Check if implementation fee needs to be paid for a production company
    func requiresImplementationFee(for company: Company?) -> Bool {
        // When IAP is disabled, no implementation fee required
        if FeatureFlags.shouldProvideUnlimitedCredits {
            return false
        }
        
        guard let company = company else { return false }
        
        // Test accounts don't need implementation fee
        if company.isTestAccount {
            return false
        }
        
        // Production accounts need implementation fee if not paid yet for this specific company
        return !company.hasImplementationFeePaid
    }
    
    /// Check if user can create invoices for production company (including implementation fee check)
    func canCreateProductionInvoice(for company: Company?) -> Bool {
        guard let company = company else { return false }
        
        // Test accounts can always create invoices
        if company.isTestAccount {
            return true
        }
        
        // Production accounts need implementation fee paid AND credits available
        return company.hasImplementationFeePaid && hasAvailableCredits(for: company)
    }

    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction: StoreKit.Transaction = try await self.checkVerified(result)
                    await self.handlePurchase(transaction: transaction, isRestored: false, for: nil)
                } catch {
                    print("❌ Transaction update failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func handlePurchase(transaction: StoreKit.Transaction, isRestored: Bool, for company: Company? = nil) async {
        guard let bundle = getInvoiceBundle(for: transaction.productID) else {
            print("❌ Unknown product ID: \(transaction.productID)")
            return
        }
        
        if bundle.isSubscription {
            // Handle subscription
            userCredits.hasActiveSubscription = true
            userCredits.subscriptionProductId = transaction.productID
            
            // For subscriptions, set expiry based on transaction expiration date
            if let expirationDate = transaction.expirationDate {
                userCredits.subscriptionExpiryDate = expirationDate
            } else {
                // If no expiration date, assume it's active for 1 month from purchase
                userCredits.subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: transaction.purchaseDate)
            }
            
            print("✅ Subscription activated: \(bundle.name) until \(userCredits.subscriptionExpiryDate?.description ?? "unknown")")
        } else if bundle.id == InvoiceBundle.implementationFee.id {
            // Handle implementation fee purchase - mark as paid for the specific company
            if let company = company {
                company.markImplementationFeePaid()
                print("✅ Implementation fee paid for company: \(company.nombre)")
            } else {
                // Fallback: mark globally if no specific company (for backward compatibility with restores)
                userCredits.hasImplementationFeePaid = true
                print("✅ Implementation fee paid globally (no specific company)")
            }
            
            // Explicitly trigger change notification for implementation fee
            Task { @MainActor in
                objectWillChange.send()
            }
        } else {
            // Handle consumable purchase
            userCredits.availableInvoices += bundle.invoiceCount
            userCredits.totalPurchased += bundle.invoiceCount
            
            print("✅ Purchase processed: +\(bundle.invoiceCount) invoices (Total: \(userCredits.availableInvoices))")
        }
        
        // Store transaction
        let purchaseTransaction = PurchaseTransaction(
            id: String(transaction.id),
            productID: transaction.productID,
            purchaseDate: transaction.purchaseDate,
            invoiceCount: bundle.invoiceCount,
            isRestored: isRestored
        )
        
        let storedTransaction = StoredTransaction(from: purchaseTransaction)
        
        // Only add if not already stored (to avoid duplicates on restore)
        if !userCredits.transactions.contains(where: { $0.id == storedTransaction.id }) {
            userCredits.transactions.append(storedTransaction)
        }
        
        saveUserCredits()
        
        // Finish the transaction
        await transaction.finish()
    }
    
    private func loadUserCredits() {
        guard let data = UserDefaults.standard.data(forKey: creditsKey),
              let credits = try? JSONDecoder().decode(UserPurchaseCredits.self, from: data) else {
            userCredits = UserPurchaseCredits()
            return
        }
        
        userCredits = credits
        print("✅ Loaded user credits: \(userCredits.availableInvoices) available invoices")
    }
    
    private func saveUserCredits() {
        do {
            let data = try JSONEncoder().encode(userCredits)
            UserDefaults.standard.set(data, forKey: creditsKey)
            
            // Force UI update by triggering a change notification
            // This ensures that any views observing this StoreKitManager will refresh
            Task { @MainActor in
                objectWillChange.send()
            }
            
            print("✅ Saved user credits: \(userCredits.availableInvoices) available invoices, Implementation Fee Paid: \(userCredits.hasImplementationFeePaid)")
        } catch {
            print("❌ Failed to save user credits: \(error)")
        }
    }
    
    /// Refresh user credits from UserDefaults and trigger UI update
    /// Call this when you need to ensure the UI shows the most current credit balance
    func refreshUserCredits() {
        loadUserCredits()
        
        // Force UI update
        Task { @MainActor in
            objectWillChange.send()
        }
    }

    // MARK: - Migration Methods
    
    /// Migrate global implementation fee payment to company-specific tracking
    /// This should be called once for existing users who paid before per-company tracking
    func migrateGlobalImplementationFeeToCompany(_ company: Company) {
        // If global implementation fee is paid but this company doesn't have it marked,
        // migrate the payment status to this company
        if userCredits.hasImplementationFeePaid && !company.hasImplementationFeePaid {
            company.markImplementationFeePaid()
            print("🔄 Migrated global implementation fee payment to company: \(company.nombre)")
        }
    }
}

// MARK: - Store Errors
enum StoreError: Error, LocalizedError {
    case failedVerification
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
*/

// TEMPORARY REPLACEMENT CLASS FOR APP SUBMISSION
// This provides basic functionality without StoreKit dependency
@MainActor
@Observable  
class StoreKitManager: NSObject, ObservableObject {
    // Minimal implementation to prevent compilation errors
    var products: [Any] = []
    var purchaseState: PurchaseState = .unknown
    var userCredits = UserPurchaseCredits()
    var isLoading = false
    var errorMessage: String?
    
    // Promo Code Integration - commented out
    // var promoCodeService = PromoCodeService()
    
    override init() {
        super.init()
        // All StoreKit functionality disabled
    }
    
    // Provide unlimited credits for all methods
    func hasAvailableCredits() -> Bool { return true }
    func hasAvailableCredits(for company: Company?) -> Bool { return true }
    func requiresImplementationFee(for company: Company?) -> Bool { return false }
    func useInvoiceCredit() -> Bool { return true }
    func useInvoiceCredit(for company: Company?) -> Bool { return true }
    func getTotalCreditsText() -> String { return "Créditos ilimitados (IAP deshabilitado)" }
    func canCreateProductionInvoice(for company: Company?) -> Bool { return true }
    func refreshUserCredits() { }
    func migrateGlobalImplementationFeeToCompany(_ company: Company) { }
    
    // Additional methods that might be called
    func loadProducts() async { }
    func purchase(_ product: Any) async { }
    func restorePurchases() async { }
}
