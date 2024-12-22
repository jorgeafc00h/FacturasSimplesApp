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
    @Binding var selectedCompanyId : String 
    @State var showAddCustomerSheet = false
    
    var body: some View {
        NavigationSplitView {
            CustomersListView(selection:$selection, selectedCompanyId: selectedCompanyId)
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
        
   }
}



#Preview (traits:   .sampleCustomers) {
    CustomersViewWrapper()
}

private struct CustomersViewWrapper: View{
    @State private var selectedCompanyId: String = ""
    
    var body : some View{
        CustomersView(selectedCompanyId: $selectedCompanyId)
    }
}
