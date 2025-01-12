//
//  Product.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//


import Foundation
import SwiftData

@Model class Product
{
 
    @Attribute(.unique)
    var productId: String = UUID().uuidString
    
    var productName:String
    var unitPrice:Decimal
    
    var productDescription: String
    
    @Relationship(deleteRule: .cascade, inverse: \ InvoiceDetail.product)
    var invoiceDetails : [InvoiceDetail] = []
    
    var companyId: String
    
    init(productName:String,unitPrice:Decimal, productDescription:String = "",companyId:String = "")
    {
        self.productName = productName
        self.unitPrice = unitPrice
        self.productDescription = ""
        self.companyId = companyId
    }
}

enum ProductSearchScope: String, Codable, CaseIterable, Identifiable, Hashable {
     
    case Todos
    case Editable
    case NonEditable
    var id: String { rawValue }
}

extension Product {
    
  
    static var previewProducts: [Product] {
        [
            Product(productName: "Iphone 11", unitPrice: 1000),
            Product(productName: "Iphone 12", unitPrice: 1),
            Product(productName: "Iphone 13", unitPrice: 1200),
        ]
    }
}
