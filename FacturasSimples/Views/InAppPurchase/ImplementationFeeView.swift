//
//  ImplementationFeeView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/12/25.
//
// COMMENTED OUT FOR APP SUBMISSION - REMOVE StoreKit DEPENDENCY
// Uncomment this entire file to re-enable in-app purchases

import SwiftUI
// import StoreKit // COMMENTED OUT - Remove StoreKit dependency

/*
struct ImplementationFeeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreKitManager
    @State private var couponCode = ""
    @State private var showCouponField = false
    @State private var isApplyingCoupon = false
    @State private var couponError: String?
    @State private var appliedDiscount: Int = 0
    
    let company: Company
    
    private var implementationFeeProduct: StoreKit.Product? {
        storeManager.products.first { $0.id == InvoiceBundle.implementationFee.id }
    }
    
    private var originalPrice: Decimal {
        implementationFeeProduct?.price ?? InvoiceBundle.implementationFee.price
    }
    
    private var discountedPrice: Decimal {
        if appliedDiscount > 0 {
            let discountMultiplier = Decimal(100 - appliedDiscount) / 100
            return originalPrice * discountMultiplier
        }
        return originalPrice
    }
    
    private var formattedOriginalPrice: String {
        implementationFeeProduct?.displayPrice ?? InvoiceBundle.implementationFee.formattedPrice
    }
    
    private var formattedDiscountedPrice: String {
        if appliedDiscount > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: discountedPrice as NSDecimalNumber) ?? "$\(discountedPrice)"
        }
        return formattedOriginalPrice
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    companyInfoSection
                    pricingSection
                    couponSection
                    purchaseSection
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Costo de Implementación")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(storeManager.errorMessage != nil)) {
                Button("OK") {
                    storeManager.errorMessage = nil
                }
            } message: {
                Text(storeManager.errorMessage ?? "")
            }
        }
        .task {
            await storeManager.loadProducts()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Activar Cuenta de Producción")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Para crear facturas en producción se requiere un costo único de implementación")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    // MARK: - Company Info Section
    private var companyInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.fill")
                    .foregroundColor(.blue)
                Text("Empresa a Activar")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Nombre:")
                        .fontWeight(.medium)
                    Text(company.nombre)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("NIT:")
                        .fontWeight(.medium)
                    Text(company.nit)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("NRC:")
                        .fontWeight(.medium)
                    Text(company.nrc)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 24)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.green)
                Text("Costo de Implementación")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                if appliedDiscount > 0 {
                    HStack {
                        Text("Precio original:")
                        Spacer()
                        Text(formattedOriginalPrice)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Descuento (\(appliedDiscount)%):")
                        Spacer()
                        Text("-\(appliedDiscount)%")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Precio final:")
                            .font(.headline)
                        Spacer()
                        Text(formattedDiscountedPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Text("Precio:")
                            .font(.headline)
                        Spacer()
                        Text(formattedOriginalPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Coupon Section
    private var couponSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "ticket")
                    .foregroundColor(.orange)
                Text("Código de Cupón")
                    .font(.headline)
                Spacer()
                
                Button(showCouponField ? "Ocultar" : "Usar Cupón") {
                    withAnimation {
                        showCouponField.toggle()
                        if !showCouponField {
                            couponCode = ""
                            couponError = nil
                            appliedDiscount = 0
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if showCouponField {
                VStack(spacing: 12) {
                    HStack {
                        TextField("Ingrese código de cupón", text: $couponCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textCase(.uppercase)
                            .disabled(isApplyingCoupon)
                        
                        Button(action: applyCoupon) {
                            if isApplyingCoupon {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Aplicar")
                            }
                        }
                        .disabled(couponCode.isEmpty || isApplyingCoupon)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(couponCode.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    if let error = couponError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if appliedDiscount > 0 {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Cupón aplicado: \(appliedDiscount)% de descuento")
                                .font(.caption)
                                .foregroundColor(.green)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if storeManager.isLoading {
                ProgressView("Cargando...")
                    .frame(height: 50)
            } else {
                Button(action: purchaseImplementationFee) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("Pagar Costo de Implementación")
                        if storeManager.purchaseState == .purchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(storeManager.purchaseState == .purchasing)
                
                if storeManager.purchaseState == .purchased {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("¡Pago completado! Ya puedes crear facturas en producción.")
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Este es un pago único por empresa")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Una vez pagado, podrás crear facturas de producción para esta empresa sin límites adicionales (sujeto a la compra de créditos)")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    private func applyCoupon() {
        guard !couponCode.isEmpty else { return }
        
        isApplyingCoupon = true
        couponError = nil
        
        // Simulate coupon validation (replace with actual API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isApplyingCoupon = false
            
            // Mock coupon validation
            switch couponCode.uppercased() {
            case "DESCUENTO10":
                appliedDiscount = 10
                couponError = nil
            case "DESCUENTO20":
                appliedDiscount = 20
                couponError = nil
            case "DESCUENTO50":
                appliedDiscount = 50
                couponError = nil
            default:
                couponError = "Código de cupón inválido"
                appliedDiscount = 0
            }
        }
    }
    
    private func purchaseImplementationFee() {
        guard let product = implementationFeeProduct else {
            storeManager.errorMessage = "Producto no disponible"
            return
        }
        
        Task {
            await storeManager.purchase(product, for: company)
            
            // If purchase was successful, dismiss the view
            if storeManager.purchaseState == .purchased {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ImplementationFeeView(company: Company(nit: "123456789", nrc: "987654", nombre: "Empresa de Prueba"))
        
}
*/

// PLACEHOLDER VIEW FOR COMPILATION
struct ImplementationFeeView: View {
    let company: Company
    
    var body: some View {
        Text("Implementation Fee Disabled")
            .navigationTitle("Costo de Implementación")
    }
}
