//
//  CustomerDetailView.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//

import SwiftUI
import SwiftData

struct CustomerDetailView: View {
     
    var customer : Customer
    
//    @Binding var customer: Customer
//    
//    init(customer: Binding<Customer>) {
//      _customer = customer
//    }
     
    
    var body: some View {
        List {
            
            CustomerViewForiOS()
            
        }
        .navigationTitle(Text("Cliente"))
    }
   
    
    @ViewBuilder
    private func CustomerViewForiOS() -> some View {
        VStack(alignment: .leading) {
            Text(customer.fullName)
                .font(.title)
                .bold()
            Text(customer.phone)
            
            HStack {
                Text(customer.nationalId)
                Spacer()
                Text(customer.email)
            }
            
        }
        NavigationLink {
          CustomerEditView(customer: customer)
        } label: {
            Text("Actualizar datos")
        }
        
        Section {
            VStack(alignment: .leading) {
                Text(customer.departammento)
                    .font(.title)
                    .bold()
                Text(customer.municipio)
                Text(customer.address)
            }
             
        } header: {
            Text("Direccion")
        }
        
        
    }
}
//#Preview(traits: .sampleCustomers) {
//    @Previewable @Query var customers: [Customer]
//    CustomerDetailView(customer: customers.first!)
//}
