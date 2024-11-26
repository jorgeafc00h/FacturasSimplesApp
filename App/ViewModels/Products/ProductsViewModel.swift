import Foundation
import SwiftUI
import SwiftData

extension ProductsListView {
    
    
    @Observable
    class ProductListViewModel{
        var isShowingAddProductSheet: Bool = false
        
        var productCount: Int = 0
        var productName: String = ""
        var unitPrice: Decimal = 0
        var productDescription: String = ""
        
        
        var showConfirmDeleteProduct: Bool = false
        var offsets: IndexSet = []
        
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }
    
    func createNewProduct() {
        let newProduct = Product(productName: "", unitPrice: 0,productDescription: "")
        modelContext.insert(newProduct)
        selection = newProduct
    }
    
    func deleteProduct(_ product: Product) {
        
        let id = product.persistentModelID
        
        let descriptor = FetchDescriptor<InvoiceDetail>(predicate: #Predicate { $0.product.persistentModelID ==  id })
        
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        if count > 0 {
            viewModel.alertTitle = "Error"
            viewModel.alertMessage = "No se puede eliminar \(product.productName) producto con \(count) facturas asociadas"
            viewModel.showAlert = true
            return
        }
        withAnimation{
            modelContext.delete(product)
        }
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
