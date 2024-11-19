
import SwiftUI
import SwiftData

struct AddProductView: View {
    
     
    @Environment(\.dismiss) private var dismiss
    
    @Binding var productName: String
    @Binding var productDescription: String
    @Binding var unitPrice: Decimal
    
    var addProduct: () -> Void
    
    var body: some View {
        Form {
            Section("Producto") {
                TextField("Nombre", text: $productName)
                TextField("Descripcion", text: $productDescription, axis: .vertical)
                    .lineLimit(3...6)
                
                HStack {
                    Text("Precio")
                    Spacer()
                    TextField("Precio", value: $unitPrice, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
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
                    addProduct()
                    dismiss()
                }
                .disabled(productName.isEmpty || productDescription.isEmpty || unitPrice.isZero)
            }
        }.accentColor(.darkCyan)
        .navigationTitle(productName.isEmpty ? "Nuevo Producto" : productName)
        
    }
}
 
