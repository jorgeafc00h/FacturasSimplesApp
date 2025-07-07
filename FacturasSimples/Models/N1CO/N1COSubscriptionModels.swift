//
//  N1COSubscriptionModels.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  N1CO subscription models
//

import Foundation

// Note: This file depends on types from N1COPaymentMethodModels.swift and N1COChargeModels.swift
// Make sure to import those or include them in your target

// MARK: - Subscription Plan Models
struct N1COSubscriptionPlan: Codable {
    let name: String
    let description: String
    let amount: Double
    let ogTitle: String?
    let ogDescription: String?
    let ogImageBase64: String?
    let linkImageBase64: String?
    let customFields: [N1COCustomField]?
    let successUrl: String
    let cancelUrl: String
    let billingCycleType: String // "DAY", "WEEK", "MONTH", "YEAR"
    let billingCyclesNumber: Int
    let cyclesToBillBeforeAllowCancelation: Int?
    let termsAndConditions: String?
    let subscriberLimit: Int?
    let enrollmentEndDate: String?
    let subscriptionEndDate: String?
    let billingDay: Int?
    let locationId: Int
}

struct N1COCustomField: Codable {
    let label: String
    let name: String
    let placeholder: String
    let isRequired: Bool
    let isVisible: Bool
    let isEditable: Bool
    let defaultValue: String?
}

// MARK: - Subscription Request/Response
struct N1COSubscriptionRequest: Codable {
    let subscriptionLinkId: Int
    let customer: N1COCustomer
    let paymentMethod: N1COPaymentMethodReference
    let backupPaymentMethod: N1COPaymentMethodReference?
    let locationCode: String
}

struct N1COSubscriptionResponse: Codable {
    let status: String
    let message: String
    let error: N1COError?
    let authentication: N1COAuthentication?
    let subscription: N1COSubscriptionInfo?
}

struct N1COSubscriptionInfo: Codable {
    let id: Int
    let status: String
    let amount: Double
    let currency: String
}
