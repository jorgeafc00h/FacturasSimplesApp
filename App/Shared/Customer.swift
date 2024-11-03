//
//  Customer.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//
import Foundation
import SwiftUI
import SwiftData

@Model class Customer : Identifiable
{
     
   // #Unique<Customer>([\.nationalId])
    
    var firstName: String
    var lastName: String
    var company: String
    var address: String
    var city: String?
    var state: String?
    var email: String
    var zipcode: Int?
    var phone: String
    
    @Attribute(.unique)
    var nationalId: String
    var contributorId: String?
    var nit: String? 
    var documentType: String?
    var codActividad: String?
    var descActividad: String?
    var departamentoCode: String = ""
    var municipioCode: String = ""
    var departammento: String
    var municipio: String
    //var color: Color
    
    var nrc: String?
    var hasInvoiceSettings: Bool = false
    
    @Relationship(deleteRule: .deny,inverse: \Invoice.customer)
    var invoices: [Invoice] = []
    
    init(firstName: String,lastName: String, nationalId: String,
         email: String,
         phone: String,
         departammento: String = "-",
         municipio: String = "-",
         address: String = "-",
         company: String = "-") {
        //self.id = id
        self.firstName = firstName
        self.nationalId = nationalId
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.departammento = departammento
        self.municipio = municipio
        self.address = address
        self.company = company
    }
}

extension Customer {
    var color: Color {
        let seed = firstName.hashValue
        var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
        return .random(using: &generator)
    }
    
    var fullName: String {
        firstName.isEmpty && lastName.isEmpty ? "Undefined User " : firstName + " " + lastName
    }
    
    var initials : String {
        (firstName.isEmpty ? "" : firstName .first?.uppercased() ?? "") +
        (lastName.isEmpty ? "" : lastName.first?.uppercased() ?? "")
    }

    
    func initCustomerInvoiceSettings(){
        descActividad = "Seleccione Actividad Economica"
        codActividad = ""
        
    }
    func deactivateCustomerInvoiceSettings(){
        descActividad = nil
        codActividad = nil
        nit = nil
        nrc = nil
        
        
    }
    
    static var previewCustomers: [Customer] {
        [
            Customer( firstName: "Joe",lastName: "Cool", nationalId: "037216721",email:"joe@cool.com",phone: "12345678"),
            Customer( firstName: "John",lastName: "Doe", nationalId: "234234233",email:"John@cool.com",phone:"87654321")
        ]
    }
}

private struct SeededRandomGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    
    func next() -> UInt64 {
        UInt64(drand48() * Double(UInt64.max))
    }
}

private extension Color {
    static var random: Color {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }
    
    static func random(using generator: inout RandomNumberGenerator) -> Color {
        let red = Double.random(in: 0..<1, using: &generator)
        let green = Double.random(in: 0..<1, using: &generator)
        let blue = Double.random(in: 0..<1, using: &generator)
        return Color(red: red, green: green, blue: blue)
    }
}

