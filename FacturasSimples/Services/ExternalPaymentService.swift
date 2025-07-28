//
//  ExternalPaymentService.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 7/22/25.
//  Simple service to provide product data for external payment system
//

import Foundation
import SwiftUI

@MainActor
class ExternalPaymentService: ObservableObject {
    static let shared = ExternalPaymentService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var availableProducts: [CustomPaymentProduct] = []
    @Published var userCredits = CustomUserCredits()
    
    private init() {
        loadAvailableProducts()
    }
    
    private func loadAvailableProducts() {
        // Static product definitions for external payment - Updated to match website pricing
        availableProducts = [
            CustomPaymentProduct(
                id: "bundle_essential_25",
                name: "Paquete Esencial",
                description: "Ideal para emprendedores y pequeños negocios",
                invoiceCount: 25,
                price: 4.90,
                formattedPrice: "$4.90",
                isPopular: false,
                productType: .consumable,
                isImplementationFee: false,
                subscriptionPeriod: nil,
                specialOfferText: nil
            ),
            CustomPaymentProduct(
                id: "bundle_initial_50",
                name: "Paquete Inicial",
                description: "Perfecto para pequeñas empresas",
                invoiceCount: 50,
                price: 9.99,
                formattedPrice: "$9.99",
                isPopular: true,
                productType: .consumable,
                isImplementationFee: false,
                subscriptionPeriod: nil,
                specialOfferText: "Popular"
            ),
            CustomPaymentProduct(
                id: "bundle_professional_100",
                name: "Paquete Profesional",
                description: "La mejor opción para empresas en crecimiento",
                invoiceCount: 100,
                price: 15.00,
                formattedPrice: "$15.00",
                isPopular: false,
                productType: .consumable,
                isImplementationFee: false,
                subscriptionPeriod: nil,
                specialOfferText: nil
            ),
            CustomPaymentProduct(
                id: "bundle_enterprise_250",
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
            ),
            CustomPaymentProduct(
                id: "enterprise_pro_monthly",
                name: "Enterprise Pro",
                description: "Suscripción mensual con facturación ilimitada para empresas grandes",
                invoiceCount: -1,
                price: 99.99,
                formattedPrice: "$99.99",
                isPopular: false,
                productType: .subscription,
                isImplementationFee: false,
                subscriptionPeriod: "monthly",
                specialOfferText: "Mejor Valor"
            ),
            CustomPaymentProduct(
                id: "enterprise_pro_yearly",
                name: "Enterprise Pro Anual",
                description: "Suscripción anual con facturación ilimitada para empresas grandes",
                invoiceCount: -1,
                price: 999.99,
                formattedPrice: "$999.99",
                isPopular: false,
                productType: .subscription,
                isImplementationFee: false,
                subscriptionPeriod: "yearly",
                specialOfferText: "Ahorra $200 vs plan mensual"
            )
        ]
    }
    
    // Placeholder methods to maintain compatibility
    func refreshProducts() async {
        isLoading = true
        // Simulate loading
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        isLoading = false
    }
    
    func updateUserCredits() async {
        // This would be updated by the external payment status checking
        // For now, we'll use the PurchaseDataManager to get credit info
        let purchaseManager = PurchaseDataManager.shared
        if let profile = purchaseManager.userProfile {
            userCredits.availableInvoices = profile.availableInvoices ?? 0
            userCredits.totalPurchased = profile.totalPurchasedInvoices ?? 0
        }
    }
    
    func consumeInvoiceCredit(for invoiceId: String) {
        // Use PurchaseDataManager to consume the credit
        PurchaseDataManager.shared.consumeInvoiceCredit(for: invoiceId)
    }
}
