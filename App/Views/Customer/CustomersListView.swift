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
                CustomersListItem(customer: customer)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        DeleteSwipeButton
                            .disabled(customer.invoices.count > 0)
                            .confirmationDialog(
                                "¿Está seguro que desea eliminar el CLiente :\(customer.fullName) de manera permanente?",
                                isPresented: $viewModel.showDeleteCustomerConfirmation,
                                titleVisibility: .visible
                            ){
                                Button("Eliminar", role: .destructive) {
                                    deleteCustomer(customer)
                                }
                                Button("Cancelar", role: .cancel){}
                            }
                    }
            }
            //.onDelete(perform: viewModel.ConfirmDelete(at:))
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("Ok!")))
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
            OverlaySection
        }
        .navigationTitle("Clientes")
        .onChange(of: customers) {
            viewModel.customersCount = customers.count
        }
        .onAppear {
            viewModel.customersCount = customers.count
        }
    }
    
 
    private var DeleteSwipeButton: some View {
        Button(role: .destructive,
               action:{
                viewModel.showDeleteCustomerConfirmation = true
                },label: {
                    VStack{
                        Text("Eliminar")
                        Image(systemName: "trash")
                    }
                })
    }
     
    private var ConfirmDeleteButton: some View {
       
        VStack{
            Button("Eliminar", role: .destructive) {
                if let cust = viewModel.toDeleteCustomer {
                    deleteCustomer(cust)
                }
            }
            Button("Cancelar", role: .cancel) {
                viewModel.offsets.removeAll()
                 
            }
        }
    }
    
     
    private var OverlaySection: some View {
        VStack{
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
    }
    
     
}

 
