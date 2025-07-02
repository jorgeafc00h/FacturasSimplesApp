//
//  CreditsStatusView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//
// COMMENTED OUT FOR APP SUBMISSION - REMOVE StoreKit DEPENDENCY
// Uncomment this entire file to re-enable in-app purchases

import SwiftUI

/*
struct CreditsStatusView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    @State private var showPurchaseView = false
    let company: Company?
    
    var showPurchaseOptions: Bool {
        return company?.requiresPaidServices ?? false
    }
    
    var hasAvailableCredits: Bool {
        guard let company = company else { return false }
        
        // Test accounts always have "unlimited" credits
        if company.isTestAccount {
            return true
        }
        
        // Use StoreKitManager's comprehensive credit checking
        return storeManager.hasAvailableCredits(for: company)
    }
    
    var creditsText: String {
        guard let company = company else { return "0 disponibles" }
        
        if company.isTestAccount {
            return "Ilimitadas (Pruebas)"
        }
        
        // Check for active subscriptions (company or global) - with proper validation
        let companyHasActiveSubscription = company.hasActiveSubscription && company.isSubscriptionActive
        let globalHasActiveSubscription = storeManager.userCredits.hasActiveSubscription && storeManager.userCredits.isSubscriptionActive
        
        if companyHasActiveSubscription || globalHasActiveSubscription {
            return "Ilimitadas"
        }
        
        // Check for promotional subscriptions - with proper validation
        let hasActivePromoSubscription = storeManager.promoCodeService.hasActivePromotionalSubscription()
        if hasActivePromoSubscription {
            return "Ilimitadas"
        }
        
        // Calculate total available credits from all sources
        var totalCredits = 0
        
        // Add company-specific credits
        totalCredits += company.availableInvoiceCredits
        
        // Add global StoreKit credits
        totalCredits += storeManager.userCredits.availableInvoices
        
        // Add promotional credits
        totalCredits += storeManager.promoCodeService.userPromoBenefits.freeInvoicesFromPromos
        
        return "\(totalCredits) disponibles"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Credits icon - smaller
            Image(systemName: company?.isTestAccount == true ? "infinity" : "creditcard.fill")
                .foregroundColor(hasAvailableCredits ? .green : .orange)
                .font(.subheadline)
            
            // Credits info - more compact
            VStack(alignment: .leading, spacing: 1) {
                Text("Disponibles")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(creditsText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(hasAvailableCredits ? .green : .primary)
            }
            
            Spacer()
            
            // Action button - only show for production accounts
            if showPurchaseOptions {
                Button(action: {
                    showPurchaseView = true
                }) {
                    Text(hasAvailableCredits ? "Comprar Más" : "Obtener Créditos")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hasAvailableCredits ? Color.blue : Color.orange)
                        .cornerRadius(6)
                }
            } else {
                // For test accounts, show test mode indicator
                Text("Pruebas")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .onAppear {
            // Refresh credits when view appears to ensure latest data
            storeManager.refreshUserCredits()
            
            // Debug logging to help identify the issue
            if let company = company {
                print("🔍 CreditsStatusView Debug for company: \(company.nombreComercial)")
                print("  • isTestAccount: \(company.isTestAccount)")
                print("  • hasActiveSubscription: \(company.hasActiveSubscription)")
                print("  • isSubscriptionActive: \(company.isSubscriptionActive)")
                print("  • availableInvoiceCredits: \(company.availableInvoiceCredits)")
                print("  • Global userCredits.hasActiveSubscription: \(storeManager.userCredits.hasActiveSubscription)")
                print("  • Global userCredits.isSubscriptionActive: \(storeManager.userCredits.isSubscriptionActive)")
                print("  • Global userCredits.availableInvoices: \(storeManager.userCredits.availableInvoices)")
                print("  • hasActivePromotionalSubscription: \(storeManager.promoCodeService.hasActivePromotionalSubscription())")
                print("  • Promo freeInvoicesFromPromos: \(storeManager.promoCodeService.userPromoBenefits.freeInvoicesFromPromos)")
                print("  • Final creditsText: '\(creditsText)'")
            }
        }
        .sheet(isPresented: $showPurchaseView) {
            if showPurchaseOptions {
                CompanyInAppPurchaseView(company: company!)
                    .environmentObject(storeManager)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Production account preview
        CreditsStatusView(company: Company(
            nit: "123456789",
            nrc: "123456",
            nombre: "Test Company",
            descActividad: "Test Activity",
            nombreComercial: "Test",
            tipoEstablecimiento: "01",
            telefono: "123456789",
            correo: "test@test.com",
            codEstableMH: "001",
            codEstable: "001",
            codPuntoVentaMH: "001",
            codPuntoVenta: "001",
            departamento: "San Salvador",
            municipio: "San Salvador",
            complemento: "Test Address",
            invoiceLogo: "",
            departamentoCode: "06",
            municipioCode: "05",
            codActividad: "01234"
        ).apply { $0.isTestAccount = false })
        .environmentObject(StoreKitManager())
        
        // Test account preview
        CreditsStatusView(company: Company(
            nit: "123456789",
            nrc: "123456",
            nombre: "Test Company",
            descActividad: "Test Activity",
            nombreComercial: "Test",
            tipoEstablecimiento: "01",
            telefono: "123456789",
            correo: "test@test.com",
            codEstableMH: "001",
            codEstable: "001",
            codPuntoVentaMH: "001",
            codPuntoVenta: "001",
            departamento: "San Salvador",
            municipio: "San Salvador",
            complemento: "Test Address",
            invoiceLogo: "",
            departamentoCode: "06",
            municipioCode: "05",
            codActividad: "01234"
        ).apply { $0.isTestAccount = true })
        .environmentObject(StoreKitManager())
        
        // Preview with different states
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Créditos de Factura")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("0 disponibles")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Obtener Créditos")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    .padding()
}

extension Company {
    func apply(_ closure: (Company) -> Void) -> Company {
        closure(self)
        return self
    }
}
*/

// PLACEHOLDER VIEW FOR COMPILATION
struct CreditsStatusView: View {
    let company: Company?
    
    var body: some View {
        HStack {
            Image(systemName: "creditcard.fill")
                .foregroundColor(.green)
            Text("Créditos: Ilimitados (IAP deshabilitado)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
