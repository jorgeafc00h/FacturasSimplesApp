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
}

