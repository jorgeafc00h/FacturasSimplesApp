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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    
    
    
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
                    Button("Guardar") {
                        addInvoice()
                        //WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                        dismiss()
                    }
                    .disabled(viewModel.disableAddInvoice)
                }
            }.accentColor(.darkCyan)
        }
        //.presentationDetents([.medium, .large])
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
            
            Button("Agregar Producto") {
                viewModel.displayProductPickerSheet.toggle()
            }
            .foregroundColor(.darkCyan)
        }
        
    }
}




#Preview(traits: .sampleCustomers) {
    AddInvoiceView()
}
