import SwiftUI
import SwiftData

extension ProductDetailView {
    
    @Observable
    class ProductDetailViewModel{
        var usageCount: Int = 0
        var isDisbledDeleteProduct: Bool = false
    }
    
    func refreshProductUsage() {
        
        let productId = product.productId
        
        let descriptor = FetchDescriptor<InvoiceDetail>(predicate: #Predicate { $0.product.productId ==  productId })
        
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        viewModel.usageCount = count
        
        viewModel.isDisbledDeleteProduct = count > 0
    }
}
