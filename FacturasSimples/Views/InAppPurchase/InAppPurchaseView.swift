//
//  InAppPurchaseView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//  Updated on 1/30/25 - App Store compliant version with Apple In-App Purchases only
//

import SwiftUI
import StoreKit

struct InAppPurchaseView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @StateObject private var promoCodeService = PromoCodeService()
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showingPromoCodeView = false
    @State private var promoCodeText = ""
    @State private var showingPromoInput = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.bottom, 24)
                    
                    // Pricing Cards
                    VStack(spacing: 20) {
                        // Paquete Inicial - 50 facturas
                        PricingCard(
                            title: "50 facturas",
                            subtitle: "Facturas",
                            packageName: "Paquete Inicial",
                            description: "Perfecto para pequeñas empresas",
                            price: "$9.99",
                            color: .blue,
                            isPopular: false,
                            icon: "doc.text",
                            productId: "com.facturassimples.paquete_inicial"
                        )
                        
                        // Paquete Profesional - 100 facturas (POPULAR)
                        PricingCard(
                            title: "100 facturas",
                            subtitle: "Facturas",
                            packageName: "Paquete Profesional",
                            description: "La mejor opción para empresas en crecimiento",
                            price: "$15.00",
                            color: .orange,
                            isPopular: true,
                            icon: "doc.text.fill",
                            productId: "com.facturassimples.paquete_profesional"
                        )
                        
                        // Paquete Empresarial - 250 facturas
                        PricingCard(
                            title: "250 facturas",
                            subtitle: "Facturas",
                            packageName: "Paquete Empresarial",
                            description: "Para empresas de alto volumen",
                            price: "$29.99",
                            color: .blue,
                            isPopular: false,
                            icon: "building.2",
                            productId: "com.facturassimples.paquete_empresarial"
                        )
                        
                        // Subscription - Facturas ilimitadas
                        PricingCard(
                            title: "Facturas ilimitadas",
                            subtitle: "Ilimitadas",
                            packageName: "Enterprise Pro Unlimited",
                            description: "Suscripción mensual con facturación ilimitada para empresas grandes",
                            price: "$99.99",
                            color: .purple,
                            isPopular: false,
                            icon: "crown",
                            productId: "com.facturassimples.subscription_unlimited",
                            isSubscription: true,
                            buttonText: "Suscribirse"
                        )
                        
                        // Annual Subscription with savings badge
                        PricingCard(
                            title: "Facturas ilimitadas",
                            subtitle: "Ilimitadas",
                            packageName: "Enterprise Pro Unlimited",
                            description: "Suscripción anual con facturación ilimitada para empresas grandes",
                            price: "$999.99",
                            color: .purple,
                            isPopular: false,
                            icon: "crown",
                            productId: "com.facturassimples.subscription_unlimited_annual",
                            isSubscription: true,
                            buttonText: "Suscribirse",
                            savingsText: "AHORRA HASTA $200"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Promo Code Section
                    promoCodeSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Restore Purchases
                    restorePurchasesSection
                        .padding(.top, 24)
                    
                    // Terms and Privacy
                    termsSection
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Elige Tu Paquete")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                Task {
                    await storeManager.requestProducts()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Elige tu paquete ideal")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Facturación profesional para tu negocio")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var restorePurchasesSection: some View {
        Button("Restaurar Compras") {
            Task {
                await storeManager.restorePurchases()
            }
        }
        .foregroundColor(.blue)
    }
    
    private var promoCodeSection: some View {
        VStack(spacing: 16) {
            // Promo Code Input
            VStack(spacing: 12) {
                HStack {
                    Text("¿Tienes un código promocional?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        showingPromoInput.toggle()
                    }) {
                        Image(systemName: showingPromoInput ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }
                }
                
                if showingPromoInput {
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
                        
                        Button("Ver Códigos Promocionales") {
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
        }
        .sheet(isPresented: $showingPromoCodeView) {
            PromoCodeView()
        }
    }
    
    private func applyPromoCode() async {
        let success = await promoCodeService.validateAndApplyPromoCode(promoCodeText)
        if success {
            promoCodeText = ""
            showingPromoInput = false
        }
    }
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link("Términos de Uso", destination: URL(string: "https://yourapp.com/terms")!)
                Link("Política de Privacidad", destination: URL(string: "https://yourapp.com/privacy")!)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

struct PricingCard: View {
    let title: String
    let subtitle: String
    let packageName: String
    let description: String
    let price: String
    let color: Color
    let isPopular: Bool
    let icon: String
    let productId: String
    let isSubscription: Bool
    let buttonText: String
    let savingsText: String?
    
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var isPurchasing = false
    
    init(title: String, subtitle: String, packageName: String, description: String, price: String, color: Color, isPopular: Bool, icon: String, productId: String, isSubscription: Bool = false, buttonText: String = "Comprar", savingsText: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.packageName = packageName
        self.description = description
        self.price = price
        self.color = color
        self.isPopular = isPopular
        self.icon = icon
        self.productId = productId
        self.isSubscription = isSubscription
        self.buttonText = buttonText
        self.savingsText = savingsText
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Badge Container with proper spacing
            VStack(spacing: 4) {
                // Popular Badge
                if isPopular {
                    HStack {
                        Spacer()
                        Text("POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(color)
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
                
                // Subscription Badge
                if isSubscription {
                    HStack {
                        Spacer()
                        Text("SUSCRIPCIÓN")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(color)
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
                
                // Savings Badge
                if let savingsText = savingsText {
                    HStack {
                        Spacer()
                        Text(savingsText)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
            }
            .padding(.bottom, isPopular || isSubscription || savingsText != nil ? 8 : 0)
            
            // Card Content with improved border
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    // Icon and Title Section
                    HStack(spacing: 12) {
                        // Icon with background
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.opacity(0.15))
                                .frame(width: 52, height: 52)
                            
                            Image(systemName: icon)
                                .foregroundColor(color)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        // Text Content
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(packageName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.top, 2)
                            
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                    
                    // Price and Button Section
                    VStack(alignment: .trailing, spacing: 12) {
                        Text(price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            purchaseProduct()
                        }) {
                            HStack(spacing: 4) {
                                if isPurchasing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Text(buttonText)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(color)
                            .clipShape(Capsule())
                        }
                        .disabled(isPurchasing)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPopular ? 
                        LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isPopular ? 2 : 1
                    )
            )
            .shadow(
                color: isPopular ? color.opacity(0.3) : Color.black.opacity(0.08), 
                radius: isPopular ? 16 : 12, 
                x: 0, 
                y: isPopular ? 8 : 4
            )
        }
    }
    
    private func purchaseProduct() {
        isPurchasing = true
        
        // Find the product from StoreKit
        if let product = storeManager.products.first(where: { $0.productIdentifier == productId }) {
            Task {
                await storeManager.purchase(product)
                isPurchasing = false
            }
        } else {
            // Fallback: simulate purchase for now
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                isPurchasing = false
            }
        }
    }
}

#Preview {
    InAppPurchaseView()
}
