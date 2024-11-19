import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Bindable var product: Product
    @Environment(\.modelContext)  var modelContext
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack{
            List{
                VStack(alignment: .leading) {
                    Text("Descripcion")
                        .font(.headline)
                    Text(product.productDescription)
                        .font(.subheadline)
                    
                    HStack {
                        Text("Precio")
                        Spacer()
                        Text(product.unitPrice.formatted(.currency(code: "USD")))
                            .font(.footnote)
                    }
                    
                    NavigationLink {
                        EditProductView(product: product)
                    } label: {
                        HStack{
                            Image(systemName: "pencil.line")
                                .symbolEffect(.breathe, options: .nonRepeating)
                            Text("Editar Producto")
                        }.foregroundColor(.darkCyan)
                    }
                }
                
                Section {
                    Button("Eliminar Producto", role: .destructive) {
                        deleteProduct()
                        dismiss()
                        
                    }.disabled(product.invoiceDetails.count > 0)
                }
            }
            .navigationTitle(product.productName.isEmpty ? "Nuevo Producto" : product.productName)
        }
    }
    
} 
#Preview(traits: .sampleProducts) {
    @Previewable @Query var products: [Product]
    ProductDetailView(product: products.first!)
}
