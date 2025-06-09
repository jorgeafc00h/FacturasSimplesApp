//
//  StoreKitManager.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//

import Foundation
import StoreKit
import SwiftUI

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
        purchaseState = .purchasing
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction: StoreKit.Transaction = try await checkVerified(verification)
                await handlePurchase(transaction: transaction, isRestored: false)
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
                    await handlePurchase(transaction: transaction, isRestored: true)
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
    
    /// Check if user has available invoice credits (including promo benefits)
    func hasAvailableCredits() -> Bool {
        return promoCodeService.hasActivePromotionalSubscription() ||
               userCredits.isSubscriptionActive || 
               promoCodeService.canCreateInvoicesWithPromo() ||
               userCredits.availableInvoices > 0
    }
    
    /// Get total available credits text (including promo benefits)
    func getTotalCreditsText() -> String {
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
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction: StoreKit.Transaction = try await self.checkVerified(result)
                    await self.handlePurchase(transaction: transaction, isRestored: false)
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
    
    private func handlePurchase(transaction: StoreKit.Transaction, isRestored: Bool) async {
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
            print("✅ Saved user credits: \(userCredits.availableInvoices) available invoices")
        } catch {
            print("❌ Failed to save user credits: \(error)")
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
