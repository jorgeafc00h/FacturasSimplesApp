import SwiftUI
import SwiftData
extension InvoiceDetailView {
    
    @Observable
    class InvoiceDetailViewModel {
        var pdfData : Data?
        var showShareSheet : Bool = false
        var pdfURL : URL?
        var showConfirmSyncSheet : Bool = false
        
        var showingDeleteConfirmation : Bool = false
        var showingConfirmAutoEmail : Bool = false
        var sendingAutomaticEmail : Bool = false
        var emailSent : Bool = false
        var showConfirmCreditNote: Bool = false
        
        var alertTitle: String = ""
        var alertMessage: String = ""
        
        var company : Company = Company(nit:"",nrc:"",nombre:"")
        var dteService = MhClient()
        
        
        var showErrorAlert : Bool = false
        var errorMessage : String = ""
        
        var isBusy : Bool = false
        
        var syncLabel: String = "Enviando..."
        
        var dte : DTE_Base?
        var dteResponse : DTEResponseWrapper?
        
        var showDeactivateSheet : Bool = false
        
        let invoiceService = InvoiceServiceClient()
        
        
        func  SyncInvoice(invoice: Invoice) async  -> DTEResponseWrapper? {
            
            
            do{
                
                let credentials = ServiceCredentials(user: dte!.emisor.nit,
                                                     credential: company.credentials,
                                                     key: company.certificatePassword,
                                                     invoiceNumber: invoice.invoiceNumber)
                
                dteResponse  = try await invoiceService.Sync(dte: dte!,credentials:credentials,isProduction: company.isProduction)
                
                print("\(dteResponse?.estado ?? "")")
                print("SELLO \(dteResponse?.selloRecibido ?? "")")
                
                
                return dteResponse
                
            }
            catch (let error){
                print(" error al firmar: \(error)")
                errorMessage = error.localizedDescription
                showErrorAlert = true
                dteResponse = nil
                return nil
            }
            
        }
        
        func backupPDF(_ invoice: Invoice)async {
            
            sendingAutomaticEmail = true
            
            let _data = InvoicePDFGenerator.generatePDF(from: invoice, company:  company)
            
            pdfData = _data
            do{
                try await invoiceService.uploadPDF(data: _data, controlNum: invoice.controlNumber!, nit: company.nit,isProduction: company.isProduction)
            }
            catch(let e){
                print("Error al subir el pdf \(e)")
            }
            sendingAutomaticEmail = false
        }
        
        func testDeserialize(_ invoice: Invoice) async -> DTE_Base? {
            let path = "https://kinvoicestdev.blob.core.windows.net/06141404941342/DTE-01-KQACC1I2-558201638398652.json?sv=2021-10-04&st=2025-02-19T22%3A15%3A58Z&se=2025-02-20T22%3A15%3A58Z&sr=b&sp=r&sig=fWFyiepbo%2B5gbvPi47CIl2wnetFN2oEEuvHgEvEZ9PQ%3D"
            
            let path2 = "https://kinvoicestdev.blob.core.windows.net/06141404941342/DTE-01-8VK8VUL7-085808497996953.json?sv=2021-10-04&st=2025-02-19T22%3A18%3A20Z&se=2025-02-20T22%3A18%3A20Z&sr=b&sp=r&sig=x4g%2FQmctgtGmv9wsDdVnhEsVFPmI7UIDr%2FoASH91TkM%3D"
            
            // let invoiceService = InvoiceServiceClient()
            
            let dte =  try? await invoiceService.getDocumentFromStorage(path: path)
            
            let dte_invoice = try? await invoiceService.getDocumentFromStorage(path: path2)
            
            print("\(dte_invoice?.identificacion.numeroControl ?? "No hay control")")
            
            return dte
        }
        
        func validateCredentialsAsync(_ invoice: Invoice) async  {
            let serviceClient  = InvoiceServiceClient()
            
            if company.credentials.isEmpty {
                isBusy = false
                showErrorAlert = true
                errorMessage = "La contraseña de hacienda aun no se ha configurado correctamente, seleccione perfil y configure la contraseña"
                return
            }
            
            if company.certificatePassword.isEmpty {
                isBusy = false
                showErrorAlert = true
                errorMessage = "La contraseña de su certificado firmador aun no se ha configurado correctamente, seleccione perfil y luego contraseña de certificado"
                return 
            }
            syncLabel = "Validando Credenciales de Hacienda....."
            isBusy = true
            
            dte = GenerateInvoiceReferences(invoice)
            
            if dte == nil {
                isBusy = false
                return
            }
            
            do{
                _ =  try await serviceClient.validateCredentials(nit: company.nit, password: company.credentials,isProduction: company.isProduction)
                syncLabel = "Enviando..."
                isBusy = false
                
                showConfirmSyncSheet = true
                //return result
            }
            catch(let message){
                print("\(message)")
                isBusy = false
                showErrorAlert = true
                errorMessage = "Usuario o contraseña incorrectos"
                
                //return false
            }
        }
        
