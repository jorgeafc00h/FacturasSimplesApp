//
//  CustomersListView.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//
import SwiftUI
import SwiftData

struct CustomersListView: View {
    @Environment(\.modelContext)  var modelContext
    
    @Query(sort: \Customer.firstName)
    var customers: [Customer]
      
    @Binding var selection: Customer?
    
    @State  var viewModel: CustomersListViewModel
    
    init(selection: Binding<Customer?>,
         searchText: String) {
        
        _selection = selection
        let predicate = #Predicate<Customer> {
            searchText.isEmpty ? true :
            $0.firstName.contains(searchText) ||
            $0.lastName.contains(searchText) ||
            $0.email.contains(searchText)
        }
        _customers = Query(filter: predicate, sort: \Customer.firstName)
        
        viewModel = CustomersListViewModel()
        
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(customers) { customer in
                CustomersListItem(customer: customer, isUnread: true)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteCustomer(customer)
                            //WidgetCenter.shared.reloadTimelines(ofKind: "CustomersWidget")
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
            }
            .onDelete(perform: deleteCustomers(at:))
        }
        .sheet(isPresented: $viewModel.isShowingItemsSheet) {
            NavigationStack {
                AddCustomerView()
            }
            .presentationDetents([.medium, .large])
        }
        .toolbar{
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
                    .disabled(viewModel.isDisabledEdit)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Spacer()
                Button("Agregar Cliente",systemImage: "plus"){ viewModel.isShowingItemsSheet=true}
                    .buttonStyle(BorderlessButtonStyle())
            }
        }
        .overlay {
            if customers.isEmpty {
                ContentUnavailableView {
                    Label("Clientes", systemImage: "person.circle")
                }description: {
                    Text("Los nuevos clientes aparecerán aquí.")
                }actions: {
                    Button("Agregar Cliente"){ viewModel.isShowingItemsSheet=true}
                }
                .offset(y: -60)
            }
        }
        .navigationTitle("Clientes")
        .onChange(of: customers) {
            viewModel.customersCount = customers.count
        }
        .onAppear {
            viewModel.customersCount = customers.count
        }
    }
}

 
