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
    static let isProduction = false // Set to true for production
    
    // MARK: - API URLs
    static var baseURL: String {
        return isProduction ? "https://api.n1co.com/api/v2" : "https://api-sandbox.n1co.shop/api/v2"
    }
    
    // MARK: - Credentials (TODO: Move to secure storage or environment variables)
    // 🔥 REPLACE THESE WITH YOUR ACTUAL N1CO CREDENTIALS:
    static let clientId = "c4e02d49-33c9-44cd-84b1-6ec09c9c1278" // Get from N1CO Dashboard → API Keys
    static let clientSecret = "Qz88Q~Ph.SCj-WviJG68JZup_~4LrW8GkPIgMaTY" // Get from N1CO Dashboard → API Keys
    static let locationId = 1 // Get from N1CO Dashboard → Locations → ID
    static let locationCode = "dev-app2" // Get from N1CO Dashboard → Locations → Code
    
    // MARK: - Payment Configuration
    static let successURL = "facturas://payment-success"
    static let cancelURL = "facturas://payment-cancel"
    
     
     
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
