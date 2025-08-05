//
//  ExternalPaymentService.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 8/3/25.
//  Service for handling external payment processing with N1CO Epay
//

import Foundation

@MainActor
@Observable
class ExternalPaymentService {
    
    // MARK: - Observable Properties
    var isProcessingPayment = false
    var lastPaymentError: String?
    var paymentHistory: [ExternalPaymentRecord] = []
    
    // MARK: - Private Properties
    private let apiBaseURL = "https://api.n1co.com/v1"
    private let paymentHistoryKey = "external_payment_history"
    
    // MARK: - Initialization
    init() {
        loadPaymentHistory()
    }
    
    // MARK: - Public Methods
    
    /// Process payment for a custom product
    func processPayment(for product: CustomPaymentProduct) async -> Bool {
        isProcessingPayment = true
        lastPaymentError = nil
        
        do {
            // Simulate API call to N1CO Epay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
            
            // In a real implementation, you would:
            // 1. Create payment intent with N1CO Epay API
            // 2. Process credit card payment
            // 3. Handle payment result
            // 4. Update user's invoice credits
            
            let success = await simulatePaymentProcessing(for: product)
            
            if success {
                // Record successful payment
                let record = ExternalPaymentRecord(
                    id: UUID().uuidString,
                    productId: product.id,
                    productName: product.name,
                    amount: product.price,
                    currency: product.currency,
                    invoiceCount: product.invoiceCount,
                    paymentDate: Date(),
                    status: .completed,
                    transactionId: generateTransactionId()
                )
                
                paymentHistory.append(record)
                savePaymentHistory()
                
                // Update user's invoice credits (integrate with your user profile system)
                await updateUserCredits(invoiceCount: product.invoiceCount)
            }
            
            isProcessingPayment = false
            return success
            
        } catch {
            lastPaymentError = "Error de red: \(error.localizedDescription)"
            isProcessingPayment = false
            return false
        }
    }
    
    /// Get payment history for user
    func getPaymentHistory() -> [ExternalPaymentRecord] {
        return paymentHistory.sorted { $0.paymentDate > $1.paymentDate }
    }
    
    /// Validate payment before processing
    func validatePayment(for product: CustomPaymentProduct) -> PaymentValidationResult {
        // Validate product
        guard product.price > 0 else {
            return .invalid("Precio del producto inválido")
        }
        
        guard product.invoiceCount > 0 else {
            return .invalid("Cantidad de facturas inválida")
        }
        
        // Validate currency
        guard ["USD", "MXN", "EUR"].contains(product.currency) else {
            return .invalid("Moneda no soportada")
        }
        
        return .valid
    }
    
    // MARK: - Private Methods
    
    private func simulatePaymentProcessing(for product: CustomPaymentProduct) async -> Bool {
        // Simulate network processing with random success/failure
        let randomSuccess = Double.random(in: 0...1) > 0.1 // 90% success rate
        
        if !randomSuccess {
            lastPaymentError = "Error al procesar el pago. Verifica los datos de tu tarjeta."
        }
        
        return randomSuccess
    }
    
    private func updateUserCredits(invoiceCount: Int) async {
        // In a real implementation, this would integrate with your user profile system
        // For now, we'll just print the update
        print("✅ Updated user credits: +\(invoiceCount) invoices")
        
        // You could integrate with your existing PurchaseDataManager here
        // PurchaseDataManager.shared.addInvoiceCredits(invoiceCount)
    }
    
    private func generateTransactionId() -> String {
        return "TXN_\(Date().timeIntervalSince1970)_\(Int.random(in: 1000...9999))"
    }
    
    private func loadPaymentHistory() {
        guard let data = UserDefaults.standard.data(forKey: paymentHistoryKey),
              let history = try? JSONDecoder().decode([ExternalPaymentRecord].self, from: data) else {
            paymentHistory = []
            return
        }
        
        paymentHistory = history
    }
    
    private func savePaymentHistory() {
        guard let data = try? JSONEncoder().encode(paymentHistory) else { return }
        UserDefaults.standard.set(data, forKey: paymentHistoryKey)
    }
}

// MARK: - Supporting Models

struct ExternalPaymentRecord: Codable, Identifiable {
    let id: String
    let productId: String
    let productName: String
    let amount: Double
    let currency: String
    let invoiceCount: Int
    let paymentDate: Date
    let status: PaymentStatus
    let transactionId: String
}

enum PaymentStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendiente"
        case .completed:
            return "Completado"
        case .failed:
            return "Fallido"
        case .refunded:
            return "Reembolsado"
        }
    }
}

enum PaymentValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}