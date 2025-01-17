import Foundation
import SwiftUI

extension AddProductView {
    
    @Observable
    class AddProductViewModel {
        var productName: String = ""
        var productDescription: String = ""
        var unitPrice: Decimal = 0
        
        var isSaveDisabled: Bool {
            productName.isEmpty || productDescription.isEmpty || unitPrice.isZero
        }
        var navigationTitle: String {
            productName.isEmpty ? "Nuevo Producto" : productName
        }
        
    }
    
    func addProduct() {
        let newProduct = Product(productName: viewModel.productName,
                                 unitPrice: viewModel.unitPrice,
                                 productDescription: viewModel.productDescription)
        
        newProduct.companyId = companyIdentifier
        modelContext.insert(newProduct)
        
        try? modelContext.save()
        
        viewModel.productName = ""
        viewModel.unitPrice = 0
        viewModel.productDescription = ""
    }
}
