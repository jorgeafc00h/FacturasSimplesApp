//
//  PromoCodeService.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/9/25.
//
// COMMENTED OUT FOR APP SUBMISSION - REMOVE StoreKit DEPENDENCY
// Uncomment this entire file to re-enable in-app purchases

import Foundation

/*
@MainActor
@Observable
class PromoCodeService: ObservableObject {
    
    // MARK: - Published Properties
    var userPromoBenefits = UserPromoBenefits()
    var isValidatingCode = false
    var validationMessage: String?
    var lastValidatedCode: PromoCode?
    
    // MARK: - Private Properties
    private let promoBenefitsKey = "user_promo_benefits"
    private let availablePromoCodes: [PromoCode]
    
    // MARK: - Initialization
    init() {
        // Initialize with some predefined promo codes
        // In a real app, these would come from your backend
        self.availablePromoCodes = PromoCodeService.createDefaultPromoCodes()
        loadUserPromoBenefits()
    }
    
    // MARK: - Public Methods
    
    /// Validate and apply a promo code
    func validateAndApplyPromoCode(_ codeText: String) async -> Bool {
        isValidatingCode = true
        validationMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let cleanCode = codeText.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find matching promo code
        guard let promoCode = availablePromoCodes.first(where: { $0.code == cleanCode }) else {
            validationMessage = "Código promocional no válido"
            isValidatingCode = false
            return false
        }
        
        // Check if code is valid
        guard promoCode.isValid else {
            switch promoCode.status {
            case .expired:
                validationMessage = "Este código promocional ha expirado"
            case .used:
                validationMessage = "Este código promocional ya alcanzó su límite de usos"
            case .invalid:
                validationMessage = "Este código promocional no está activo"
            case .active:
                validationMessage = "Error desconocido"
            }
            isValidatingCode = false
            return false
        }
        
        // Check if already applied
        if userPromoBenefits.appliedPromoCodes.contains(where: { $0.promoCode.id == promoCode.id }) {
            validationMessage = "Ya has aplicado este código promocional"
            isValidatingCode = false
            return false
        }
        
        // Apply the promo code
        applyPromoCode(promoCode)
        
        lastValidatedCode = promoCode
        validationMessage = "¡Código aplicado exitosamente! \(promoCode.displayText)"
        isValidatingCode = false
        
        return true
    }
    
    /// Use a free invoice from promo benefits
    func usePromoInvoiceCredit() -> Bool {
        guard userPromoBenefits.freeInvoicesFromPromos > 0 else { return false }
        
        userPromoBenefits.freeInvoicesFromPromos -= 1
        saveUserPromoBenefits()
        return true
    }
    
    /// Check if user can create invoices with promo benefits
    func canCreateInvoicesWithPromo() -> Bool {
        return userPromoBenefits.hasActivePromoBenefits
    }
    
    /// Get discount percentage for current user (if any active discount promo)
    func getCurrentDiscountPercentage() -> Int? {
        let activeDiscountPromos = userPromoBenefits.appliedPromoCodes.filter { 
            $0.isStillValid && $0.promoCode.type == .discount 
        }
        
        return activeDiscountPromos.first?.promoCode.discountPercent
    }
    
    /// Check if user has promotional subscription active
    func hasActivePromotionalSubscription() -> Bool {
        return userPromoBenefits.isPromotionalSubscriptionActive
    }
    
    // MARK: - Private Methods
    
    private func applyPromoCode(_ promoCode: PromoCode) {
        let appliedDate = Date()
        var expiryDate: Date?
        
        switch promoCode.type {
        case .freeAccess:
            if let freeCount = promoCode.freeInvoiceCount {
                userPromoBenefits.freeInvoicesFromPromos += freeCount
            }
            
        case .discount:
            // Discount codes typically have an expiry date
            expiryDate = Calendar.current.date(byAdding: .day, value: 30, to: appliedDate) // 30 days validity
            
        case .freeSubscription:
            if let freeDays = promoCode.freeDurationDays {
                userPromoBenefits.hasActiveFreeSubscription = true
                userPromoBenefits.freeSubscriptionExpiryDate = Calendar.current.date(byAdding: .day, value: freeDays, to: appliedDate)
            }
        }
        
        let appliedPromo = AppliedPromoCode(
            promoCode: promoCode,
            appliedDate: appliedDate,
            expiryDate: expiryDate,
            isActive: true
        )
        
        userPromoBenefits.appliedPromoCodes.append(appliedPromo)
        saveUserPromoBenefits()
        
        print("✅ Applied promo code: \(promoCode.code) - \(promoCode.displayText)")
    }
    
    private func loadUserPromoBenefits() {
        guard let data = UserDefaults.standard.data(forKey: promoBenefitsKey),
              let benefits = try? JSONDecoder().decode(UserPromoBenefits.self, from: data) else {
            userPromoBenefits = UserPromoBenefits()
            return
        }
        
        userPromoBenefits = benefits
        print("✅ Loaded user promo benefits: \(userPromoBenefits.activeBenefitsText)")
    }
    
    private func saveUserPromoBenefits() {
        do {
            let data = try JSONEncoder().encode(userPromoBenefits)
            UserDefaults.standard.set(data, forKey: promoBenefitsKey)
            print("✅ Saved user promo benefits")
        } catch {
            print("❌ Failed to save user promo benefits: \(error)")
        }
    }
    
    // MARK: - Static Methods
    
    static func createDefaultPromoCodes() -> [PromoCode] {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        
        return [
            // Free access codes
            PromoCode(
                id: "promo_free50",
                code: "FREE50",
                type: .freeAccess,
                description: "50 facturas gratuitas",
                discountPercent: nil,
                freeInvoiceCount: 50,
                freeDurationDays: nil,
                validFrom: now,
                validUntil: futureDate,
                maxUses: 1000,
                currentUses: 0,
                isActive: true
            ),
            
            PromoCode(
                id: "promo_welcome",
                code: "WELCOME2025",
                type: .freeAccess,
                description: "Bienvenida - 25 facturas gratis",
                discountPercent: nil,
                freeInvoiceCount: 25,
                freeDurationDays: nil,
                validFrom: now,
                validUntil: futureDate,
                maxUses: 500,
                currentUses: 0,
                isActive: true
            ),
            
            // Discount codes
            PromoCode(
                id: "promo_discount50",
                code: "SAVE50",
                type: .discount,
                description: "50% de descuento en paquetes",
                discountPercent: 50,
                freeInvoiceCount: nil,
                freeDurationDays: nil,
                validFrom: now,
                validUntil: futureDate,
                maxUses: 200,
                currentUses: 0,
                isActive: true
            ),
            
            PromoCode(
                id: "promo_discount25",
                code: "NEWUSER25",
                type: .discount,
                description: "25% de descuento para nuevos usuarios",
                discountPercent: 25,
                freeInvoiceCount: nil,
                freeDurationDays: nil,
                validFrom: now,
                validUntil: futureDate,
                maxUses: 1000,
                currentUses: 0,
                isActive: true
            ),
            
            // Free subscription codes
            PromoCode(
                id: "promo_trial30",
                code: "TRIAL30",
                type: .freeSubscription,
                description: "30 días gratis de Enterprise Pro",
                discountPercent: nil,
                freeInvoiceCount: nil,
                freeDurationDays: 30,
                validFrom: now,
                validUntil: futureDate,
                maxUses: 100,
                currentUses: 0,
                isActive: true
            ),
            
            PromoCode(
                id: "promo_enterprise7",
                code: "ENTERPRISE7",
                type: .freeSubscription,
                description: "7 días gratis de Enterprise Pro",
                discountPercent: nil,
                freeInvoiceCount: nil,
                freeDurationDays: 7,
                validFrom: now,
                validUntil: futureDate,
                maxUses: 500,
                currentUses: 0,
                isActive: true
            )
        ]
    }
}
*/

// PLACEHOLDER CLASS FOR COMPILATION
@MainActor
@Observable
class PromoCodeService: ObservableObject {
    var userPromoBenefits = UserPromoBenefits()
    var isValidatingCode = false
    var validationMessage: String?
    var lastValidatedCode: PromoCode?
    
    init() {}
    
    func hasActivePromotionalSubscription() -> Bool { return false }
    func canCreateInvoicesWithPromo() -> Bool { return false }
    func usePromoInvoiceCredit() -> Bool { return false }
    func validatePromoCode(_ code: String) async -> Bool { return false }
}

// PLACEHOLDER STRUCTS FOR COMPILATION
struct UserPromoBenefits: Codable {
    var freeInvoicesFromPromos: Int = 0
    var hasPromotionalSubscription: Bool = false
    var promotionalSubscriptionExpiry: Date?
    var redeemedPromoCodes: [String] = []
}

struct PromoCode: Codable, Identifiable {
    let id = UUID()
    let code: String
    let benefits: PromoBenefits
    let validFrom: Date
    let validUntil: Date
    let maxUses: Int
    var currentUses: Int
    let isActive: Bool
}

struct PromoBenefits: Codable {
    let freeInvoices: Int
    let subscriptionDays: Int
    let description: String
}
