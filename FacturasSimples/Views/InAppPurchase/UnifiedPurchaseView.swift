//
//  UnifiedPurchaseView.swift
//  FacturasSimples
//
//  Created by AI Assistant
//  Unified view that allows users to choose between Apple In-App Purchases and External Web Payments
//

import SwiftUI
import StoreKit

struct UnifiedPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appleStoreManager = AppleStoreKitManager.shared
    @StateObject private var externalPaymentService = ExternalPaymentService.shared
    @StateObject private var purchaseManager = PurchaseDataManager.shared
    
    @State private var selectedPaymentMethod: PaymentMethod = .applePay
    @State private var selectedProduct: CustomPaymentProduct?
    @State private var showingExternalPayment = false
    @State private var showingPurchaseHistory = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    @State private var showingCouponInput = false
    
    // Check if we should only show Apple IAP for App Store compliance
    private var shouldUseOnlyAppleIAP: Bool {
        FeatureFlags.shared.shouldUseOnlyAppleInAppPurchases
    }
    
    // Available products based on selected payment method
    private var availableProducts: [CustomPaymentProduct] {
        if shouldUseOnlyAppleIAP {
            // Only show Apple StoreKit products for App Store compliance
            return appleStoreManager.availableProducts.compactMap { product in
                appleStoreManager.customPaymentProduct(from: product)
            }.sorted { $0.price < $1.price }
        } else {
            switch selectedPaymentMethod {
            case .applePay:
                // For Apple Pay, use Apple StoreKit products
                return appleStoreManager.availableProducts.compactMap { product in
                    appleStoreManager.customPaymentProduct(from: product)
                }.sorted { $0.price < $1.price }
                
            case .webPayment:
                // For web payment, use external products
                return externalPaymentService.availableProducts.sorted { $0.price < $1.price }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    if appleStoreManager.isLoading || externalPaymentService.isLoading {
                        ProgressView("Cargando productos...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        creditsSection
                        
                        // Coupon code section (only for Apple Pay)
                        if selectedPaymentMethod == .applePay || shouldUseOnlyAppleIAP {
                            couponCodeSection
                        }
                        
                        // Only show payment method selector if external payments are allowed
                        if !shouldUseOnlyAppleIAP {
                            paymentMethodSelector
                        }
                        
                        productsSection
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
        .sheet(isPresented: $showingExternalPayment) {
            if let product = selectedProduct {
                ExternalPaymentView(product: product) {
                    handlePaymentSuccess(for: product)
                }
            }
        }
        .sheet(isPresented: $showingPurchaseHistory) {
            PurchaseHistoryView(onBrowseBundles: {
                showingPurchaseHistory = false
            })
        }
        .alert("¡Compra Exitosa!", isPresented: $showSuccessAlert) {
            Button("OK") {
                showSuccessAlert = false
            }
        } message: {
            Text(successMessage)
        }
        .alert("Error en la Compra", isPresented: .constant(appleStoreManager.errorMessage != nil)) {
            Button("OK") {
                appleStoreManager.errorMessage = nil
            }
        } message: {
            Text(appleStoreManager.errorMessage ?? "")
        }
        .onChange(of: appleStoreManager.purchaseState) { _, state in
            handleApplePurchaseStateChange(state)
        }
        .onAppear {
            // Request products when view appears if not already loaded
            if appleStoreManager.availableProducts.isEmpty && !appleStoreManager.isLoading {
                appleStoreManager.requestProducts()
            }
        }
    }
    
    // MARK: - Purchase State Handling
    private func handleApplePurchaseStateChange(_ state: ApplePurchaseState) {
        switch state {
        case .success:
            if let product = selectedProduct {
                handlePaymentSuccess(for: product)
            }
            // Additional refresh for Apple purchases to ensure credits are updated
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                purchaseManager.loadUserProfile()
            }
        case .cancelled:
            print("🚫 User cancelled Apple Pay purchase")
        case .pending:
            successMessage = "Tu compra está siendo procesada. Te notificaremos cuando esté completa."
            showSuccessAlert = true
        case .failed(let error):
            print("❌ Apple Pay purchase failed: \(error)")
        case .idle, .processing:
            break
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Comprar Paquetes de Facturas")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Elige tu método de pago preferido para completar la compra")
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
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.green)
                
                Text("Estado de Créditos")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(purchaseManager.userProfile?.availableInvoices ?? 0) facturas disponibles")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Coupon Code Section
    private var couponCodeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.orange)
                
                Text("Código de Descuento")
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
                CouponCodeInputView(
                    storeManager: appleStoreManager,
                    selectedProduct: selectedProduct
                )
                .transition(.opacity.combined(with: .scale))
            }
            
            // Show applied discount info if available
            if let appliedDiscount = appleStoreManager.appliedDiscount,
               let selectedProduct = selectedProduct,
               let appleProduct = appleStoreManager.availableProducts.first(where: { 
                   appleStoreManager.customPaymentProduct(from: $0)?.id == selectedProduct.id 
               }) {
                AppliedDiscountView(
                    originalProduct: appleProduct,
                    discount: appliedDiscount,
                    storeManager: appleStoreManager
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: showingCouponInput)
    }
    
    // MARK: - Payment Method Selector
    private var paymentMethodSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Only show payment method selector if external payments are allowed
            if !shouldUseOnlyAppleIAP {
                Text("Método de Pago")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    PaymentMethodCard(
                        method: .applePay,
                        isSelected: selectedPaymentMethod == .applePay,
                        onTap: { selectedPaymentMethod = .applePay }
                    )
                    
                    PaymentMethodCard(
                        method: .webPayment,
                        isSelected: selectedPaymentMethod == .webPayment,
                        onTap: { selectedPaymentMethod = .webPayment }
                    )
                }
            } else {
                // For App Store compliance, only show Apple Pay option
                Text("Método de Pago: Apple In-App Purchase")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Products Section
    private var productsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Elige Tu Paquete")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if appleStoreManager.isLoading || externalPaymentService.isLoading {
                ProgressView("Cargando productos...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                VStack(spacing: 12) {
                    ForEach(availableProducts.filter { !$0.isImplementationFee }, id: \.id) { product in
                        UnifiedProductCard(
                            product: product,
                            paymentMethod: selectedPaymentMethod,
                            isPurchasing: (selectedPaymentMethod == .applePay && appleStoreManager.purchaseState == .processing) ||
                                         (selectedPaymentMethod == .webPayment && externalPaymentService.isLoading),
                            onPurchase: { handleProductSelection(product) },
                            appliedDiscount: appleStoreManager.appliedDiscount,
                            storeManager: appleStoreManager
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Purchase History Section
    private var purchaseHistorySection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingPurchaseHistory = true
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
    }
    
    // MARK: - Actions
    
    private func handleProductSelection(_ product: CustomPaymentProduct) {
        selectedProduct = product
        
        switch selectedPaymentMethod {
        case .applePay:
            handleApplePayPurchase(product)
        case .webPayment:
            showingExternalPayment = true
        }
    }
    
    private func handleApplePayPurchase(_ product: CustomPaymentProduct) {
        // Find the matching Apple StoreKit product
        guard let appleProduct = appleStoreManager.availableProducts.first(where: { skProduct in
            // Match by invoice count and price to find the correct product
            if let customProduct = appleStoreManager.customPaymentProduct(from: skProduct) {
                return customProduct.invoiceCount == product.invoiceCount && 
                       customProduct.price == product.price
            }
            return false
        }) else {
            print("❌ No matching Apple product found for: \(product.name)")
            return
        }
        
        // Check if there's an applied discount
        if appleStoreManager.appliedDiscount != nil {
            // For now, we'll handle discounts in post-processing
            // The actual discount validation should be done server-side
            appleStoreManager.purchase(appleProduct)
        } else {
            // Regular purchase
            appleStoreManager.purchase(appleProduct)
        }
    }
    
    private func handlePaymentSuccess(for product: CustomPaymentProduct) {
        successMessage = "¡Has comprado exitosamente \(product.invoiceCountText)!"
        showSuccessAlert = true
        
        // Refresh user profile to show updated credits with a slight delay
        // to ensure backend processing is complete
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            purchaseManager.loadUserProfile()
        }
        
        print("✅ Purchase successful: \(product.name)")
    }
}

// MARK: - Payment Method Enum

enum PaymentMethod: String, CaseIterable {
    case applePay = "apple_pay"
    case webPayment = "web_payment"
    
    var title: String {
        switch self {
        case .applePay:
            return "Apple Pay"
        case .webPayment:
            return "Tarjeta de Crédito"
        }
    }
    
    var description: String {
        switch self {
        case .applePay:
            return "Pago rápido y seguro con Touch ID o Face ID"
        case .webPayment:
            return "Pagar con tarjeta de crédito en nuestro portal seguro"
        }
    }
    
    var icon: String {
        switch self {
        case .applePay:
            return "apple.logo"
        case .webPayment:
            return "creditcard"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .applePay:
            return .black
        case .webPayment:
            return .blue
        }
    }
}

// MARK: - Payment Method Card

struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(isSelected ? method.accentColor : method.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: method.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : method.accentColor)
                }
                
                // Method info
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(method.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(method.accentColor)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? method.accentColor.opacity(0.6) : Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Unified Product Card

struct UnifiedProductCard: View {
    let product: CustomPaymentProduct
    let paymentMethod: PaymentMethod
    let isPurchasing: Bool
    let onPurchase: () -> Void
    let appliedDiscount: AppliedDiscount?
    let storeManager: AppleStoreKitManager
    
    // Computed property to check if discount applies to this product
    private var discountAppliesToProduct: Bool {
        guard appliedDiscount != nil else { return false }
        return storeManager.isDiscountValidForProduct(product.id)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Icon and info
            VStack(spacing: 8) {
                // Badge
                HStack {
                    if discountAppliesToProduct, let appliedDiscount = appliedDiscount {
                        Text("DESCUENTO \(Int(appliedDiscount.discountPercentage))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .scaleEffect(discountAppliesToProduct ? 1.05 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: discountAppliesToProduct)
                            .transition(.scale.combined(with: .opacity))
                    } else if let specialOffer = product.specialOfferText {
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
                    } else if product.isSubscription {
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
                    } else if product.isPopular {
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
                    Image(systemName: product.isSubscription ? "crown.fill" : "doc.text.fill")
                        .font(.title)
                        .foregroundColor(product.isSubscription ? .purple : (product.isPopular ? .orange : .blue))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(product.isSubscription ? Color.purple.opacity(0.1) : (product.isPopular ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1)))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.invoiceCountText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if !product.isSubscription {
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
                
                // Product name and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(product.description)
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
                    VStack(alignment: .trailing, spacing: 2) {
                        if discountAppliesToProduct, let appliedDiscount = appliedDiscount {
                            // Show original price crossed out
                            Text(product.formattedPrice)
                                .font(.caption)
                                .strikethrough()
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                            
                            // Show discounted price with animation
                            Text(appliedDiscount.discountedPriceFormatted ?? appliedDiscount.discountedPrice)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .scaleEffect(discountAppliesToProduct ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: discountAppliesToProduct)
                                .transition(.scale)
                            
                            // Show savings with pulse animation
                            Text("Ahorras \(appliedDiscount.savingsFormatted ?? appliedDiscount.savings)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .scaleEffect(discountAppliesToProduct ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true), value: discountAppliesToProduct)
                                .transition(.opacity)
                        } else {
                            Text(product.formattedPrice)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .transition(.opacity)
                        }
                        
                        if product.isSubscription {
                            Text(product.subscriptionText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Purchase button
                Button(action: onPurchase) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: paymentMethod == .applePay ? "apple.logo" : "link")
                            Text(paymentMethod == .applePay ? (product.isSubscription ? "Suscribirse" : "Comprar") : (product.isSubscription ? "Suscribirse" : "Comprar"))
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(width: 110, height: 40)
                    .background(
                        LinearGradient(
                            colors: product.isSubscription ? 
                                [Color.purple, Color.purple.opacity(0.8)] : 
                                (product.isPopular ? 
                                    [Color.orange, Color.red.opacity(0.8)] : 
                                    [Color.blue, Color.blue.opacity(0.8)]
                                ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(
                        color: (product.isSubscription ? Color.purple : (product.isPopular ? Color.orange : Color.blue)).opacity(0.3), 
                        radius: 4, 
                        x: 0, 
                        y: 2
                    )
                }
                .disabled(isPurchasing)
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
                                colors: discountAppliesToProduct ? 
                                    [Color.red.opacity(0.8), Color.red.opacity(0.4)] :
                                    (product.isSubscription ? 
                                        [Color.purple.opacity(0.6), Color.purple.opacity(0.3)] : 
                                        (product.isPopular ? 
                                            [Color.orange.opacity(0.6), Color.red.opacity(0.3)] : 
                                            [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]
                                        )
                                    ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: discountAppliesToProduct ? 3 : (product.isSubscription || product.isPopular ? 2 : 1)
                        )
                        .animation(.easeInOut(duration: 0.4), value: discountAppliesToProduct)
                )
                .shadow(
                    color: discountAppliesToProduct ? 
                        Color.red.opacity(0.3) :
                        Color.black.opacity(0.05),
                    radius: discountAppliesToProduct ? 12 : (product.isSubscription || product.isPopular ? 8 : 4),
                    x: 0,
                    y: discountAppliesToProduct ? 6 : (product.isSubscription || product.isPopular ? 4 : 2)
                )
                .animation(.easeInOut(duration: 0.4), value: discountAppliesToProduct)
        )
    }
}

// MARK: - Coupon Code Input View

struct CouponCodeInputView: View {
    @ObservedObject var storeManager: AppleStoreKitManager
    let selectedProduct: CustomPaymentProduct?
    
    @State private var couponCode = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.orange)
                
                TextField("Ingresa tu código de descuento", text: $couponCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .focused($isInputFocused)
                    .onSubmit {
                        applyCouponCode()
                    }
                
                Button(action: applyCouponCode) {
                    if storeManager.discountValidationState == .validating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 20, height: 20)
                    } else {
                        Text("Aplicar")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(couponCode.isEmpty || storeManager.discountValidationState == .validating)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(couponCode.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                )
                .foregroundColor(.white)
            }
            
            // Validation feedback
            switch storeManager.discountValidationState {
            case .valid:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("¡Código aplicado correctamente!")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
                
            case .invalid:
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Código no válido o expirado")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                
            case .expired:
                HStack {
                    Image(systemName: "clock.circle.fill")
                        .foregroundColor(.orange)
                    Text("Este código ha expirado")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                
            case .validating:
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Validando código...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
            case .idle:
                EmptyView()
            }
            
            // Clear button if code is applied
            if storeManager.discountValidationState == .valid {
                Button(action: {
                    couponCode = ""
                    storeManager.clearCouponCode()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Quitar código")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            couponCode = storeManager.currentCouponCode
        }
    }
    
    private func applyCouponCode() {
        guard !couponCode.isEmpty,
              let selectedProduct = selectedProduct,
              let appleProduct = storeManager.availableProducts.first(where: { 
                  storeManager.customPaymentProduct(from: $0)?.id == selectedProduct.id 
              }) else { return }
        
        isInputFocused = false
        storeManager.validateCouponCode(couponCode, for: appleProduct)
    }
}

// MARK: - Applied Discount View

struct AppliedDiscountView: View {
    let originalProduct: SKProduct
    let discount: AppliedDiscount
    let storeManager: AppleStoreKitManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.green)
                
                Text("Descuento Aplicado")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
                
                Button(action: {
                    storeManager.clearAppliedDiscount()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Código:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(discount.couponCode)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Precio Original:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatPrice(originalProduct.price, locale: originalProduct.priceLocale))
                            .font(.subheadline)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Precio con Descuento:")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        
                        Text(discount.discountedPriceFormatted ?? discount.discountedPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                // Discount details
                HStack {
                    Text(getDiscountDescription())
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if let savings = calculateSavings() {
                        Text("Ahorras \(savings)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatPrice(_ price: NSDecimalNumber, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: price) ?? "$\(price)"
    }
    
    private func getDiscountDescription() -> String {
        return "Descuento del \(Int(discount.discountPercentage))%"
    }
    
    private func calculateSavings() -> String? {
        return discount.savingsFormatted ?? discount.savings
    }
}

#Preview {
    UnifiedPurchaseView()
}
