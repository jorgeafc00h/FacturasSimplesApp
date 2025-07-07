//
//  N1COPaymentMethodModels.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  N1CO payment method and customer models
//

import Foundation

// MARK: - Customer Models
struct N1COCustomer: Codable {
    let id: String?
    let name: String
    let email: String
    let phoneNumber: String
}

// MARK: - Credit Card Models
struct N1COCreditCard: Codable {
    let number: String
    let expirationMonth: String
    let expirationYear: String
    let cvv: String
    let cardHolder: String
    let singleUse: Bool
}

// MARK: - Payment Method Request/Response
struct N1COPaymentMethodRequest: Codable {
    let customer: N1COCustomer
    let card: N1COCreditCard
}

struct N1COPaymentMethodResponse: Codable {
    let id: String
    let type: String
    let bin: N1COBIN?
    let success: Bool
    let message: String
}

struct N1COPaymentMethodReference: Codable {
    let id: String
}

// MARK: - BIN Information
struct N1COBIN: Codable {
    let brand: String
    let issuerName: String
    let countryCode: String
}
