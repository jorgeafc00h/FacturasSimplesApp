import SwiftUI
import SwiftData

struct ProductsListView: View {
    @Environment(\.modelContext) var modelContext
    
    @Binding var selection: Product?
    
    @Query(sort: \Product.productName)
    var products: [Product]
    
    @State var viewModel = ProductListViewModel()
    
    init(selection: Binding<Product?>, searchText: String) {
        _selection = selection
         
        let predicate = #Predicate<Product> {
            searchText.isEmpty ? true :
            $0.productName.localizedStandardContains(searchText)
        }
        
        _products = Query(filter: predicate, sort: \Product.productName)
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(products){ product in
                ProductListItemView(product: product)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteProduct(product)
                        }label:{
                            Label("Eliminar", systemImage: "trash")
                        }.disabled(isDisabledDeleteProduct(product))
                    }
            }
        }
        .navigationTitle("Productos")
        .overlay{
            if products.isEmpty {
                ContentUnavailableView {
                    Label("Productos", systemImage: "list.bullet.rectangle.portrait")
                }description: {
                    Text("Los Productos pueden ser vinculados a una o varias facturas.")
                }actions: {
                    Button("Agregar Producto",systemImage: "plus"){ viewModel.isShowingAddProductSheet=true}
                        .buttonStyle(BorderlessButtonStyle())
                }
                .offset(y: -60)
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddProductSheet) {
            NavigationStack {
                AddProductView(productName: $viewModel.productName,
                               productDescription: $viewModel.productDescription,
                               unitPrice: $viewModel.unitPrice,
                               addProduct: addProduct)
            }
            .presentationDetents([.medium, .large])
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
                    .disabled(viewModel.productCount==0)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Spacer()
                Button("Agregar Producto",systemImage: "plus"){ viewModel.isShowingAddProductSheet=true}
                    .buttonStyle(BorderlessButtonStyle())
            }
        }
        .onChange(of: products) {
            viewModel.productCount = products.count
        }
        .onAppear {
            viewModel.productCount = products.count
        }
    }
    
    
}
