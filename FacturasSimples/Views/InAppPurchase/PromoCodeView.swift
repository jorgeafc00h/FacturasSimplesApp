//
//  PromoCodeView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/9/25.
//
// COMMENTED OUT FOR APP SUBMISSION - REMOVE StoreKit DEPENDENCY
// Uncomment this entire file to re-enable in-app purchases

import SwiftUI

/*
struct PromoCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var promoCodeService = PromoCodeService()
    @State private var promoCodeText = ""
    @State private var showSuccessAlert = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    promoCodeInputSection
                    currentBenefitsSection
                    appliedPromoCodesSection
                }
                .padding()
            }
            .navigationTitle("Códigos Promocionales")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("¡Código Aplicado!", isPresented: $showSuccessAlert) {
                Button("OK") { }
            } message: {
                if let lastCode = promoCodeService.lastValidatedCode {
                    Text("Has recibido: \(lastCode.displayText)")
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Códigos Promocionales")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ingresa un código promocional para obtener facturas gratuitas, descuentos o acceso premium al comprar subscripciones anuales")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    // MARK: - Promo Code Input Section
    private var promoCodeInputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Código Promocional")
                    .font(.headline)
                
                HStack {
                    TextField("Ingresa tu código", text: $promoCodeText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .focused($isTextFieldFocused)
                    
                    Button("Aplicar") {
                        applyPromoCode()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(promoCodeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || promoCodeService.isValidatingCode)
                }
            }
            
            if promoCodeService.isValidatingCode {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Validando código...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let message = promoCodeService.validationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(promoCodeService.lastValidatedCode != nil ? .green : .red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Current Benefits Section
    private var currentBenefitsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Beneficios Activos")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                if promoCodeService.userPromoBenefits.freeInvoicesFromPromos > 0 {
                    benefitRow(
                        icon: "doc.text.fill",
                        title: "Facturas Gratuitas",
                        value: "\(promoCodeService.userPromoBenefits.freeInvoicesFromPromos)",
                        color: .blue
                    )
                }
                
                if promoCodeService.userPromoBenefits.isPromotionalSubscriptionActive {
                    benefitRow(
                        icon: "crown.fill",
                        title: "Suscripción Promocional",
                        value: "Activa",
                        color: .purple
                    )
                    
                    if let expiryDate = promoCodeService.userPromoBenefits.freeSubscriptionExpiryDate {
                        Text("Expira: \(formatDate(expiryDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let discountPercent = promoCodeService.getCurrentDiscountPercentage() {
                    benefitRow(
                        icon: "percent",
                        title: "Descuento Activo",
                        value: "\(discountPercent)%",
                        color: .green
                    )
                }
                
                if !promoCodeService.userPromoBenefits.hasActivePromoBenefits && promoCodeService.getCurrentDiscountPercentage() == nil {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("No tienes beneficios activos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Applied Promo Codes Section
    private var appliedPromoCodesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Códigos Aplicados")
                    .font(.headline)
                Spacer()
            }
            
            if promoCodeService.userPromoBenefits.appliedPromoCodes.isEmpty {
                HStack {
                    Image(systemName: "ticket")
                        .foregroundColor(.secondary)
                    Text("No has aplicado códigos promocionales")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(promoCodeService.userPromoBenefits.appliedPromoCodes, id: \.promoCode.id) { appliedPromo in
                        appliedPromoCodeRow(appliedPromo)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func benefitRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
    
    private func appliedPromoCodeRow(_ appliedPromo: AppliedPromoCode) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appliedPromo.promoCode.code)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(appliedPromo.promoCode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("Aplicado: \(formatDate(appliedPromo.appliedDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                statusBadge(for: appliedPromo)
                
                if let expiryDate = appliedPromo.expiryDate {
                    Text("Expira: \(formatDate(expiryDate))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(appliedPromo.isStillValid ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func statusBadge(for appliedPromo: AppliedPromoCode) -> some View {
        Text(appliedPromo.isStillValid ? "Activo" : "Expirado")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(appliedPromo.isStillValid ? Color.green : Color.gray)
            .cornerRadius(4)
    }
    
    // MARK: - Methods
    
    private func applyPromoCode() {
        isTextFieldFocused = false
        
        Task {
            let success = await promoCodeService.validateAndApplyPromoCode(promoCodeText)
            
            if success {
                promoCodeText = ""
                showSuccessAlert = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    PromoCodeView()
}
*/

// PLACEHOLDER VIEW FOR COMPILATION
struct PromoCodeView: View {
    var body: some View {
        Text("Promo Code View Disabled")
            .navigationTitle("Código Promocional")
    }
}
