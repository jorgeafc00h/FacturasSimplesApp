//
//  ExternalPaymentView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 8/3/25.
//  External payment view for credit card processing with N1CO Epay
//

import SwiftUI

struct ExternalPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var externalPaymentService = ExternalPaymentService()
    @State private var selectedProduct: CustomPaymentProduct?
    @State private var isProcessingPayment = false
    @State private var showSuccessAlert = false
    @State private var paymentError: String?
    
    let products: [CustomPaymentProduct] = [
        CustomPaymentProduct(
            id: "paquete_50",
            name: "Paquete de 50 facturas",
            description: "Perfecto para pequeñas empresas",
            price: 9.99,
            currency: "USD",
            invoiceCount: 50
        ),
        CustomPaymentProduct(
            id: "paquete_100",
            name: "Paquete de 100 facturas",
            description: "La mejor opción para empresas en crecimiento",
            price: 15.00,
            currency: "USD",
            invoiceCount: 100
        ),
        CustomPaymentProduct(
            id: "paquete_250",
            name: "Paquete de 250 facturas",
            description: "Para empresas de alto volumen",
            price: 29.99,
            currency: "USD",
            invoiceCount: 250
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    productsSection
                }
                .padding()
            }
            .navigationTitle("Pago Externo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Pago Exitoso", isPresented: $showSuccessAlert) {
            Button("OK") { 
                dismiss()
            }
        } message: {
            Text("Tu compra se ha procesado exitosamente.")
        }
        .alert("Error de Pago", isPresented: .constant(paymentError != nil)) {
            Button("OK") { 
                paymentError = nil
            }
        } message: {
            if let error = paymentError {
                Text(error)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Pago con Tarjeta")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Procesa tu pago de forma segura")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var productsSection: some View {
        VStack(spacing: 16) {
            Text("Selecciona un Paquete")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 12) {
                ForEach(products, id: \.id) { product in
                    ExternalProductCard(product: product) {
                        processPayment(for: product)
                    }
                }
            }
        }
    }
    
    private func processPayment(for product: CustomPaymentProduct) {
        selectedProduct = product
        isProcessingPayment = true
        
        Task {
            do {
                // Simulate payment processing
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
                
                // Here you would integrate with N1CO Epay or your payment processor
                let success = await externalPaymentService.processPayment(for: product)
                
                await MainActor.run {
                    isProcessingPayment = false
                    if success {
                        showSuccessAlert = true
                    } else {
                        paymentError = "No se pudo procesar el pago. Intenta de nuevo."
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingPayment = false
                    paymentError = "Error de conexión. Verifica tu internet e intenta de nuevo."
                }
            }
        }
    }
}

struct ExternalProductCard: View {
    let product: CustomPaymentProduct
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("\(product.invoiceCount) facturas")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Button("Comprar") {
                    onPurchase()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Custom Payment Product Model
struct CustomPaymentProduct: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let invoiceCount: Int
}

#Preview {
    ExternalPaymentView()
}
