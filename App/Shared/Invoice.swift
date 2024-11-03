//
//  Invoice.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//
import Foundation
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
    
    var customerId: Int
     
    var status: InvoiceStatus
    var customer: Customer
    var invoiceType: InvoiceType
    var generationCode: String?
    var controlNumber: String?
    var receptionSeal: String?
    
    @Relationship(deleteRule: .cascade, inverse: \ InvoiceDetail.invoice)
    private var items: [InvoiceDetail] = []

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
            return invoiceType == .ccf
        }

        var totalItems: Int {
            return items.count
        }

        init(invoiceNumber: String,
             date: Date, customerId: Int,
             status: InvoiceStatus, customer: Customer,
             invoiceType: InvoiceType = .Factura,
             generationCode: String = "",
             controlNumber: String = "",
             receptionSeal: String = "") {
            
            self.invoiceNumber = invoiceNumber
            self.date = date
            self.customerId = customerId
            
            self.status = status
            self.customer = customer
            self.invoiceType = invoiceType
            self.generationCode = generationCode
            self.controlNumber = controlNumber
            self.receptionSeal = receptionSeal
        }
   
}
enum InvoiceStatus:Codable {
    case Nueva
    case Sincronizando
    case Completada
    case Cancelada
}


enum InvoiceType: Codable {
    case Factura
    case ccf
}


@Model class InvoiceDetail {
    
    var quantity: Int
    
    var invoice : Invoice
    
    var product: Product
    
    var productTotal: Decimal {
        return  Decimal(quantity) * product.unitPrice
    }
    
    init(quantity: Int,
         product: Product,
         invoice: Invoice) {
        
      self.quantity = quantity
      self.product = product
      self.invoice = invoice
    }
    
}


extension Invoice {
    static var previewInvoices: [Invoice] {
        let customer = Customer( firstName: "Joe",lastName: "Cool", nationalId: "037216721",email:"joe@cool.com",phone: "12345678")
        let product1 = Product(pproductName: "Product 1", unitPrice: 10.0)
        let product2 = Product(pproductName: "Product 2", unitPrice: 20.0)
        
        let invoice1 = Invoice(invoiceNumber: "INV-001",
                               date: Date(),
                               customerId: 1,
                               status: .Nueva,
                               customer: customer,
                               invoiceType: .Factura)
        
        let invoice2 = Invoice(invoiceNumber: "INV-002",
                               date: Date(),
                               customerId: 1,
                               status: .Completada,
                               customer: customer,
                               invoiceType: .ccf)
        
        let detail1 = InvoiceDetail(quantity: 2, product: product1, invoice: invoice1)
        let detail2 = InvoiceDetail(quantity: 1, product: product2, invoice: invoice1)
        let detail3 = InvoiceDetail(quantity: 3, product: product1, invoice: invoice2)
        
        invoice1.items = [detail1, detail2]
        invoice2.items = [detail3]
        
        return [invoice1, invoice2]
    }
}
