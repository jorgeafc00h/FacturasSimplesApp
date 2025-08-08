import SwiftUI
import SwiftData

extension  InvoicesListView{
    
    @Observable
    class InvoicesListViewModel{
        var isShowingAddInvoiceSheet : Bool = false
        var showCreditsAlert: Bool = false
        var showPurchaseView: Bool = false
        var invocesCount: Int = 0
       
        var offsets: IndexSet = []
        var toDeleteInovice: Invoice?
        
    }
    
    func SyncCatalogs() async {
        
        if(catalog.isEmpty){
            do{
                let collection = try await syncService.getCatalogs()
                
                for c in collection{
                    modelContext.insert(c)
                }
                
                try? modelContext.save()
            }
            catch{
                print(error)
            }
        } 
    }
     
    /// Create a predicate based on search scope and text - now using shared utility
    func getSearchPredicate(scope: InvoiceSearchScope, searchText: String, companyId: String) -> Predicate<Invoice> {
        return InvoiceSearchUtils.getSearchPredicate(scope: scope, searchText: searchText, companyId: companyId)
    }
    
    private func getSearchPredicateWithMultipleKeywords(scope: InvoiceSearchScope, key1: String, key2: String, companyId: String) -> Predicate<Invoice> {
        return InvoiceSearchUtils.getSearchPredicateWithMultipleKeywords(scope: scope, key1: key1, key2: key2, companyId: companyId)
    }
}

