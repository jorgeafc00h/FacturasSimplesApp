import SwiftUI
import SwiftData

struct ProductsListView: View {
    @Environment(\.modelContext) var modelContext
    
    @Binding var selection: Product?
    
    @Query(sort: \Product.productName)
    var products: [Product]
    
    @State var viewModel = ProductListViewModel()
    
    @State var searchText : String = ""
    @State var searchScope: ProductSearchScope = .Editable
    
    @AppStorage("selectedCompanyIdentifier")  var companyIdentifier : String = ""
    
    init(selection: Binding<Product?>, selectedCompanyId: String) {
        
        _selection = selection
         
        let companyId = selectedCompanyId.isEmpty ? companyIdentifier : companyIdentifier
        
        let predicate =
           // searchScope == .Editable ?
            #Predicate<Product> {
            searchText.isEmpty ?
            $0.companyId == companyId:
            $0.productName.localizedStandardContains(searchText) &&
            $0.companyId == companyId //&&
            //$0.invoiceDetails.count == 0
            }
//            :
//            #Predicate<Product> {
//            searchText.isEmpty ?
//            true:
//            $0.productName.localizedStandardContains(searchText) //&&
//            $0.companyId == companyId //&&
//            //$0.invoiceDetails.count > 0
//            }
         
        
        _products = Query(filter: predicate, sort: \Product.productName)
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(products){ product in
                ProductListItemView(product: product)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            selection = product
                            viewModel.showConfirmDeleteProduct.toggle()
                        }label:{
                            VStack{
                                Text("Eliminar")
                                Image(systemName: "trash")
                            }
                        }
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
        .searchable(text: $searchText, placement: .sidebar)
        .searchScopes($searchScope){
            Text("Editable").tag(ProductSearchScope.Editable)
            Text("No Editable").tag(ProductSearchScope.NonEditable)
        }
    }
    
    private var ConfirmDeleteButton: some View {
       
        VStack{
            Button("Eliminar", role: .destructive) {
                if let pr = selection {
                    deleteProduct(pr)
                }
            }
            Button("Cancelar", role: .cancel) {
                viewModel.offsets.removeAll()
                 
            }
        }
    }
}
