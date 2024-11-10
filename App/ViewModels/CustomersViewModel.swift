

import Foundation
import SwiftUI
import SwiftData

extension CustomersListView {
    
    @Observable
    class CustomersListViewModel{
       
        var isShowingItemsSheet: Bool = false
        
        //var selection: Customer?
        var customersCount: Int = 0
        
        var isDisabledEdit:Bool {
            customersCount == 0
        }
        
    }
    
    /// extensions methdos
    
    func deleteCustomers(at offsets: IndexSet) {
        withAnimation {
            offsets.map { customers[$0] }.forEach(deleteCustomer)
        }
    }
    
    func deleteCustomer(_ cust: Customer) {
        /**
         Unselect the item before deleting it.
         */
        if cust.persistentModelID == selection?.persistentModelID {
            selection = nil
        }
        modelContext.delete(cust)
    }
}
 
