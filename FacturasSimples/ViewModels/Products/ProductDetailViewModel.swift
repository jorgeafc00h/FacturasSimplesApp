import SwiftUI
import SwiftData

extension ProductDetailView {
    
    @Observable
    class ProductDetailViewModel{
        var usageCount: Int = 0
        var isDisbledDeleteProduct: Bool = false
        var isDisbleEditProduct: Bool = false
        
        var completedInvoiceCount: Int = 0
    }
    
    func refreshProductUsage() {
        
        let productId = product.productId
        
        let descriptor = FetchDescriptor<InvoiceDetail>(predicate: #Predicate { $0.product?.productId ==  productId })
        
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        viewModel.usageCount = count
        
        viewModel.isDisbledDeleteProduct = count > 0
        
        
        let completedInvocesDescriptor = FetchDescriptor<InvoiceDetail>(predicate: #Predicate{
            $0.product?.productId == productId
            && $0.invoice != nil
            && $0.invoice!.generationCode != ""
            && $0.invoice!.receptionSeal != ""
            && $0.invoice!.receptionSeal != ""
            //&& $0.invoice!.status == .completada
        })
        let completedCount = (try? modelContext.fetchCount(completedInvocesDescriptor)) ?? 0
        
        viewModel.completedInvoiceCount = completedCount
        viewModel.isDisbleEditProduct = completedCount > 0
        
    }
    

}
