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
    var locked: Bool
    
    @Attribute(.preserveValueOnDeletion)
    var status: Int32
    var customer: Customer
    var invoiceType: Int32
    var generationCode: String?
    var controlNumber: String?
    var receptionSeal: String?
    
    @Relationship(deleteRule: .cascade, inverse: \ InvoiceDetail.invoice)
    var invoiceDetails: [InvoiceDetail] = [InvoiceDetail]()
    
    init(invoiceNumber: String, date: Date, customerId: Int, locked: Bool, customer: Customer,
         status: Int32, invoiceType: Int32,
         generationCode: String? = nil, controlNumber: String? = nil,
         receptionSeal: String? = nil) {
        
        self.invoiceNumber = invoiceNumber
        self.date = date
        self.customerId = customerId
        self.locked = locked
        self.customer = customer
        self.generationCode = generationCode
        self.controlNumber = controlNumber
        self.receptionSeal = receptionSeal
        self.status = status
        self.invoiceType = invoiceType
    }
   
}
enum InvoiceStatus {
    case Nueva
    case Sincronizando
    case Completada
    case Cancelada
}


enum InvoiceType {
    case Factura
    case ccf
}


@Model class InvoiceDetail {
    
    @Attribute(.unique)
    var id: String = UUID().uuidString
    
    
    var invoice : Invoice
    
    init(invoice: Invoice) {
        self.invoice = invoice
    }
    
}
