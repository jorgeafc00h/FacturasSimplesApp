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
    
    // Single CloudKit container that syncs all models
    var modelContainer: ModelContainer {
        if let container = _modelContainer {
            return container
        }
        
        do {
            let schema = Schema([
                            Invoice.self,
                            Customer.self,
                            Catalog.self,
                            CatalogOption.self,
                            Product.self,
                            InvoiceDetail.self,
                            Company.self
                        ])
            
            // CloudKit configuration - all models sync to iCloud
            let cloudKitConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.kandangalabs.facturassimples")
            )
            
            let container = try ModelContainer(for: schema, configurations: [cloudKitConfiguration])
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
                let fallbackSchema = Schema([
                    Invoice.self,
                    Customer.self,
                    Product.self,
                    InvoiceDetail.self,
                    Company.self,
                    Catalog.self,
                    CatalogOption.self
                ])
                
                let localConfiguration = ModelConfiguration(
                    schema: fallbackSchema,
                    isStoredInMemoryOnly: false
                )
                
                let fallbackContainer = try ModelContainer(for: fallbackSchema, configurations: [])
                print("✅ Successfully created fallback local container")
                _modelContainer = fallbackContainer
                return fallbackContainer
                
            } catch {
                print("❌ Failed to create fallback container: \(error)")
                // As last resort, create in-memory container
                let memorySchema = Schema([
                    Invoice.self,
                    Customer.self,
                    Product.self,
                    InvoiceDetail.self,
                    Company.self,
                    Catalog.self,
                    CatalogOption.self
                ])
                
                let memoryConfiguration = ModelConfiguration(
                    schema: memorySchema,
                    isStoredInMemoryOnly: true
                )
                
                do {
                    let memoryContainer = try ModelContainer(for: memorySchema, configurations: [memoryConfiguration])
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

