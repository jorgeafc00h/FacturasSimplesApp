import Foundation

// MARK: - Payment Status Models

/// Response model for payment status checks - supports both new simplified and legacy formats
struct PaymentStatusResponse: Codable {
    // New simplified format fields
    let orderReference: String?
    let isSuccess: Bool?
    let date: String?
    let invoiceCount: Int?
    let sku: String?
    let paidAmount: Double?
    
    // Legacy format fields
    let orderId: String?
    let description: String?
    let metadata: PaymentMetadata?
    let level: String?
    let type: String? // "SuccessPayment" means successful, others indicate different states
    
    /// Indicates if the payment was successful and credits should be added
    var isPaymentCompleted: Bool {
        // Check new format first
        if let isSuccess = isSuccess {
            return isSuccess
        }
        
        // Fall back to legacy format
        return type == "SuccessPayment"
    }
    
    /// Indicates if the payment is still being processed
    var isPaymentPending: Bool {
        // Check new format first
        if let isSuccess = isSuccess {
            return !isSuccess
        }
        
        // Fall back to legacy format
        return type != "SuccessPayment"
    }
    
    /// Indicates if the payment failed
    var isPaymentFailed: Bool {
        // Check new format first
        if let isSuccess = isSuccess {
            return !isSuccess
        }
        
        // Fall back to legacy format
        return type == "FailedPayment" || type == "ErrorPayment"
    }
    
    /// Indicates if the order was not found (still in progress)
    var isOrderNotFound: Bool {
        return type == "not_found"
    }
    
    /// Gets the transaction date
    var transactionDate: Date? {
        // Check new format first
        if let dateString = date {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: dateString)
        }
        
        // Fall back to legacy format
        guard let dateString = metadata?.transactionDate else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    /// Gets the paid amount as string (for legacy compatibility)
    var paidAmountString: String? {
        // Check new format first
        if let amount = paidAmount {
            return String(amount)
        }
        
        // Fall back to legacy format
        return metadata?.paidAmount
    }
    
    /// Gets the paid amount as double
    var paidAmountDouble: Double? {
        // Check new format first
        if let amount = paidAmount {
            return amount
        }
        
        // Fall back to legacy format
        if let amountString = metadata?.paidAmount {
            return Double(amountString)
        }
        
        return nil
    }
    
    /// Gets the number of invoices/credits from the payment
    var creditsToAdd: Int {
        // Check new format first
        if let count = invoiceCount {
            return count
        }
        
        // For legacy format, try to extract from order total details or default to 1
        return 1
    }
    
    /// Gets the buyer email from metadata if available
    var buyerEmail: String? {
        return metadata?.buyerEmail
    }
    
    /// Gets the product SKU
    var productSku: String? {
        // Check new format first
        if let sku = sku {
            return sku
        }
        
        // Legacy format doesn't have SKU, return nil
        return nil
    }
    
    /// Gets the order reference (works for both formats)
    var orderRef: String? {
        // Check new format first
        if let ref = orderReference {
            return ref
        }
        
        // Fall back to legacy metadata
        return metadata?.orderReference
    }
    
    // Custom initializer for 404/not found responses
    init(notFoundOrderId: String) {
        self.orderReference = nil
        self.isSuccess = nil
        self.date = nil
        self.invoiceCount = nil
        self.sku = nil
        self.paidAmount = nil
        self.orderId = notFoundOrderId
        self.description = "Order is still being processed"
        self.metadata = nil
        self.level = "Info"
        self.type = "not_found"
    }
}

/// Payment metadata containing detailed payment information
struct PaymentMetadata: Codable {
    let paymentId: String?
    let chargeId: String?
    let status: String?
    let authorizationCode: String?
    let sequentialNumber: String?
    let accountId: String?
    let paymentProcessor: String?
    let paymentProcessorReference: String?
    let transactionDate: String?
    let paidAmount: String?
    let buyerName: String?
    let buyerPhone: String?
    let buyerEmail: String?
    let checkoutNote: String?
    let orderReference: String?
    let orderTotalDetails: OrderTotalDetails?
    let isManagedPaymentMethod: Bool?
    let invoiceName: String?
    let invoiceAddress: String?
    let invoiceTaxCode: String?
    
    enum CodingKeys: String, CodingKey {
        case paymentId = "PaymentId"
        case chargeId = "ChargeId"
        case status = "Status"
        case authorizationCode = "AuthorizationCode"
        case sequentialNumber = "SequentialNumber"
        case accountId = "AccountId"
        case paymentProcessor = "PaymentProcessor"
        case paymentProcessorReference = "PaymentProcessorReference"
        case transactionDate = "TransactionDate"
        case paidAmount = "PaidAmount"
        case buyerName = "BuyerName"
        case buyerPhone = "BuyerPhone"
        case buyerEmail = "BuyerEmail"
        case checkoutNote = "CheckoutNote"
        case orderReference = "OrderReference"
        case orderTotalDetails = "OrderTotalDetails"
        case isManagedPaymentMethod = "IsManagedPaymentMethod"
        case invoiceName = "InvoiceName"
        case invoiceAddress = "InvoiceAddress"
        case invoiceTaxCode = "InvoiceTaxCode"
    }
}

/// Order total details from payment metadata
struct OrderTotalDetails: Codable {
    let subtotal: String
    let shippingAmount: String
    let discountAmount: String
    let surchargeAmount: String
    let total: String
}
