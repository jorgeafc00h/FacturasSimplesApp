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
    
    @State private var testL: String = ""
    
    var body: some View {
        
        NavigationStack {
            
            VStack{
                
                Form{
                    CustomerSection(customer: $customer, displayPickerSheet: $displayPickerSheet)
                    
                    InvoiceDataSection(invoiceNumber: $invoiceNumber,
                                       date: $date,
                                       invoiceType: $invoiceType)
                }
                Button{
                    displayProductPickerSheet.toggle()
                }label: {
                    HStack{
                        Image(systemName: "plus")
                        Text("Agregar Producto")
                    }.font(.subheadline)
                }.foregroundColor(.darkCyan)
                
                ProductDetailsSection(details: $details)
                
                
                
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
                    .disabled(invoiceNumber.isEmpty || customer == nil || details.isEmpty)
                }
            }.accentColor(.darkCyan)
        }
        //.presentationDetents([.medium, .large])
    }
    
    private func addInvoice()
    {
        let invoice = Invoice(invoiceNumber: invoiceNumber,
                              date:date, 
                              status: .Nueva,
                              customer: customer!,
                              invoiceType: invoiceType)
        invoice.items = details
        
        modelContext.insert(invoice)
    }
}

private struct CustomerSection :View {
    
    @Binding var customer: Customer?
    @Binding var displayPickerSheet: Bool
    
    var body: some View {
        Section {
            
            Group{
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
        Section {
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
    
     
    
    var body: some View {
        VStack{
            List {
                ForEach(details,id: \.self){ detail in
                    
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
            .edgesIgnoringSafeArea(.bottom)
            .overlay {
                if details.isEmpty {
                    ContentUnavailableView {
                        Label("productos", systemImage: "list.clipboard.fill").foregroundColor(.blueGray)
                    }description: {
                        Text("...")
                    }
                    .offset(y: -60)
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
