//
//  CustomPaymentModels.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  Custom payment product and state models
//

import Foundation

// MARK: - Custom Payment Product Models
struct CustomPaymentProduct: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let invoiceCount: Int
    let price: Double
    let formattedPrice: String
    let isPopular: Bool
    let productType: CustomProductType
    let isImplementationFee: Bool
    let subscriptionPeriod: String?
    let specialOfferText: String?
    
    // Helper properties
    var isUnlimited: Bool {
        return invoiceCount == -1
    }
    
    var isSubscription: Bool {
        return productType == .subscription
    }
    
    var invoiceCountText: String {
        if isSubscription && isUnlimited {
            return "Facturas ilimitadas"
        } else if isUnlimited {
            return "Ilimitadas"
        } else {
            return "\(invoiceCount) facturas"
        }
    }
    
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
    
    // Static product definitions
    static let bundleBasic = CustomPaymentProduct(
        id: "facturas_bundle_basic_25",
        name: "Básico E",
        description: "Paquete básico para emprendedores",
        invoiceCount: 25,
        price: 4.99,
        formattedPrice: "$4.99",
        isPopular: false,
        productType: .consumable,
        isImplementationFee: false,
        subscriptionPeriod: nil,
        specialOfferText: nil
    )
    
    static let bundle50 = CustomPaymentProduct(
        id: "facturas_bundle_50",
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
    
    static let bundle100 = CustomPaymentProduct(
        id: "facturas_bundle_100",
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
    
    static let bundle250 = CustomPaymentProduct(
        id: "facturas_bundle_250",
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
    
    static let enterpriseProMonthly = CustomPaymentProduct(
        id: "facturas_enterprise_pro_monthly",
        name: "Enterprise Pro Unlimited",
        description: "Suscripción mensual con facturación ilimitada para empresas grandes",
        invoiceCount: -1,
        price: 99.99,
        formattedPrice: "$99.99",
        isPopular: false,
        productType: .subscription,
        isImplementationFee: false,
        subscriptionPeriod: "monthly",
        specialOfferText: nil
    )
    
    static let enterpriseProYearly = CustomPaymentProduct(
        id: "facturas_enterprise_pro_yearly",
        name: "Enterprise Pro Unlimited Anual",
        description: "Suscripción anual con facturación ilimitada para empresas grandes",
        invoiceCount: -1,
        price: 999.99,
        formattedPrice: "$999.99",
        isPopular: false,
        productType: .subscription,
        isImplementationFee: false,
        subscriptionPeriod: "yearly",
        specialOfferText: "AHORRA HASTA $200"
    )
    
    static let implementationFee = CustomPaymentProduct(
        id: "facturas_implementation_fee",
        name: "Costo de Implementación",
        description: "Tarifa única para activar cuenta de producción",
        invoiceCount: 0,
        price: 165.00,
        formattedPrice: "$165.00",
        isPopular: false,
        productType: .consumable,
        isImplementationFee: true,
        subscriptionPeriod: nil,
        specialOfferText: nil
    )
    
    static let allProducts: [CustomPaymentProduct] = [
        bundleBasic, bundle50, bundle100, bundle250, 
        enterpriseProMonthly, enterpriseProYearly, 
        implementationFee
    ]
}

enum CustomProductType: String, Codable, CaseIterable {
    case consumable
    case subscription
}

// MARK: - Purchase State
enum CustomPurchaseState: Equatable {
    case idle
    case processing
    case requiresAuthentication(String) // 3DS authentication URL
    case succeeded(String) // Order ID
    case failed(String) // Error message
}

// MARK: - Custom User Credits
struct CustomUserCredits: Codable {
    var availableInvoices: Int = 0
    var totalPurchased: Int = 0
    var hasActiveSubscription: Bool = false
    var subscriptionExpiryDate: Date?
    var subscriptionId: String?
    var transactions: [CustomStoredTransaction] = []
    var hasImplementationFeePaid: Bool = false
    
    var canCreateInvoices: Bool {
        return hasActiveSubscription || availableInvoices > 0
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
}

// MARK: - Custom Stored Transaction
struct CustomStoredTransaction: Codable, Identifiable {
    let id: String
    let productID: String
    let productName: String?
    let amount: Double
    let currency: String?
    let purchaseDate: Date
    let status: String?
    let isRestored: Bool
    let invoiceCount: Int
    let isSubscription: Bool
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case networkError(String)
    case authenticationFailed(String)
    case paymentMethodCreationFailed(String)
    case subscriptionFailed(String)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .paymentMethodCreationFailed(let message):
            return "Payment method creation failed: \(message)"
        case .subscriptionFailed(let message):
            return "Subscription failed: \(message)"
        case .invalidConfiguration:
            return "Invalid payment configuration"
        }
    }
}
