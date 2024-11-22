
import SwiftUI
import SwiftData

struct AddProductView: View {
    
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext 
    
    @State var viewModel = AddProductViewModel()
    
    var body: some View {
        Form {
            Section("Producto") {
                TextField("Nombre", text: $viewModel.productName)
                TextField("Descripcion", text: $viewModel.productDescription, axis: .vertical)
                    .lineLimit(3...6)
                
                HStack {
                    Text("Precio")
                    Spacer()
                    TextField("Precio", value: $viewModel.unitPrice, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
            }         }
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
                .disabled(viewModel.isSaveDisabled)
            }
        }.accentColor(.darkCyan)
            .navigationTitle(viewModel.navigationTitle)
        
    }
}

