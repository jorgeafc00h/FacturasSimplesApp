//
//  CloudKitSyncManager.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI
import SwiftData
import CloudKit

@MainActor
class CloudKitSyncManager: ObservableObject {
    static let shared = CloudKitSyncManager()
    
    @Published var syncStatus: SyncStatus = .unknown
    @Published var syncMessage: String = ""
    @Published var isInitializing = false
    
    enum SyncStatus {
        case unknown
        case checking
        case syncing
        case completed
        case error(String)
        case noAccount
        case notAvailable
    }
    
    private init() {}
    
    /// Performs initial CloudKit sync check when app starts
    func performInitialSync() async {
        guard !isInitializing else { return }
        
        isInitializing = true
        syncStatus = .checking
        syncMessage = "Checking CloudKit availability..."
        
        do {
            // Check CloudKit account status
            let (isAvailable, error) = await CloudKitConfiguration.shared.checkAccountStatus()
            
            if let error = error {
                syncStatus = .error(error.localizedDescription)
                syncMessage = "CloudKit not available: \(error.localizedDescription)"
                isInitializing = false
                return
            }
            
            guard isAvailable else {
                syncStatus = .noAccount
                syncMessage = "iCloud account not available"
                isInitializing = false
                return
            }
            
            // Check if we have any production companies locally
            syncMessage = "Checking for production companies..."
            let hasProductionCompanies = await checkForProductionCompanies()
            
            if !hasProductionCompanies {
                // No production companies locally, try to sync from CloudKit
                syncStatus = .syncing
                syncMessage = "Syncing production companies from iCloud..."
                
                // Force CloudKit to check for remote changes
                await forceCloudKitRefresh()
                
                // Give CloudKit time to sync after forcing refresh
                try await Task.sleep(for: .seconds(5))
                
                // Check again after sync delay
                let hasCompaniesAfterSync = await checkForProductionCompanies()
                
                if hasCompaniesAfterSync {
                    syncStatus = .completed
                    syncMessage = "Successfully synced production companies"
                    
                    // Update customer sync status for all customers
                    let modelContext = await DataModel.shared.getModelContext()
                    DataSyncFilterManager.shared.updateAllDataSyncStatus(context: modelContext)
                    
                    // Also sync customers for the newly synced companies
                    await syncCustomersForProductionCompanies()
                } else {
                    // No production companies found - complete sync successfully to allow onboarding
                    syncStatus = .completed
                    syncMessage = "Sync completed - ready for setup"
                }
            } else {
                // We have production companies, trigger a sync to get latest data
                syncStatus = .syncing
                syncMessage = "Syncing latest customer data..."
                
                // Update customer sync status for existing customers
                let modelContext = await DataModel.shared.getModelContext()
                DataSyncFilterManager.shared.updateAllDataSyncStatus(context: modelContext)
                
                await syncCustomersForProductionCompanies()
                
                syncStatus = .completed
                syncMessage = "Sync completed successfully"
            }
            
        } catch {
            syncStatus = .error(error.localizedDescription)
            syncMessage = "Sync failed: \(error.localizedDescription)"
        }
        
        isInitializing = false
    }
    
