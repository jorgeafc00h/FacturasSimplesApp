
import SwiftUI
import SwiftData

struct EditProductView: View {
    
     
    @Environment(\.dismiss) private var dismiss
    
    @State var product: Product
    @Environment(\.modelContext) var modelContext

    @Binding var disableEditPrice: Bool
    
    var body: some View {
        Form {
            Section("Producto") {
                TextField("Nombre", text: $product.productName)
                TextField("Descripcion", text: $product.productDescription, axis: .vertical)
                    .lineLimit(3...6)
                
                HStack {
                    Text("Precio")
                    Spacer()
                    TextField("Precio", value: $product.unitPrice, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .disabled(disableEditPrice)
                }
            }
            
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                   
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar") {
                     
                    dismiss()
                }
                .disabled(product.productName.isEmpty || product.productDescription.isEmpty || product.unitPrice.isZero)
            }
        }.accentColor(.darkCyan)
        .navigationTitle("Editar Producto")
        
    }
}
 
#Preview(traits: .sampleProducts)  {
    @Previewable @Query var products: [Product]
    
    EditProductView(product: products.first!, disableEditPrice: .constant(false))
}
 
