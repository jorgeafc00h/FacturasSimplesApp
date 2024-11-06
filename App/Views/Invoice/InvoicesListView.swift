import SwiftUI
import SwiftData

struct InvoicesListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Invoice.date, order: .forward)
    var invoices: [Invoice]
    
    @State var isShowingItemsSheet: Bool = false
    
    @Binding var selection: Invoice?
    @Binding var invoicesCount: Int
    @Binding var unreadInvoicesIdentifiers: [PersistentIdentifier]
    
    @State private var selectedCustomer: Customer?
    @State private var isVisibleCustomerPicker : Bool = true
    
    init(selection: Binding<Invoice?>, invoicesCount: Binding<Int>,
         unreadInvoicesIdentifiers: Binding<[PersistentIdentifier]>,
         searchText: String) {
        
        _selection = selection
        _invoicesCount = invoicesCount
        _unreadInvoicesIdentifiers = unreadInvoicesIdentifiers
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

private struct NewInvoiceToolbarLink : View {
    var body: some View {
        NavigationLink(destination: AddInvoiceView()) {
            Button("Nueva Factura",systemImage: "plus"){
                print("New invoice")
            }.buttonStyle(BorderlessButtonStyle())
        }
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

