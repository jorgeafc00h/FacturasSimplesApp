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
        .navigationTitle(Text(invoice.invoiceType.stringValue() ))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                ShareButton()
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task {
                            
                            _ = await viewModel.testDeserialize(invoice)
                        }
                    } label: {
                        Text("Generar Nota de crédito")
                    }
                    .help("Clears all content from the cache")
                    EditButon()
                        .help("Editar Información General de la factura")
                    PrintButton()
                        .help("Vista preview de impresion para compartir factura PDF")
                    
                    if( invoice.status == .Completada){
                        SendEmailButton()
                            .help( "Enviar factura por email automatico, eso es util en caso de que actualize el correo electronico del cliente o si desea enviar nuevamente la factura")
                    }
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .onAppear(){
            refreshPDF() 
        }
//        .onChange(of: invoice) {
//            refreshPDF()
//        }
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
    
    @ViewBuilder
    private func PrintButton() -> some View {
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
    }
    
    @ViewBuilder
    private func ShareButton() -> some View {
        Button {
            viewModel.showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        
        
        
    }
   
    @ViewBuilder
    private func EditButon() -> some View {
        NavigationLink {
            InvoiceEditView(invoice: invoice)
        } label: {
            HStack{
                Image(systemName: "pencil.line")
                    .symbolEffect(.breathe, options: .nonRepeating)
                Text("Editar factura")
            }.foregroundColor(.darkCyan)
        }.disabled(invoice.status == .Completada)
    }
    
    @ViewBuilder
    private func SendEmailButton() -> some View {
        Button {
            viewModel.showingConfirmAutoEmail.toggle()
        }
        label: {
            HStack{
                Image(systemName: "envelope.fill")
                    .symbolEffect(.breathe, options: .nonRepeating)
                Text("Enviar PDF por Email")
                
            }.foregroundColor(.darkCyan)
        }
        .disabled(viewModel.emailSent)
        
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
        
        
        EditButon()
        PrintButton()
      
        
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
                    VStack(alignment: .leading){
                        Text("Cod. Gen.")
                            .padding(.top, 5)
                        Text(invoice.generationCode!)
                            .font(.footnote)
                            .padding(.top, 5)
                    }
                    VStack(alignment: .leading){
                        Text("Sello")
                            .padding(.top, 5)
                        Text(invoice.receptionSeal!)
                            .font(.footnote)
                            .padding(.top, 5)
                    }
                    VStack(alignment: .leading){
                        Text("Número Control")
                            .padding(.top, 5)
                        Text(invoice.controlNumber!)
                            .font(.footnote)
                            .padding(.top, 5)
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
    
    private var ButtonActions : some View {
        Section {
            
            if invoice.status == .Nueva{
                
                withAnimation(){
                    
                    Button(action: {
                        
                        Task{
                            _ = await viewModel.validateCredentialsAsync(invoice)
                            viewModel.showConfirmSync()
                        }
                    },label: {
                        HStack {
                            if viewModel.isBusy{
                                Label(viewModel.syncLabel,systemImage: "progress.indicator")
                                
                                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                            }
                            else{
                                Image(systemName: "checkmark.seal.text.page.fill")
                                
                                Text("Completar y Sincronizar")
                            }
                        }
                    })
                    .disabled(viewModel.isBusy ||
                              invoice.status == .Completada)
                    .confirmationDialog(
                        "¿Desea completar y sincronizar esta factura con el ministerio de hacienda?",
                        isPresented: $viewModel.showConfirmSyncSheet,
                        titleVisibility: .visible
                    ) {
                        
                        Button(action: SyncInvoice, label: { Text("Sincronizar") })
                        
                        
                        Button("Cancelar", role: .cancel) {}
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .padding()
                    .background(.darkCyan)
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
            
            if invoice.status == .Completada {
                HStack {
                    Text("\(invoice.invoiceType)")
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
                    .confirmationDialog(
                        "¿Desea enviar nuevamente esta factura via email : \(invoice.customer.email)?",
                        isPresented: $viewModel.showingConfirmAutoEmail,
                        titleVisibility: .visible
                    ) {
                        
                        Button{
                            viewModel.sendingAutomaticEmail = true
                            Task{
                               await viewModel.backupPDF(invoice)
                            }
                        }
                        label: {
                            Text("Enviar")
                        }
                        
                        
                        Button("Cancelar", role: .cancel) {}
                    }
                if viewModel.sendingAutomaticEmail {
                    Label("Enviando correo con documento adjunto...",systemImage: "progress.indicator")
                        .foregroundColor(.darkCyan)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                }
                 
            }
        }
    }
}

#Preview(traits: .sampleInvoices) {
    @Previewable @Query var invoices: [Invoice]
    InvoiceDetailView(invoice: invoices.first!)
}
