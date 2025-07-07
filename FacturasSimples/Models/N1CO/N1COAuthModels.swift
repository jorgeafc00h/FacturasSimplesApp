//
//  N1COAuthModels.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  N1CO authentication models
//

import Foundation

// MARK: - Authentication Models
struct N1COAuthRequest: Codable {
    let clientId: String
    let clientSecret: String
}

struct N1COAuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
}
