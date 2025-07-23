//
//
//  PurchaseHistoryView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//  Purchase history view for external payment system
//

import SwiftUI

struct PurchaseHistoryView: View {
    @StateObject private var purchaseManager = PurchaseDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Optional callback to handle "Browse Bundles" action
    var onBrowseBundles: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if purchaseManager.recentTransactions.isEmpty {
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
            }
        }
        .task {
            purchaseManager.loadRecentTransactions()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "creditcard.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("Sin Compras Registradas")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Cuando realices compras de paquetes de facturas, aparecerán aquí.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let onBrowseBundles = onBrowseBundles {
                Button("Explorar Paquetes") {
                    onBrowseBundles()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Transactions List
    private var transactionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(purchaseManager.recentTransactions.sorted(by: { ($0.purchaseDate ?? Date()) > ($1.purchaseDate ?? Date()) })) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
            .padding()
        }
    }
}

// MARK: - Transaction Row View
struct TransactionRowView: View {
    let transaction: PurchaseTransaction
    
    private var transactionStatusColor: Color {
        switch transaction.status?.lowercased() ?? "" {
        case "completed", "success", "successful":
            return .green
        case "pending", "processing":
            return .orange
        case "failed", "error", "cancelled":
            return .red
        default:
            return .secondary
        }
    }
    
    private var transactionStatusIcon: String {
        switch transaction.status?.lowercased() ?? "" {
        case "completed", "success", "successful":
            return "checkmark.circle.fill"
        case "pending", "processing":
            return "clock.circle.fill"
        case "failed", "error", "cancelled":
            return "xmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            Image(systemName: transactionStatusIcon)
                .font(.title2)
                .foregroundColor(transactionStatusColor)
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(transaction.invoiceCount ?? 0) Facturas")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", transaction.amount ?? 0.0))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text(transaction.productName ?? "Unknown Product")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text((transaction.status ?? "Unknown").capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(transactionStatusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(transactionStatusColor.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text((transaction.purchaseDate ?? Date()).formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    PurchaseHistoryView()
}
