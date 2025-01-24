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
     
//    func fetchInvoices(){
//        let predicate = #Predicate<Invoice> {
//            searchText.isEmpty ?
//            $0.customer.companyOwnerId == selectedCompanyId:
//            $0.invoiceNumber.localizedStandardContains(searchText) ||
//            $0.customer.firstName.localizedStandardContains(searchText) ||
//            $0.customer.lastName.localizedStandardContains(searchText) ||
//            $0.customer.email.localizedStandardContains(searchText) &&
//            $0.customer.companyOwnerId == selectedCompanyId
//        }
//        
//        let sortDescriptor =  SortDescriptor(\Invoice.invoiceNumber,order: .reverse)
//        
//        let descriptor = FetchDescriptor<Invoice>(predicate: predicate, sortBy: [sortDescriptor])
//        
//        let _customers = try? modelContext.fetch(descriptor)
//        
//        if let collection = _customers{
//            viewModel.invoices = collection
//            viewModel.invocesCount = collection.count
//        }
//    }

}

