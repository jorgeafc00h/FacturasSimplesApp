import SwiftUI
import SwiftData

struct InvoicesListView: View {
    @Environment(\.modelContext)  var modelContext
    
    @Query(sort: \Invoice.date, order: .reverse)
    var invoices: [Invoice]
    
    @Binding var selection: Invoice?
    
    @State var viewModel = InvoicesListViewModel()
    
    init(selection: Binding<Invoice?>,
         searchText: String) {
        
        _selection = selection
        
        let predicate = #Predicate<Invoice> {
            searchText.isEmpty ? true :
            $0.invoiceNumber.localizedStandardContains(searchText) ||
            $0.customer.firstName.localizedStandardContains(searchText) ||
            $0.customer.lastName.localizedStandardContains(searchText) ||
            $0.customer.email.localizedStandardContains(searchText)
        }
        _invoices = Query(filter: predicate, sort: \Invoice.date, order: .reverse)
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(invoices){ inv in
                InvoiceListItem(invoice: inv)
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddInvoiceSheet) {
            AddInvoiceView()
        }
        .toolbar{
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Nueva Factura",systemImage: "plus"){
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
        .navigationTitle("Facturas")
        .onChange(of: invoices) {
            viewModel.invocesCount = invoices.count
        }
        .onAppear {
            viewModel.invocesCount = invoices.count
        }
        
    }
    
    private var EmptyInvoicesOverlay: some View {
        
        ContentUnavailableView {
            Label("Facturas", systemImage: "list.bullet.rectangle.portrait")
        }description: {
            Text("Las Nuevas Facturas apareceran aquí.")
        }actions: {
            Button("Crear Factura", systemImage: "plus"){
                viewModel.isShowingAddInvoiceSheet.toggle()
            }
        }
        .offset(y: -60)
    }
}







