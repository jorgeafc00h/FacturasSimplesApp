//
//  DataModel.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//

import SwiftUI
import SwiftData

actor DataModel {
    struct TransactionAuthor {
        static let widget = "widget"
    }

    static let shared = DataModel()
    private init() {}
    
    nonisolated lazy var modelContainer: ModelContainer = {
        let modelContainer: ModelContainer
        do {
            let schema = Schema([Invoice.self,Customer.self, Catalog.self,CatalogOption.self, Product.self, InvoiceDetail.self, Emisor.self])
            modelContainer = try ModelContainer(for: schema,configurations: [])
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
        return modelContainer
    }()
}
 
