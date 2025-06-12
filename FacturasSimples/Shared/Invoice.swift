//
//  Invoice.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//
import Foundation
import SwiftUI
import SwiftData
import CloudKit

@Model class Invoice
{
    // CloudKit-compatible identifier - remove unique constraint
    var inoviceId: String = UUID().uuidString
    
    // CloudKit requires default values for non-optional attributes
    @Attribute(.preserveValueOnDeletion)
    var invoiceNumber: String = ""
    
    // CloudKit automatically handles Date types - provide default
    var date: Date = Date()
    
    var status: InvoiceStatus = InvoiceStatus.Nueva
    var statusRawValue: Int = 0
    
    // CloudKit handles relationships automatically
    var customer: Customer?
    var invoiceType: InvoiceType = InvoiceType.Factura
    
    var documentType: String = ""
    
    // Optional strings work well with CloudKit
    var generationCode: String?
    var controlNumber: String?
    var receptionSeal: String?
    
    var relatedDocumentNumber: String?
    var relatedDocumentType: String?
    var relatedInvoiceType: InvoiceType?
    var relatedId: String?
    var relatedDocumentDate: Date?
    
    var invalidatedViaApi: Bool = false
    
    // CloudKit handles cascade relationships - make optional
    @Relationship(deleteRule: .cascade, inverse: \InvoiceDetail.invoice)
    var items: [InvoiceDetail]?
    
    // Computed properties don't sync to CloudKit (which is what we want)
    var totalAmount: Decimal {
        return (items ?? []).reduce(0){
            ($0 + $1.productTotal).rounded()
        }
    }
    
    var tax: Decimal {
        return (totalAmount - (totalAmount / Constants.includedTax)).rounded()
    }
    
    var subTotal: Decimal {
        return (totalAmount > 0 ? totalAmount - tax : 0).rounded()
    }
    
    var isCCF: Bool {
        return invoiceType == .CCF
    }
    
    var totalItems: Int {
        return items?.count ?? 0
    }
    
    
    var totalWithoutTax: Decimal {
        return (totalAmount / 1.13).rounded()
    }
    
    var ivaRete1: Decimal{
        return customer?.hasContributorRetention == true ?
        (totalWithoutTax * 0.01).rounded() : 0
    }
  
    
    var version: Int {
        return isCCF ? 3 : 1
    }
    
    
    
    init(invoiceNumber: String,
         date: Date,
         status: InvoiceStatus, customer: Customer? = nil,
         invoiceType: InvoiceType = .Factura,
         generationCode: String = "",
         controlNumber: String = "",
         receptionSeal: String = "") {
        
        self.invoiceNumber = invoiceNumber
        self.date = date
        //self.customerId = customerId
        
        self.status = status
        self.customer = customer
        self.invoiceType = invoiceType
        self.generationCode = generationCode
        self.controlNumber = controlNumber
        self.receptionSeal = receptionSeal
        self.documentType = Extensions.documentTypeFromInvoiceType(invoiceType)
        self.statusRawValue = status.rawValue
        self.relatedDocumentNumber = ""
        self.relatedDocumentType = ""
        
    }
    
}
enum InvoiceStatus:Int, Codable, CaseIterable, Identifiable, Hashable {
    case Nueva
    case Sincronizando
    case Completada
    case Anulada
    var id: Int { rawValue }
    func stringValue() -> String {
        switch(self) {
        case .Nueva:
            return "Nueva"
        case .Anulada:
            return "Anulada"
        case .Completada:
            return "Completada"
        case .Sincronizando:
            return "Sincronizando"
        }
        
    }
}

//enum InvoicetSearchScope: String, Codable, CaseIterable, Identifiable, Hashable {
//
//    case Factura
//    case Credito
//    case NonEditable
//    var id: String { rawValue }
//}

enum InvoiceType: Int, Codable, CaseIterable, Identifiable, Hashable {
    case Factura
    case CCF
    case NotaCredito
    var id: Int { rawValue }
    func stringValue() -> String {
        switch(self) {
        case .Factura:
            return "FACTURA"
        case .CCF:
            return "COMPROBANTE DE CRÉDITO FISCAL"
            
        case .NotaCredito:
            return "NOTA DE CRÉDITO"
        }
    }
}



@Model class InvoiceDetail {
    
    // Provide default value for CloudKit compatibility
    var quantity: Decimal = 0.0
    var invoice : Invoice?
    var product: Product?
    
    var productTotal: Decimal {
        guard let product = product else { return 0 }
        return  quantity * product.unitPrice
    }
    
    var productTotalWithoutTax: Decimal{
        return productTotal /  Constants.includedTax
    }
    
    init(quantity: Decimal,
         product: Product? = nil
    ) {
        self.quantity = quantity
        self.product = product
    }
}


extension Invoice {
    
    var statusColor :Color {
        switch status  {
        case .Completada:
            return Color.green
        case .Nueva:
            return Color.orange
        case .Anulada:
            return Color.red
        default:
            return Color.gray
        }
    }
    
    var canCratenewInvoice: Bool {
        
        return (items?.count ?? 0) > 0 && status == .Nueva && !invoiceNumber.isEmpty
    }
    
    static var previewInvoices: [Invoice] {
        let customer = Customer( firstName: "Joe",lastName: "Cool", nationalId: "037216721",email:"joe@cool.com",phone: "12345678")
        let product1 = Product(productName: "Product 1", unitPrice: 10.0)
        let product2 = Product(productName: "Product 2", unitPrice: 20.0)
        
        let invoice1 = Invoice(invoiceNumber: "INV-001",
                               date: Date(),
                               status: .Nueva,
                               customer: customer,
                               invoiceType: .Factura)
        
        let invoice2 = Invoice(invoiceNumber: "INV-002",
                               date: Date(),
                               status: .Completada,
                               customer: customer,
                               invoiceType: .CCF)
        
        let detail1 = InvoiceDetail(quantity: 2, product: product1)
        let detail2 = InvoiceDetail(quantity: 1, product: product2)
        let detail3 = InvoiceDetail(quantity: 3, product: product1)
        
        invoice1.items = [detail1, detail2]
        invoice2.items = [detail3]
        
        return [invoice1, invoice2]
    }
}
