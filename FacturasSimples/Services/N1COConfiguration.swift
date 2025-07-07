//
//  N1COConfiguration.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  Configuration file for N1CO Epay API credentials
//

import Foundation

struct N1COConfiguration {
    // MARK: - Environment Configuration
    static let isProduction = true // Set to true for production
    
    // MARK: - API URLs
    static var baseURL: String {
        return isProduction ? "https://api.n1co.com/api/v2" : "https://api-sandbox.n1co.shop/api/v2"
    }
    
    // MARK: - Credentials (TODO: Move to secure storage or environment variables)
    // 🔥 REPLACE THESE WITH YOUR ACTUAL N1CO CREDENTIALS:
    static let clientId = "c096d38a-7876-4718-85b3-9fa95d12adc4" // Get from N1CO Dashboard → API Keys
    static let clientSecret = "aTh8Q~RSrinSPxR8uh7jzDXqT~KT9uY7jaBJUa_k" // Get from N1CO Dashboard → API Keys
    static let locationId = 1 // Get from N1CO Dashboard → Locations → ID
    static let locationCode = "FACTURAS-01" // Get from N1CO Dashboard → Locations → Code
    
    // MARK: - Payment Configuration
    static let successURL = "facturas://payment-success"
    static let cancelURL = "facturas://payment-cancel"
    
    // MARK: - Validation
    static var isConfigured: Bool {
        return !clientId.contains("YOUR_") && 
               !clientSecret.contains("YOUR_") &&
               !locationCode.contains("FACTURAS-")
    }
    
    // MARK: - Configuration Helper
    static func validateConfiguration() throws {
        guard isConfigured else {
            throw N1COConfigurationError.invalidCredentials
        }
    }
}

// MARK: - Configuration Errors
enum N1COConfigurationError: LocalizedError {
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "N1CO credentials are not properly configured. Please update N1COConfiguration.swift with your actual credentials."
        }
    }
}
