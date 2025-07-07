//
//  CreditsStatusView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//
// Updated to use N1CO payment system

import SwiftUI

struct CreditsStatusView: View {
    @StateObject private var n1coService = N1COEpayService.shared
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
        
        // Check N1CO user credits
        let userCredits = n1coService.userCredits
        return userCredits.canCreateInvoices
    }
    
    var creditsText: String {
        guard let company = company else { return "0 disponibles" }
        
        if company.isTestAccount {
            return "Ilimitadas (Pruebas)"
        }
        
        let userCredits = n1coService.userCredits
        
        // Check for active subscription
        if userCredits.isSubscriptionActive {
            return "Ilimitadas (Suscripción)"
        }
        
        // Show available invoice credits
        return "\(userCredits.availableInvoices) disponibles"
    }
    
    var creditsIcon: String {
        guard let company = company else { return "creditcard.fill" }
        
        if company.isTestAccount {
            return "infinity"
        }
        
        let userCredits = n1coService.userCredits
        if userCredits.isSubscriptionActive {
            return "infinity.circle.fill"
        }
        
        return "creditcard.fill"
    }
    
    var creditsColor: Color {
        if hasAvailableCredits {
            return company?.isTestAccount == true ? .blue : .green
        } else {
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Credits icon with gradient background
            ZStack {
                Circle()
                    .fill(creditsColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: creditsIcon)
                    .foregroundColor(creditsColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            // Credits info
            VStack(alignment: .leading, spacing: 2) {
                Text("Disponibles")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(creditsText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(hasAvailableCredits ? creditsColor : .primary)
            }
            
            Spacer()
            
            // Action button - only show for production accounts
            if showPurchaseOptions {
                Button(action: {
                    showPurchaseView = true
                }) {
                    Text(hasAvailableCredits ? "Comprar Más" : "Obtener Créditos")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    hasAvailableCredits ? Color.blue : Color.orange,
                                    hasAvailableCredits ? Color.blue.opacity(0.8) : Color.orange.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                        .shadow(color: (hasAvailableCredits ? Color.blue : Color.orange).opacity(0.3), radius: 2, x: 0, y: 1)
                }
            } else {
                // For test accounts, show test mode indicator
                HStack(spacing: 4) {
                    Image(systemName: "testtube.2")
                        .font(.caption2)
                    Text("Pruebas")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            // Debug logging for N1CO credits
            if let company = company {
                let userCredits = n1coService.userCredits
                print("🔍 N1CO CreditsStatusView Debug for company: \(company.nombreComercial)")
                print("  • isTestAccount: \(company.isTestAccount)")
                print("  • availableInvoices: \(userCredits.availableInvoices)")
                print("  • hasActiveSubscription: \(userCredits.hasActiveSubscription)")
                print("  • isSubscriptionActive: \(userCredits.isSubscriptionActive)")
                print("  • canCreateInvoices: \(userCredits.canCreateInvoices)")
                print("  • creditsText: '\(creditsText)'")
            }
        }
        .sheet(isPresented: $showPurchaseView) {
            if showPurchaseOptions {
                N1COPurchaseView(company: company)
            }
        }
    }
}

// MARK: - N1CO Purchase View
struct N1COPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var n1coService = N1COEpayService.shared
    @State private var selectedProduct: CustomPaymentProduct? = nil
    @State private var showCreditCardInput = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    let company: Company?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    if n1coService.isLoading {
                        ProgressView("Cargando productos...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        creditsSection
                        purchaseOptionsSection
                    }
                    
                    purchaseHistorySection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Paquetes de Facturas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showCreditCardInput) {
            if let product = selectedProduct {
                CreditCardInputView(product: product) {
                    handlePaymentSuccess()
                }
            }
        }
        .alert("¡Pago Exitoso!", isPresented: $showSuccessAlert) {
            Button("OK") {
                showSuccessAlert = false
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
        .alert("Error de Pago", isPresented: .constant(n1coService.errorMessage != nil)) {
            Button("OK") {
                n1coService.errorMessage = nil
            }
        } message: {
            Text(n1coService.errorMessage ?? "")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Comprar Paquetes de Facturas")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Paga con tarjeta de crédito de forma segura y obtén créditos instantáneamente")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    // MARK: - Credits Section
    private var creditsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: n1coService.userCredits.isSubscriptionActive ? "crown.fill" : "creditcard.fill")
                    .foregroundColor(n1coService.userCredits.isSubscriptionActive ? .orange : .green)
                
                Text("Estado de Créditos")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(n1coService.userCredits.creditsText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if n1coService.userCredits.isSubscriptionActive {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                        Text("Suscripción activa")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
                
                if n1coService.userCredits.hasImplementationFeePaid {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Costo de implementación pagado")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background((n1coService.userCredits.isSubscriptionActive ? Color.orange : Color.green).opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Purchase Options Section
    private var purchaseOptionsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Elige Tu Paquete")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(n1coService.availableProducts.filter { !$0.isImplementationFee }, id: \.id) { product in
                    CustomPurchaseBundleCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isPurchasing: n1coService.purchaseState == .processing,
                        onPurchase: {
                            selectedProduct = product
                            showCreditCardInput = true
                        }
                    )
                }
                
                // Implementation Fee (if not paid)
                if !n1coService.userCredits.hasImplementationFeePaid,
                   let implementationFee = n1coService.availableProducts.first(where: { $0.isImplementationFee }) {
                    
                    CustomPurchaseBundleCard(
                        product: implementationFee,
                        isSelected: selectedProduct?.id == implementationFee.id,
                        isPurchasing: n1coService.purchaseState == .processing,
                        onPurchase: {
                            selectedProduct = implementationFee
                            showCreditCardInput = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Purchase History Section
    private var purchaseHistorySection: some View {
        VStack(spacing: 12) {
            Button(action: {
                // TODO: Implement purchase history view
                print("Show purchase history")
            }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Ver Historial de Compras")
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            Text("Revisa todas tus compras y transacciones realizadas")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Success Handler
    private func handlePaymentSuccess() {
        successMessage = "Tu pago ha sido procesado exitosamente. Los créditos han sido agregados a tu cuenta."
        showSuccessAlert = true
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
    }
    .padding()
}

extension Company {
    func apply(_ closure: (Company) -> Void) -> Company {
        closure(self)
        return self
    }
}
