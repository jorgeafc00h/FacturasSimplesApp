//
//  N1COChargeModels.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  N1CO charge and transaction models
//

import Foundation

// MARK: - Order Models
struct N1COOrder: Codable {
    let id: String
    let amount: Double
    let description: String
    let name: String
}

struct N1COOrderResponse: Codable {
    let id: String
    let reference: String
    let amount: Double
    let currency: String
    let authorizationCode: String?
}

// MARK: - Billing Information
struct N1COBillingInfo: Codable {
    let countryCode: String
    let stateCode: String?
    let zipCode: String?
}

// MARK: - Charge Request/Response
struct N1COChargeRequest: Codable {
    let order: N1COOrder
    let cardId: String
    let authenticationId: String?
    let billingInfo: N1COBillingInfo?
}

struct N1COChargeResponse: Codable {
    let status: String
    let message: String
    let error: N1COError?
    let authentication: N1COAuthentication?
    let order: N1COOrderResponse?
    let createdAt: String
}

// MARK: - Error Models
struct N1COError: Codable {
    let code: String
    let message: String
}

// MARK: - 3DS Authentication
struct N1COAuthentication: Codable {
    let url: String
    let id: String
}
