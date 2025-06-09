//
//  PromoCode.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/9/25.
//

import Foundation

// MARK: - Promo Code Types
enum PromoCodeType: String, Codable, CaseIterable {
    case freeAccess = "free_access"
    case discount = "discount"
    case freeSubscription = "free_subscription"
    
    var displayName: String {
        switch self {
        case .freeAccess:
            return "Acceso Gratuito"
        case .discount:
            return "Descuento"
        case .freeSubscription:
            return "Suscripción Gratuita"
        }
    }
}

// MARK: - Promo Code Status
enum PromoCodeStatus: String, Codable {
    case active = "active"
    case expired = "expired"
    case used = "used"
    case invalid = "invalid"
}

// MARK: - Promo Code Model
struct PromoCode: Codable, Identifiable {
    let id: String
    let code: String
    let type: PromoCodeType
    let description: String
    let discountPercent: Int? // For discount type (0-100)
    let freeInvoiceCount: Int? // For free access type
    let freeDurationDays: Int? // For free subscription type
    let validFrom: Date
    let validUntil: Date
    let maxUses: Int?
    let currentUses: Int
    let isActive: Bool
    
    // Helper computed properties
    var isValid: Bool {
        let now = Date()
        return isActive && now >= validFrom && now <= validUntil && 
               (maxUses == nil || currentUses < maxUses!)
    }
    
    var status: PromoCodeStatus {
        let now = Date()
        
        if !isActive {
            return .invalid
        }
        
        if now > validUntil {
            return .expired
        }
        
        if let maxUses = maxUses, currentUses >= maxUses {
            return .used
        }
        
        return .active
    }
    
    var displayText: String {
        switch type {
        case .freeAccess:
            if let count = freeInvoiceCount {
                return "\(count) facturas gratis"
            }
            return "Acceso gratuito"
            
        case .discount:
            if let percent = discountPercent {
                return "\(percent)% de descuento"
            }
            return "Descuento especial"
            
        case .freeSubscription:
            if let days = freeDurationDays {
                return "\(days) días de suscripción gratis"
            }
            return "Suscripción gratuita"
        }
    }
}

// MARK: - Applied Promo Code
struct AppliedPromoCode: Codable {
    let promoCode: PromoCode
    let appliedDate: Date
    let expiryDate: Date?
    let isActive: Bool
    
    var isStillValid: Bool {
        guard isActive else { return false }
        
        if let expiryDate = expiryDate {
            return Date() < expiryDate
        }
        
        return true
    }
}

// MARK: - User Promo Benefits
struct UserPromoBenefits: Codable {
    var appliedPromoCodes: [AppliedPromoCode]
    var freeInvoicesFromPromos: Int
    var hasActiveFreeSubscription: Bool
    var freeSubscriptionExpiryDate: Date?
    
    init() {
        self.appliedPromoCodes = []
        self.freeInvoicesFromPromos = 0
        self.hasActiveFreeSubscription = false
        self.freeSubscriptionExpiryDate = nil
    }
    
    // Check if user has any active promo benefits
    var hasActivePromoBenefits: Bool {
        return freeInvoicesFromPromos > 0 || 
               (hasActiveFreeSubscription && isPromotionalSubscriptionActive)
    }
    
    // Check if promotional subscription is still active
    var isPromotionalSubscriptionActive: Bool {
        guard hasActiveFreeSubscription else { return false }
        
        if let expiryDate = freeSubscriptionExpiryDate {
            return Date() < expiryDate
        }
        
        return false
    }
    
    // Get text representation of active benefits
    var activeBenefitsText: String {
        var benefits: [String] = []
        
        if freeInvoicesFromPromos > 0 {
            benefits.append("\(freeInvoicesFromPromos) facturas gratis")
        }
        
        if isPromotionalSubscriptionActive {
            benefits.append("Suscripción promocional activa")
        }
        
        return benefits.isEmpty ? "Sin beneficios activos" : benefits.joined(separator: ", ")
    }
}
