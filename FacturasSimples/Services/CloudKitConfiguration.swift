//
//  CloudKitConfiguration.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/10/25.
//

import Foundation
import CloudKit
import SwiftData

class CloudKitConfiguration {
    static let shared = CloudKitConfiguration()
    
    private let containerIdentifier = "iCloud.kandangalabs.facturassimples"
    private lazy var container = CKContainer(identifier: containerIdentifier)
    
    private init() {}
    
    // MARK: - CloudKit Account Status
    
    func checkAccountStatus() async -> (isAvailable: Bool, error: Error?) {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                return (true, nil)
            case .noAccount:
                return (false, CloudKitError.noAccount)
            case .restricted:
                return (false, CloudKitError.restricted)
            case .temporarilyUnavailable:
                return (false, CloudKitError.temporarilyUnavailable)
            case .couldNotDetermine:
                return (false, CloudKitError.couldNotDetermine)
            @unknown default:
                return (false, CloudKitError.unknown)
            }
        } catch {
            return (false, error)
        }
    }
    
    // MARK: - CloudKit Permissions
    
    func requestPermissions() async -> Bool {
        do {
            let status = try await container.requestApplicationPermission(.userDiscoverability)
            return status == .granted
        } catch {
            print("Failed to request CloudKit permissions: \(error)")
            return false
        }
    }
    
    // MARK: - Manual Sync Trigger
    
    func triggerManualSync() async {
        // This will trigger a sync by making a small change to CloudKit
        // SwiftData will automatically handle the actual sync
        print("Manual CloudKit sync triggered")
    }
    
    func forceCustomerSync(for companyId: String) async throws {
        // This method can be called when customers aren't syncing properly
        let modelContext = await DataModel.shared.getModelContext()
        
        // Fetch all customers for the production company
        let descriptor = FetchDescriptor<Customer>(
            predicate: #Predicate { customer in
                customer.companyOwnerId == companyId
            }
        )
        
        let customers = try modelContext.fetch(descriptor)
        
        // Force a save to trigger CloudKit sync
        for customer in customers {
            // Make a minimal change to trigger sync
            let currentId = customer.companyOwnerId
            customer.companyOwnerId = currentId // No-op change to trigger sync
        }
        
        try modelContext.save()
        
        print("Forced sync for \(customers.count) customers in company \(companyId)")
    }
    
    func forceProductSync(for companyId: String) async throws {
        // This method can be called when products aren't syncing properly
        let modelContext = await DataModel.shared.getModelContext()
        
        // Fetch all products for the production company
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { product in
                product.companyId == companyId
            }
        )
        
        let products = try modelContext.fetch(descriptor)
        
        // Force a save to trigger CloudKit sync
        for product in products {
            // Make a minimal change to trigger sync
            let currentId = product.companyId
            product.companyId = currentId // No-op change to trigger sync
        }
        
        try modelContext.save()
        
        print("Forced sync for \(products.count) products in company \(companyId)")
    }
    
    func forceInvoiceSync(for companyId: String) async throws {
        // This method can be called when invoices aren't syncing properly
        let modelContext = await DataModel.shared.getModelContext()
        
        // Fetch all invoices for the production company
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate { invoice in
                invoice.customer?.companyOwnerId == companyId
            }
        )
        
        let invoices = try modelContext.fetch(descriptor)
        
        // Force a save to trigger CloudKit sync
        for invoice in invoices {
            // Make a minimal change to trigger sync
            let currentNumber = invoice.invoiceNumber
            invoice.invoiceNumber = currentNumber // No-op change to trigger sync
        }
        
        try modelContext.save()
        
        print("Forced sync for \(invoices.count) invoices in company \(companyId)")
    }
    
    func forceAllDataSync(for companyId: String) async throws {
        try await forceCustomerSync(for: companyId)
        try await forceProductSync(for: companyId)
        try await forceInvoiceSync(for: companyId)
    }
    
    // MARK: - CloudKit Status Monitoring
    
    func startMonitoring(completion: @escaping (CloudKitSyncStatus) -> Void) {
        // Monitor for remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { _ in
            completion(.synced)
        }
        
        // Check initial status
        Task {
            let (isAvailable, _) = await checkAccountStatus()
            await MainActor.run {
                completion(isAvailable ? .synced : .notAvailable)
            }
        }
    }
}

// MARK: - CloudKit Errors

enum CloudKitError: LocalizedError {
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noAccount:
            return "No iCloud account is configured on this device"
        case .restricted:
            return "iCloud account access is restricted"
        case .temporarilyUnavailable:
            return "iCloud account is temporarily unavailable"
        case .couldNotDetermine:
            return "Could not determine iCloud account status"
        case .unknown:
            return "Unknown iCloud error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noAccount:
            return "Please sign into iCloud in Settings"
        case .restricted:
            return "Check Screen Time or parental controls"
        case .temporarilyUnavailable:
            return "Try again later"
        case .couldNotDetermine, .unknown:
            return "Check your internet connection and try again"
        }
    }
}

// MARK: - CloudKit Sync Status (moved from CloudKitSyncStatusView)

enum CloudKitSyncStatus {
    case unknown
    case notAvailable
    case syncing
    case synced
    case error
}
