//
//  PurchaseIntegrationGuide.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  Integration guide for purchase system with invoice creation
//

import Foundation

/*
 
 🎯 PURCHASE INTEGRATION GUIDE
 ============================
 
 This guide shows how to integrate the new SwiftData purchase system with your existing invoice creation flow.
 
 ## 1. CHECK CREDITS BEFORE INVOICE CREATION
 
 ```swift
 // In your InvoiceCreationViewModel or wherever you create invoices
 
 func canCreateInvoice() -> Bool {
     return PurchaseDataManager.shared.canCreateInvoice()
 }
 
 func createInvoice() {
     // Check if user has credits
     guard canCreateInvoice() else {
         // Show purchase view
         showPurchaseView = true
         return
     }
     
     // Create invoice logic here...
     let invoice = Invoice(...)
     
     // IMPORTANT: Consume credit after successful creation
     let invoiceId = invoice.id ?? UUID().uuidString
     N1COEpayService.shared.consumeInvoiceCredit(for: invoiceId)
 }
 ```
 
 ## 2. UPDATE YOUR INVOICE CREATION VIEW
 
 ```swift
 struct InvoiceCreationView: View {
     @StateObject private var purchaseManager = PurchaseDataManager.shared
     @State private var showPurchaseView = false
     
     var body: some View {
         VStack {
             // Your invoice form here...
             
             Button("Crear Factura") {
                 createInvoice()
             }
             .disabled(!purchaseManager.canCreateInvoice())
         }
         .sheet(isPresented: $showPurchaseView) {
             InAppPurchaseView()
         }
     }
 }
 ```
 
 ## 3. SHOW CREDITS IN YOUR UI
 
 ```swift
 struct CreditsStatusView: View {
     @StateObject private var purchaseManager = PurchaseDataManager.shared
     
     var body: some View {
         HStack {
             Image(systemName: purchaseManager.userProfile?.isSubscriptionActive == true ? "crown.fill" : "doc.text.fill")
                 .foregroundColor(purchaseManager.userProfile?.isSubscriptionActive == true ? .orange : .blue)
             
             Text(purchaseManager.userProfile?.creditsText ?? "Sin créditos")
                 .font(.caption)
             
             Spacer()
             
             Button("Comprar") {
                 // Show purchase view
             }
         }
     }
 }
 ```
 
 ## 4. MIGRATION FROM OLD SYSTEM
 
 The system automatically migrates from UserDefaults to SwiftData on first launch.
 Your existing purchase data will be preserved.
 
 ## 5. CLOUDKIT SYNC
 
 Purchase data is now synced across all user devices via CloudKit:
 - ✅ Purchase history synced
 - ✅ Credit balances synced  
 - ✅ Subscription status synced
 - ✅ Consumption tracking synced
 
 ## 6. ANALYTICS & REPORTING
 
 ```swift
 // Get spending analytics
 let totalSpent = PurchaseDataManager.shared.getTotalSpent()
 let monthlyData = PurchaseDataManager.shared.getMonthlySpending()
 
 // Get transaction history
 let transactions = PurchaseDataManager.shared.getTransactionHistory(limit: 100)
 ```
 
 ## 7. SUBSCRIPTION MANAGEMENT
 
 ```swift
 // Check subscription status
 if let profile = PurchaseDataManager.shared.userProfile {
     if profile.isSubscriptionActive {
         // User has active subscription - unlimited invoices
     } else {
         // User on pay-per-invoice model
     }
 }
 ```
 
 ## 8. TESTING
 
 1. Update N1COConfiguration.swift with your credentials
 2. Set `isProduction = false` for sandbox testing
 3. Test purchase flow with test credit cards
 4. Verify credits are consumed when creating invoices
 5. Test CloudKit sync across devices
 
 */

// MARK: - Example Integration Helper
@MainActor
class InvoiceCreationHelper {
    
    static func canCreateInvoice() -> Bool {
        return PurchaseDataManager.shared.canCreateInvoice()
    }
    
    static func consumeCreditForInvoice(_ invoiceId: String) {
        N1COEpayService.shared.consumeInvoiceCredit(for: invoiceId)
    }
    
    static func getRemainingCredits() -> Int {
        return PurchaseDataManager.shared.userProfile?.availableInvoices ?? 0
    }
    
    static func hasActiveSubscription() -> Bool {
        return PurchaseDataManager.shared.userProfile?.isSubscriptionActive ?? false
    }
    
    static func getCreditsDisplayText() -> String {
        return PurchaseDataManager.shared.userProfile?.creditsText ?? "Sin créditos disponibles"
    }
}
