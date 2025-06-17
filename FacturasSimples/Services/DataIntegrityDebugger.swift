//
//  DataIntegrityDebugger.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/16/25.
//

import SwiftUI
import SwiftData

@MainActor
struct DataIntegrityDebugger {
    let modelContext: ModelContext
    
    init() {
        self.modelContext = DataModel.shared.getModelContext()
    }
    
    func getDiagnosticString() -> String {
        var results: [String] = []
        results.append("=== DATA INTEGRITY DIAGNOSTIC ===")
        
        do {
            // Get all companies
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            results.append("Total companies: \(allCompanies.count)")
            
            if allCompanies.isEmpty {
                results.append("⚠️ WARNING: No companies found in database!")
                results.append("This means the onboarding process may not have completed properly.")
            }
            
            for (index, company) in allCompanies.enumerated() {
                results.append("\nCompany \(index + 1):")
                results.append("  Name: \(company.nombre)")
                results.append("  ID: \(company.id)")
                results.append("  Is Test: \(company.isTestAccount)")
                results.append("  NIT: \(company.nit)")
                results.append("  NRC: \(company.nrc)")
            }
            
            // Get all customers
            let allCustomers = try modelContext.fetch(FetchDescriptor<Customer>())
            results.append("\nTotal customers: \(allCustomers.count)")
            
            let validCompanyIds = Set(allCompanies.map { $0.id })
            results.append("Valid company IDs: \(Array(validCompanyIds))")
            
            if allCustomers.isEmpty {
                results.append("No customers found in database.")
            } else {
                for (index, customer) in allCustomers.enumerated() {
                    let isOrphaned = !validCompanyIds.contains(customer.companyOwnerId)
                    results.append("\nCustomer \(index + 1):")
                    results.append("  Name: \(customer.firstName) \(customer.lastName)")
                    results.append("  Company Owner ID: '\(customer.companyOwnerId)'")
                    results.append("  Is Orphaned: \(isOrphaned ? "YES ❌" : "NO ✅")")
                    results.append("  Should Sync: \(customer.shouldSyncToCloudKit)")
                    
                    if let matchingCompany = allCompanies.first(where: { $0.id == customer.companyOwnerId }) {
                        results.append("  Linked Company: \(matchingCompany.nombre) (Test: \(matchingCompany.isTestAccount))")
                    } else {
                        results.append("  ❌ NO MATCHING COMPANY FOUND!")
                        results.append("     Available IDs: \(Array(validCompanyIds))")
                        results.append("     Customer's ID: '\(customer.companyOwnerId)'")
                        
                        // Try to find similar IDs (in case of string comparison issues)
                        for companyId in validCompanyIds {
                            if companyId.contains(customer.companyOwnerId) || customer.companyOwnerId.contains(companyId) {
                                results.append("     Similar ID found: '\(companyId)'")
                            }
                        }
                    }
                }
            }
            
            // Check AppStorage value
            let selectedCompanyId = UserDefaults.standard.string(forKey: "selectedCompanyIdentifier") ?? ""
            results.append("\n=== APP STORAGE STATE ===")
            results.append("selectedCompanyIdentifier: '\(selectedCompanyId)'")
            
            if selectedCompanyId.isEmpty {
                results.append("⚠️ WARNING: No company selected in AppStorage!")
            } else if let selectedCompany = allCompanies.first(where: { $0.id == selectedCompanyId }) {
                results.append("✅ Selected company: \(selectedCompany.nombre) (Test: \(selectedCompany.isTestAccount))")
            } else {
                results.append("❌ Selected company ID does not match any existing company!")
                results.append("   Available company IDs: \(Array(validCompanyIds))")
                results.append("   Selected ID: '\(selectedCompanyId)'")
            }
            
            // Additional diagnostic checks
            results.append("\n=== ADDITIONAL CHECKS ===")
            
            // Check for duplicate company IDs
            let companyIds = allCompanies.map { $0.id }
            let uniqueIds = Set(companyIds)
            if companyIds.count != uniqueIds.count {
                results.append("⚠️ WARNING: Duplicate company IDs found!")
                let duplicates = Dictionary(grouping: companyIds, by: { $0 }).filter { $1.count > 1 }
                for (id, instances) in duplicates {
                    results.append("   ID '\(id)' appears \(instances.count) times")
                }
            }
            
            // Check production vs test companies
            let productionCompanies = allCompanies.filter { !$0.isTestAccount }
            let testCompanies = allCompanies.filter { $0.isTestAccount }
            results.append("Production companies: \(productionCompanies.count)")
            results.append("Test companies: \(testCompanies.count)")
            
            if !selectedCompanyId.isEmpty {
                let selectedIsProduction = allCompanies.first(where: { $0.id == selectedCompanyId })?.isTestAccount == false
                results.append("Selected company is production: \(selectedIsProduction)")
            }
            
        } catch {
            results.append("❌ Error in diagnostic: \(error)")
        }
        
        results.append("\n=== END DIAGNOSTIC ===")
        return results.joined(separator: "\n")
    }
    
    func printDetailedDiagnostic() {
        print(getDiagnosticString())
    }
}
