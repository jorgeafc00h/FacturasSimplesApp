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
     
    /// Create a predicate based on search scope and text
    func getSearchPredicate(scope: InvoiceSearchScope, searchText: String, companyId: String) -> Predicate<Invoice> {
        if searchText.isEmpty {
            switch scope {
            case .factura:
                
                let  _type = Extensions.documentTypeFromInvoiceType( InvoiceType.Factura)
                
                return #Predicate<Invoice> {
                    $0.customer.companyOwnerId == companyId &&
                    $0.documentType == _type
                }
            case .ccf:
                let  _type = Extensions.documentTypeFromInvoiceType( InvoiceType.CCF)
                
                return #Predicate<Invoice> {
                    $0.customer.companyOwnerId == companyId &&
                    $0.documentType == _type
                }
            default :
                return #Predicate<Invoice> {
                    $0.customer.companyOwnerId == companyId
                }
            }
        }
        
        switch scope {
        case .nombre:
            return #Predicate<Invoice> {
                ($0.customer.firstName.localizedStandardContains(searchText) ||
                 $0.customer.lastName.localizedStandardContains(searchText)) &&
                $0.customer.companyOwnerId == companyId
            }
        case .nit:
            return #Predicate<Invoice> {
                $0.customer.nit.localizedStandardContains(searchText) &&
                $0.customer.companyOwnerId == companyId
            }
        case .dui:
            return #Predicate<Invoice> {
                $0.customer.nationalId.localizedStandardContains(searchText) &&
                $0.customer.companyOwnerId == companyId
            }
        case .nrc:
            return #Predicate<Invoice> {
                //($0.customer.nrc != nil &&
                $0.customer.nrc.localizedStandardContains(searchText) &&
                $0.customer.companyOwnerId == companyId
            }
            
        case .factura:
            
            let  _type = Extensions.documentTypeFromInvoiceType( InvoiceType.Factura)
            
            return #Predicate<Invoice> {
                $0.documentType == _type &&
                $0.customer.companyOwnerId == companyId &&
                $0.customer.firstName.localizedStandardContains(searchText)
            }
        
        case .ccf:
        
            let  _type = Extensions.documentTypeFromInvoiceType( InvoiceType.CCF)
        
        return #Predicate<Invoice> {
            //$0.controlNumber != nil &&  $0.controlNumber!.contains(searchText) ||
            $0.documentType == _type &&
            $0.customer.companyOwnerId == companyId &&
            $0.customer.firstName.localizedStandardContains(searchText)
        }
      }
    }

}

