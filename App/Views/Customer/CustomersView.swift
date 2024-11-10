//
//  CustomersView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct CustomersView: View {
    @State  var selection: Customer?
    @State var searchText: String = ""
    
    var body: some View {
        NavigationSplitView {
            CustomersListView(selection:$selection,searchText: searchText)
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
