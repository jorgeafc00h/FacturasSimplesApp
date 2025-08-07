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
        GeometryReader { geometry in
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.9, green: 0.4, blue: 0.6),   // Pink
                        Color(red: 0.8, green: 0.3, blue: 0.5),   // Deeper pink
                        Color(red: 0.7, green: 0.2, blue: 0.4)    // Deep red-pink
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Close button
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Header Section
                        elegantHeaderSection
                        
                        // Feature illustration with dots
                        featureIllustrationSection
                        
                        // Credits display (if available)
                        if let profile = purchaseManager.userProfile, 
                           let availableInvoices = profile.availableInvoices,
                           availableInvoices > 0 {
                            creditsDisplayBanner(availableInvoices)
                        }
                        
                        // Main Products Section
                        if appleStoreManager.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .foregroundColor(.white)
                                
                                Text("Cargando productos...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else if availableProducts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("No se pudieron cargar los productos")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                
                                if let error = appleStoreManager.errorMessage {
                                    Text(error)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 4)
                                }
                                
                                Button("Reintentar") {
                                    appleStoreManager.requestProducts()
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.4))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            // Subscriptions Section
                            elegantProductsSection
                            
                            // Consumables Section
                            elegantConsumablesSection
                        }
                        
                        // CTA Button
                        elegantCTASection
                        
                        // Footer links
                        footerLinksSection
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView()
            }
        }
        .onAppear {
            print("🏪 UnifiedPurchaseView: Appearing, requesting products...")
            appleStoreManager.requestProducts()
            
            // Also load user profile to ensure we have latest credits info
            Task {
                await purchaseManager.loadUserProfile()
            }
        }
        .onChange(of: appleStoreManager.purchaseState) { _, newState in
            switch newState {
            case .success:
                if let product = selectedProduct {
                    // Create more specific success messages
                    switch product.productIdentifier {
                    case "com.kandangalabs.facturas.bundle25":
                        successMessage = "¡Perfecto! Has adquirido 25 facturas para tu negocio. Ya puedes empezar a facturar."
                    case "com.kandangalabs.facturas.bundle50":
                        successMessage = "¡Excelente! Has adquirido 50 facturas. Perfecto para pequeñas empresas en crecimiento."
                    case "com.kandangalabs.facturas.bundle100":
                        successMessage = "¡Fantástico! Has adquirido 100 facturas. La mejor opción para empresas en expansión."
                    case "com.kandangalabs.facturas.bundle250":
                        successMessage = "¡Increíble! Has adquirido 250 facturas. Ideal para empresas de alto volumen."
                    case "com.kandangalabs.facturas.enterprise_pro_unlimited_monthly":
                        successMessage = "¡Bienvenido a Enterprise Pro! Ahora tienes facturación ilimitada cada mes."
                    case "com.kandangalabs.facturas.enterprise_pro_unlimited_anual":
                        successMessage = "¡Bienvenido a Enterprise Pro Anual! Disfruta de facturación ilimitada todo el año con gran ahorro."
                    default:
                        successMessage = "¡Compra exitosa! Has adquirido \(product.localizedTitle)"
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSuccessAlert = true
                    }
                    
                    // Refresh user profile to show updated credits
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                        await purchaseManager.loadUserProfile()
                    }
                }
            case .failed:
                successMessage = appleStoreManager.errorMessage ?? "No se pudo completar la compra. Inténtalo de nuevo."
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccessAlert = true
                }
            default:
                break
            }
        }
        .overlay(
            // Custom elegant success overlay
            Group {
                if showSuccessAlert {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        ElegantSuccessView(
                            message: successMessage,
                            onDismiss: {
                                showSuccessAlert = false
                                if successMessage.contains("prueba gratuita") || successMessage.contains("Compra exitosa") {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        dismiss()
                                    }
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        )
    }
    
    // MARK: - Purchase Logic
    private func handleProductSelection(_ product: SKProduct) {
        print("🛒 Attempting to purchase: \(product.productIdentifier)")
        print("📦 Product details: \(product.localizedTitle) - \(product.price)")
        
        selectedProduct = product
        appleStoreManager.purchase(product)
    }
    
    // MARK: - Free Trial Logic
    private func activateFreeTrial() {
        // Add 15 invoices as free trial
        purchaseManager.activateFreeTrial(with: 15)
        
        // Show success message
        successMessage = "¡Bienvenido! Tu prueba gratuita está activa. Tienes 15 facturas para explorar todas las funciones profesionales."
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccessAlert = true
        }
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    // MARK: - Elegant View Sections
    
    @State private var selectedPlan: String = "annual"
    @State private var selectedConsumable: String? = nil
    @State private var showConsumables: Bool = false
    
    private var elegantHeaderSection: some View {
        VStack(spacing: 20) {
            Text(purchaseManager.userProfile?.hasClaimedFreeTrial == true ? "Elige Tu Plan" : "Actualizar a Pro")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(purchaseManager.userProfile?.hasClaimedFreeTrial == true ? 
                 "Selecciona el plan perfecto para tu negocio." : 
                 "Obtén 15 facturas gratis y desbloquea el poder completo de la facturación profesional.")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(4)
        }
    }
    
    private var featureIllustrationSection: some View {
        VStack(spacing: 24) {
            // Simple icon illustration
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            
            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index == 2 ? Color.white : Color.white.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    private func creditsDisplayBanner(_ credits: Int) -> some View {
        HStack {
            Image(systemName: "creditcard.fill")
                .foregroundColor(.white.opacity(0.9))
                .font(.title3)
            
            Text("Tienes \(credits) facturas disponibles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
    
    private var elegantProductsSection: some View {
        VStack(spacing: 16) {
            // Annual Plan (Recommended)
            ElegantPlanCard(
                title: "Plan Anual", 
                trial: purchaseManager.userProfile?.hasClaimedFreeTrial != true ? "15 facturas gratis, luego" : "",
                price: "$999.99/año",
                savings: "Ahorra $200",
                isSelected: selectedPlan == "annual",
                isRecommended: true
            ) {
                selectedPlan = "annual"
            }
            
            // Monthly Plan
            ElegantPlanCard(
                title: "Plan Mensual",
                trial: "",
                price: "$99.99/mes",
                savings: nil,
                isSelected: selectedPlan == "monthly", 
                isRecommended: false
            ) {
                selectedPlan = "monthly"
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var elegantConsumablesSection: some View {
        VStack(spacing: 20) {
            // Section divider and title
            VStack(spacing: 16) {
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                    Text("O compra créditos")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showConsumables.toggle()
                    }
                }) {
                    HStack {
                        Text(showConsumables ? "Ocultar paquetes" : "Ver paquetes de créditos")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: showConsumables ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            
            if showConsumables {
                VStack(spacing: 16) {
                    // Paquete Esencial (25 facturas - $4.90)
                    ElegantConsumableCard(
                        title: "Paquete Esencial",
                        subtitle: "25 facturas",
                        price: "$4.90",
                        description: "Ideal para emprendedores y pequeños negocios",
                        isSelected: selectedConsumable == "bundle25",
                        isPopular: false
                    ) {
                        selectedConsumable = "bundle25"
                    }
                    
                    // Paquete Inicial (50 facturas - $9.99)
                    ElegantConsumableCard(
                        title: "Paquete Inicial",
                        subtitle: "50 facturas",
                        price: "$9.99",
                        description: "Perfecto para pequeñas empresas en crecimiento",
                        isSelected: selectedConsumable == "bundle50",
                        isPopular: false
                    ) {
                        selectedConsumable = "bundle50"
                    }
                    
                    // Paquete Profesional (100 facturas - $15.00) - Popular
                    ElegantConsumableCard(
                        title: "Paquete Profesional",
                        subtitle: "100 facturas", 
                        price: "$15.00",
                        description: "La mejor opción para empresas en expansión",
                        isSelected: selectedConsumable == "bundle100",
                        isPopular: true
                    ) {
                        selectedConsumable = "bundle100"
                    }
                    
                    // Paquete Empresarial (250 facturas - $29.99)
                    ElegantConsumableCard(
                        title: "Paquete Empresarial",
                        subtitle: "250 facturas",
                        price: "$29.99", 
                        description: "Para empresas de alto volumen y facturación intensa",
                        isSelected: selectedConsumable == "bundle250",
                        isPopular: false
                    ) {
                        selectedConsumable = "bundle250"
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.3), value: showConsumables)
    }
    
    private var elegantCTASection: some View {
        VStack(spacing: 16) {
            if purchaseManager.userProfile?.hasClaimedFreeTrial != true {
                Text("15 facturas gratis, luego $999.99/año")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Button(action: {
                print("🔘 CTA Button tapped")
                
                if let selectedConsumable = selectedConsumable {
                    // Handle consumable purchase
                    let productId = "com.kandangalabs.facturas.\(selectedConsumable)"
                    print("🛒 Looking for consumable product: \(productId)")
                    
                    if let product = availableProducts.first(where: { $0.productIdentifier == productId }) {
                        print("✅ Found consumable product: \(product.localizedTitle)")
                        handleProductSelection(product)
                    } else {
                        print("❌ Consumable product not found among available products:")
                        for product in availableProducts {
                            print("   - \(product.productIdentifier): \(product.localizedTitle)")
                        }
                        
                        // Show error
                        appleStoreManager.errorMessage = "Producto no disponible. Por favor intenta más tarde."
                    }
                } else if purchaseManager.userProfile?.hasClaimedFreeTrial == true {
                    // Handle subscription purchase
                    let subscriptionId = selectedPlan == "annual" ? 
                        "com.kandangalabs.facturas.enterprise_pro_unlimited_anual" :
                        "com.kandangalabs.facturas.enterprise_pro_unlimited_monthly"
                    
                    print("🛒 Looking for subscription product: \(subscriptionId)")
                    
                    if let product = availableProducts.first(where: { $0.productIdentifier == subscriptionId }) {
                        print("✅ Found subscription product: \(product.localizedTitle)")
                        handleProductSelection(product)
                    } else {
                        print("❌ Subscription product not found among available products:")
                        for product in availableProducts {
                            print("   - \(product.productIdentifier): \(product.localizedTitle)")
                        }
                        
                        // Show error
                        appleStoreManager.errorMessage = "Suscripción no disponible. Por favor intenta más tarde."
                    }
                } else {
                    // Activate free trial
                    print("🎁 Activating free trial")
                    activateFreeTrial()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: selectedConsumable != nil ? "creditcard.fill" : (purchaseManager.userProfile?.hasClaimedFreeTrial == true ? "crown.fill" : "gift.fill"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(getButtonText())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.9, green: 0.4, blue: 0.6),
                                    Color(red: 0.8, green: 0.3, blue: 0.5),
                                    Color(red: 0.7, green: 0.2, blue: 0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color(red: 0.9, green: 0.4, blue: 0.6).opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var footerLinksSection: some View {
        HStack(spacing: 24) {
            Button("Restaurar compras") {
                Task {
                    await appleStoreManager.restorePurchases()
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            
            if let termsURL = URL(string: "https://www.facturassimples.pro/terminos-y-condiciones") {
                Link("Términos y condiciones", destination: termsURL)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getButtonText() -> String {
        if let selectedConsumable = selectedConsumable {
            switch selectedConsumable {
            case "bundle25":
                return "Comprar 25 facturas"
            case "bundle50":
                return "Comprar 50 facturas"
            case "bundle100":
                return "Comprar 100 facturas"
            case "bundle250":
                return "Comprar 250 facturas"
            default:
                return "Comprar paquete"
            }
        } else if purchaseManager.userProfile?.hasClaimedFreeTrial == true {
            return selectedPlan == "annual" ? "Suscribirse Anual" : "Suscribirse Mensual"
        } else {
            return "Pruébalo Gratis"
        }
    }
}

// MARK: - Elegant Plan Card

struct ElegantPlanCard: View {
    let title: String
    let trial: String
    let price: String
    let savings: String?
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !trial.isEmpty {
                        Text(trial)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(price)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    if let savings = savings {
                        Text(savings)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Simple selection indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                        
                        // Checkmark in the center
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.4))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.white.opacity(0.8) : 
                                (isRecommended ? Color(red: 0.9, green: 0.4, blue: 0.6) : Color.white.opacity(0.3)), 
                                lineWidth: isSelected ? 2 : (isRecommended ? 2 : 1)
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Elegant Consumable Card (Horizontal Layout)

struct ElegantConsumableCard: View {
    let title: String
    let subtitle: String
    let price: String
    let description: String
    let isSelected: Bool
    let isPopular: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Popular badge (similar to subscription cards)
                if isPopular {
                    HStack {
                        Spacer()
                        Text("Popular")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(red: 0.9, green: 0.4, blue: 0.6), Color(red: 0.8, green: 0.3, blue: 0.5)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(red: 0.9, green: 0.4, blue: 0.6).opacity(0.4), radius: 6, x: 0, y: 3)
                        Spacer()
                    }
                    .padding(.top, -8)
                    .padding(.bottom, 16)
                }
                
                // Main horizontal content
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Pago único")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                        
                        Text(description)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(2)
                            .lineSpacing(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 16) {
                        // Price with enhanced styling
                        Text(price)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        
                        // Enhanced selection indicator with glow
                        ZStack {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: isSelected ? [.white, .white.opacity(0.8)] : [.white.opacity(0.6), .white.opacity(0.4)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isSelected ? 3 : 2
                                )
                                .frame(width: 28, height: 28)
                                .shadow(color: isSelected ? .white.opacity(0.4) : .clear, radius: isSelected ? 4 : 0)
                            
                            if isSelected {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.white, .white.opacity(0.9)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 16, height: 16)
                                    .shadow(color: .white.opacity(0.3), radius: 2)
                                
                                // Enhanced checkmark
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.4))
                            }
                        }
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    isSelected ? 
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.25),
                            Color.black.opacity(0.15),
                            Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.10)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isSelected ? 
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.9), .white.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            (isPopular ? 
                             LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.9, green: 0.4, blue: 0.6), Color(red: 0.8, green: 0.3, blue: 0.5)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                             ) :
                             LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                             )),
                            lineWidth: isSelected ? 2.5 : (isPopular ? 2 : 1.5)
                        )
                )
        )
        .shadow(
            color: isSelected ? .white.opacity(0.2) : (isPopular ? Color(red: 0.9, green: 0.4, blue: 0.6).opacity(0.3) : Color.black.opacity(0.1)),
            radius: isSelected ? 12 : (isPopular ? 8 : 4),
            x: 0,
            y: isSelected ? 6 : (isPopular ? 4 : 2)
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Elegant Success View

struct ElegantSuccessView: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var checkmarkOpacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Success icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.9, green: 0.4, blue: 0.6),
                                Color(red: 0.7, green: 0.2, blue: 0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(red: 0.9, green: 0.4, blue: 0.6).opacity(0.4), radius: 20, x: 0, y: 8)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
            }
            
            // Success message
            VStack(spacing: 12) {
                Text(message.contains("prueba gratuita") ? "¡Bienvenido!" : "¡Compra exitosa!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            // Close button
            Button(action: onDismiss) {
                Text("Continuar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.8, green: 0.3, blue: 0.5),
                            Color(red: 0.9, green: 0.4, blue: 0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
        )
        .padding(.horizontal, 40)
        .onAppear {
            // Animate checkmark
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                checkmarkOpacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
                checkmarkScale = 1.0
            }
        }
    }
}


#Preview {
    UnifiedPurchaseView()
}
