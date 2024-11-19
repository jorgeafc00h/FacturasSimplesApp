import Foundation
import SwiftUI

extension ProductsListView {
    
    
    @Observable
    class ProductListViewModel{
        var isShowingAddProductSheet: Bool = false
        
        var productCount: Int = 0
        var productName: String = ""
        var unitPrice: Decimal = 0
        var productDescription: String = ""
        
         
    }
    
    func createNewProduct() {
        let newProduct = Product(productName: "", unitPrice: 0,productDescription: "")
        modelContext.insert(newProduct)
        selection = newProduct
    }
    
    func deleteProduct(_ product: Product) {
        modelContext.delete(product)
    }
    
    func isDisabledDeleteProduct(_ product: Product) -> Bool {
        return product.invoiceDetails.count > 0
    }
    
    func addProduct() {
        let newProduct = Product(productName: viewModel.productName,
                                 unitPrice: viewModel.unitPrice,
                                 productDescription: viewModel.productDescription)
        modelContext.insert(newProduct)
        
        viewModel.productName = ""
        viewModel.unitPrice = 0
        viewModel.productDescription = ""
    }
    
}

extension ProductDetailView{
    
    func deleteProduct() {
        modelContext.delete(product)
    }
}
