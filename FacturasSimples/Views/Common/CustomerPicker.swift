//
//  CustomerPicker.swift
//  App
//
//  Created by Jorge Flores on 11/4/24.
//

import SwiftUI
import SwiftData

struct CustomerPicker :View {
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.modelContext)  var modelContext
    
    @Query(sort: \Customer.firstName)
    var customers: [Customer]
    
    @Binding var selection : Customer?
    
    @State private var searchText: String = ""
    @AppStorage("selectedCompanyIdentifier")  var companyIdentifier : String = ""
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
           customers
        } else {
            customers.filter{searchText.isEmpty ?
                $0.companyOwnerId == companyIdentifier:
                $0.firstName.contains(searchText) ||
                $0.lastName.contains(searchText) ||
                $0.email.contains(searchText) &&
                $0.companyOwnerId == companyIdentifier
            }
        }
    }
     
    init(selection : Binding<Customer?>){
        
        _selection = selection
        
        let filterPredicate = #Predicate<Customer> {
            searchText.isEmpty ?
            $0.companyOwnerId == companyIdentifier :
            $0.firstName.contains(searchText) ||
            $0.lastName.contains(searchText) ||
            $0.email.contains(searchText) ||
            $0.companyOwnerId == companyIdentifier
            }
         
        _customers = Query(filter: filterPredicate, sort: \Customer.firstName)
    }
    
    var body: some View {
        NavigationView{
            List{
                ForEach(filteredCustomers, id: \.self){ customer in
                    CustomerPickerItem(customer: customer)
                        .onTapGesture {
                            withAnimation {
                                selection = customer
                                searchText = ""
                                dismiss()
                            }
                        }
                }
            }
            
            .listStyle(.plain)
            .frame(idealWidth: LayoutConstants.sheetIdealWidth,
                   idealHeight: LayoutConstants.sheetIdealHeight)
            .navigationTitle("Seleccione Cliente")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
            }.accentColor(.darkCyan)
            
        }
        .searchable(text: $searchText, prompt: "Buscar Cliente")
        .presentationDetents([.medium, .large])
    }
}
private struct CustomerPickerItem: View {
    
    @State var customer: Customer
    
    var body: some View {
        HStack {
            Circle()
                .fill(customer.color)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(String(customer.initials))
                        .font(.system(size: 20))
                        .foregroundStyle(.background)
                }
            
            
            VStack(alignment: .leading) {
                Text(customer.fullName)
                    .font(.headline)
                Text(customer.email)
                    .font(.subheadline)
            }
            Spacer()
            VStack{
                Text(customer.phone)
                    .font(.footnote)
                Text(customer.nationalId)
                    .font(.footnote)
            }
        }
        
    }
}

#Preview(traits: .sampleCustomers) {
    @Previewable @Query var customers: [Customer]
    
    List {
        CustomerPickerItem(customer: customers.first!)
    }
}



