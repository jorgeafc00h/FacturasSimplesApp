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
    var products: [Product]
    
    @AppStorage("selectedCompanyIdentifier")  var companyIdentifier : String = ""
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            products
        } else {
            products.filter{searchText.isEmpty ?
                $0.companyId == companyIdentifier:
                $0.productName.localizedStandardContains(searchText) &&
                $0.companyId == companyIdentifier
            }
        }
    }
    
    init(details: Binding<[InvoiceDetail]>) {
        _details = details
        let predicate = #Predicate<Product> {
            searchText.isEmpty ?
            $0.companyId == companyIdentifier :
            $0.productName.localizedStandardContains(searchText) &&
            $0.companyId == companyIdentifier
        }
        _products = Query(filter: predicate, sort: \Product.productName)
    }
    
    var body: some View {
        NavigationStack {
            ProductFromCatalogPicker
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
            }.accentColor(.darkCyan)
        }
        
        
        
    }
    
    private func AddSelectedProduct(){
        withAnimation{
            if let selectedProduct = selection{
                let detail = InvoiceDetail(quantity: 1, product: selectedProduct)
                details.append(detail)
                dismiss()
            }
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
            Text(product.unitPrice.formatted(.currency(code:"USD")))
        }
        
    }
}

#Preview(traits: .sampleProducts) {
    @Previewable @Query var products: [Product]
    
    List {
        ProductPickerItem(product: products.first!)
    }
}
