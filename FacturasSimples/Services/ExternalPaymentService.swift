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
        // Static product definitions for external payment
        availableProducts = [
            CustomPaymentProduct(
                id: "bundle_50",
                name: "Paquete Básico",
                description: "Ideal para emprendedores y pequeñas empresas",
                invoiceCount: 50,
                price: 15.00,
                formattedPrice: "$15.00",
                isPopular: false,
                productType: .consumable,
                isImplementationFee: false,
                subscriptionPeriod: nil,
                specialOfferText: nil
            ),
            CustomPaymentProduct(
                id: "bundle_100",
                name: "Paquete Estándar",
                description: "Perfecto para empresas en crecimiento",
                invoiceCount: 100,
                price: 25.00,
                formattedPrice: "$25.00",
                isPopular: true,
                productType: .consumable,
                isImplementationFee: false,
                subscriptionPeriod: nil,
                specialOfferText: "¡Más Popular!"
            ),
            CustomPaymentProduct(
                id: "bundle_250",
                name: "Paquete Profesional",
                description: "Para empresas con alto volumen de facturación",
                invoiceCount: 250,
                price: 50.00,
                formattedPrice: "$50.00",
                isPopular: false,
                productType: .consumable,
                isImplementationFee: false,
                subscriptionPeriod: nil,
                specialOfferText: nil
            ),
            CustomPaymentProduct(
                id: "bundle_500",
                name: "Paquete Empresarial",
                description: "Para grandes empresas y corporaciones",
                invoiceCount: 500,
                price: 90.00,
                formattedPrice: "$90.00",
                isPopular: false,
                productType: .consumable,
                isImplementationFee: false,
                subscriptionPeriod: nil,
                specialOfferText: "Mejor Valor"
            ),
            CustomPaymentProduct(
                id: "implementation_fee",
                name: "Tarifa de Implementación",
                description: "Configuración inicial y activación del servicio",
                invoiceCount: 0,
                price: 25.00,
                formattedPrice: "$25.00",
                isPopular: false,
                productType: .consumable,
                isImplementationFee: true,
                subscriptionPeriod: nil,
                specialOfferText: nil
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