        func GenerateInvoiceReferences(_ invoice: Invoice) -> DTE_Base? {
            
            Extensions.generateControlNumberAndCode(invoice)
            
            do {
                let envCode =  invoiceService.getEnvironmetCode(company.isProduction)
                
                let dte = try MhClient.mapInvoice(invoice: invoice, company: company,environmentCode: envCode)
                
                print("DTE Numero control:\(dte.identificacion.numeroControl ?? "")")
                
                return dte
            } catch (let error){
                print("failed to map invoice to dte \(error.localizedDescription)")
                
                errorMessage = "No se pudo generar EL DTE verifique los campos requeridos \n \(error.localizedDescription)"
                showErrorAlert = true
                return nil
            }
        }
    }
    
    
    
    func SyncInvoice(){
        
        try? modelContext.save()
        
        if viewModel.dte != nil {
            viewModel.isBusy = true
            Task {
                
                if let response =   await viewModel.SyncInvoice(invoice: invoice){
                    
                    invoice.status = .Completada
                    invoice.statusRawValue =  invoice.status.id
                    invoice.receptionSeal = response.selloRecibido
                    try? modelContext.save()
                    
                    udpateRelatedDocuemntFromCreditNote()
                    await viewModel.backupPDF(invoice)
                }
                viewModel.isBusy = false
            }
        }
    }
    
    func udpateRelatedDocuemntFromCreditNote() {
        if invoice.invoiceType == .NotaCredito {
            
            let id = invoice.relatedId!
            
            let descriptor = FetchDescriptor<Invoice>(
                predicate: #Predicate<Invoice>{
                    $0.inoviceId == id
                }
                
            )
            
            if let relatedInvoice = try? modelContext.fetch(descriptor).first {
                relatedInvoice.status = .Anulada
                relatedInvoice.statusRawValue =  relatedInvoice.status.id
                try? modelContext.save()
            }
        }
    }
    
    func deleteInvoice (){
        if invoice.status == .Completada {
            viewModel.alertTitle = "Error"
            viewModel.alertMessage = "No se puede eliminar una factura Completada"
            viewModel.showErrorAlert = true
            return
        }
        
        else{
            withAnimation{
            modelContext.delete(invoice)
            dismiss()
            }
       }
    }
    
    func loadEmisor() {
        viewModel.dteResponse = nil
        if invoice.documentType.isEmpty{
            invoice.documentType = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
            try? modelContext.save()
        }
        print("DocType \(invoice.documentType)")
        
        do{
            let descriptor = FetchDescriptor<Company>(
                predicate: #Predicate<Company>{
                    $0.id == companyIdentifier
                }
                // sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            if let company = try modelContext.fetch(descriptor).first {
                viewModel.company = company
                
                //load tipo establecimiento
                if company.establecimiento == ""{
                    let typeCode = company.tipoEstablecimiento
                    
                    let _descriptor = FetchDescriptor<CatalogOption>(predicate: #Predicate {
                        $0.catalog?.id == "CAT-008" && $0.code == typeCode
                    })
                    
                    if let _catalogOption = try? modelContext.fetch(_descriptor).first {
                        viewModel.company.establecimiento = _catalogOption.details
                    } else {
                        print("no selected tipoEstablecimiento identifier: \(company.tipoEstablecimiento) ")
                    }
                }
                
            }
        }
        catch{
            print("error loading emisor data")
        }
    }
    func refreshPDF(){
        viewModel.pdfData = nil
        loadEmisor()
        viewModel.pdfData = InvoicePDFGenerator.generatePDF(from: invoice, company: viewModel.company)
    }
    
    
    func generateCreditNote(){
        
        let note = Invoice(invoiceNumber: invoice.invoiceNumber,
                           date: invoice.date,
                           status: invoice.status, customer: invoice.customer,
                           invoiceType: .NotaCredito)
        
        let items = (invoice.items ?? []).map { detail -> InvoiceDetail in
            return InvoiceDetail(quantity: detail.quantity, product: detail.product)
            
        }
        
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate<Invoice>{
                $0.customer?.companyOwnerId == companyIdentifier
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let latestInvoice = try? modelContext.fetch(descriptor).first {
            if let currentNumber = Int(latestInvoice.invoiceNumber) {
                note.invoiceNumber = String(format: "%05d", currentNumber + 1)
            } else {
                let currentNumber = Int(invoice.invoiceNumber)
                note.invoiceNumber = String(format: "%05d", currentNumber! + 1)
            }
        } else {
            let currentNumber = Int(invoice.invoiceNumber)
            note.invoiceNumber = String(format: "%05d", currentNumber! + 1)
        }
        
        note.status = .Nueva
        note.date = Date()
        note.invoiceType = .NotaCredito
        note.documentType = Extensions.documentTypeFromInvoiceType(.NotaCredito)
        note.relatedDocumentNumber = invoice.generationCode
        note.relatedDocumentType = invoice.documentType
        note.relatedInvoiceType = invoice.invoiceType
        note.relatedId = invoice.inoviceId
        note.items = items
        note.relatedDocumentDate = invoice.date
        
        // Set correct sync status based on company type (through customer)
        if let customerId = invoice.customer?.companyOwnerId {
            let isProductionCompany = !customerId.isEmpty && 
                                    DataSyncFilterManager.shared.getProductionCompanies(context: modelContext)
                                        .contains { $0.id == customerId }
            note.shouldSyncToCloudKit = isProductionCompany
        } else {
            note.shouldSyncToCloudKit = false
        }
        
        modelContext.insert(note)
        try? modelContext.save()
        
        dismiss()
        
        
    }
    
    func invalidateDocument(){
        
    }
    
}

