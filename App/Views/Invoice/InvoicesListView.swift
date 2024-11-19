import SwiftUI
import SwiftData

struct InvoicesListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Invoice.date, order: .reverse)
    var invoices: [Invoice]
    
    @State var isShowingItemsSheet: Bool = false
    
    @Binding var selection: Invoice?
    @State var invoicesCount: Int = 0
     
    
    init(selection: Binding<Invoice?>,
         searchText: String) {
        
        _selection = selection
         
        let predicate = #Predicate<Invoice> {
            searchText.isEmpty ? true : $0.invoiceNumber.contains(searchText)
        }
        _invoices = Query(filter: predicate, sort: \Invoice.date)
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(invoices){ inv in
                InvoiceListItem(invoice: inv)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteInvoice(inv)
                            //WidgetCenter.shared.reloadTimelines(ofKind: "CustomersWidget")
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                
            }
        }
        //.onDelete(perform: deleteInvoices(at:))
        .sheet(isPresented: $isShowingItemsSheet) {
            AddInvoiceView()
        }
        .toolbar{
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
                    .disabled(invoicesCount == 0)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Spacer()
                Button("Nueva Factura",systemImage: "plus"){isShowingItemsSheet=true}
                    .buttonStyle(BorderlessButtonStyle())
                
            }
        }
        .overlay {
            if invoices.isEmpty {
                EmptyInvoicesOverlay(isShowingItemsSheet: $isShowingItemsSheet)
            }
        }
        .navigationTitle("Facturas")
        .onChange(of: invoices) {
            invoicesCount = invoices.count
        }
        .onAppear {
            invoicesCount = invoices.count
        }
    }
}


private struct EmptyInvoicesOverlay : View {
    
    @Binding var isShowingItemsSheet: Bool
    
    var body: some View {
        ContentUnavailableView {
            Label("Facturas", systemImage: "list.bullet.rectangle.portrait")
        }description: {
            Text("Las Nuevas Facturas apareceran aquí.")
        }actions: {
            Button("Crear Factura"){isShowingItemsSheet=true}
        }
        .offset(y: -60)
    }
}
 

extension InvoicesListView {
    private func deleteInvoices(at offsets: IndexSet) {
        withAnimation {
            offsets.map { invoices[$0] }.forEach(deleteInvoice)
        }
    }
    
    private func deleteInvoice(_ invoice: Invoice) {
        /**
         Unselect the item before deleting it.
         */
        if invoice.persistentModelID == selection?.persistentModelID {
            selection = nil
        }
        modelContext.delete(invoice)
    }
}

