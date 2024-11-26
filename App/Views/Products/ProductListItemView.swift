import SwiftUI

struct ProductListItemView: View {
    let product: Product
    
    var body: some View {
        NavigationLink(value: product) {
            VStack(alignment: .leading) {
                Text(product.productName)
                    .font(.headline)
                Text(product.unitPrice.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
} 
