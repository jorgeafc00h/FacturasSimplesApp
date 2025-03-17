import SwiftUI
import SwiftData

 
struct InvoicesListView: View {
    @Environment(\.modelContext) var modelContext
    
    @Binding var selection: Invoice?
    
    @State var viewModel = InvoicesListViewModel()
    
    @AppStorage("selectedCompanyName") var selectedCompanyName: String = ""
    @AppStorage("selectedCompanyIdentifier") var companyIdentifier: String = ""
    
    @Query(filter: #Predicate<Catalog> { $0.id == "CAT-012" }, sort: \Catalog.id)
    var catalog: [Catalog]
    var syncService = InvoiceServiceClient()
    
    @Query var invoices: [Invoice]
    
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
        }
        .toolbar{
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Nueva Factura", systemImage: "plus"){
                    viewModel.isShowingAddInvoiceSheet.toggle()
                }
                .buttonStyle(BorderlessButtonStyle()) 
            }
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
    
    /// Create a predicate based on search scope and text
    func getSearchPredicate(scope: InvoiceSearchScope, searchText: String, companyId: String) -> Predicate<Invoice> {
        if searchText.isEmpty {
            switch scope {
            case .factura:
                
                let  _type = Extensions.documentTypeFromInvoiceType( InvoiceType.Factura)
                
                return #Predicate<Invoice> {
                    $0.customer.companyOwnerId == companyId &&
                    $0.documentType == _type
                }
            case .ccf:
                let  _type = Extensions.documentTypeFromInvoiceType( InvoiceType.CCF)
                
                return #Predicate<Invoice> {
                    $0.customer.companyOwnerId == companyId &&
                    $0.documentType == _type
                }
            default :
                return #Predicate<Invoice> {
                    $0.customer.companyOwnerId == companyId
                }
            }
        }
        
        switch scope {
        case .nombre:
            return #Predicate<Invoice> {
                ($0.customer.firstName.localizedStandardContains(searchText) ||
                 $0.customer.lastName.localizedStandardContains(searchText)) &&
                $0.customer.companyOwnerId == companyId
            }
        case .nit:
            return #Predicate<Invoice> {
                $0.customer.nit.localizedStandardContains(searchText) &&
                $0.customer.companyOwnerId == companyId
            }
        case .dui:
            return #Predicate<Invoice> {
                $0.customer.nationalId.localizedStandardContains(searchText) &&
                $0.customer.companyOwnerId == companyId
            }
        case .nrc:
            return #Predicate<Invoice> {
                //($0.customer.nrc != nil &&
                $0.customer.nrc.localizedStandardContains(searchText) &&
                $0.customer.companyOwnerId == companyId
            }
            
        case .factura:
            
            let  _type = Extensions.documentTypeFromInvoiceType( InvoiceType.Factura)
            
            return #Predicate<Invoice> {
                $0.documentType == _type &&
                $0.customer.companyOwnerId == companyId &&
                $0.customer.firstName.localizedStandardContains(searchText)
            }
        
        case .ccf:
        
            let  _type = Extensions.documentTypeFromInvoiceType( InvoiceType.CCF)
        
        return #Predicate<Invoice> {
            //$0.controlNumber != nil &&  $0.controlNumber!.contains(searchText) ||
            $0.documentType == _type &&
            $0.customer.companyOwnerId == companyId &&
            $0.customer.firstName.localizedStandardContains(searchText)
        }
      }
    }
    
     
}







