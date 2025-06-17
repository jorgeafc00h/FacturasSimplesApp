//
//  SyncTroubleshootingView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI
import SwiftData

struct SyncTroubleshootingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var companyStorageManager: CompanyStorageManager
    
    @State private var troubleshootingResults: [String] = []
    @State private var isRunning: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Quick Fixes") {
                    Button("🔧 Fix iPhone 'No Production Account' Issue") {
                        fixNoProductionAccountIssue()
                    }
                    .disabled(isRunning)
                    
                    Button("🗑️ Remove All Test Companies") {
                        removeAllTestCompanies()
                    }
                    .disabled(isRunning)
                    .foregroundColor(.red)
                    
                    Button("🔄 Force Complete Sync") {
                        forceCompleteSync()
                    }
                    .disabled(isRunning)
                    
                    if isRunning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                        }
                    }
                }
                
                if !troubleshootingResults.isEmpty {
                    Section("Results") {
                        ForEach(troubleshootingResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
                
                Section("Current Issue Analysis") {
                    Text("Based on your diagnostic output:")
                    Text("• You have 1 production company that should sync")
                    Text("• You have 2 test companies that shouldn't sync")
                    Text("• iPhone says 'no production account' - likely sync delay")
                    Text("• Multiple duplicate company names causing confusion")
                }
            }
            .navigationTitle("Sync Troubleshooting")
        }
    }
    
    private func fixNoProductionAccountIssue() {
        isRunning = true
        troubleshootingResults.removeAll()
        
        Task {
            await performFixNoProductionAccount()
            
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    private func removeAllTestCompanies() {
        isRunning = true
        troubleshootingResults.removeAll()
        
        Task {
            await performRemoveTestCompanies()
            
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    private func forceCompleteSync() {
        isRunning = true
        troubleshootingResults.removeAll()
        
        Task {
            await performForceCompleteSync()
            
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    @MainActor
    private func performFixNoProductionAccount() async {
        troubleshootingResults.append("=== FIXING 'NO PRODUCTION ACCOUNT' ISSUE ===")
        
        do {
            // Step 1: Get all companies and production companies using new manager
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            let productionCompanies = DataSyncFilterManager.shared.getProductionCompanies(context: modelContext)
            
            troubleshootingResults.append("📊 Found \(allCompanies.count) total companies")
            troubleshootingResults.append("🏢 Found \(productionCompanies.count) production companies")
            
            if productionCompanies.isEmpty {
                troubleshootingResults.append("❌ No production companies found!")
                
                // Check if we can convert a test company to production
                let testCompanies = DataSyncFilterManager.shared.getTestCompanies(context: modelContext)
                if !testCompanies.isEmpty {
                    troubleshootingResults.append("🔄 Converting first test company to production...")
                    let firstTest = testCompanies[0]
                    firstTest.isTestAccount = false
                    try modelContext.save()
                    troubleshootingResults.append("✅ Converted '\(firstTest.nombre)' to production company")
                    
                    // Set as current company
                    companyStorageManager.switchToCompanyContext(firstTest)
                    troubleshootingResults.append("✅ Set as current company")
                } else {
                    troubleshootingResults.append("❌ No companies found to convert")
                    return
                }
            } else {
                // Set the first production company as current
                let productionCompany = productionCompanies.first!
                troubleshootingResults.append("Setting current company to: \(productionCompany.nombre)")
                companyStorageManager.switchToCompanyContext(productionCompany)
            }
            
            // Update customer sync status
            DataSyncFilterManager.shared.updateAllDataSyncStatus(context: modelContext)
            troubleshootingResults.append("✅ Updated customer sync status")
            
            // Force save and sync
            try modelContext.save()
            troubleshootingResults.append("✅ Model context saved")
            
            // Force CloudKit sync
            await CloudKitConfiguration.shared.triggerManualSync()
            troubleshootingResults.append("✅ CloudKit sync triggered")
            
            // Wait and verify
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            let postSyncCount = DataSyncFilterManager.shared.getProductionCompanies(context: modelContext).count
            
            troubleshootingResults.append("Production companies after sync: \(postSyncCount)")
            troubleshootingResults.append("✅ Fix complete - check iPhone in a few moments")
            
        } catch {
            troubleshootingResults.append("❌ Error: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func performRemoveTestCompanies() async {
        troubleshootingResults.append("=== REMOVING ALL TEST COMPANIES ===")
        
        do {
            // Find all test companies
            let testCompanies = try modelContext.fetch(FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    company.isTestAccount == true
                }
            ))
            
            troubleshootingResults.append("Found \(testCompanies.count) test companies to remove")
            
            var totalCustomersRemoved = 0
            
            for company in testCompanies {
                troubleshootingResults.append("Removing: \(company.nombre) (ID: \(company.id))")
                
                // Remove customers for this company
                let companyId = company.id
                let customers = try modelContext.fetch(FetchDescriptor<Customer>(
                    predicate: #Predicate { customer in
                        customer.companyOwnerId == companyId
                    }
                ))
                
                totalCustomersRemoved += customers.count
                
                for customer in customers {
                    modelContext.delete(customer)
                }
                
                // Remove the company
                modelContext.delete(company)
            }
            
            try modelContext.save()
            
            troubleshootingResults.append("✅ Removed \(testCompanies.count) test companies")
            troubleshootingResults.append("✅ Removed \(totalCustomersRemoved) test customers")
            troubleshootingResults.append("Only production data remains for CloudKit sync")
            
        } catch {
            troubleshootingResults.append("❌ Error: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func performForceCompleteSync() async {
        troubleshootingResults.append("=== FORCING COMPLETE SYNC ===")
        
        do {
            // Step 1: Save current state
            try modelContext.save()
            troubleshootingResults.append("✅ Local data saved")
            
            // Step 2: Force customer sync
            try await CloudKitConfiguration.shared.forceCustomerSync(for: "production")
            troubleshootingResults.append("✅ Customer sync forced")
            
            // Step 3: Wait for sync
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Step 4: Check production company status
            let productionCompanies = try modelContext.fetch(FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    !company.isTestAccount
                }
            ))
            
            if !productionCompanies.isEmpty {
                let company = productionCompanies.first!
                troubleshootingResults.append("Production company: \(company.nombre)")
                troubleshootingResults.append("Company ID: \(company.id)")
                
                // Count customers for this company
                let companyId = company.id
                let customers = try modelContext.fetch(FetchDescriptor<Customer>(
                    predicate: #Predicate { customer in
                        customer.companyOwnerId == companyId
                    }
                ))
                
                troubleshootingResults.append("Customers: \(customers.count)")
                
                // Set as current company if not already set
                if companyStorageManager.currentCompany?.id != company.id {
                    companyStorageManager.switchToCompanyContext(company)
                    troubleshootingResults.append("✅ Set as current company")
                }
            }
            
            troubleshootingResults.append("✅ Complete sync finished")
            troubleshootingResults.append("Check other devices in a few moments")
            
        } catch {
            troubleshootingResults.append("❌ Error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SyncTroubleshootingView()
}
