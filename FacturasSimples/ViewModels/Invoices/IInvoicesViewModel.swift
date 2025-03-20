import Foundation
import SwiftData
import SwiftUI

extension InvoicesView{
    
    @Observable
    class InvoicesViewModel{
        var showAddInvoiceSheet: Bool = false
        var showAddCustomerSheet: Bool = false
        
        var showAddTestInvoices: Bool = false
         
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
        var newProductHasTax: Bool = true
       
        var disableAddInvoice : Bool {
            return invoiceNumber.isEmpty || details.isEmpty || customer == nil
        }
        
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
        
            if invoice.documentType.isEmpty{
                invoice.documentType = Extensions.documentTypeFromInvoiceType(viewModel.invoiceType)
            }
            
            
            modelContext.insert(invoice)
            try? modelContext.save()
            
            selectedInvoice = invoice
            dismiss()
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
        withAnimation(.bouncy(duration: 2.3)) {
            viewModel.displayProductPickerSheet=true;
        }
    }
    func ShowAddProductSection(){
        withAnimation(.easeInOut(duration: 2.34)) {
            viewModel.showAddProductSection.toggle()
        }
    }
    func AddNewProduct(){
        withAnimation(.easeInOut(duration: 2.34)) {
            
            let _price = viewModel.newProductHasTax ? viewModel.unitPrice : viewModel.productUnitPricePlusTax
            
            let product = Product(productName: viewModel.productName, unitPrice: _price)
            product.companyId = companyIdentifier
            viewModel.productName="";
            viewModel.unitPrice=0.0;
            let detail = InvoiceDetail(quantity: 1, product: product)
            viewModel.details.append(detail)
            viewModel.showAddProductSection.toggle()
        }
    }
    func getNextInoviceNumber(){
        
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate<Invoice>{
                $0.customer.companyOwnerId == companyIdentifier
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let latestInvoice = try? modelContext.fetch(descriptor).first {
            if let currentNumber = Int(latestInvoice.invoiceNumber) {
                viewModel.invoiceNumber = String(format: "%05d", currentNumber + 1)
            } else {
                viewModel.invoiceNumber = "00001"
            }
        } else {
            viewModel.invoiceNumber = "00001"
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
            
            if invoice.documentType.isEmpty{
                invoice.documentType = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
            }
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



