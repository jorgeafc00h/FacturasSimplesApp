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
    @State private var searchScope: SearchScope = .name
    @AppStorage("selectedCompanyIdentifier")  var companyIdentifier : String = ""
    
    enum SearchScope: String, CaseIterable {
        case name = "Nombre"
        case dui = "DUI"
        case nit = "NIT"
        case nrc = "NRC"
    }
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return customers.filter { $0.companyOwnerId == companyIdentifier }
        } else {
            return customers.filter {
                //                let matchesCompany = $0.companyOwnerId == companyIdentifier
                //
                //                guard matchesCompany else { return false }
                
                switch searchScope {
                case .name:
                    return $0.firstName.localizedStandardContains(searchText) ||
                    $0.lastName.localizedStandardContains(searchText) &&
                    $0.companyOwnerId == companyIdentifier
                case .dui:
                    return $0.nationalId.localizedStandardContains(searchText) &&
                           $0.companyOwnerId == companyIdentifier
                case .nit:
                    return $0.nit.localizedStandardContains(searchText) &&
                           $0.companyOwnerId == companyIdentifier
                case .nrc:
                    return $0.nrc.localizedStandardContains(searchText) &&
                    $0.companyOwnerId == companyIdentifier
                }
            }
        }
    }
     
    init(selection : Binding<Customer?>){
        _selection = selection
        
        // Basic filter just for company - search filtering is handled by filteredCustomers computed property
        let filterPredicate = #Predicate<Customer> { $0.companyOwnerId == companyIdentifier }
         
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
        .searchScopes($searchScope, scopes: {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Text(scope.rawValue).tag(scope)
            }
        })
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



