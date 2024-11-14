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
    @State private var showingPDFPreview = false
    @State private var pdfData: Data?
    
    var body: some View {
        NavigationStack{
            List {
                InvoiceViewForiOS()
                productsSection
            }
        }
        .navigationTitle(Text("Factura"))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    pdfData = InvoicePDFGenerator.generatePDF(from: invoice)
                    showingPDFPreview = true
                } label: {
                    Image(systemName: "printer.filled.and.paper.inverse")
                }
                
                if let pdfData = pdfData {
                    ShareLink(item: pdfData, preview: SharePreview("Factura.pdf")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            
                NavigationLink {
                    InvoiceEditView(invoice: invoice)
                } label: {
                    Image(systemName: "pencil.line")
                }
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = pdfData {
                InvoicePDFPreview(pdfData: pdfData)
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
            
        }
        
        NavigationLink {
            InvoiceEditView(invoice: invoice)
        } label: {
            HStack{
                
                Image(systemName: "pencil.line")
                Text("Actualizar datos")
            }.foregroundColor(.darkCyan)
        }
        
        Section {
            HStack{
                Button(action: {
                    pdfData = InvoicePDFGenerator.generatePDF(from: invoice)
                    showingPDFPreview = true
                }, label: {
                    HStack {
                        Image(systemName: "printer.filled.and.paper.inverse")
                        
                    }
                })
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(.darkCyan)
                .cornerRadius(10)
                
                Button(action: {
                    pdfData = InvoicePDFGenerator.generatePDF(from: invoice)
                }, label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        
                    }
                })
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(.darkCyan)
                .cornerRadius(10)
                
                Button(action: {
                    print(".")
                }, label: {
                    HStack {
                        Image(systemName: "pencil.line")
                        
                    }
                })
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(.darkCyan)
                .cornerRadius(10)
            } .buttonStyle(BorderlessButtonStyle())
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
