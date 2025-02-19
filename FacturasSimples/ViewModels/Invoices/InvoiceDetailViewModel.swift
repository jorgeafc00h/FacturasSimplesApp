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
        
        let  invoiceService = InvoiceServiceClient()
        
        _ = try? await invoiceService.uploadPDF(data: _data, controlNum: invoice.controlNumber!, nit: company.nit)
        
        sendingAutomaticEmail = false
        emailSent = true
    }
        
        func testDeserialize(_ invoice: Invoice) async -> DTEResponseWrapper? {
            let path = "https://kinvoicestdev.blob.core.windows.net/06141404941342/DTE-03-4V841VOJ-281168646418339.json?sv=2021-10-04&st=2025-02-05T13%3A23%3A43Z&se=2025-02-07T13%3A23%3A00Z&sr=b&sp=r&sig=lIG8kOvr0aFualetkFaDDzcKcd9Wz%2B0CB1%2BhsThRCUM%3D"
            
            let path2 = "https://kinvoicestdev.blob.core.windows.net/06141404941342/DTE-01-EE7L1BXY-939246480329284.json?sv=2021-10-04&st=2025-02-05T13%3A54%3A54Z&se=2025-02-06T13%3A54%3A54Z&sr=b&sp=r&sig=aoyi8o%2B9hoUBxCH6fBg5JtfPlDeFY0cOxkvc4SAQjtw%3D"
            
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
    
     
    
}

