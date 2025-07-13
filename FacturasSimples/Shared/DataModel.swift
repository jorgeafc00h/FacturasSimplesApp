//
//  DataModel.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//

import SwiftUI
import SwiftData
import CloudKit
import CoreData

@MainActor
class DataModel {
    
    static let shared = DataModel()
    private init() {}
    
    // Store the container instances
    private var _modelContainer: ModelContainer?
    private var _purchaseContainer: ModelContainer?
    
    // ModelContainer with separate configurations for CloudKit and local-only data
    var modelContainer: ModelContainer {
        if let container = _modelContainer {
            return container
        }
        
        do {
            // CloudKit configuration - syncs main business data only (NO purchase models)
            let cloudKitConfiguration = ModelConfiguration(
                "CloudKitData",
                schema: Schema([
                    Invoice.self,
                    Customer.self,
                    Product.self,
                    InvoiceDetail.self,
                    Company.self
                ]),
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.kandangalabs.facturassimples")
            )
            
            // Local-only configuration - stores Catalog data locally without CloudKit sync
            let localConfiguration = ModelConfiguration(
                "LocalData",
                schema: Schema([
                    Catalog.self,
                    CatalogOption.self
                ]),
                isStoredInMemoryOnly: false
            )
            
            let container = try ModelContainer(
                for: Invoice.self, Customer.self, Product.self, InvoiceDetail.self, Company.self, 
                     Catalog.self, CatalogOption.self,
                configurations: cloudKitConfiguration, localConfiguration
            )
            _modelContainer = container
            return container
            
        } catch {
            // More detailed error logging to help debug
            print("❌ Failed to create CloudKit model container")
            print("Error: \(error)")
            print("Error description: \(error.localizedDescription)")
            
            // Create a fallback local-only container to prevent complete crash
            do {
                print("🔄 Attempting to create fallback local container...")
                
                let fallbackConfiguration = ModelConfiguration(
                    "FallbackLocalData",
                    schema: Schema([
                        Invoice.self,
                        Customer.self,
                        Product.self,
                        InvoiceDetail.self,
                        Company.self,
                        Catalog.self,
                        CatalogOption.self
                    ]),
                    isStoredInMemoryOnly: false
                )
                
                let fallbackContainer = try ModelContainer(
                    for: Invoice.self, Customer.self, Product.self, InvoiceDetail.self, Company.self, 
                         Catalog.self, CatalogOption.self,
                    configurations: fallbackConfiguration
                )
                print("✅ Successfully created fallback local container")
                _modelContainer = fallbackContainer
                return fallbackContainer
                
            } catch {
                print("❌ Failed to create fallback container: \(error)")
                // As last resort, create in-memory container
                let memoryConfiguration = ModelConfiguration(
                    "MemoryData",
                    schema: Schema([
                        Invoice.self,
                        Customer.self,
                        Product.self,
                        InvoiceDetail.self,
                        Company.self,
                        Catalog.self,
                        CatalogOption.self
                    ]),
                    isStoredInMemoryOnly: true
                )
                
                do {
                    let memoryContainer = try ModelContainer(
                        for: Invoice.self, Customer.self, Product.self, InvoiceDetail.self, Company.self, 
                             Catalog.self, CatalogOption.self,
                        configurations: memoryConfiguration
                    )
                    _modelContainer = memoryContainer
                    return memoryContainer
                } catch {
                    fatalError("Failed to create even in-memory container: \(error)")
                }
            }
        }
    }
    
    // Separate container for purchase models (local-only, no CloudKit)
    var purchaseContainer: ModelContainer {
        if let container = _purchaseContainer {
            return container
        }
        
        // During development, clear any existing purchase store that might have CloudKit metadata
        #if DEBUG
        clearExistingPurchaseStore()
        #endif
        
        do {
            // Try creating an extremely basic in-memory container first to avoid any CloudKit detection
            print("🔄 Creating basic in-memory purchase container to avoid CloudKit detection...")
            let memoryConfig = ModelConfiguration(
                "PurchaseMemoryOnly",
                schema: Schema([
                    PurchaseTransaction.self,
                    UserPurchaseProfile.self,
                    InvoiceConsumption.self,
                    SavedPaymentMethod.self
                ]),
                isStoredInMemoryOnly: true
            )
            
            let memoryContainer = try ModelContainer(
                for: PurchaseTransaction.self, UserPurchaseProfile.self, InvoiceConsumption.self, SavedPaymentMethod.self,
                configurations: memoryConfig
            )
            print("✅ Successfully created in-memory purchase container")
            _purchaseContainer = memoryContainer
            return memoryContainer
            
        } catch {
            print("❌ Failed to create purchase container: \(error)")
            print("🔄 Trying alternative approach with minimal schema...")
            
            // If even in-memory fails, create the most basic container possible
            do {
                // Create a container with just one model to test
                let basicConfig = ModelConfiguration(
                    "BasicPurchase",
                    schema: Schema([PurchaseTransaction.self]),
                    isStoredInMemoryOnly: true
                )
                
                let basicContainer = try ModelContainer(
                    for: PurchaseTransaction.self,
                    configurations: basicConfig
                )
                print("✅ Created basic purchase container with minimal schema")
                _purchaseContainer = basicContainer
                return basicContainer
            } catch {
                print("❌ Even basic purchase container failed: \(error)")
                // Last resort: return the main container and handle purchase models separately
                print("🔄 Using main container as last resort for purchases")
                return modelContainer
            }
        }
    }
    
    // Helper function to clear existing purchase store files during development
    #if DEBUG
    private func clearExistingPurchaseStore() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("⚠️ Could not access documents directory")
            return
        }
        
        let possibleStoreNames = [
            "PurchaseData.store",
            "LocalPurchaseData.store",
            "PurchaseData.sqlite",
            "LocalPurchaseData.sqlite"
        ]
        
        for storeName in possibleStoreNames {
            let storeURL = documentsPath.appendingPathComponent(storeName)
            if FileManager.default.fileExists(atPath: storeURL.path) {
                do {
                    try FileManager.default.removeItem(at: storeURL)
                    print("🗑️ Removed existing purchase store: \(storeName)")
                } catch {
                    print("⚠️ Failed to remove \(storeName): \(error)")
                }
            }
        }
        
        // Also try to clear from Application Support directory
        if let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            for storeName in possibleStoreNames {
                let storeURL = appSupportPath.appendingPathComponent(storeName)
                if FileManager.default.fileExists(atPath: storeURL.path) {
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        print("🗑️ Removed existing purchase store from App Support: \(storeName)")
                    } catch {
                        print("⚠️ Failed to remove \(storeName) from App Support: \(error)")
                    }
                }
            }
        }
    }
    #endif
    
    // Function to get the model context
    func getModelContext() -> ModelContext {
        return modelContainer.mainContext
    }
    
    // Function to get the purchase model context
    func getPurchaseModelContext() -> ModelContext {
        return purchaseContainer.mainContext
    }
}

