//
//  InvoicesView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct InvoicesView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddTrip = false
    @State private var selection: Invoice?
    @State private var searchText: String = ""
    @State private var invoicesCount = 0
    @State private var unreadInvoicesIdentifiers: [PersistentIdentifier] = []
    
    @Environment(\.modelContext)  var modelContext
    
    @Query(sort: \Catalog.id)
    var catalog: [Catalog]
    
    var syncService = CatalogServiceClient()
    var body: some View {
        
        NavigationStack {
            InvoicesListView(selection:$selection,
                             invoicesCount: $invoicesCount,
                             unreadInvoicesIdentifiers: $unreadInvoicesIdentifiers,
                             searchText: searchText)
        }
        .searchable(text: $searchText, placement: .sidebar)
        .task {
            do{
                if(catalog.isEmpty) {
                    
                    let collection = try await syncService.getCatalogs()
                    
                    for c in collection{
                        modelContext.insert(c)
                    }
                    
                    try? modelContext.save()
                }
            }
            catch {
                print(error)
            }
        }
    }
}

#Preview {
    InvoicesView()
}
