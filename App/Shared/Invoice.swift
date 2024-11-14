//
//  Invoice.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//
import Foundation
import SwiftUI
import SwiftData

@Model class Invoice
{
    
    
    @Attribute(.unique)
    var inoviceId: String = UUID().uuidString
    //    @Relationship(deleteRule: .cascade, inverse: \Product.inv)
    //    var products: [Product] = [Product]()
    
    
    @Attribute(.preserveValueOnDeletion)
    var invoiceNumber: String
    var date: Date
    
    //var customerId: Int
    
    var status: InvoiceStatus
    var customer: Customer
    var invoiceType: InvoiceType
    var generationCode: String?
    var controlNumber: String?
    var receptionSeal: String?
    
    @Relationship(deleteRule: .cascade, inverse: \ InvoiceDetail.invoice)
    var items: [InvoiceDetail] = []
    
    /// review this logic
    var totalAmount: Decimal {
        return items.reduce(0) { $0 + $1.productTotal }
    }
    
    var tax: Decimal {
        return totalAmount - (totalAmount / Constants.includedTax)
    }
    
    var subTotal: Decimal {
        return totalAmount > 0 ? totalAmount - tax : 0
    }
    
    var isCCF: Bool {
        return invoiceType == .CCF
    }
    
    var totalItems: Int {
        return items.count
    }
    
    
    init(invoiceNumber: String,
         date: Date,
         status: InvoiceStatus, customer: Customer,
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
    }
    
}
enum InvoiceStatus:Int, Codable {
    case Nueva
    case Sincronizando
    case Completada
    case Cancelada
    
    func stringValue() -> String {
        switch(self) {
        case .Nueva:
          return "Nueva"
        case .Cancelada:
          return "Cancelada"
        case .Completada:
            return "Completada"
        case .Sincronizando:
            return "Sincronizando"
        }
        
      }
}


enum InvoiceType:Int, Codable {
    case Factura
    case CCF
    
    func stringValue() -> String {
        switch(self) {
        case .Factura:
          return "Factura"
        case .CCF:
          return "Comprobante Credito Fiscal"
        }
      }
}
    
    
    @Model class InvoiceDetail {
        
        var quantity: Int
        var invoice : Invoice?
        var product: Product
        
        var productTotal: Decimal {
            return  Decimal(quantity) * product.unitPrice
        }
        
        init(quantity: Int,
             product: Product
            ) {
            
            self.quantity = quantity
            self.product = product
            //self.invoice = invoice
        }
        
    }
    
    
    extension Invoice {
        
        var statusColor :Color {
            switch status  {
            case .Completada:
                return Color.green
            case .Nueva:
                return Color.orange
            case .Cancelada:
                return Color.red
            default:
                return Color.gray
            }
        }
        
        var canCratenewInvoice: Bool {
            
            return items.count > 0 && status == .Nueva && !invoiceNumber.isEmpty
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
