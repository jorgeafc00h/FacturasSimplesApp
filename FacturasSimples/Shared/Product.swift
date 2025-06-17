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
 
    // Remove unique constraint for CloudKit compatibility
    var productId: String = UUID().uuidString
    
    // Provide default values for CloudKit
    var productName: String = ""
    var unitPrice: Decimal = 0.0
    
    var productDescription: String = ""
    
    // Make relationship optional for CloudKit
    @Relationship(deleteRule: .nullify, inverse: \ InvoiceDetail.product)
    var invoiceDetails: [InvoiceDetail]?
    
    var companyId: String = ""
    
    // CloudKit sync control - only sync products from production companies
    var shouldSyncToCloudKit: Bool = true  // Default to true for backwards compatibility
    
    // Helper computed property to check if this product belongs to a test company
    var isFromTestCompany: Bool {
        return !shouldSyncToCloudKit
    }
    
    var priceWithoutTax: Decimal {
        return   unitPrice / Constants.includedTax
    }
    
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
