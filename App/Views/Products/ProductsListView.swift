import SwiftUI
import SwiftData

struct ProductsListView: View {
    @Environment(\.modelContext) var modelContext
    
    @Binding var selection: Product?
    
    @Query(sort: \Product.productName)
    var products: [Product]
    
    @State var viewModel = ProductListViewModel()
    
    init(selection: Binding<Product?>, searchText: String, scope: ProductSearchScope) {
        _selection = selection
         
        let predicate = #Predicate<Product> {
            searchText.isEmpty ? true :
            $0.productName.localizedStandardContains(searchText)
        }
//        
//        let predicate = #Predicate<Product> {
//            searchText.isEmpty ? true :
//             
//            scope == .Editable ?
//            $0.productName.localizedStandardContains(searchText) && $0.invoiceDetails.count == 0:
//            $0.productName.localizedStandardContains(searchText) && $0.invoiceDetails.count > 0
//                
//            
//        }
        
        _products = Query(filter: predicate, sort: \Product.productName)
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(products){ product in
                ProductListItemView(product: product)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.toDeleteProduct = product
                            viewModel.showConfirmDeleteProduct.toggle()
                        }label:{
                            VStack{
                                Text("Eliminar")
                                Image(systemName: "trash")
                            }
                            
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
                AddProductView()
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "¿Está seguro que desea eliminar este producto?",
            isPresented: $viewModel.showConfirmDeleteProduct,
            titleVisibility: .visible
        ){
            ConfirmDeleteButton
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("Ok!")))
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
    
    private var ConfirmDeleteButton: some View {
       
        VStack{
            Button("Eliminar", role: .destructive) {
                if let pr = viewModel.toDeleteProduct {
                    deleteProduct(pr)
                }
            }
            Button("Cancelar", role: .cancel) {
                viewModel.offsets.removeAll()
                 
            }
        }
    }
}
