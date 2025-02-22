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
        
         
        var alertTitle: String = ""
        var alertMessage: String = ""
        
        var company : Company = Company(nit:"",nrc:"",nombre:"")
        var dteService = MhClient()
        
        
        var showErrorAlert : Bool = false
        var errorMessage : String = ""
        
        var isBusy : Bool = false
        
        func showConfirmSync(){
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
            
            
            showConfirmSyncSheet.toggle()
        }
        
        
        func SyncDocumentAsync(_ invoice: Invoice) async -> Bool {
            
            isBusy = true
            
            let validation = await validateCredentialsAsync()
            
            if !validation {
                isBusy = false
                return false
            }
             
            let dte = await SyncInvoice(invoice)
            
            if dte == nil {
                isBusy = false
                return false
            }
            else{
                _ =   await backupPDF(invoice)
            }
            
            isBusy = false
            return true
        }
        
       private func SyncInvoice(_ invoice: Invoice) async -> DTE_Base?{
        do{
            
            let dte = try dteService.mapInvoice(invoice: invoice, company: company)
            let invoiceService = InvoiceServiceClient()
            
            let credentials = ServiceCredentials(user: dte.emisor.nit,
                                                    credential: company.credentials,
                                                    key: company.certificatePassword,
                                                    invoiceNumber: invoice.invoiceNumber)
            
            let result = try await invoiceService.Sync(dte: dte,credentials:credentials)
            
            if(result.response.estado == "PROCESADO"){
                invoice.generationCode = result.response.codigoGeneracion
                invoice.receptionSeal = result.response.selloRecibido
                invoice.controlNumber = result.numeroControl
                invoice.status = .Completada
                
                
                
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let docs = documentsURL.appendingPathComponent("DTE_DOCUMENTOS")
                
                do {
                    try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true, attributes: nil)
                    let dteJsonUrl = docs.appendingPathComponent("\(result.numeroControl).json")
                    
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    encoder.dateEncodingStrategy = .iso8601
                    
                    let jsonData =  try encoder.encode(result.dte)
                    
                    do {
                        try jsonData.write(to: dteJsonUrl)
                        print("Successfully wrote to file!")
                    } catch {
                        print("Error writing to file: \(error)")
                    }
                    
                } catch {
                    print("Error creating directory: \(error)")
                }
            }
            
            return dte
            
        }
        catch (let error){
            print(" error al firmar: \(error)")
            errorMessage = error.localizedDescription
            showErrorAlert = true
            return nil
        }
        
    }
        
        func backupPDF(_ invoice: Invoice)async -> Void{
        
        sendingAutomaticEmail = true
        
        let _data = InvoicePDFGenerator.generatePDF(from: invoice, company:  company)
        //refreshPDF()
        pdfData = _data
            
        let  invoiceService = InvoiceServiceClient()
        
        _ = try? await invoiceService.uploadPDF(data: _data, controlNum: invoice.controlNumber!, nit: company.nit)
        
        sendingAutomaticEmail = false
        emailSent = true
    }
        
        func testDeserialize(_ invoice: Invoice) async -> DTEResponseWrapper? {
            let path = "https://kinvoicestdev.blob.core.windows.net/06141404941342/DTE-01-KQACC1I2-558201638398652.json?sv=2021-10-04&st=2025-02-19T22%3A15%3A58Z&se=2025-02-20T22%3A15%3A58Z&sr=b&sp=r&sig=fWFyiepbo%2B5gbvPi47CIl2wnetFN2oEEuvHgEvEZ9PQ%3D"
            
            let path2 = "https://kinvoicestdev.blob.core.windows.net/06141404941342/DTE-01-8VK8VUL7-085808497996953.json?sv=2021-10-04&st=2025-02-19T22%3A18%3A20Z&se=2025-02-20T22%3A18%3A20Z&sr=b&sp=r&sig=x4g%2FQmctgtGmv9wsDdVnhEsVFPmI7UIDr%2FoASH91TkM%3D"
            
            let invoiceService = InvoiceServiceClient()
            
            let dte =  try? await invoiceService.getDocumentFromStorage(path: path)
            
            let dte_invoice = try? await invoiceService.getDocumentFromStorage(path: path2)
            
            print("\(dte_invoice?.numeroControl ?? "No hay control")")
            
            return dte
        }
        func validateCredentialsAsync() async  -> Bool {
            let serviceClient  = InvoiceServiceClient()
            
            if company.credentials.isEmpty {
                isBusy = false
                showErrorAlert = true
                errorMessage = "La contraseña de hacienda aun no se ha configurado correctamente, seleccione perfil y configure la contraseña"
                return false
            }
            
            if company.certificatePassword.isEmpty {
                isBusy = false
                showErrorAlert = true
                errorMessage = "La contraseña de su certificado firmador aun no se ha configurado correctamente, seleccione perfil y luego contraseña de certificado"
                return false
            }
            
            do{
                return try await serviceClient.validateCredentials(nit: company.nit, password: company.credentials)
            }
            catch(let message){
                print("\(message)")
                isBusy = false
                showErrorAlert = true
                errorMessage = "Usuario o contraseña incorrectos"
                
                return false
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
        withAnimation{
            modelContext.delete(invoice)
            dismiss()
        }
    }
    
    func loadEmisor() {
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
                        $0.catalog.id == "CAT-008" && $0.code == typeCode
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
    
    
    func GenerateInvoiceReferences(){
        if invoice.controlNumber == nil || invoice.controlNumber == "" {
            invoice.controlNumber =  invoice.isCCF ?
            try? Extensions.generateString(baseString: "DTE-03",pattern: nil) :
            try? Extensions.generateString(baseString: "DTE",pattern: "^DTE-01-[A-Z0-9]{8}-[0-9]{15}$")
        }
        try? modelContext.save()
    }
    
}

