//
//  PurchaseHistoryView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//  Purchase history view using N1CO payment system with SwiftData and iCloud sync
//

import SwiftUI

struct PurchaseHistoryView: View {
    @StateObject private var n1coService = N1COEpayService.shared
    @StateObject private var purchaseManager = PurchaseDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Optional callback to handle "Browse Bundles" action
    var onBrowseBundles: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if n1coService.userCredits.transactions.isEmpty {
                    emptyStateView
                } else {
                    transactionsList
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Actualizar") {
                        Task {
                            await refreshPurchaseHistory()
                        }
                    }
                    .disabled(n1coService.isLoading)
                }
            }
            .refreshable {
                await refreshPurchaseHistory()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Sin Compras Registradas")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tu historial de compras aparecerá aquí una vez que adquieras paquetes de facturas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Ver Paquetes Disponibles") {
                dismiss()
                onBrowseBundles?()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Transactions List
    private var transactionsList: some View {
        List {
            // Summary Section
            Section {
                summaryCard
            }
            
            // Active Subscription Section
            if n1coService.userCredits.hasActiveSubscription {
                Section("Suscripción Activa") {
                    subscriptionCard
                }
            }
            
            // Transactions Section
            Section("Historial de Compras") {
                ForEach(n1coService.userCredits.transactions.sorted { $0.purchaseDate > $1.purchaseDate }) { transaction in
                    N1COTransactionRow(transaction: transaction)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Facturas Disponibles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if n1coService.userCredits.isSubscriptionActive {
                        Text("Ilimitadas")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    } else {
                        Text("\(n1coService.userCredits.availableInvoices)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Comprado")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(n1coService.userCredits.totalPurchased)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            if !n1coService.userCredits.isSubscriptionActive && 
               n1coService.userCredits.totalPurchased > n1coService.userCredits.availableInvoices {
                let usedCredits = n1coService.userCredits.totalPurchased - n1coService.userCredits.availableInvoices
                
                HStack {
                    Text("Facturas Utilizadas:")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(usedCredits)")
                        .fontWeight(.medium)
                }
                .font(.caption)
            }
            
            // Implementation Fee Status
            if n1coService.userCredits.hasImplementationFeePaid {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Cuenta de Producción Activada")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Subscription Card
    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.purple)
                
                Text("Enterprise Pro Unlimited")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("ACTIVA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.purple)
                    .cornerRadius(4)
            }
            
            Text("Facturas ilimitadas")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let expiryDate = n1coService.userCredits.subscriptionExpiryDate {
                Text("Renovación: \(expiryDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    private func refreshPurchaseHistory() async {
        // Reload data from SwiftData
        purchaseManager.loadUserProfile()
        // Notify N1CO service to refresh
        n1coService.objectWillChange.send()
    }
}

// MARK: - N1CO Transaction Row
struct N1COTransactionRow: View {
    let transaction: CustomStoredTransaction
    
    private var product: CustomPaymentProduct? {
        CustomPaymentProduct.allProducts.first { $0.id == transaction.productID }
    }
    
    private var transactionTypeIcon: String {
        if product?.isImplementationFee == true {
            return "gear.circle.fill"
        } else if product?.isSubscription == true {
            return "crown.circle.fill"
        } else if transaction.isRestored {
            return "arrow.clockwise.circle.fill"
        } else {
            return "purchased.circle.fill"
        }
    }
    
    private var transactionTypeColor: Color {
        if product?.isImplementationFee == true {
            return .orange
        } else if product?.isSubscription == true {
            return .purple
        } else if transaction.isRestored {
            return .blue
        } else {
            return .green
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: transactionTypeIcon)
                .foregroundColor(transactionTypeColor)
                .font(.title2)
            
            // Transaction details
            VStack(alignment: .leading, spacing: 2) {
                Text(product?.name ?? "Producto Desconocido")
                    .font(.headline)
                    .lineLimit(2)
                
                if let product = product {
                    if product.isImplementationFee {
                        Text("Activación de cuenta de producción")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if product.isSubscription {
                        Text("Suscripción - Facturas ilimitadas")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(transaction.invoiceCount) facturas")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(transaction.purchaseDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status and price
            VStack(alignment: .trailing, spacing: 2) {
                if transaction.isRestored {
                    Text("Restaurada")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                } else if product?.isSubscription == true {
                    Text("Suscripción")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                } else if product?.isImplementationFee == true {
                    Text("Activación")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Text("Comprada")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(String(format: "$%.2f", transaction.amount))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    PurchaseHistoryView()
}
