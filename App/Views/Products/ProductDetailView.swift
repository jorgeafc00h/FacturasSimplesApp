import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Bindable var product: Product
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section("Producto") {
                TextField("Nombre", text: $product.productName)
//                TextField("Descripcion", text: $product.productDescription!, axis: .vertical)
//                    .lineLimit(3...6)
//                
                HStack {
                    Text("Precio")
                    Spacer()
                    TextField("Precio", value: $product.unitPrice, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
            }
            
            Section {
                Button("Eliminar Producto", role: .destructive) {
                    deleteProduct()
                }
            }
        }
        .navigationTitle(product.productName.isEmpty ? "Nuevo Producto" : product.productName)
    }
    
    private func deleteProduct() {
        modelContext.delete(product)
    }
} 
