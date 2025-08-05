//
//  UnifiedPurchaseView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//  Updated for App Store compliance - Apple In-App Purchases only

import SwiftUI
import StoreKit

struct UnifiedPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appleStoreManager = AppleStoreKitManager.shared
    @StateObject private var purchaseManager = PurchaseDataManager.shared
    @StateObject private var promoCodeService = PromoCodeService()
    
    @State private var selectedProduct: SKProduct?
    @State private var showingPurchaseHistory = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    @State private var showingCouponInput = false
    @State private var showingPromoCodeView = false
    @State private var promoCodeText = ""
    
    // Only Apple IAP for App Store compliance
    private var shouldUseOnlyAppleIAP: Bool {
        FeatureFlags.shared.shouldUseOnlyAppleInAppPurchases
    }
    
    // Available products - only Apple StoreKit products for App Store compliance
    private var availableProducts: [SKProduct] {
        return appleStoreManager.availableProducts.sorted { 
            $0.price.compare($1.price) == .orderedAscending
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    if appleStoreManager.isLoading {
                        ProgressView("Cargando productos...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        creditsSection
                        productsSection
                        promoCodeSection
                    }
                }
                .padding()
            }
            .navigationTitle("Comprar Créditos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            appleStoreManager.requestProducts()
        }
        .alert("Compra Exitosa", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Compra Créditos")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Adquiere créditos para facturar con tu cuenta empresarial")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Credits Section
    private var creditsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Créditos Actuales")
                    .font(.headline)
                Spacer()
                Text("\(purchaseManager.userProfile?.availableInvoices ?? 0)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Products Section
    private var productsSection: some View {
        VStack(spacing: 16) {
            Text("Selecciona un Paquete")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 12) {
                ForEach(availableProducts, id: \.productIdentifier) { product in
                    ProductCard(product: product) {
                        handleProductSelection(product)
                    }
                }
            }
        }
    }
    
    // MARK: - Purchase Logic
    private func handleProductSelection(_ product: SKProduct) {
        selectedProduct = product
        appleStoreManager.purchase(product)
        handlePaymentSuccess(for: product)
    }
    
    private func handlePaymentSuccess(for product: SKProduct) {
        successMessage = "¡Has comprado exitosamente \(product.localizedTitle)!"
        showSuccessAlert = true
        
        // Refresh user profile to show updated credits
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            purchaseManager.loadUserProfile()
        }
        
        print("✅ Purchase successful: \(product.localizedTitle)")
    }
    
    // MARK: - Promo Code Section
    private var promoCodeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Código Promocional")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showingCouponInput.toggle()
                }) {
                    Image(systemName: showingCouponInput ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            
            if showingCouponInput {
                VStack(spacing: 12) {
                    HStack {
                        TextField("Ingresa tu código promocional", text: $promoCodeText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                        
                        Button("Aplicar") {
                            Task {
                                await applyPromoCode()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(promoCodeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || promoCodeService.isValidatingCode)
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
                    
                    Button("Ver Todos los Códigos") {
                        showingPromoCodeView = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingPromoCodeView) {
            PromoCodeView()
        }
    }
    
    private func applyPromoCode() async {
        let success = await promoCodeService.validateAndApplyPromoCode(promoCodeText)
        if success {
            promoCodeText = ""
            showingCouponInput = false
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: SKProduct
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(product.localizedTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(product.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formatPrice(product.price, locale: product.priceLocale))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Button("Comprar") {
                    onPurchase()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatPrice(_ price: NSDecimalNumber, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: price) ?? "$\(price)"
    }
}

#Preview {
    UnifiedPurchaseView()
}
