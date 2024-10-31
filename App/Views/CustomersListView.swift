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
    
    @State var isShowingItemsSheet: Bool = false
    
    @Binding var selection: Customer?
    @Binding var customersCount: Int
    @Binding var unreadCustomersIdentifiers: [PersistentIdentifier]
    
    init(selection: Binding<Customer?>, customersCount: Binding<Int>,
         unreadCustomersIdentifiers: Binding<[PersistentIdentifier]>,
         searchText: String) {
        
        _selection = selection
        _customersCount = customersCount
        _unreadCustomersIdentifiers = unreadCustomersIdentifiers
        let predicate = #Predicate<Customer> {
            searchText.isEmpty ? true : $0.firstName.contains(searchText) || $0.lastName.contains(searchText) || $0.email.contains(searchText)
        }
        _customers = Query(filter: predicate, sort: \Customer.firstName)
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(customers) { customer in
                CustomersListItem(customer: customer, isUnread: unreadCustomersIdentifiers.contains(customer.persistentModelID))
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
        .sheet(isPresented: $isShowingItemsSheet) {
            NavigationStack {
                AddCustomerView()
            }
            .presentationDetents([.medium, .large])
        }
        //.sheet(item: $customerToEdit){ cust in CustomerEditView(customer: cust) }
        .toolbar{
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
                    .disabled(customersCount == 0)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Spacer()
                Button("Agregar Cliente",systemImage: "plus"){isShowingItemsSheet=true}
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
                    Button("Agregar Cliente"){isShowingItemsSheet=true}
                }
                .offset(y: -60)
            }
        }
        .navigationTitle("Clientes")
       
        .onChange(of: customers) {
            customersCount = customers.count
        }
        .onAppear {
            customersCount = customers.count
        }
    }
}

extension CustomersListView {
    private func deleteCustomers(at offsets: IndexSet) {
        withAnimation {
            offsets.map { customers[$0] }.forEach(deleteCustomer)
        }
    }
    
    private func deleteCustomer(_ cust: Customer) {
        /**
         Unselect the item before deleting it.
         */
        if cust.persistentModelID == selection?.persistentModelID {
            selection = nil
        }
        modelContext.delete(cust)
    }
}
