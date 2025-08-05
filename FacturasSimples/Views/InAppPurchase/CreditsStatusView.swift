//
//  CreditsStatusView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 6/3/25.
//

import SwiftUI

struct CreditsStatusView: View {
    @StateObject private var purchaseManager = PurchaseDataManager.shared
    @State private var showPurchaseView = false
    let company: Company?
    
    var showPurchaseOptions: Bool {
        return company?.requiresPaidServices ?? false
    }
    
    var hasAvailableCredits: Bool {
        guard let company = company else { return false }
        
        // Test accounts always have "unlimited" credits
        if company.isTestAccount {
            return true
        }
        
        // Use the published userProfile to make this reactive
        return (purchaseManager.userProfile?.availableInvoices ?? 0) > 0
    }
    
    var creditsText: String {
        guard let company = company else { return "0 disponibles" }
        
        if company.isTestAccount {
            return "Ilimitadas (Prueba)"
        }
        
        // Use the published userProfile to make this reactive
        let balance = purchaseManager.userProfile?.availableInvoices ?? 0
        
        // Debug logging to track credit updates
        print("💰 CreditsStatusView: Current balance: \(balance)")
        
        return "\(balance) disponibles"
    }
    
    var creditsIcon: String {
        guard let company = company else { return "creditcard.fill" }
        
        if company.isTestAccount {
            return "infinity"
        }
        
        return "creditcard.fill"
    }
    
    var creditsColor: Color {
        if hasAvailableCredits {
            return company?.isTestAccount == true ? .blue : .green
        } else {
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Credits icon with gradient background
            ZStack {
                Circle()
                    .fill(creditsColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: creditsIcon)
                    .foregroundColor(creditsColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            // Credits info
            VStack(alignment: .leading, spacing: 2) {
                Text("Disponibles")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(creditsText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(hasAvailableCredits ? creditsColor : .primary)
            }
            
            Spacer()
            
            // Purchase button for paid accounts
            if showPurchaseOptions {
                Button(action: {
                    showPurchaseView = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .onAppear {
            // Ensure user profile is loaded when view appears
            purchaseManager.loadUserProfile()
            print("💰 CreditsStatusView: View appeared, loading user profile")
        }
        .onChange(of: purchaseManager.userProfile?.availableInvoices) { oldValue, newValue in
            print("💰 CreditsStatusView: Credits changed from \(oldValue ?? 0) to \(newValue ?? 0)")
        }
        .sheet(isPresented: $showPurchaseView) {
            InAppPurchaseView()
        }
    }
}

#Preview {
    CreditsStatusView(company: nil)
}
