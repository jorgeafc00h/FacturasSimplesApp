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
    
    // Store the container instance
    private var _modelContainer: ModelContainer?
    
    // ModelContainer with separate configurations for CloudKit and local-only data
    var modelContainer: ModelContainer {
        if let container = _modelContainer {
            return container
        }
        
        do {
            // CloudKit configuration - syncs main business data only
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
                for: Invoice.self, Customer.self, Product.self, InvoiceDetail.self, Company.self, Catalog.self, CatalogOption.self,
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
                    for: Invoice.self, Customer.self, Product.self, InvoiceDetail.self, Company.self, Catalog.self, CatalogOption.self,
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
                        for: Invoice.self, Customer.self, Product.self, InvoiceDetail.self, Company.self, Catalog.self, CatalogOption.self,
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
    
    // Function to get the model context
    func getModelContext() -> ModelContext {
        return modelContainer.mainContext
    }
}

