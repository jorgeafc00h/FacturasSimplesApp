import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Bindable var product: Product
    @Environment(\.modelContext)  var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State var viewModel = ProductDetailViewModel()
     
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
                        
                    }.disabled(viewModel.isDisbledDeleteProduct)
                }
                Section{
                    if viewModel.usageCount > 0 {
                        
                        Label("este producto se esta usando en \(viewModel.usageCount) facturas", systemImage: "exclamationmark.triangle.fill")
                    }
                }
            }
            .navigationTitle(product.productName.isEmpty ? "Nuevo Producto" : product.productName)
        }.onAppear(perform: refreshProductUsage)
        
    }
    
    
}
#Preview(traits: .sampleProducts) {
    @Previewable @Query var products: [Product]
    ProductDetailView(product: products.first!)
}
