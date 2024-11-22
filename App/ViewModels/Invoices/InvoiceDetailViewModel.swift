import SwiftUI
import SwiftData
extension InvoiceDetailView {
    
    @Observable
    class InvoiceDetailViewModel {
        var pdfData : Data?
        var showShareSheet : Bool = false
        var pdfURL : URL?
        var showConfirmSyncSheet : Bool = false
        
        func showConfirmSync(){
            showConfirmSyncSheet.toggle()
        }
    }
     
    func SyncInvoice(){
        
    }
}

