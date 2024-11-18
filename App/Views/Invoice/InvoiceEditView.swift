import SwiftUI
import SwiftData

struct InvoiceEditView: View {
    @Bindable var invoice: Invoice
    @Environment(\.modelContext)  var modelContext
    @Environment(\.dismiss)  var dismiss
    
    let accentColor = Color(.darkCyan)// Color(red: 0.5, green: 0.0, blue: 0.1) // Wine red
    
    @State var viewModel = InvoiceEditViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                customerSection
                invoiceDetailsSection
                productsSection
                invoiceTotalSeaction
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
            if viewModel.showAddProductSection {
                addProductSection
            }
            HStack{
                if !viewModel.showAddProductSection {
                    Button(action: SearchProduct,label: {
                        Label("Buscar Producto", systemImage: "magnifyingglass")
                    })
                }
                Spacer()
                Button(action: ShowAddProductSection,label: {
                    viewModel.showAddProductSection ?
                    Image(systemName: "xmark.circle.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundColor(.red):
                    Image(systemName: "plus")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundColor(.darkCyan)
                })
            }
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(accentColor)
            
        }
        
        
    }
    
    private var addProductSection : some View{
        VStack{
            TextField("Producto", text: $viewModel.productName)
            
            HStack{
                TextField("Precio Unitario", value: $viewModel.unitPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                Spacer()
                Button(action: AddNewProduct,label: {
                    Image(systemName: "checkmark.circle.fill")
                        .contentTransition(.symbolEffect(.replace))
                   	
                }).disabled(viewModel.canSaveNewProduct)
            }.padding(.vertical, 10)
        }.buttonStyle(BorderlessButtonStyle())
    }
    
   private var invoiceTotalSeaction : some View{
       VStack{
           HStack{
               Text("Sub Total:")
               Spacer()
               Text(invoice.subTotal.formatted(.currency(code: "USD")))
           }
           HStack{
               Text("IVA:")
               Spacer()
               Text(invoice.tax.formatted(.currency(code: "USD")))
           }
           HStack{
               Text("Total:")
               Spacer()
               Text(invoice.totalAmount.formatted(.currency(code: "USD")))
           }
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
