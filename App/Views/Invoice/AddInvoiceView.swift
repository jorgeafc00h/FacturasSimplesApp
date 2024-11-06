//
//  AddInvoiceView.swift
//  App
//
//  Created by Jorge Flores on 11/3/24.
//

import SwiftUI
import SwiftData

struct AddInvoiceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    
    @State private var customer: Customer?
    @State private var displayPickerSheet: Bool = false
    @State private var invoiceNumber : String = ""
    @State private var date: Date = Date()
    @State private var invoiceType : InvoiceType = .Factura
    
    @State private var displayProductPickerSheet: Bool = false
    @State private var details:[InvoiceDetail] = []
    
    
    var body: some View {
        
        NavigationStack {
            
            
            Form{
                CustomerSection(customer: $customer, displayPickerSheet: $displayPickerSheet)
                
                InvoiceDataSection(invoiceNumber: $invoiceNumber,
                                   date: $date,
                                   invoiceType: $invoiceType)
                
                ProductDetailsSection(details:$details,
                                      displayProductPickerSheet: $displayProductPickerSheet)
                
            }
            .frame(idealWidth: LayoutConstants.sheetIdealWidth,
                   idealHeight: LayoutConstants.sheetIdealHeight)
            .navigationTitle("Nueva Factura")
            .sheet(isPresented: $displayPickerSheet){
                CustomerPicker(selection: $customer)
            }
            .sheet(isPresented: $displayProductPickerSheet){
                ProductPicker(details: $details)
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
                    .disabled(true)
                }
            }.accentColor(.darkCyan)
        }
        //.presentationDetents([.medium, .large])
    }
    
    private func addInvoice()
    {
        
    }
}

private struct CustomerSection :View {
    
    @Binding var customer: Customer?
    @Binding var displayPickerSheet: Bool
    
    var body: some View {
        Section(header: Text("Cliente")) {
            
            CustomerGroupBox{
                Button{
                    displayPickerSheet.toggle()
                }label: {
                    if customer == nil {
                        HStack{
                            Image(systemName: "magnifyingglass")
                            Text("Buscar Cliente")
                        }.foregroundColor(.darkCyan)
                    }
                    else {
                        HStack{
                            Text(customer!.fullName)
                            Spacer()
                            Text(customer!.nationalId)
                        }
                    }
                }
            }
            
            
        }
    }
}

private struct InvoiceDataSection: View{
    
    @Binding var invoiceNumber: String
    @Binding var date: Date
    @Binding var invoiceType: InvoiceType
    
    @State var invoiceTypes :[InvoiceType] = [.Factura,.CCF]
    
    var body : some View{
        Section(header: Text("Factura")) {
            Group {
                TextField("Numero de Factura",text: $invoiceNumber)
                HStack{
                    Text("Fecha:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker(selection: $date) {
                        Label("End Date", systemImage: "calendar")
                    }
                    .labelsHidden()
                }
                HStack{
                    Text("Tipo Documento:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker(" ", selection: $invoiceType) {
                        ForEach(invoiceTypes, id: \.self) { invoiceType in
                            
                            Text(invoiceType.stringValue()).tag(invoiceType)
                        }
                    }
                }
                
            }
            
        }
    }
}

private struct ProductDetailsSection : View {
    
    @Binding var details: [InvoiceDetail]
    
    
    @Binding var displayProductPickerSheet: Bool
    
    var body: some View {
        Section(header:Text("Productos/Servicios")){
            CustomerGroupBox{
                Button{
                    displayProductPickerSheet.toggle()
                }label: {
                    HStack{
                        Image(systemName: "plus")
                        Text("Agregar Producto")
                    }.font(.subheadline)
                }
            }
            CustomerGroupBox{
                List{
                    ForEach(details){detail in
                        ProductDetailItemView(detail: detail)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteDetail(detail: detail)
                                    //WidgetCenter.shared.reloadTimelines(ofKind: "CustomersWidget")
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    func deleteDetail(detail:InvoiceDetail){
        withAnimation{
            let index = details.firstIndex(of: detail)
            
            details.remove(at: index!)
        }
    }
}


#Preview(traits: .sampleCustomers) {
    AddInvoiceView()
}
