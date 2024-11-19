import SwiftUI
import SwiftData

struct ProductsListView: View {
    @Binding var selection: Product?
    var searchText: String
    
    @Environment(\.modelContext) var modelContext
    
    @Query private var products: [Product]
    
    init(selection: Binding<Product?>, searchText: String) {
        _selection = selection
        self.searchText = searchText
        
        let predicate = #Predicate<Product> { product in
            if searchText.isEmpty {
                return true
            } else {
                return product.productName.localizedStandardContains(searchText)
            }
        }
        
        _products = Query(filter: predicate, sort: \Product.productName)
    }
    
    var body: some View {
        List(products, selection: $selection) { product in
            ProductListItemView(product: product)
        }
        .navigationTitle("Productos")
        .overlay{
            if products.isEmpty {
                ContentUnavailableView {
                    Label("Productos", systemImage: "list.bullet.rectangle.portrait")
                }description: {
                    Text("Los Productos pueden ser vinculados a una o muchas facturas.")
                }actions: {
                    Button(action: createNewProduct) {
                        Label("Crear Producto", systemImage: "plus")
                    }
                }
                .offset(y: -60)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: createNewProduct) {
                    Label("Crear Producto", systemImage: "plus")
                }
            }
        }
    }
    
    private func createNewProduct() {
        let newProduct = Product(productName: "", unitPrice: 0,productDescription: "")
        modelContext.insert(newProduct)
        selection = newProduct
    }
} 
