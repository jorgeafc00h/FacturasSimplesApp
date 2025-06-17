//
//  CloudKitDiagnosticView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI
import SwiftData
import CloudKit

struct CloudKitDiagnosticView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var companyStorageManager: CompanyStorageManager
    
    @State private var diagnosticResults: [String] = []
    @State private var isRunning: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section("CloudKit Sync Diagnostic") {
                    Button("Run Diagnostic") {
                        runDiagnostic()
                    }
                    .disabled(isRunning)
                    
                    if isRunning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Running diagnostic...")
                        }
                    }
                }
                
                if !diagnosticResults.isEmpty {
                    Section("Results") {
                        ForEach(diagnosticResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("CloudKit Diagnostic")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Copy Results") {
                        let results = diagnosticResults.joined(separator: "\n")
                        UIPasteboard.general.string = results
                    }
                    .disabled(diagnosticResults.isEmpty)
                }
            }
        }
    }
    
    private func runDiagnostic() {
        isRunning = true
        diagnosticResults = []
        
        Task {
            await performDiagnostic()
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    private func performDiagnostic() async {
        var results: [String] = []
        
        // Check CloudKit account status
        let (accountAvailable, accountError) = await CloudKitConfiguration.shared.checkAccountStatus()
        results.append("=== CLOUDKIT ACCOUNT STATUS ===")
        results.append("Account Available: \(accountAvailable)")
        if let error = accountError {
            results.append("Account Error: \(error.localizedDescription)")
        }
        results.append("")
        
        // Check companies
        results.append("=== COMPANIES ===")
        do {
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            results.append("Total Companies: \(allCompanies.count)")
            
            let productionCompanies = allCompanies.filter { !$0.isTestAccount }
            let testCompanies = allCompanies.filter { $0.isTestAccount }
            
            results.append("Production Companies: \(productionCompanies.count)")
            results.append("Test Companies: \(testCompanies.count)")
            results.append("")
            
            for company in productionCompanies {
                results.append("Production Company:")
                results.append("  ID: \(company.id)")
                results.append("  Name: \(company.nombre)")
                results.append("  NIT: \(company.nit)")
                results.append("  Should Sync: \(company.shouldSyncToCloudKit)")
                results.append("")
            }
            
            // Check current company
            if let currentCompany = companyStorageManager.currentCompany {
                results.append("=== CURRENT COMPANY ===")
                results.append("ID: \(currentCompany.id)")
                results.append("Name: \(currentCompany.nombre)")
                results.append("Is Test: \(currentCompany.isTestAccount)")
                results.append("Should Sync: \(currentCompany.shouldSyncToCloudKit)")
                results.append("")
            }
            
        } catch {
            results.append("Error fetching companies: \(error)")
        }
        
        // Check customers
        results.append("=== CUSTOMERS ===")
        do {
            let allCustomers = try modelContext.fetch(FetchDescriptor<Customer>())
            results.append("Total Customers: \(allCustomers.count)")
            
            // Group by company
            let customersByCompany = Dictionary(grouping: allCustomers) { $0.companyOwnerId }
            
            for (companyId, customers) in customersByCompany {
                let company = try? modelContext.fetch(FetchDescriptor<Company>(
                    predicate: #Predicate { $0.id == companyId }
                )).first
                
                results.append("Company ID: \(companyId)")
                results.append("  Company Name: \(company?.nombre ?? "Unknown")")
                results.append("  Is Test: \(company?.isTestAccount ?? true)")
                results.append("  Customers: \(customers.count)")
                
                for customer in customers.prefix(3) {
                    results.append("    - \(customer.firstName) \(customer.lastName) (\(customer.email))")
                }
                
                if customers.count > 3 {
                    results.append("    ... and \(customers.count - 3) more")
                }
                results.append("")
            }
            
        } catch {
            results.append("Error fetching customers: \(error)")
        }
        
        // Check CloudKit container configuration
        results.append("=== CLOUDKIT CONFIGURATION ===")
        results.append("Container ID: iCloud.kandangalabs.facturassimples")
        results.append("Database: Private")
        results.append("Schema Models: Invoice, Customer, Catalog, CatalogOption, Product, InvoiceDetail, Company")
        results.append("")
        
        // Check recent changes
        results.append("=== RECENT ACTIVITY ===")
        do {
            let recentCustomers = try modelContext.fetch(FetchDescriptor<Customer>(
                sortBy: [SortDescriptor(\.firstName)]
            ))
            results.append("Customers created in sync order:")
            for customer in recentCustomers.prefix(5) {
                results.append("  - \(customer.firstName) \(customer.lastName) (Company: \(customer.companyOwnerId))")
            }
        } catch {
            results.append("Error fetching recent customers: \(error)")
        }
        
        await MainActor.run {
            self.diagnosticResults = results
        }
    }
}

#Preview {
    CloudKitDiagnosticView()
}
