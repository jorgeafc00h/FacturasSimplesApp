import SwiftUI
import SwiftData

 
struct InvoicesListView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @Binding var selection: Invoice?
    
    @State var viewModel = InvoicesListViewModel()
    
    @AppStorage("selectedCompanyName") var selectedCompanyName: String = ""
    @AppStorage("selectedCompanyIdentifier") var companyIdentifier: String = ""
    
    @Query(filter: #Predicate<Catalog> { $0.id == "CAT-012" }, sort: \Catalog.id)
    var catalog: [Catalog]
    var syncService = InvoiceServiceClient()
    
    @Query var invoices: [Invoice]
    @Query var companies: [Company]
    
    var selectedCompany: Company? {
        companies.first { $0.id == companyIdentifier }
    }
    
    init(selection: Binding<Invoice?>, selectedCompanyId: String, searchText: String, searchScope: InvoiceSearchScope) {
        _selection = selection
        
        let companyId = selectedCompanyId.isEmpty ? companyIdentifier : selectedCompanyId
        
        let predicate = getSearchPredicate(scope: searchScope, searchText: searchText, companyId: companyId)
        
        _invoices = Query(filter: predicate, sort: \Invoice.date, order: .reverse)
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(invoices){ inv in
                InvoiceListItem(invoice: inv)
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddInvoiceSheet) {
            AddInvoiceView(selectedInvoice: $selection)
                .environmentObject(storeKitManager)
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) {
//                CreditsStatusView(company: selectedCompany)
//                    .environmentObject(storeKitManager)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Nueva Factura", systemImage: "plus"){
//                    if storeKitManager.hasAvailableCredits() {
//                        viewModel.isShowingAddInvoiceSheet.toggle()
//                    } else {
//                        // Show purchase view or alert
//                        viewModel.showCreditsAlert = true
//                    }
                    viewModel.isShowingAddInvoiceSheet.toggle()
                }
                .buttonStyle(BorderlessButtonStyle()) 
            }
            
            
//            ToolbarItem(placement: .automatic){
//                Menu{
//                    
//                    
//                }label: {
//                    Image(systemName: "line.3.horizontal.decrease.circle")
//                }
//            }
        }
        .overlay {
            if invoices.isEmpty {
                EmptyInvoicesOverlay
            }
        }
        .navigationTitle("Facturas: \(selectedCompanyName)")
        .task { await SyncCatalogs() }
    }
    
    private var EmptyInvoicesOverlay: some View {
        ContentUnavailableView {
            Label("Facturas", systemImage: "list.bullet.rectangle.portrait")
                .symbolEffect(.breathe)
        }description: {
            Text("Las Nuevas Facturas apareceran aquí.")
        }actions: {
            Button("Crear Factura", systemImage: "plus"){
                viewModel.isShowingAddInvoiceSheet.toggle()
            }
            if Constants.EnvironmentCode == "00" {
                
            }
        }
        .offset(y: -60)
    }
    
     
}







