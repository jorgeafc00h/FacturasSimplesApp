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
        
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        
        var company : Company = Company(nit:"",nrc:"",nombre:"")
        var dteService = MhClient()
        //var documentSigner = DocumentSigner()
        
        var showErrorAlert : Bool = false
        var errorMessage : String = ""
        
        var isBusy : Bool = false
        
        func showConfirmSync(){
            showConfirmSyncSheet.toggle()
        }
        
        func SyncInvoice(_ invoice: Invoice) async -> DTE_Base?{
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
                        let dteJsonUrl = docs.appendingPathComponent("\(invoice.invoiceNumber).json")
                        
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
    }
 
    
    func deleteInvoice (){
        if invoice.status == .Completada {
            viewModel.alertTitle = "Error"
            viewModel.alertMessage = "No se puede eliminar una factura Completada"
            viewModel.showAlert = true
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
    
    func SyncInvoice() async{
        
        _ = await viewModel.SyncInvoice(invoice)
    }
    
}

