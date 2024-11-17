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
        var showAddProductSection = false
        var invoiceNumber : String = ""
        var date: Date = Date()
        var invoiceType : InvoiceType = .Factura
        
        
        var details:[InvoiceDetail] = []
        var invoiceTypes :[InvoiceType] = [.Factura,.CCF]
        var invoiceStatuses :[InvoiceStatus] = [.Nueva,.Completada,.Cancelada]
        
        var productName :String = ""
        var unitPrice :Decimal = 0.0
       
        var disableAddInvoice : Bool {
            return invoiceNumber.isEmpty || details.isEmpty || customer == nil
        }
        
        var canSaveNewProduct: Bool {
            return productName.isEmpty && unitPrice.isZero
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
        withAnimation{
            viewModel.details.remove(atOffsets: offsets)
        }
    }
    func SearchProduct(){
        withAnimation(.bouncy(duration: 4)) {
            viewModel.displayProductPickerSheet=true;
        }
    }
    func ShowAddProductSection(){
        withAnimation(.easeInOut(duration: 4)) {
            viewModel.showAddProductSection.toggle()
        }
    }
    func AddNewProduct(){
        withAnimation(.easeInOut(duration: 4)) {
            let product = Product(productName: viewModel.productName, unitPrice: viewModel.unitPrice)
            viewModel.productName="";
            viewModel.unitPrice=0.0;
            let detail = InvoiceDetail(quantity: 1, product: product)
            viewModel.details.append(detail)
            viewModel.showAddProductSection.toggle()
        }
    }
}

extension InvoiceEditView {
    
    @Observable
    class InvoiceEditViewModel{
        
        var showingProductPicker = false
        var showAddProductSection = false
        var invoiceTypes :[InvoiceType] = [.Factura,.CCF]
        var invoiceStatuses :[InvoiceStatus] = [.Nueva,.Completada,.Cancelada]
        
        var productName :String = ""
        var unitPrice :Decimal = 0.0
        // 1. Formatter for our value to show as currency
         var currencyFormater: NumberFormatter = {
             var formatter = NumberFormatter()
             
             formatter.numberStyle = .currency
             formatter.currencySymbol = "$"
             
             return formatter
         }()
        
        var canSaveNewProduct: Bool {
            return productName.isEmpty && unitPrice.isZero
        }
    }
    
    func SearchProduct(){
        withAnimation(.easeInOut(duration: 2.5)) {
            viewModel.showingProductPicker=true;
        }
    }
    func ShowAddProductSection(){
        withAnimation(.easeInOut(duration:2.5)) {
            viewModel.showAddProductSection.toggle()
        }
    }
    
    func AddNewProduct(){
        let product = Product(productName: viewModel.productName, unitPrice: viewModel.unitPrice)
        viewModel.productName="";
        viewModel.unitPrice=0.0;
        let detail = InvoiceDetail(quantity: 1, product: product)
        invoice.items.append(detail)
        viewModel.showAddProductSection.toggle()
    }
}



