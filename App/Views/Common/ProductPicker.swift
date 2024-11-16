//
//  ProductPicker.swift
//  App
//
//  Created by Jorge Flores on 11/5/24.
//

import SwiftData
import SwiftUI

struct ProductPicker: View {
    @Binding var details: [InvoiceDetail]
    
    @State private var isShowingAddNewProduct: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selection: Product?
    
    @State private var searchText: String = ""
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \Product.productName)
    var products: [Product] = []
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            products
        } else {
            products.filter{searchText.isEmpty ? true :
                $0.productName.contains(searchText)
            }
        }
    }
    
    init(details: Binding<[InvoiceDetail]>) {
        _details = details
        let predicate = #Predicate<Product> {
            searchText.isEmpty ? true : $0.productName.contains(searchText)
        }
        _products = Query(filter: predicate, sort: \Product.productName)
    }
    
    var body: some View {
        NavigationView {
            
            if isShowingAddNewProduct{
                NewProductFormView(details:$details)
            }
            else {
                ProductFromCatalogPicker
            }
            
        }.presentationDetents([.medium, .large])
    }
    
    private var ProductFromCatalogPicker: some View {
        
        withAnimation {
            List {
                ForEach(filteredProducts) { product in
                    ProductPickerItem(product: product)
                        .onTapGesture {
                            withAnimation {
                                selection = product
                                searchText = ""
                                AddSelectedProduct()
                                dismiss()
                            }
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Buscar")
            .frame(
                idealWidth: LayoutConstants.sheetIdealWidth,
                idealHeight: LayoutConstants.sheetIdealHeight
            )
            .navigationTitle("Productos")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Spacer()
                    Button("Nuevo Producto",systemImage: "plus"){isShowingAddNewProduct=true}
                        .buttonStyle(BorderlessButtonStyle())
                }
            }.accentColor(.darkCyan)
        }
        
        
        
    }
    
    private func AddSelectedProduct(){
        
        if let selectedProduct = selection{
            let detail = InvoiceDetail(quantity: 1, product: selectedProduct)
            
            details.append(detail)
            dismiss()
        }
    }
    
    
}

 struct NewProductFormView: View {
    
    @State private var productName: String = ""
    @State private var unitPrice: Decimal = 0.0
    @State private var quantity: Int = 1
    
    @Binding var details: [InvoiceDetail]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    init(details: Binding<[InvoiceDetail]>){
        
        _details = details
    }
    
    var body: some View{
        withAnimation{
            VStack{
                Form{
                    Group{
                        TextField("Producto", text: $productName)
                        TextField("Precio Unitario", value: $unitPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        
                    }
                }
                Button(action: addNewProduct) {
                    Text("Guardar")
                        .fontWeight(.bold)
                        .foregroundColor(.darkBlue)
                        .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.darkCyan), lineWidth: 2).shadow(color: .white, radius: 6))
                }.padding(.bottom)
            }
            .frame(
                idealWidth: LayoutConstants.sheetIdealWidth,
                idealHeight: LayoutConstants.sheetIdealHeight
            )
            .navigationTitle("Nuevo Producto")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Spacer()
                    Button("Guardar",systemImage: "checkmark.circle",action: addNewProduct)
                        .buttonStyle(BorderlessButtonStyle())
                }
            }.accentColor(.darkCyan)
        }
    }
    
    func addNewProduct(){
        withAnimation{
            let product = Product(productName: productName, unitPrice: unitPrice)
            
            modelContext.insert(product)
            
            let detail = InvoiceDetail(quantity: 1, product: product)
            
            details.append(detail)
            dismiss()
        }
    }
}


private struct ProductPickerItem: View {
    
    @State var product: Product
    
    var body: some View {
        HStack {
            Circle()
                .fill(.darkCyan)
                .frame(width: 7, height: 7)
            
            Text(product.productName)
            Spacer()
            Text("$\(product.unitPrice)")
        }
        
    }
}

#Preview(traits: .sampleProducts) {
    @Previewable @Query var products: [Product]
    
    List {
        ProductPickerItem(product: products.first!)
    }
}