    /// Checks if we have any production companies locally
    private func checkForProductionCompanies() async -> Bool {
        do {
            let modelContext = await DataModel.shared.getModelContext()
            let descriptor = FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    !company.isTestAccount
                }
            )
            let productionCompanies = try modelContext.fetch(descriptor)
            return !productionCompanies.isEmpty
        } catch {
            print("Error checking for production companies: \(error)")
            return false
        }
    }
    
    /// Syncs customers for all production companies
    private func syncCustomersForProductionCompanies() async {
        do {
            let modelContext = await DataModel.shared.getModelContext()
            let descriptor = FetchDescriptor<Company>(
                predicate: #Predicate { company in
                    !company.isTestAccount
                }
            )
            let productionCompanies = try modelContext.fetch(descriptor)
            
            for company in productionCompanies {
                try await CloudKitConfiguration.shared.forceCustomerSync(for: company.id)
            }
        } catch {
            print("Error syncing customers: \(error)")
        }
    }
    
    /// Forces CloudKit to check for remote changes
    private func forceCloudKitRefresh() async {
        do {
            // Get the model context and save it to trigger CloudKit sync
            let modelContext = await DataModel.shared.getModelContext()
            
            // Create a temporary object and immediately delete it to force sync
            let tempCompany = Company(nit: "temp", nrc: "temp", nombre: "temp_sync_trigger", isTestAccount: true)
            modelContext.insert(tempCompany)
            
            try modelContext.save()
            
            // Immediately delete the temp object
            modelContext.delete(tempCompany)
            try modelContext.save()
            
            print("CloudKit refresh triggered")
        } catch {
            print("Error forcing CloudKit refresh: \(error)")
        }
    }
    
    /// Force a complete sync refresh
    func forceSyncRefresh() async {
        await performInitialSync()
    }
    
    /// Get a user-friendly status message
    var statusMessage: String {
        switch syncStatus {
        case .unknown:
            return "Ready"
        case .checking:
            return "Checking iCloud..."
        case .syncing:
            return "Syncing from iCloud..."
        case .completed:
            return "Sync completed"
        case .error(let message):
            return "Error: \(message)"
        case .noAccount:
            return "iCloud account not available"
        case .notAvailable:
            return "CloudKit not available"
        }
    }
    
    /// Indicates if sync is currently in progress
    var isSyncing: Bool {
        switch syncStatus {
        case .checking, .syncing:
            return true
        default:
            return false
        }
    }
    
    /// Enhanced diagnostic method to check CloudKit sync status
    func performCloudKitDiagnostic() async -> CloudKitDiagnosticResult {
        var result = CloudKitDiagnosticResult()
        
        do {
            // Check CloudKit account status
            let (isAvailable, error) = await CloudKitConfiguration.shared.checkAccountStatus()
            result.accountAvailable = isAvailable
            result.accountError = error?.localizedDescription
            
            // Check local companies
            let modelContext = await DataModel.shared.getModelContext()
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            result.localCompanies = allCompanies.map { CompanyInfo(id: $0.id, name: $0.nombre, isTest: $0.isTestAccount) }
            
            // Check local customers  
            let allCustomers = try modelContext.fetch(FetchDescriptor<Customer>())
            result.localCustomers = allCustomers.map { CustomerInfo(id: $0.persistentModelID.hashValue.description, name: $0.fullName, companyId: $0.companyOwnerId) }
            
            result.totalLocalCompanies = allCompanies.count
            result.productionCompanies = allCompanies.filter { !$0.isTestAccount }.count
            result.testCompanies = allCompanies.filter { $0.isTestAccount }.count
            
        } catch {
            result.diagnosticError = error.localizedDescription
        }
        
        return result
    }
    
    /// Diagnostic result structure
    struct CloudKitDiagnosticResult {
        var accountAvailable: Bool = false
        var accountError: String?
        var localCompanies: [CompanyInfo] = []
        var localCustomers: [CustomerInfo] = []
        var totalLocalCompanies: Int = 0
        var productionCompanies: Int = 0
        var testCompanies: Int = 0
        var diagnosticError: String?
    }
    
    struct CompanyInfo {
        let id: String
        let name: String
        let isTest: Bool
    }
    
    struct CustomerInfo {
        let id: String
        let name: String
        let companyId: String
    }
    
    /// Convert a test company to production (for fixing sync issues)
    func convertTestCompanyToProduction(companyId: String) async throws {
        let modelContext = await DataModel.shared.getModelContext()
        
        let descriptor = FetchDescriptor<Company>(
            predicate: #Predicate { company in
                company.id == companyId
            }
        )
        
        if let company = try modelContext.fetch(descriptor).first {
            company.isTestAccount = false
            try modelContext.save()
            print("Converted company \(company.nombre) to production")
            
            // Update customer sync status for all customers of this company
            DataSyncFilterManager.shared.updateAllDataSyncStatus(context: modelContext)
            print("Updated customer sync status for company \(company.nombre)")
            
        } else {
            throw NSError(domain: "CompanyNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Company with ID \(companyId) not found"])
        }
    }
}
