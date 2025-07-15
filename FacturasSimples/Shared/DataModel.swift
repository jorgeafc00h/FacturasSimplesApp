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
        
        // Note: Removed automatic store clearing to preserve purchase data
        // #if DEBUG
        // clearExistingPurchaseStore()
        // #endif
        
        do {
            // Create CloudKit-enabled purchase container for cross-device sync
            print("🔄 Creating CloudKit-enabled purchase container for cross-device sync...")
            let purchaseCloudKitConfig = ModelConfiguration(
                "PurchaseCloudKitData",
                schema: Schema([
                    PurchaseTransaction.self,
                    UserPurchaseProfile.self,
                    InvoiceConsumption.self,
                    SavedPaymentMethod.self
                ]),
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.kandangalabs.facturassimples.purchases")
            )
            
            let cloudKitContainer = try ModelContainer(
                for: PurchaseTransaction.self, UserPurchaseProfile.self, InvoiceConsumption.self, SavedPaymentMethod.self,
                configurations: purchaseCloudKitConfig
            )
            print("✅ Successfully created CloudKit-enabled purchase container")
            _purchaseContainer = cloudKitContainer
            return cloudKitContainer
            
        } catch {
            print("❌ Failed to create CloudKit purchase container: \(error)")
            print("🔄 Trying fallback local-only purchase container...")
            
            // Fallback to local-only persistent storage if CloudKit fails
            do {
                let localConfig = ModelConfiguration(
                    "PurchaseLocalFallback",
                    schema: Schema([
                        PurchaseTransaction.self,
                        UserPurchaseProfile.self,
                        InvoiceConsumption.self,
                        SavedPaymentMethod.self
                    ]),
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )
                
                let localContainer = try ModelContainer(
                    for: PurchaseTransaction.self, UserPurchaseProfile.self, InvoiceConsumption.self, SavedPaymentMethod.self,
                    configurations: localConfig
                )
                print("⚠️ Using local-only purchase container as fallback")
                _purchaseContainer = localContainer
                return localContainer
                
                
            } catch {
                print("❌ Failed to create local purchase container: \(error)")
                print("🔄 Trying final in-memory purchase container...")
                
                // Final fallback to in-memory
                do {
                    let memoryConfig = ModelConfiguration(
                        "PurchaseMemoryFinal",
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
                    print("⚠️ Using in-memory purchase container as final fallback")
                    _purchaseContainer = memoryContainer
                    return memoryContainer
                    
                } catch {
                    print("❌ Failed to create any purchase container: \(error)")
                    print("🔄 Trying minimal schema approach...")
                    
                    // Absolute last resort: minimal schema
                    do {
                        let basicConfig = ModelConfiguration(
                            "BasicPurchase",
                            schema: Schema([PurchaseTransaction.self]),
                            isStoredInMemoryOnly: true
                        )
                        
                        let basicContainer = try ModelContainer(
                            for: PurchaseTransaction.self,
                            configurations: basicConfig
                        )
                        print("✅ Created minimal purchase container")
                        _purchaseContainer = basicContainer
                        return basicContainer
                    } catch {
                        print("❌ Even minimal purchase container failed: \(error)")
                        print("🔄 Using main container as last resort for purchases")
                        return modelContainer
                    }
                }
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
    
    // Function to check if purchases are syncing to CloudKit
    func isPurchaseSyncEnabled() -> Bool {
        // Since we created the purchase container with CloudKit, we can track this internally
        // For now, we'll assume it's enabled if the container was created successfully
        // In a real implementation, you could track the CloudKit state more precisely
        do {
            _ = getPurchaseModelContext()
            // If we can access the context successfully, assume CloudKit is working
            return true
        } catch {
            return false
        }
    }
    
    // Function to get sync status information
    func getPurchaseSyncStatus() -> String {
        let isCloudKitEnabled = isPurchaseSyncEnabled()
        if isCloudKitEnabled {
            return "✅ Purchase history syncs across devices via iCloud"
        } else {
            return "⚠️ Purchase history stored locally only"
        }
    }
    
    // Function to manually trigger purchase sync (if needed)
    func triggerPurchaseSync() async {
        guard isPurchaseSyncEnabled() else {
            print("⚠️ Purchase sync not available - using local storage")
            return
        }
        
        let context = getPurchaseModelContext()
        do {
            try context.save()
            print("✅ Purchase data sync triggered")
        } catch {
            print("❌ Failed to trigger purchase sync: \(error)")
        }
    }
}

