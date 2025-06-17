//
//  CloudKitDataCleanupView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI
import SwiftData
import CloudKit

struct CloudKitDataCleanupView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var companyStorageManager: CompanyStorageManager
    
    @State private var cleanupResults: [String] = []
    @State private var isRunning: Bool = false
    @State private var showingConfirmation = false
    @State private var cleanupAction: CleanupAction = .removeTestCompanies
    
    enum CleanupAction: String, CaseIterable {
        case removeTestCompanies = "Remove Test Companies & Their Customers"
        case removeDuplicateCompanies = "Remove Duplicate Companies (Keep Production)"
        case removeOrphanedCustomers = "Remove Customers Without Valid Companies"
        case forceCloudKitSync = "Force CloudKit Sync for Production Data"
        case validateDataIntegrity = "Validate Data Integrity (Read-Only)"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Data Cleanup Actions") {
                    ForEach(CleanupAction.allCases, id: \.self) { action in
                        Button(action.rawValue) {
                            cleanupAction = action
                            if action == .validateDataIntegrity {
                                performCleanup()
                            } else {
                                showingConfirmation = true
                            }
                        }
                        .disabled(isRunning)
                        .foregroundColor(colorForAction(action))
                    }
                    
                    if isRunning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                        }
                    }
                }
                
                if !cleanupResults.isEmpty {
                    Section("Cleanup Results") {
                        ForEach(cleanupResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("Data Cleanup")
            .alert("Confirm Action", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Proceed", role: .destructive) {
                    performCleanup()
                }
            } message: {
                Text("Are you sure you want to \(cleanupAction.rawValue.lowercased())? This action cannot be undone.")
            }
        }
    }
    
    private func colorForAction(_ action: CleanupAction) -> Color {
        switch action {
        case .validateDataIntegrity:
            return .blue
        case .forceCloudKitSync:
            return .orange
        case .removeTestCompanies, .removeDuplicateCompanies, .removeOrphanedCustomers:
            return .red
        }
    }
    
    private func performCleanup() {
        isRunning = true
        cleanupResults.removeAll()
        
        Task {
            await executeCleanupAction()
            
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    @MainActor
    private func executeCleanupAction() async {
        switch cleanupAction {
        case .removeTestCompanies:
            await removeTestCompanies()
        case .removeDuplicateCompanies:
            await removeDuplicateCompanies()
        case .removeOrphanedCustomers:
            await removeOrphanedCustomers()
        case .forceCloudKitSync:
            await forceCloudKitSync()
        case .validateDataIntegrity:
            await validateDataIntegrity()
        }
    }
    
    private func removeTestCompanies() async {
        cleanupResults.append("=== REMOVING TEST COMPANIES ===")
        
        do {
            // Find all test companies
            let testCompanies = try modelContext.fetch(FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    company.isTestAccount == true
                }
            ))
            
            cleanupResults.append("Found \(testCompanies.count) test companies")
            
            for company in testCompanies {
                cleanupResults.append("Removing company: \(company.nombre) (ID: \(company.id))")
                
                // Find and remove customers for this company
                let companyId = company.id
                let customers = try modelContext.fetch(FetchDescriptor<Customer>(
                    predicate: #Predicate { customer in
                        customer.companyOwnerId == companyId
                    }
                ))
                
                cleanupResults.append("  - Removing \(customers.count) customers")
                
                for customer in customers {
                    modelContext.delete(customer)
                }
                
                // Remove the company
                modelContext.delete(company)
            }
            
            try modelContext.save()
            cleanupResults.append("✅ Test companies and their customers removed successfully")
            
        } catch {
            cleanupResults.append("❌ Error: \(error.localizedDescription)")
        }
    }
    
    private func removeDuplicateCompanies() async {
        cleanupResults.append("=== REMOVING DUPLICATE COMPANIES ===")
        
        do {
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            cleanupResults.append("Found \(allCompanies.count) total companies")
            
            // Group by name and NIT
            let groupedCompanies = Dictionary(grouping: allCompanies) { company in
                "\(company.nombre)-\(company.nit)"
            }
            
            for (key, companies) in groupedCompanies where companies.count > 1 {
                cleanupResults.append("Found duplicates for: \(key)")
                
                // Keep production company if exists, otherwise keep the first one
                let productionCompany = companies.first { !$0.isTestAccount }
                let companyToKeep = productionCompany ?? companies.first!
                
                cleanupResults.append("  Keeping: \(companyToKeep.id) (Test: \(companyToKeep.isTestAccount))")
                
                for company in companies where company.id != companyToKeep.id {
                    cleanupResults.append("  Removing: \(company.id) (Test: \(company.isTestAccount))")
                    
                    // Move customers to the kept company
                    let companyId = company.id
                    let customers = try modelContext.fetch(FetchDescriptor<Customer>(
                        predicate: #Predicate { customer in
                            customer.companyOwnerId == companyId
                        }
                    ))
                    
                    for customer in customers {
                        customer.companyOwnerId = companyToKeep.id
                    }
                    
                    modelContext.delete(company)
                }
            }
            
            try modelContext.save()
            cleanupResults.append("✅ Duplicate companies removed successfully")
            
        } catch {
            cleanupResults.append("❌ Error: \(error.localizedDescription)")
        }
    }
    
    private func removeOrphanedCustomers() async {
        cleanupResults.append("=== REMOVING ORPHANED CUSTOMERS ===")
        
        do {
            let allCustomers = try modelContext.fetch(FetchDescriptor<Customer>())
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            
            let validCompanyIds = Set(allCompanies.map { $0.id })
            
            var orphanedCount = 0
            
            for customer in allCustomers {
                if !validCompanyIds.contains(customer.companyOwnerId) {
                    cleanupResults.append("Removing orphaned customer: \(customer.fullName) (Company ID: \(customer.companyOwnerId))")
                    modelContext.delete(customer)
                    orphanedCount += 1
                }
            }
            
            if orphanedCount > 0 {
                try modelContext.save()
                cleanupResults.append("✅ Removed \(orphanedCount) orphaned customers")
            } else {
                cleanupResults.append("✅ No orphaned customers found")
            }
            
        } catch {
            cleanupResults.append("❌ Error: \(error.localizedDescription)")
        }
    }
    
    private func forceCloudKitSync() async {
        cleanupResults.append("=== FORCING CLOUDKIT SYNC ===")
        
        do {
            // Force save to trigger CloudKit sync
            try modelContext.save()
            
            // Use CloudKitConfiguration to force sync
            try await CloudKitConfiguration.shared.forceCustomerSync(for: "production")
            
            cleanupResults.append("✅ CloudKit sync triggered")
            cleanupResults.append("Note: Sync may take a few moments to complete")
            
            // Wait a moment and check sync status
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            let productionCompanies = try modelContext.fetch(FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    !company.isTestAccount
                }
            ))
            
            cleanupResults.append("Production companies after sync: \(productionCompanies.count)")
            
        } catch {
            cleanupResults.append("❌ Error: \(error.localizedDescription)")
        }
    }
    
    private func validateDataIntegrity() async {
        cleanupResults.append("=== DATA INTEGRITY VALIDATION ===")
        
        do {
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            let allCustomers = try modelContext.fetch(FetchDescriptor<Customer>())
            
            cleanupResults.append("Total companies: \(allCompanies.count)")
            cleanupResults.append("Total customers: \(allCustomers.count)")
            
            // Check production companies
            let productionCompanies = allCompanies.filter { !$0.isTestAccount }
            cleanupResults.append("Production companies: \(productionCompanies.count)")
            
            if productionCompanies.isEmpty {
                cleanupResults.append("⚠️ WARNING: No production companies found!")
            }
            
            // Check for duplicate companies
            let companyGroups = Dictionary(grouping: allCompanies) { company in
                "\(company.nombre)-\(company.nit)"
            }
            let duplicates = companyGroups.filter { $1.count > 1 }
            
            if !duplicates.isEmpty {
                cleanupResults.append("⚠️ WARNING: Found \(duplicates.count) duplicate company groups:")
                for (key, companies) in duplicates {
                    cleanupResults.append("  - \(key): \(companies.count) copies")
                }
            }
            
            // Check customer company linkage
            let validCompanyIds = Set(allCompanies.map { $0.id })
            let orphanedCustomers = allCustomers.filter { !validCompanyIds.contains($0.companyOwnerId) }
            
            if !orphanedCustomers.isEmpty {
                cleanupResults.append("⚠️ WARNING: Found \(orphanedCustomers.count) orphaned customers")
            }
            
            // Check current company
            if let currentCompany = companyStorageManager.currentCompany {
                cleanupResults.append("Current company: \(currentCompany.nombre) (Test: \(currentCompany.isTestAccount))")
            } else {
                cleanupResults.append("⚠️ WARNING: No current company set")
            }
            
            cleanupResults.append("✅ Validation complete")
            
        } catch {
            cleanupResults.append("❌ Error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    CloudKitDataCleanupView()
}
