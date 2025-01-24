//
//  InvoiceDetailView.swift
//  App
//
//  Created by Jorge Flores on 11/4/24.
//

import SwiftUI
import SwiftData

struct InvoiceDetailView: View {
    
    @Bindable var invoice: Invoice
    
    @State var viewModel = InvoiceDetailViewModel()
    @Environment(\.dismiss) var dismiss;
    @Environment(\.modelContext) var modelContext
    @AppStorage("selectedCompanyIdentifier")  var companyIdentifier : String = ""
    
    var body: some View {
        NavigationStack{
            List {
                InvoiceViewForiOS()
                productsSection
                ButtonActions
            } 
        }
        .navigationTitle(Text("Factura"))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                NavigationLink {
                    if let pdfData = viewModel.pdfData {
                        InvoicePDFPreview(pdfData: pdfData,invoice: invoice)
                    }
                } label: {
                    HStack{
                        Image(systemName: "printer.filled.and.paper.inverse")
                            .symbolEffect(.breathe, options: .nonRepeating)
                        
                    }.foregroundColor(.darkCyan)
                }
                
                Button {
                    viewModel.showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                
                
                NavigationLink {
                    InvoiceEditView(invoice: invoice)
                } label: {
                    Image(systemName: "pencil.line")
                }
            }
        }
        .onAppear(){
            refreshPDF()
        }
        .onChange(of: invoice) {
            refreshPDF()
        }
        .onChange(of: viewModel.company){
            refreshPDF()
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let pdfData = viewModel.pdfData {
                SharePDFSheet(
                    activityItems: [pdfData],
                    invoice: invoice
                )
            }
        }
    }
    
    private var ButtonActions : some View {
        Section {
            if invoice.status == .Nueva {
                Button(action: viewModel.showConfirmSync,
                       label: {
                    HStack {
                        Image(systemName: "checkmark.seal.text.page.fill")
                            .symbolEffect(.pulse, options: .repeat(.continuous))
                        Text("Completar y Sincronizar")
                    }
                })
                .confirmationDialog(
                    "¿Desea completar y sincronizar esta factura con el ministerio de hacienda?",
                    isPresented: $viewModel.showConfirmSyncSheet,
                    titleVisibility: .visible
                ) {
                    
                    Button{
                        Task{
                           _ =   await viewModel.SignDocument(invoice)
                        }
                    }
                    label: {
                        Text("Sincronizar")
                    }
                    
                    
                    Button("Cancelar", role: .cancel) {}
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(.green)
                .cornerRadius(10)
                .alert(isPresented: $viewModel.showErrorAlert) {
                           Alert(
                               title: Text("Error"),
                               message: Text(viewModel.errorMessage),
                               dismissButton: .default(Text("OK"))
                           )
                       }
            }
        }
    }
    
    @ViewBuilder
    private func InvoiceViewForiOS() -> some View {
        
        VStack(alignment: .leading) {
            Text(invoice.invoiceNumber)
                .font(.title)
                .bold()
            
            HStack {
                Text("Cliente")
                Spacer()
                Text(invoice.customer.fullName)
            }
            HStack {
                Text("Identificación")
                Spacer()
                Text(invoice.customer.nationalId)
            }
            HStack {
                Text("Email")
                Spacer()
                Text(invoice.customer.email)
            }
            HStack {
                Text("Estado")
                Spacer()
                Circle()
                    .fill(invoice.statusColor)
                    .frame(width: 8, height: 8)
                Text("\(invoice.status)")
                    .font(.subheadline)
                    .foregroundColor(invoice.statusColor)
                    .padding(7)
                    .background(invoice.statusColor.opacity(0.09))
                    .cornerRadius(8)
            }
        }
        
        NavigationLink {
            InvoiceEditView(invoice: invoice)
        } label: {
            HStack{
                Image(systemName: "pencil.line")
                    .symbolEffect(.breathe, options: .nonRepeating)
                Text("Editar factura")
            }.foregroundColor(.darkCyan)
        }.disabled(invoice.status == .Completada)
        
        NavigationLink {
            if let pdfData = viewModel.pdfData {
                InvoicePDFPreview(pdfData: pdfData,invoice: invoice)
            }
        } label: {
            HStack{
                Image(systemName: "printer.filled.and.paper.inverse")
                    .symbolEffect(.breathe, options: .nonRepeating)
                Text("PDF")
            }.foregroundColor(.darkCyan)
        }
        
        
        if invoice.status == .Nueva {
            Button(role: .destructive,
                   action: { viewModel.showingDeleteConfirmation = true },
                   label: {
                        Label("Eliminar Factura",systemImage: "trash")
                    .symbolEffect(.breathe, options: .nonRepeating)
                    .foregroundColor(.red)
                })
                
            .confirmationDialog(
                "¿Está seguro que desea eliminar esta Factura?",
                isPresented: $viewModel.showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    deleteInvoice()
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
        Section {
            Group{
                VStack(alignment: .leading) {
                    
                    HStack {
                        Text("Fecha")
                        Spacer()
                        Text(invoice.date, style: .date)
                        
                    }
                    HStack{
                        Text("Tipo")
                        Spacer()
                        Text(invoice.invoiceType.stringValue())
                    }
                    HStack{
                        Text("Estado")
                        Spacer()
                        Text(invoice.status.stringValue())
                    }
                    HStack{
                        Text("Cod. Gen.")
                        Spacer()
                        Text(invoice.generationCode!)
                    }
                    HStack{
                        Text("Sello")
                        Spacer()
                        Text(invoice.receptionSeal!)
                    }
                    HStack{
                        Text("Numero Control")
                        Spacer()
                        Text(invoice.controlNumber!)
                    }
                    
                }
            }
            
        }
        Section{
            Group{
                VStack(alignment: .leading) {
                    HStack{
                        Text("Sub Total")
                        Spacer()
                        Text(invoice.subTotal.formatted(.currency(code:"USD")))
                    }
                    HStack{
                        Text("Total")
                        Spacer()
                        Text(invoice.totalAmount.formatted(.currency(code:"USD")))
                    }
                }
            }
        }
        
    }
    
    
    private var productsSection: some View {
        Section(header: Text("Productos")) {
            ForEach($invoice.items){ $detail in
                ProductDetailItemView(detail: detail)
                
            }
        }
    }
}

#Preview(traits: .sampleInvoices) {
    @Previewable @Query var invoices: [Invoice]
    InvoiceDetailView(invoice: invoices.first!)
}
