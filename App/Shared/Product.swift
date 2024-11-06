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
    
    init(productName:String,unitPrice:Decimal)
    {
        self.productName=productName
        self.unitPrice=unitPrice
    }
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
