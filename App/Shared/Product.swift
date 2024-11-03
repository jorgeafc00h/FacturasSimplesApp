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
    
    var pproductName:String
    var unitPrice:Decimal
    
    init(pproductName:String,unitPrice:Decimal)
    {
        self.pproductName=pproductName
        self.unitPrice=unitPrice
    }
}
