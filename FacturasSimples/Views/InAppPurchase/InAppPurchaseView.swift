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
    @EnvironmentObject var storeManager: StoreKitManager
    @State private var selectedBundle: InvoiceBundle?
    @State private var showPromoCodeView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    if storeManager.isLoading {
                        ProgressView("Cargando productos...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        creditsSection
                    
                        if storeManager.promoCodeService.userPromoBenefits.hasActivePromoBenefits || storeManager.promoCodeService.getCurrentDiscountPercentage() != nil {
                            promoBenefitsSection
                        }
                    
                        purchaseOptionsSection
                        promoCodeSection
                    }
                    
                    restoreSection
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
        VStack(spacing: 20) {
            HStack {
                Text("Elige Tu Paquete")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(InvoiceBundle.allBundles.filter{ !$0.isImplementationFee}, id: \.id) { bundle in
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
            
            Text("Obtén facturas gratuitas, descuentos especiales o acceso premium, al comprar de subscripciones anuales")
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
        HStack(spacing: 16) {
            // Left side - Icon and info
            VStack(spacing: 8) {
                // Badge
                HStack {
                    if let specialOffer = bundle.specialOfferText {
                        Text(specialOffer)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    } else if bundle.isSubscription {
                        Text("SUSCRIPCIÓN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    } else if bundle.isPopular {
                        Text("POPULAR")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.red.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    Spacer()
                }
                
                // Icon and count
                HStack(spacing: 12) {
                    Image(systemName: bundle.isSubscription ? "crown.fill" : "doc.text.fill")
                        .font(.title)
                        .foregroundColor(bundle.isSubscription ? .purple : (bundle.isPopular ? .orange : .blue))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(bundle.isSubscription ? Color.purple.opacity(0.1) : (bundle.isPopular ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1)))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bundle.invoiceCountText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if !bundle.isSubscription {
                            Text("Facturas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Ilimitadas")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    Spacer()
                }
                
                // Bundle name and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(bundle.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(bundle.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Right side - Price and purchase button
            VStack(spacing: 12) {
                // Price display
                VStack(alignment: .trailing, spacing: 4) {
                    if let product = product {
                        let priceInfo = storeManager.getDiscountedPrice(for: product)
                        
                        if let discountedPrice = priceInfo.discountedPrice, let discountPercent = priceInfo.discountPercent {
                            // Show discounted price
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(bundle.formattedPrice)
                                    .font(.caption)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                
                                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: discountedPrice).doubleValue))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                
                                Text("\(discountPercent)% OFF")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(8)
                            }
                        } else {
                            // Show regular price
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(bundle.formattedPrice)
                                    .font(.title3)
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
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Purchase button
                Button(action: onPurchase) {
                    HStack {
                        if isPurchasing && isSelected {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text(bundle.isSubscription ? "Suscribirse" : "Comprar")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(width: 100, height: 40)
                    .background(
                        LinearGradient(
                            colors: bundle.isSubscription ? 
                                [Color.purple, Color.purple.opacity(0.8)] : 
                                (bundle.isPopular ? 
                                    [Color.orange, Color.red.opacity(0.8)] : 
                                    [Color.blue, Color.blue.opacity(0.8)]
                                ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: (bundle.isSubscription ? Color.purple : (bundle.isPopular ? Color.orange : Color.blue)).opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(product == nil || isPurchasing)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: bundle.isSubscription ? 
                                    [Color.purple.opacity(0.6), Color.purple.opacity(0.3)] : 
                                    (bundle.isPopular ? 
                                        [Color.orange.opacity(0.6), Color.red.opacity(0.3)] : 
                                        [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]
                                    ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: bundle.isSubscription || bundle.isPopular ? 2 : 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: bundle.isSubscription || bundle.isPopular ? 8 : 4,
                    x: 0,
                    y: bundle.isSubscription || bundle.isPopular ? 4 : 2
                )
        )
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    InAppPurchaseView()
        .environmentObject(StoreKitManager())
}
