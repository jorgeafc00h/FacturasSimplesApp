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
        var documentSigner = DocumentSigner()
        
        var showErrorAlert : Bool = false
        var errorMessage : String = ""
        
        func showConfirmSync(){
            showConfirmSyncSheet.toggle()
        }
        
        func SignDocument(_ invoice: Invoice) async -> DTE_Base?{
            do{
                
                let dte = try dteService.mapInvoice(invoice: invoice, company: company)
            
                print("cert path : \(company.certificatePath)")
           
                let encoder = JSONEncoder()
                //encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                
                let jsonData =  try encoder.encode(dte)
                let jsonString = String(data: jsonData, encoding: .utf8)!
                    
                print("DTE JSON")
                print(jsonString)
                
                
                let signingRequest = DocumentSigningRequest(
                    nit: company.nit,
                    passwordPri: company.certificatePassword,
                    dteJson: jsonString)
                
                let signedDocument = try await documentSigner.signDocument(request: signingRequest, certificatePath: company.certificatePath)
                
                if !signedDocument.success  {
                    errorMessage = signedDocument.error!
                    showErrorAlert = true
                }
                
                return dte
                
            }
            catch (let error){
                print(" error al firmar: \(error)")
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
            return nil
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
        
        await viewModel.SignDocument(invoice)
    }
    
}

