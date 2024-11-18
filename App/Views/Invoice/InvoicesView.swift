//
//  InvoicesView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct InvoicesView: View {
    @State private var selection: Invoice?
    @State private var searchText: String = ""
    
    @Environment(\.modelContext)  var modelContext
    
    @Query(filter: #Predicate<Catalog> { $0.id == "CAT-012"}, sort: \Catalog.id)
    var catalog: [Catalog]
    var syncService = CatalogServiceClient() 
   
    var body: some View {
        
        NavigationSplitView{
            InvoicesListView(selection:$selection, 
                             searchText: searchText)
        } 
        detail:{
            if let inv = selection {
                InvoiceDetailView(invoice: inv)
            }
        }
        .searchable(text: $searchText, placement: .sidebar)
        .task { await SyncCatalogs()}
    }
    
   
}

#Preview (traits: .sampleInvoices) {
    InvoicesView()
}
