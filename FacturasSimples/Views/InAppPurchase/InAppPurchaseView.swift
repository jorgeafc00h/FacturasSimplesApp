//
//  InAppPurchaseView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//  Updated on 1/14/25 - Migrated from Apple StoreKit to N1CO Epay custom credit card payments
//

import SwiftUI

struct InAppPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paymentService = N1COEpayService.shared
    @State private var selectedProduct: CustomPaymentProduct?
    @State private var showingCreditCardInput = false
    @State private var showPurchaseHistory = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    if paymentService.isLoading {
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
        .sheet(isPresented: $showingCreditCardInput) {
            if let product = selectedProduct {
                CreditCardInputView(product: product) {
                    handlePaymentSuccess()
                }
            }
        }
        .sheet(isPresented: $showPurchaseHistory) {
            CustomPurchaseHistoryView()
        }
        .alert("¡Pago Exitoso!", isPresented: $showSuccessAlert) {
            Button("OK") {
                showSuccessAlert = false
            }
        } message: {
            Text(successMessage)
        }
        .alert("Error de Pago", isPresented: .constant(paymentService.errorMessage != nil)) {
            Button("OK") {
                paymentService.errorMessage = nil
            }
        } message: {
            Text(paymentService.errorMessage ?? "")
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
                Image(systemName: paymentService.userCredits.isSubscriptionActive ? "crown.fill" : "creditcard.fill")
                    .foregroundColor(paymentService.userCredits.isSubscriptionActive ? .orange : .green)
                
                Text("Estado de Créditos")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(paymentService.userCredits.creditsText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if paymentService.userCredits.isSubscriptionActive {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                        Text("Suscripción activa")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
                
                if paymentService.userCredits.hasImplementationFeePaid {
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
        .background((paymentService.userCredits.isSubscriptionActive ? Color.orange : Color.green).opacity(0.1))
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
                ForEach(paymentService.availableProducts.filter { !$0.isImplementationFee }, id: \.id) { product in
                    CustomPurchaseBundleCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isPurchasing: paymentService.purchaseState == .processing,
                        onPurchase: {
                            selectedProduct = product
                            showingCreditCardInput = true
                        }
                    )
                }
                
                // Implementation Fee (if not paid)
                if !paymentService.userCredits.hasImplementationFeePaid,
                   let implementationFee = paymentService.availableProducts.first(where: { $0.isImplementationFee }) {
                    
                    CustomPurchaseBundleCard(
                        product: implementationFee,
                        isSelected: selectedProduct?.id == implementationFee.id,
                        isPurchasing: paymentService.purchaseState == .processing,
                        onPurchase: {
                            selectedProduct = implementationFee
                            showingCreditCardInput = true
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
                showPurchaseHistory = true
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

// MARK: - Custom Purchase Bundle Card
struct CustomPurchaseBundleCard: View {
    let product: CustomPaymentProduct
    let isSelected: Bool
    let isPurchasing: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Icon and info
            VStack(spacing: 8) {
                // Badge
                HStack {
                    if let specialOffer = product.specialOfferText {
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
                    } else if product.isImplementationFee {
                        Text("REQUERIDO")
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
                    }
                    Spacer()
                }
                
                // Icon and count
                HStack(spacing: 12) {
                    Image(systemName: product.isSubscription ? "crown.fill" : (product.isImplementationFee ? "gear.badge" : "doc.text.fill"))
                        .font(.title)
                        .foregroundColor(product.isSubscription ? .purple : (product.isPopular ? .orange : (product.isImplementationFee ? .red : .blue)))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(product.isSubscription ? Color.purple.opacity(0.1) : (product.isPopular ? Color.orange.opacity(0.1) : (product.isImplementationFee ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.invoiceCountText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if product.isImplementationFee {
                            Text("Activación")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if !product.isSubscription {
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
                        Text(product.formattedPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
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
                        if isPurchasing && isSelected {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "creditcard.fill")
                            Text(product.isSubscription ? "Suscribirse" : "Comprar")
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
                                    (product.isImplementationFee ?
                                        [Color.red, Color.red.opacity(0.8)] :
                                        [Color.blue, Color.blue.opacity(0.8)]
                                    )
                                ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: (product.isSubscription ? Color.purple : (product.isPopular ? Color.orange : (product.isImplementationFee ? Color.red : Color.blue))).opacity(0.3), radius: 4, x: 0, y: 2)
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
                                colors: product.isSubscription ? 
                                    [Color.purple.opacity(0.6), Color.purple.opacity(0.3)] : 
                                    (product.isPopular ? 
                                        [Color.orange.opacity(0.6), Color.red.opacity(0.3)] : 
                                        (product.isImplementationFee ?
                                            [Color.red.opacity(0.6), Color.red.opacity(0.3)] :
                                            [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]
                                        )
                                    ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: product.isSubscription || product.isPopular || product.isImplementationFee ? 2 : 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: product.isSubscription || product.isPopular || product.isImplementationFee ? 8 : 4,
                    x: 0,
                    y: product.isSubscription || product.isPopular || product.isImplementationFee ? 4 : 2
                )
        )
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Custom Purchase History View
struct CustomPurchaseHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseDataManager.shared
    
    var body: some View {
        NavigationView {
            List {
                if purchaseManager.recentTransactions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Sin Historial de Compras")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Tus compras aparecerán aquí una vez que realices tu primera transacción")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(purchaseManager.recentTransactions) { transaction in
                        SwiftDataTransactionRow(transaction: transaction)
                    }
                }
                
                // Analytics Section
                if !purchaseManager.recentTransactions.isEmpty {
                    Section("Estadísticas") {
                        HStack {
                            Text("Total Gastado")
                            Spacer()
                            Text("$\(String(format: "%.2f", purchaseManager.getTotalSpent()))")
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Total de Transacciones")
                            Spacer()
                            Text("\(purchaseManager.recentTransactions.count)")
                                .fontWeight(.bold)
                        }
                        
                        if let profile = purchaseManager.userProfile {
                            HStack {
                                Text("Facturas Consumidas")
                                Spacer()
                                Text("\(profile.consumptions?.count ?? 0)")
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Historial de Compras")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - SwiftData Transaction Row
struct SwiftDataTransactionRow: View {
    let transaction: PurchaseTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: (transaction.isSubscription ?? false) ? "crown.fill" : ((transaction.productID ?? "").contains("implementation") ? "gear.badge" : "doc.text.fill"))
                .font(.title2)
                .foregroundColor((transaction.isSubscription ?? false) ? .purple : ((transaction.productID ?? "").contains("implementation") ? .red : .blue))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill((transaction.isSubscription ?? false) ? Color.purple.opacity(0.1) : ((transaction.productID ?? "").contains("implementation") ? Color.red.opacity(0.1) : Color.blue.opacity(0.1)))
                )
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.productName ?? "Unknown Product")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(DateFormatter.transactionDateFormatter.string(from: transaction.purchaseDate ?? Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if (transaction.invoiceCount ?? 0) > 0 {
                    Text("\(transaction.invoiceCount) facturas")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(statusColor(for: transaction.status ?? "Unknown"))
                        .frame(width: 8, height: 8)
                    Text((transaction.status ?? "Unknown").capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount and details
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", transaction.amount ?? 0.0))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if (transaction.isRestored ?? false) {
                    Text("Restaurado")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if let authCode = transaction.authorizationCode {
                    Text("Auth: \(authCode)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "completed", "succeeded":
            return .green
        case "pending":
            return .orange
        case "failed":
            return .red
        case "refunded":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let transactionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
#Preview {
    InAppPurchaseView()
}
