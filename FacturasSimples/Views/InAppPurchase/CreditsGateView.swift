//
//  CreditsGateView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//
// COMMENTED OUT FOR APP SUBMISSION - REMOVE StoreKit DEPENDENCY
// Uncomment this entire file to re-enable in-app purchases

import SwiftUI

/*
struct CreditsGateView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    @State private var showPurchaseView = false
    @Environment(\.dismiss) private var dismiss
    
    let onProceed: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            // Title and message
            VStack(spacing: 12) {
                Text("Sin Créditos de Factura")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Necesitas créditos de factura para crear una nueva factura. Compra un paquete para continuar.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Current credits (if any)
            if storeManager.userCredits.availableInvoices > 0 {
                HStack {
                    Text("Créditos Disponibles:")
                    Spacer()
                    Text("\(storeManager.userCredits.availableInvoices)")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                // Purchase button
                Button(action: {
                    showPurchaseView = true
                }) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("Comprar Créditos de Factura")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // Restore button
                Button(action: {
                    Task {
                        await storeManager.restorePurchases()
                        
                        // Check if restore gave us credits
                        if storeManager.hasAvailableCredits() {
                            onProceed()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Restaurar Compras")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(storeManager.isLoading)
                
                // Cancel button
                Button("Cancelar") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Créditos de Factura Requeridos")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPurchaseView) {
            InAppPurchaseView()
                .environmentObject(storeManager)
        }
        .onChange(of: storeManager.userCredits.availableInvoices) { _, newValue in
            if newValue > 0 {
                onProceed()
            }
        }
        .onAppear {
            // Refresh credits when the gate appears to ensure current balance
            storeManager.refreshUserCredits()
        }
    }
}

// MARK: - Credits Guard Modifier
extension View {
    func requiresInvoiceCredits(
        storeManager: StoreKitManager,
        onProceed: @escaping () -> Void
    ) -> some View {
        Group {
            if storeManager.hasAvailableCredits() {
                self
            } else {
                CreditsGateView(onProceed: onProceed)
                    .environmentObject(storeManager)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        CreditsGateView {
            print("Proceeding with invoice creation")
        }
        .environmentObject(StoreKitManager())
    }
}
*/

// PLACEHOLDER VIEW FOR COMPILATION
struct CreditsGateView: View {
    let onProceed: () -> Void
    
    var body: some View {
        VStack {
            Text("Credits Gate Disabled")
            Button("Continue") {
                onProceed()
            }
        }
        .navigationTitle("Comprar Créditos")
    }
}
