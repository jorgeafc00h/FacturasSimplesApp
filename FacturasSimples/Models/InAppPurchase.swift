//
//  InAppPurchase.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//

import Foundation
import StoreKit

// MARK: - Invoice Bundle Product
struct InvoiceBundle: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let invoiceCount: Int
    let price: Decimal
    let formattedPrice: String
    let isPopular: Bool
    
    // Product identifiers - these should match your App Store Connect configuration
    static let bundle50 = InvoiceBundle(
        id: "com.kandangalabs.facturas.bundle50",
        name: "Starter Bundle",
        description: "Perfect for small businesses",
        invoiceCount: 50,
        price: 9.99,
        formattedPrice: "$9.99",
        isPopular: false
    )
    
    static let bundle100 = InvoiceBundle(
        id: "com.kandangalabs.facturas.bundle100",
        name: "Professional Bundle",
        description: "Best value for growing businesses",
        invoiceCount: 100,
        price: 15.00,
        formattedPrice: "$15.00",
        isPopular: true
    )
    
    static let bundle250 = InvoiceBundle(
        id: "com.kandangalabs.facturas.bundle250",
        name: "Enterprise Bundle",
        description: "For high-volume businesses",
        invoiceCount: 250,
        price: 29.99,
        formattedPrice: "$29.99",
        isPopular: false
    )
    
    static let allBundles: [InvoiceBundle] = [bundle50, bundle100, bundle250]
    static let allProductIDs: Set<String> = Set(allBundles.map { $0.id })
}

// MARK: - Purchase State
enum PurchaseState {
    case unknown
    case purchasing
    case purchased
    case failed(Error)
    case restored
    case deferred
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
    var transactions: [StoredTransaction]
    
    init() {
        self.availableInvoices = 0
        self.totalPurchased = 0
        self.transactions = []
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
