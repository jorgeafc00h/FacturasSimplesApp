import SwiftUI
import SwiftData

extension  InvoicesListView{
    
    @Observable
    class InvoicesListViewModel{
        var isShowingAddInvoiceSheet : Bool = false
        var invocesCount: Int = 0
        
       
        var offsets: IndexSet = []
        var toDeleteInovice: Invoice?
         
    }
     
   
    
}
