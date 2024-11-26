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
    @State var showAddCustomerSheet = false
    
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
            else{
                ContentUnavailableView {
                    Label("Seleccione una Cliente", systemImage: "person.circle.fill")
                } description: {
                    Text("seleccione un cliente o haga click en agregar cliente para comenzar a facturar")
                }
                actions: {
                    
                    Button("Agregar Cliente", systemImage: "plus"){
                        showAddCustomerSheet = true
                    }
                }
                .sheet(isPresented: $showAddCustomerSheet) {
                    NavigationStack{
                        AddCustomerView()
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar)
        
   }
}



#Preview (traits:   .sampleCustomers) {
    CustomersView()
}
