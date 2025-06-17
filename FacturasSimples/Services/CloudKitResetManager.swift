//
//  CloudKitResetManager.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI
import SwiftData
import CloudKit

@MainActor
class CloudKitResetManager: ObservableObject {
    static let shared = CloudKitResetManager()
    
    @Published var isResetting = false
    @Published var resetProgress = ""
    
    private init() {}
    
    /// Completely resets all CloudKit and local data
    func performNuclearReset() async throws {
        isResetting = true
        resetProgress = "Starting complete reset..."
        
        do {
            // Step 1: Clear all local data
            resetProgress = "Clearing local data..."
            try await clearAllLocalData()
            
            // Step 2: Clear CloudKit data by deleting all records
            resetProgress = "Clearing CloudKit data..."
            try await clearAllCloudKitData()
            
            resetProgress = "Reset completed successfully"
            
            // Wait a moment before finishing
            try await Task.sleep(for: .seconds(1))
            
        } catch {
            resetProgress = "Reset failed: \(error.localizedDescription)"
            throw error
        }
        
        isResetting = false
    }
    
    /// Clears all local SwiftData
    private func clearAllLocalData() async throws {
        let modelContext = DataModel.shared.getModelContext()
        
        // Delete all companies (will cascade to customers, invoices, etc.)
        let companyDescriptor = FetchDescriptor<Company>()
        let companies = try modelContext.fetch(companyDescriptor)
        
        for company in companies {
            modelContext.delete(company)
        }
        
        // Delete any orphaned customers
        let customerDescriptor = FetchDescriptor<Customer>()
        let customers = try modelContext.fetch(customerDescriptor)
        
        for customer in customers {
            modelContext.delete(customer)
        }
        
        // Delete any orphaned products
        let productDescriptor = FetchDescriptor<Product>()
        let products = try modelContext.fetch(productDescriptor)
        
        for product in products {
            modelContext.delete(product)
        }
        
        // Delete any orphaned invoices
        let invoiceDescriptor = FetchDescriptor<Invoice>()
        let invoices = try modelContext.fetch(invoiceDescriptor)
        
        for invoice in invoices {
            modelContext.delete(invoice)
        }
        
        try modelContext.save()
    }
    
    /// Clears all CloudKit data by deleting records
    private func clearAllCloudKitData() async throws {
        let container = CKContainer(identifier: "iCloud.kandangalabs.facturassimples")
        let database = container.privateCloudDatabase
        
        // Record types to clear
        let recordTypes = ["Company", "Customer", "Product", "Invoice", "InvoiceDetail", "Catalog", "CatalogOption"]
        
        for recordType in recordTypes {
            try await deleteAllRecordsOfType(recordType, from: database)
        }
    }
    
    /// Deletes all records of a specific type from CloudKit
    private func deleteAllRecordsOfType(_ recordType: String, from database: CKDatabase) async throws {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        
        var allRecordIDs: [CKRecord.ID] = []
        var cursor: CKQueryOperation.Cursor? = nil
        
        repeat {
            let (matchResults, queryCursor) = try await database.records(matching: query, inZoneWith: nil, desiredKeys: [], resultsLimit: 200)
            cursor = queryCursor
            
            for (recordID, result) in matchResults {
                switch result {
                case .success(_):
                    allRecordIDs.append(recordID)
                case .failure(let error):
                    print("Error fetching record \(recordID): \(error)")
                }
            }
        } while cursor != nil
        
        // Delete records in batches of 400 (CloudKit limit)
        let batchSize = 400
        for i in stride(from: 0, to: allRecordIDs.count, by: batchSize) {
            let endIndex = min(i + batchSize, allRecordIDs.count)
            let batch = Array(allRecordIDs[i..<endIndex])
            
            if !batch.isEmpty {
                let (_, deleteResults) = try await database.modifyRecords(saving: [], deleting: batch)
                
                for (recordID, result) in deleteResults {
                    switch result {
                    case .success():
                        print("Successfully deleted record: \(recordID)")
                    case .failure(let error):
                        print("Failed to delete record \(recordID): \(error)")
                    }
                }
            }
        }
    }
}
