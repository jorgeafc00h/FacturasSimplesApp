//
//  InAppPurchaseView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//

import SwiftUI
import StoreKit

struct InAppPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreKitManager()
    @State private var selectedBundle: InvoiceBundle?
    @State private var showPromoCodeView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if storeManager.isLoading {
                        ProgressView("Cargando productos...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {                    creditsSection
                    
                    if storeManager.promoCodeService.userPromoBenefits.hasActivePromoBenefits || storeManager.promoCodeService.getCurrentDiscountPercentage() != nil {
                        promoBenefitsSection
                    }
                    
                    purchaseOptionsSection
                    promoCodeSection
                    }
                    
                    restoreSection
                }
                .padding()
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
            .alert("Error", isPresented: .constant(storeManager.errorMessage != nil)) {
                Button("OK") {
                    storeManager.errorMessage = nil
                }
            } message: {
                Text(storeManager.errorMessage ?? "")
            }
        }
        .sheet(isPresented: $showPromoCodeView) {
            PromoCodeView()
        }
        .task {
            await storeManager.loadProducts()
            await storeManager.checkSubscriptionStatus()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Comprar Paquetes de Facturas")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Compra créditos de facturas para crear facturas profesionales sin límites")
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
                Image(systemName: storeManager.userCredits.isSubscriptionActive || storeManager.promoCodeService.hasActivePromotionalSubscription() ? "crown.fill" : "creditcard.fill")
                    .foregroundColor(storeManager.userCredits.isSubscriptionActive || storeManager.promoCodeService.hasActivePromotionalSubscription() ? .orange : .green)
                
                Text("Estado de Créditos")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(storeManager.getTotalCreditsText())
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Individual credit sources
                if storeManager.promoCodeService.hasActivePromotionalSubscription() {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.purple)
                        Text("Suscripción promocional activa")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Spacer()
                    }
                } else if storeManager.userCredits.isSubscriptionActive {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                        Text(storeManager.userCredits.subscriptionStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                if storeManager.promoCodeService.userPromoBenefits.freeInvoicesFromPromos > 0 {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.orange)
                        Text("\(storeManager.promoCodeService.userPromoBenefits.freeInvoicesFromPromos) facturas promocionales disponibles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background((storeManager.userCredits.isSubscriptionActive || storeManager.promoCodeService.hasActivePromotionalSubscription() ? Color.orange : Color.green).opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Purchase Options Section
    private var purchaseOptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Elige Tu Paquete")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(InvoiceBundle.allBundles, id: \.id) { bundle in
                    PurchaseBundleCard(
                        bundle: bundle,
                        product: storeManager.getProduct(for: bundle),
                        isSelected: selectedBundle?.id == bundle.id,
                        isPurchasing: storeManager.purchaseState == .purchasing,
                        onPurchase: {
                            selectedBundle = bundle
                            Task {
                                if let product = storeManager.getProduct(for: bundle) {
                                    await storeManager.purchase(product)
                                }
                            }
                        },
                        storeManager: storeManager
                    )
                }
            }
        }
    }
    
    // MARK: - Restore Section
    private var restoreSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await storeManager.restorePurchases()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Restaurar Compras")
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .disabled(storeManager.isLoading)
            
            Text("Restaura compras anteriores para recuperar tus créditos de facturas")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Promo Benefits Section
    private var promoBenefitsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.orange)
                
                Text("Beneficios Promocionales")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                if storeManager.promoCodeService.userPromoBenefits.freeInvoicesFromPromos > 0 {
                    HStack {
                        Text("Facturas promocionales:")
                        Spacer()
                        Text("\(storeManager.promoCodeService.userPromoBenefits.freeInvoicesFromPromos)")
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                
                if storeManager.promoCodeService.hasActivePromotionalSubscription() {
                    HStack {
                        Text("Suscripción promocional:")
                        Spacer()
                        Text("Activa")
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                }
                
                if let discountPercent = storeManager.promoCodeService.getCurrentDiscountPercentage() {
                    HStack {
                        Text("Descuento activo:")
                        Spacer()
                        Text("\(discountPercent)% OFF")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Promo Code Section
    private var promoCodeSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showPromoCodeView = true
            }) {
                HStack {
                    Image(systemName: "ticket.fill")
                        .foregroundColor(.orange)
                    
                    Text("¿Tienes un código promocional?")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Text("Obtén facturas gratuitas, descuentos especiales o acceso premium")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Purchase Bundle Card
struct PurchaseBundleCard: View {
    let bundle: InvoiceBundle
    let product: StoreKit.Product?
    let isSelected: Bool
    let isPurchasing: Bool
    let onPurchase: () -> Void
    @ObservedObject var storeManager: StoreKitManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Popular badge or subscription badge
            if bundle.isSubscription {
                HStack {
                    Spacer()
                    Text("SUSCRIPCIÓN")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple)
                        .cornerRadius(4)
                }
            } else if bundle.isPopular {
                HStack {
                    Spacer()
                    Text("POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
            }
            
            // Icon and count
            VStack(spacing: 4) {
                Image(systemName: bundle.isSubscription ? "crown.fill" : "doc.text.fill")
                    .font(.title)
                    .foregroundColor(bundle.isSubscription ? .purple : (bundle.isPopular ? .orange : .blue))
                
                Text(bundle.invoiceCountText)
                    .font(bundle.isSubscription ? .headline : .title)
                    .fontWeight(.bold)
                    .foregroundColor(bundle.isSubscription ? .purple : (bundle.isPopular ? .orange : .blue))
                
                if !bundle.isSubscription {
                    Text("Facturas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Bundle name
            Text(bundle.name)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Description
            Text(bundle.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            Spacer()
            
            // Price and purchase button
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    if let product = product {
                        let priceInfo = storeManager.getDiscountedPrice(for: product)
                        
                        if let discountedPrice = priceInfo.discountedPrice, let discountPercent = priceInfo.discountPercent {
                            // Show discounted price
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(bundle.formattedPrice)
                                        .font(.caption)
                                        .strikethrough()
                                        .foregroundColor(.secondary)
                                    
                                    Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: discountedPrice).doubleValue))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                Text("\(discountPercent)% OFF")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .cornerRadius(4)
                            }
                        } else {
                            // Show regular price
                            HStack {
                                Text(bundle.formattedPrice)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                if bundle.isSubscription {
                                    Text(bundle.subscriptionText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        Text(bundle.formattedPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: onPurchase) {
                    Group {
                        if isPurchasing && isSelected {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(bundle.isSubscription ? "Suscribirse" : "Comprar")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(bundle.isSubscription ? Color.purple : (bundle.isPopular ? Color.orange : Color.blue))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(product == nil || isPurchasing)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            bundle.isSubscription ? Color.purple : (bundle.isPopular ? Color.orange : Color.blue.opacity(0.3)),
                            lineWidth: (bundle.isSubscription || bundle.isPopular) ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    InAppPurchaseView()
}
