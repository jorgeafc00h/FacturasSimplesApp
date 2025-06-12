//
//  CompanyStorageManager.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/10/25.
//

import Foundation
import SwiftData
import CloudKit

// Notification for when company data is updated
extension Notification.Name {
    static let companyDataUpdated = Notification.Name("companyDataUpdated")
}

@MainActor
class CompanyStorageManager: ObservableObject {
    static let shared = CompanyStorageManager()
    
    @Published var currentCompany: Company?
    @Published var currentContext: ModelContext
    
    private init() {
        // Use unified CloudKit container for all models
        self.currentContext = DataModel.shared.getModelContext()
    }
    
    // Switch to a specific company (all companies are in the same container now)
    func switchToCompanyContext(_ company: Company) {
        currentCompany = company
        print("Switched to company: \(company.nombre)")
    }
    
    // Get all companies from the unified storage
    func getAllCompanies() throws -> [Company] {
        let descriptor = FetchDescriptor<Company>()
        return try currentContext.fetch(descriptor)
    }
    
    // Save company to the unified storage
    func saveCompany(_ company: Company) throws {
        // Check if company already exists
        let descriptor = FetchDescriptor<Company>()
        let allCompanies = try currentContext.fetch(descriptor)
        let existingCompany = allCompanies.first { $0.id == company.id }
        
        if existingCompany == nil {
            currentContext.insert(company)
        }
        
        try currentContext.save()
        
        // Update current company if this is the active one
        if currentCompany?.id == company.id {
            switchToCompanyContext(company)
        }
    }
    
    // Delete company from the unified storage
    func deleteCompany(_ company: Company) throws {
        let descriptor = FetchDescriptor<Company>()
        let allCompanies = try currentContext.fetch(descriptor)
        if let existingCompany = allCompanies.first(where: { $0.id == company.id }) {
            currentContext.delete(existingCompany)
            try currentContext.save()
        }
    }
    
    // Toggle test/production flag (no storage change needed now)
    func toggleCompanyEnvironment(_ company: Company) throws {
        company.isTestAccount.toggle()
        try saveCompany(company)
        print("Toggled company '\(company.nombre)' environment to \(company.isTestAccount ? "Test" : "Production")")
    }
    
    // Get invoices for current company context
    func getInvoicesForCurrentCompany(companyId: String) throws -> [Invoice] {
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate<Invoice> { invoice in
                invoice.customer?.companyOwnerId == companyId
            }
        )
        return try currentContext.fetch(descriptor)
    }
    
    // Get customers for current company context
    func getCustomersForCurrentCompany(companyId: String) throws -> [Customer] {
        let descriptor = FetchDescriptor<Customer>(
            predicate: #Predicate<Customer> { customer in
                customer.companyOwnerId == companyId
            }
        )
        return try currentContext.fetch(descriptor)
    }
    
    // Get products for current company context
    func getProductsForCurrentCompany(companyId: String) throws -> [Product] {
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate<Product> { product in
                product.companyId == companyId
            }
        )
        return try currentContext.fetch(descriptor)
    }
}
