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
        var showConfirmDebitNote: Bool = false
        
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
                
                let response = try await invoiceService.Sync(dte: dte!,credentials:credentials,isProduction: company.isProduction)
                
                await MainActor.run {
                    dteResponse = response
                }
                
                print("\(response.estado ?? "")")
                print("SELLO \(response.selloRecibido ?? "")")
                
                
                return response
                
            }
            catch (let error){
                print(" error al firmar: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    dteResponse = nil
                }
                return nil
            }
            
        }
        
        func backupPDF(_ invoice: Invoice)async {
            
            await MainActor.run {
                sendingAutomaticEmail = true
            }
            
            let _data = InvoicePDFGenerator.generatePDF(from: invoice, company:  company)
            
            await MainActor.run {
                pdfData = _data
            }
            
            do{
                try await invoiceService.uploadPDF(data: _data, controlNum: invoice.controlNumber!, nit: company.nit,isProduction: company.isProduction)
            }
            catch(let e){
                print("Error al subir el pdf \(e)")
            }
            
            await MainActor.run {
                sendingAutomaticEmail = false
            }
        }
        
        
        func validateCredentialsAsync(_ invoice: Invoice) async  {
            let serviceClient  = InvoiceServiceClient()
            
            if company.credentials.isEmpty {
                await MainActor.run {
                    isBusy = false
                    showErrorAlert = true
                    errorMessage = "La contraseña de hacienda aun no se ha configurado correctamente, seleccione perfil y configure la contraseña"
                }
                return
            }
            
            if company.certificatePassword.isEmpty {
                await MainActor.run {
                    isBusy = false
                    showErrorAlert = true
                    errorMessage = "La contraseña de su certificado firmador aun no se ha configurado correctamente, seleccione perfil y luego contraseña de certificado"
                }
                return 
            }
            
            await MainActor.run {
                syncLabel = "Validando Credenciales de Hacienda....."
                isBusy = true
            }
            
            dte = GenerateInvoiceReferences(invoice)
            
            if dte == nil {
                await MainActor.run {
                    isBusy = false
                }
                return
            }
            
            do{
                _ =  try await serviceClient.validateCredentials(nit: company.nit, password: company.credentials,isProduction: company.isProduction)
                await MainActor.run {
                    syncLabel = "Enviando..."
                    isBusy = false
                    showConfirmSyncSheet = true
                }
                //return result
            }
            catch(let message){
                print("\(message)")
                await MainActor.run {
                    isBusy = false
                    showErrorAlert = true
                    errorMessage = "Usuario o contraseña incorrectos"
                }
                
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
            // Check if user has available credits before attempting sync
            let canProceed = validateCreditsBeforeSync()
            guard canProceed else {
                viewModel.errorMessage = "No tienes créditos suficientes para completar esta factura. Compra más créditos en la sección de compras."
                viewModel.showErrorAlert = true
                return
            }
            
            viewModel.isBusy = true
            Task {
                
                if let response = await viewModel.SyncInvoice(invoice: invoice){
                    
                    invoice.status = .Completada
                    invoice.statusRawValue = invoice.status.id
                    invoice.receptionSeal = response.selloRecibido
                    try? modelContext.save()
                    
                    udpateRelatedDocuemntFromCreditNote()
                    
                    // Consume credit ONLY after successful sync using PurchaseDataManager
                    consumeCreditForCompletedInvoice()
                    
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
    
    func deleteInvoice() {
        if invoice.status == .Completada {
            viewModel.alertTitle = "Error"
            viewModel.alertMessage = "No se puede eliminar una factura Completada"
            viewModel.showErrorAlert = true
            return
        }
        
        else{
            withAnimation{
                // No need to refund credits since they're only consumed when invoice is synced
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
    
    
    // TODO centralize this on extension
    func getNextInoviceOrCCFNumber(invoiceType:InvoiceType) -> String{
       print("Get Next Invoice number \(invoiceType) ")
       let _type =  Extensions.documentTypeFromInvoiceType(invoiceType)
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate<Invoice>{
                $0.customer?.companyOwnerId == companyIdentifier &&
                $0.documentType == _type
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let latestInvoice = try? modelContext.fetch(descriptor).first {
            if let currentNumber = Int(latestInvoice.invoiceNumber) {
                print("# \(currentNumber)")
               return String(format: "%05d", currentNumber + 1)
            } else {
                return "00001"
            }
        } else {
            return "00001"
        }
    }
    
    @MainActor
    func generateCreditNote(){
        
        let note = Invoice(invoiceNumber: invoice.invoiceNumber,
                           date: invoice.date,
                           status: invoice.status, customer: invoice.customer,
                           invoiceType: .NotaCredito)
        
        let items = (invoice.items ?? []).map { detail -> InvoiceDetail in
            return InvoiceDetail(quantity: detail.quantity, product: detail.product)
            
        }
        
        note.invoiceNumber = getNextInoviceOrCCFNumber(invoiceType: .CCF)
         
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
    
    
    @MainActor
    func generateDebitNote(){
        let note = Invoice(invoiceNumber: invoice.invoiceNumber,
                           date: invoice.date,
                           status: invoice.status, customer: invoice.customer,
                           invoiceType: .NotaDebito)
        
        let items = (invoice.items ?? []).map { detail -> InvoiceDetail in
            return InvoiceDetail(quantity: detail.quantity, product: detail.product)
            
        }
        
        note.invoiceNumber = getNextInoviceOrCCFNumber(invoiceType: .CCF)
        note.status = .Nueva
        note.date = Date()
        note.invoiceType = .NotaDebito
        note.documentType = Extensions.documentTypeFromInvoiceType(.NotaDebito)
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
    
    /// Validate if user has available credits before attempting sync
    func validateCreditsBeforeSync() -> Bool {
     
        // Get the company associated with this invoice
        guard let customerId = invoice.customer?.companyOwnerId else {
            print("⚠️ No company ID found for invoice")
            return false
        }
        
        let descriptor = FetchDescriptor<Company>(
            predicate: #Predicate<Company> { company in
                company.id == customerId
            }
        )
        
        guard let company = try? modelContext.fetch(descriptor).first else {
            print("⚠️ Company not found")
            return false
        }

        // if it's a test company, bypass credit validation
        if company.isTestAccount {
            print("🧪 Test company detected - bypassing credit validation")
            return true
        }

        // Use PurchaseDataManager for centralized credit validation
        return PurchaseDataManager.shared.validateCreditsBeforeInvoiceSync(for: customerId)
    }
    
    /// Consume credit for a completed invoice using N1CO system
    func consumeCreditForCompletedInvoice() {
        // Get the company associated with this invoice
        guard let customerId = invoice.customer?.companyOwnerId else {
            print("⚠️ Cannot consume credit - no company ID found for invoice")
            return
        }
        
        let descriptor = FetchDescriptor<Company>(
            predicate: #Predicate<Company> { company in
                company.id == customerId
            }
        )
        
        guard let company = try? modelContext.fetch(descriptor).first else {
            print("⚠️ Cannot consume credit - company not found")
            return
        }
        
        // Use PurchaseDataManager for centralized credit consumption
        PurchaseDataManager.shared.consumeCreditForCompletedInvoice(invoice.inoviceId, companyId: customerId)
    }
}

