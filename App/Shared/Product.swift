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
 
    var id:Int32
    var pproductName:String
    var unitPrice:Decimal
    
    init(id:Int32,pproductName:String,unitPrice:Decimal)
    {
        self.id=id
        self.pproductName=pproductName
        self.unitPrice=unitPrice
    }
}
