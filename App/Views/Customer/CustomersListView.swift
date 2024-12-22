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
    @State var searchText: String = ""
    
    @AppStorage("selectedCompanyName")  var selectedCompanyName : String = ""
    @AppStorage("selectedCompanyIdentifier")  var companyIdentifier : String = ""
    
    init(selection: Binding<Customer?>, selectedCompanyId: String ) {
        
        _selection = selection
      
        viewModel = CustomersListViewModel()
        
        let companyId = selectedCompanyId.isEmpty ? companyIdentifier : selectedCompanyId
        
        let predicate = #Predicate<Customer> {
            searchText.isEmpty ?
            $0.companyOwnerId == companyId :
            $0.firstName.localizedStandardContains(searchText) ||
            $0.lastName.localizedStandardContains(searchText) ||
            $0.email.localizedStandardContains(searchText) &&
            $0.companyOwnerId == companyId
        }
        
        _customers  = Query(filter: predicate, sort: \Customer.firstName)
    }
     
    
    var body: some View {
        List(selection: $selection) {
            ForEach(customers) { customer in
                CustomersListItem(customer: customer)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive,
                               action:{
                                viewModel.showDeleteCustomerConfirmation = true
                                selection = customer
                                },label: {
                                    VStack{
                                        Text("Eliminar")
                                        Image(systemName: "trash")
                                    }
                                })
                    }
            }
            .confirmationDialog(
                "¿Está seguro que desea eliminar el CLiente :\( selection != nil ? selection!.fullName : "" ) de manera permanente?",
                isPresented: $viewModel.showDeleteCustomerConfirmation,
                titleVisibility: .visible
            ){
                Button("Eliminar", role: .destructive) {
                    if let cust = selection {
                        deleteCustomer(cust)
                    }
                }
                Button("Cancelar", role: .cancel){}
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
           
            ToolbarItemGroup(placement: .topBarTrailing) {
                Spacer()
                Button("Agregar Cliente",systemImage: "plus"){ viewModel.isShowingItemsSheet=true}
                    .buttonStyle(BorderlessButtonStyle())
            }
        }
        .overlay {
            OverlaySection
        }
        .navigationTitle("Clientes: \(selectedCompanyName)")
        .navigationBarTitleDisplayMode(.automatic)
        .searchable(text: $searchText, placement: .sidebar)
        
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

 
