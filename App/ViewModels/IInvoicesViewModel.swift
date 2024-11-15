import Foundation
import SwiftData
import SwiftUI

extension InvoicesView{
    
    @Observable
    class InvoicesViewModel{
        
         
        
        
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
}

extension AddInvoiceView {
    
    @Observable
    class AddInvoiceViewModel{
        var customer: Customer?
        var displayPickerSheet: Bool = false
        var displayProductPickerSheet: Bool = false
        var invoiceNumber : String = ""
        var date: Date = Date()
        var invoiceType : InvoiceType = .Factura
        
        
        var details:[InvoiceDetail] = []
        var invoiceTypes :[InvoiceType] = [.Factura,.CCF]
        var invoiceStatuses :[InvoiceStatus] = [.Nueva,.Completada,.Cancelada]
        
       
       
        var disableAddInvoice : Bool {
            return invoiceNumber.isEmpty || details.isEmpty || customer == nil
        }
        
        
       
    }
    
    func addInvoice()
    {
        withAnimation{
            let invoice = Invoice(invoiceNumber: viewModel.invoiceNumber,
                                  date: viewModel.date,
                                  status: .Nueva,
                                  customer: viewModel.customer!,
                                  invoiceType: viewModel.invoiceType)
            invoice.items = viewModel.details
            
            modelContext.insert(invoice)
        }
    }
    func deleteDetail(detail:InvoiceDetail){
        withAnimation{
            let index = viewModel.details.firstIndex(of: detail)
            
            viewModel.details.remove(at: index!)
        }
    }
    func deleteProduct(at offsets: IndexSet) {
        viewModel.details.remove(atOffsets: offsets)
    }
}

extension InvoiceEditView {
    
    @Observable
    class InvoiceEditViewModel{
        
        var showingProductPicker = false
        var invoiceTypes :[InvoiceType] = [.Factura,.CCF]
        var invoiceStatuses :[InvoiceStatus] = [.Nueva,.Completada,.Cancelada]
        
        
        // 1. Formatter for our value to show as currency
         var currencyFormater: NumberFormatter = {
             var formatter = NumberFormatter()
             
             formatter.numberStyle = .currency
             formatter.currencySymbol = "$"
             
             return formatter
         }()
        
    }
}



