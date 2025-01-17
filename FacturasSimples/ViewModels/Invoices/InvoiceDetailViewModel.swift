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
        
        func showConfirmSync(){
            showConfirmSyncSheet.toggle()
        }
    }
     
    func SyncInvoice(){
        
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
}

