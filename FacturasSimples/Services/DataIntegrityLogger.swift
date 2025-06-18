//
//  DataIntegrityLogger.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/16/25.
//

import SwiftUI
import SwiftData

@MainActor
class DataIntegrityLogger {
    static let shared = DataIntegrityLogger()
    
    private init() {}
    
    func logCustomerCreation(companyId: String, customerName: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        print("[\(timestamp)] CUSTOMER_CREATION: Company ID '\(companyId)' for customer '\(customerName)'")
        
        // Log current companies in database
        let modelContext = DataModel.shared.getModelContext()
        do {
            let companies = try modelContext.fetch(FetchDescriptor<Company>())
            let companyIds = companies.map { $0.id }
            print("[\(timestamp)] AVAILABLE_COMPANIES: \(companyIds)")
            
            let selectedCompanyExists = companies.contains { $0.id == companyId }
            print("[\(timestamp)] COMPANY_EXISTS: \(selectedCompanyExists)")
            
            if let matchingCompany = companies.first(where: { $0.id == companyId }) {
                print("[\(timestamp)] MATCHED_COMPANY: '\(matchingCompany.nombre)' (Test: \(matchingCompany.isTestAccount))")
            }
        } catch {
            print("[\(timestamp)] ERROR_FETCHING_COMPANIES: \(error)")
        }
    }
    
    func logAppStorageState() {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let selectedCompanyId = UserDefaults.standard.string(forKey: "selectedCompanyIdentifier") ?? ""
        print("[\(timestamp)] APP_STORAGE_COMPANY_ID: '\(selectedCompanyId)'")
    }
    
    func logCustomerSaved(customer: Customer) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        print("[\(timestamp)] CUSTOMER_SAVED: '\(customer.firstName) \(customer.lastName)' with companyOwnerId '\(customer.companyOwnerId)'")
    }
    
    func logOrphanCheck() {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        print("[\(timestamp)] ORPHAN_CHECK_STARTED")
        
        let modelContext = DataModel.shared.getModelContext()
        do {
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            let allCustomers = try modelContext.fetch(FetchDescriptor<Customer>())
            let validCompanyIds = Set(allCompanies.map { $0.id })
            
            let orphanedCustomers = allCustomers.filter { !validCompanyIds.contains($0.companyOwnerId) }
            
            print("[\(timestamp)] TOTAL_COMPANIES: \(allCompanies.count)")
            print("[\(timestamp)] TOTAL_CUSTOMERS: \(allCustomers.count)")
            print("[\(timestamp)] ORPHANED_CUSTOMERS: \(orphanedCustomers.count)")
            
            for orphan in orphanedCustomers {
                print("[\(timestamp)] ORPHAN: '\(orphan.firstName) \(orphan.lastName)' with companyOwnerId '\(orphan.companyOwnerId)'")
            }
        } catch {
            print("[\(timestamp)] ERROR_ORPHAN_CHECK: \(error)")
        }
    }
    
    // Test function to verify logging is working
    func testLogging() {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        print("[\(timestamp)] 🧪 TEST_LOGGING: DataIntegrityLogger is working correctly")
        logAppStorageState()
    }
}
