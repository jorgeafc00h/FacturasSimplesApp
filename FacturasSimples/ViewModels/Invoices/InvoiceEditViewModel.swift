import Foundation
import SwiftData
import SwiftUI


extension InvoiceEditView {
    
    @Observable
    class InvoiceEditViewModel{
        
        var showingProductPicker = false
        var showAddProductSection = false
        var invoiceTypes :[InvoiceType] = [.Factura,.CCF]
        var invoiceStatuses :[InvoiceStatus] = [.Nueva,.Completada,.Anulada]
        
        var productName :String = ""
        var unitPrice :Decimal = 0.0
        var newProductHasTax: Bool = true
        
        // 1. Formatter for our value to show as currency
         var currencyFormater: NumberFormatter = {
             var formatter = NumberFormatter()
             
             formatter.numberStyle = .currency
             formatter.currencySymbol = "$"
             
             return formatter
         }()
        
        var isDisabledAddProduct: Bool {
            return productName.isEmpty && unitPrice.isZero
        }
        
        private var tax: Decimal {
            return (unitPrice - (unitPrice / Constants.includedTax)).rounded()
        }
        
        var productPlusTax: Decimal {
            return  ((unitPrice * Constants.includedTax) - unitPrice ).rounded()
        }
        
        var productTax: Decimal {
            return newProductHasTax ? tax:  productPlusTax
        }
        
        var productWithoutTax: Decimal {
            return unitPrice - productTax
        }
        var productUnitPricePlusTax: Decimal {
            return unitPrice + productPlusTax
        }
        var total : Decimal = 0.0
        
        var showErrorAlert: Bool = false
        var errorMessage: String = ""
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
        
        let _price = viewModel.newProductHasTax ? viewModel.unitPrice : viewModel.productUnitPricePlusTax
        
        let product = Product(productName: viewModel.productName, unitPrice: _price)
         
        viewModel.productName="";
        viewModel.unitPrice=0.0;
        let detail = InvoiceDetail(quantity: 1, product: product)
        invoice.items.append(detail)
        viewModel.showAddProductSection.toggle()
    }
    
    func saveInvoice() {
        do {
            
            invoice.items = invoice.items.map { detail -> InvoiceDetail in
                
                if(detail.product.companyId.isEmpty){
                    detail.product.companyId = companyIdentifier
                }
                
                return detail
            }
            
            invoice.documentType  = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
            
            if invoice.totalAmount >  viewModel.total, disableIfInvoiceTypeIsNotAvailableInOptions()  {
                viewModel.showErrorAlert = true
                let errorMessage = invoice.relatedInvoiceType == .Factura ?
                "El Total no puede ser mayor al total de la factura" :
                "El Total no puede ser mayor al total del crédito fiscal"
                viewModel.errorMessage  =  errorMessage
                return
            }
            
             
            try modelContext.save()
            dismiss()
            
        } catch {
            print("Error saving invoice: \(error)")
        }
    }
    func deleteProduct(at offsets: IndexSet) {
        invoice.items.remove(atOffsets: offsets)
    }
    
    func disableIfInvoiceTypeIsNotAvailableInOptions() -> Bool{
        return !viewModel.invoiceTypes.contains(where: { $0.rawValue == invoice.invoiceType.id })
    }
    
    func setDefaultsForCreditNote(){
        
        let isRequiredtrack = disableIfInvoiceTypeIsNotAvailableInOptions()
        
        if isRequiredtrack {
            viewModel.total = invoice.totalAmount
        }
    }
}
