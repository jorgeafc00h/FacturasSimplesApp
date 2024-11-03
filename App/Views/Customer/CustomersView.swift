//
//  CustomersView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct CustomersView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State  var selection: Customer?
    @State private var searchText: String = ""
    @State private var customersCount = 0
    @State private var unreadCustomersIdentifiers: [PersistentIdentifier] = []
    
    
    var body: some View {
        NavigationSplitView {
            CustomersListView(selection:$selection,
                              customersCount: $customersCount,
                              unreadCustomersIdentifiers: $unreadCustomersIdentifiers,
                              searchText: searchText)
        }
        detail: {
            if let cust = selection {
                NavigationStack {
                    CustomerDetailView(customer:cust)
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar)
         
        
   }
}



#Preview (traits:   .sampleCustomers) {
    CustomersView()
}
