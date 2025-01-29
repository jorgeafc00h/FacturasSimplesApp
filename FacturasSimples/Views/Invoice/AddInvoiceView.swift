//
//  AddInvoiceView.swift
//  App
//
//  Created by Jorge Flores on 11/3/24.
//

import SwiftUI
import SwiftData

struct AddInvoiceView: View {
    @Environment(\.modelContext)  var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss)  var dismiss
    @Environment(\.timeZone) private var timeZone
    
    @AppStorage("selectedCompanyIdentifier")  var companyIdentifier : String = ""
    
    @State var viewModel = AddInvoiceViewModel()
    
    var body: some View {
        
        NavigationStack { 
            Form{
                CustomerSection
                InvoiceDataSection
                ProductDetailsSection
                Section {
                    Button(action: addInvoice, label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Crear Factura")
                        }
                    })
                    .disabled(viewModel.disableAddInvoice)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(.darkCyan)
                    .cornerRadius(10)
                }
            }
            .frame(idealWidth: LayoutConstants.sheetIdealWidth,
                   idealHeight: LayoutConstants.sheetIdealHeight)
            .navigationTitle("Nueva Factura")
            .sheet(isPresented: $viewModel.displayPickerSheet){
                CustomerPicker(selection:$viewModel.customer)
            }
            .sheet(isPresented: $viewModel.displayProductPickerSheet){
                ProductPicker(details: $viewModel.details)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Guardar",action: addInvoice)
                    .disabled(viewModel.disableAddInvoice)
                }
            }.accentColor(.darkCyan)
        }
        .onAppear(perform: getNextInoviceNumber)
        .presentationDetents([.medium, .large])
    }
    
    
    
    private var CustomerSection: some View {
        Section {
            Group{
                Button{
                    viewModel.displayPickerSheet.toggle()
                }label: {
                    if viewModel.customer == nil {
                        HStack{
                            Image(systemName: "magnifyingglass")
                            Text("Buscar Cliente")
                        }.foregroundColor(.darkCyan)
                    }
                    else {
                        HStack{
                            Text(viewModel.customer!.fullName)
                            Spacer()
                            Text(viewModel.customer!.nationalId)
                        }
                    }
                }
            }
            
            
        }
        
    }
    
    private var InvoiceDataSection : some View{
        Section {
            Group {
                TextField("Numero de Factura",text: $viewModel.invoiceNumber)
                    .keyboardType(.numberPad)
                HStack{
                    Text("Fecha:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
                        .labelsHidden()
                    
                }
               
                HStack{
                    Text("Tipo Documento:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker(" ", selection: $viewModel.invoiceType) {
                        ForEach(viewModel.invoiceTypes, id: \.self) { invoiceType in
                            
                            Text(invoiceType.stringValue()).tag(invoiceType)
                        }
                    }.pickerStyle(.segmented)
                }
                
            }
            
        }
    }
    
    
    private var ProductDetailsSection: some View {
        Section(header: Text("Productos")) {
            ForEach($viewModel.details) { $item in
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
            .foregroundColor(.darkCyan)
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
                       
                }).disabled(viewModel.isDisabledAddProduct)
            }.padding(.vertical, 10)
        }.buttonStyle(BorderlessButtonStyle())
    }
}




#Preview(traits: .sampleCustomers) {
    AddInvoiceView()
}
