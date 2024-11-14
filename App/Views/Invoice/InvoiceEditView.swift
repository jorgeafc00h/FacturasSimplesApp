import SwiftUI
import SwiftData

struct InvoiceEditView: View {
    @Bindable var invoice: Invoice
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)  var dismiss
    
    let accentColor = Color(.darkCyan)// Color(red: 0.5, green: 0.0, blue: 0.1) // Wine red
    
    @State private var viewModel = InvoiceEditViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                customerSection
                invoiceDetailsSection
                productsSection
                
                Section {
                    Button(action: saveInvoice, label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Guardar Factura")
                        }
                    })
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(accentColor)
                    .cornerRadius(10)
                }
            }
            .sheet(isPresented: $viewModel.showingProductPicker) {
                ProductPicker(details: $invoice.items)
            }
            .navigationTitle("Editar Factura")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .accentColor(accentColor)
    }
    
    private var customerSection: some View {
        Section(header: Text("Customer")) {
            HStack {
                Text(invoice.customer.fullName)
                Spacer()
                
                .foregroundColor(accentColor)
            }
        }
        
    }
    
    private var invoiceDetailsSection: some View {
        
         
        
        Section(header: Text("Factura")) {
            TextField("Numero Factura", text: $invoice.invoiceNumber)
                .disabled(true)
            DatePicker("Fecha", selection: $invoice.date, displayedComponents: .date)
            Picker("Estado",selection: $invoice.status){
                ForEach(viewModel.invoiceStatuses,id: \.self){ stat in
                    Text(stat.stringValue()).tag(stat)
                }
            }.disabled(true)
            Picker(" ", selection: $invoice.invoiceType) {
                ForEach(viewModel.invoiceTypes, id: \.self) { invoiceType in
                    
                    Text(invoiceType.stringValue()).tag(invoiceType)
                }
            }.pickerStyle(.segmented)

        }
    }
    
    private var productsSection: some View {
        Section(header: Text("Productos")) {
            ForEach($invoice.items) { $item in
                ProductDetailEditView(item: $item)
            }
            .onDelete(perform: deleteProduct)
            
            Button("Agregar Producto") {
                viewModel.showingProductPicker = true
            }
            .foregroundColor(accentColor)
        }

    }
    
    private func deleteProduct(at offsets: IndexSet) {
        invoice.items.remove(atOffsets: offsets)
    }
    
    private func saveInvoice() {
        do {
            try modelContext.save()
            dismiss()
             
        } catch {
            print("Error saving invoice: \(error)")
        }
    }
}

// Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Invoice.self, configurations: config)
        let example = Invoice.previewInvoices[0]
        return InvoiceEditView(invoice: example)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
} 
