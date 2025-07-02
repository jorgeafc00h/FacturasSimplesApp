//
//  PurchaseHistoryView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//
// COMMENTED OUT FOR APP SUBMISSION - REMOVE StoreKit DEPENDENCY
// Uncomment this entire file to re-enable in-app purchases

import SwiftUI

/*
struct PurchaseHistoryView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    @Environment(\.dismiss) private var dismiss
    
    // Optional callback to handle "Browse Bundles" action
    var onBrowseBundles: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if storeManager.userCredits.transactions.isEmpty {
                    emptyStateView
                } else {
                    transactionsList
                }
            }
            .navigationTitle("Purchase History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Restore") {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    }
                    .disabled(storeManager.isLoading)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Purchases Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your purchase history will appear here once you buy invoice bundles")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Browse Bundles") {
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
            
            // Transactions Section
            Section("Purchase History") {
                ForEach(storeManager.userCredits.transactions.sorted { $0.purchaseDate > $1.purchaseDate }) { transaction in
                    TransactionRow(transaction: transaction)
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
                    Text("Available Credits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(storeManager.userCredits.availableInvoices)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Purchased")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(storeManager.userCredits.totalPurchased)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            if storeManager.userCredits.totalPurchased > storeManager.userCredits.availableInvoices {
                let usedCredits = storeManager.userCredits.totalPurchased - storeManager.userCredits.availableInvoices
                
                HStack {
                    Text("Credits Used:")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(usedCredits)")
                        .fontWeight(.medium)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: StoredTransaction
    
    private var bundle: InvoiceBundle? {
        InvoiceBundle.allBundles.first { $0.id == transaction.productID }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: transaction.isRestored ? "arrow.clockwise.circle.fill" : "purchased.circle.fill")
                .foregroundColor(transaction.isRestored ? .orange : .green)
                .font(.title2)
            
            // Transaction details
            VStack(alignment: .leading, spacing: 2) {
                Text(bundle?.name ?? "Unknown Bundle")
                    .font(.headline)
                
                Text("\(transaction.invoiceCount) invoices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(transaction.purchaseDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status badge
            VStack(alignment: .trailing, spacing: 2) {
                if transaction.isRestored {
                    Text("Restored")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Text("Purchased")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(bundle?.formattedPrice ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    PurchaseHistoryView()
        .environmentObject(StoreKitManager())
}
*/

// PLACEHOLDER VIEW FOR COMPILATION
struct PurchaseHistoryView: View {
    var onBrowseBundles: (() -> Void)? = nil
    
    var body: some View {
        Text("Purchase History Disabled")
            .navigationTitle("Historial de Compras")
    }
}
