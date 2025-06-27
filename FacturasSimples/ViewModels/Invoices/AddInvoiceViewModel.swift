import Foundation
import SwiftData
import SwiftUI

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
        var showImplementationFee: Bool = false
        
        
        var details:[InvoiceDetail] = []
        var invoiceTypes :[InvoiceType] = [.Factura,.CCF,.SujetoExcluido]
        var invoiceStatuses :[InvoiceStatus] = [.Nueva,.Completada,.Anulada]
        
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
        
        // Computed properties don't sync to CloudKit (which is what we want)
        var totalAmount: Decimal {
            return (details).reduce(0){
                ($0 + $1.productTotal).rounded()
            }
        }
        
         
        var subTotal: Decimal {
            
           
            return (totalAmount > 0 ? totalAmount - tax : 0).rounded()
        }
        var reteRenta: Decimal{
            return (totalAmount > 0 ? totalAmount * 0.10 : 0)
        }
        var totalPagar : Decimal{
            
            if invoiceType == .SujetoExcluido{
                return (totalAmount > 0 ? totalAmount - reteRenta : 0)
            }
            
            return totalAmount
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
             
            
            // Set correct sync status based on company type (through customer)
            if let customerId = viewModel.customer?.companyOwnerId {
                let isProductionCompany = !customerId.isEmpty && 
                                        DataSyncFilterManager.shared.getProductionCompanies(context: modelContext)
                                            .contains { $0.id == customerId }
                invoice.shouldSyncToCloudKit = isProductionCompany
            } else {
                invoice.shouldSyncToCloudKit = false
            }
            
            modelContext.insert(invoice)
            try? modelContext.save()
            
            selectedInvoice = invoice
            dismiss()
        }
    }
    
    func handleCreateInvoice(storeKitManager: StoreKitManager, showCreditsGate: Binding<Bool>) {
        // Check if user has sufficient credits ONLY for production companies
        guard let selectedCompany = getSelectedCompany() else {
            // If no company found, proceed (fallback)
            addInvoice()
            return
        }
        
        // Test accounts don't need credit validation
        if selectedCompany.isTestAccount {
            addInvoice()
            return
        }
        
        // For production accounts, check if implementation fee is required
        if storeKitManager.requiresImplementationFee(for: selectedCompany) {
            // Show implementation fee purchase flow
            viewModel.showImplementationFee = true
            return
        }
        
        // Production accounts need credit validation (but don't consume yet)
        guard storeKitManager.hasAvailableCredits(for: selectedCompany) else {
            showCreditsGate.wrappedValue = true
            return
        }
        
        // Proceed with invoice creation (credit will be consumed when synced)
        addInvoice()
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
            
            // Set correct sync status based on company type
            let isProductionCompany = !companyIdentifier.isEmpty && 
                                    DataSyncFilterManager.shared.getProductionCompanies(context: modelContext)
                                        .contains { $0.id == companyIdentifier }
            product.shouldSyncToCloudKit = isProductionCompany
            
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
                $0.customer?.companyOwnerId == companyIdentifier
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
    func getNextInoviceOrCCFNumber(invoiceType:InvoiceType){
       print("Get Next Invoice number \(invoiceType) ")
       let _type =  Extensions.documentTypeFromInvoiceType(invoiceType)
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate<Invoice>{
                $0.customer?.companyOwnerId == companyIdentifier &&
                $0.documentType == _type
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let latestInvoice = try? modelContext.fetch(descriptor).first {
            if let currentNumber = Int(latestInvoice.invoiceNumber) {
                print("# \(currentNumber)")
                viewModel.invoiceNumber = String(format: "%05d", currentNumber + 1)
            } else {
                viewModel.invoiceNumber = "00001"
            }
        } else {
            viewModel.invoiceNumber = "00001"
        }
    }
    
    func getSelectedCompany() -> Company? {
        let descriptor = FetchDescriptor<Company>(
            predicate: #Predicate<Company> { company in
                company.id == companyIdentifier
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
}

