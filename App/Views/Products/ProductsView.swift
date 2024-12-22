//
//  ProductsView.swift
//  App
//
//  Created by Jorge Flores on 11/6/24.
//

import SwiftUI
import SwiftData

struct ProductsView: View {
    @State var selection: Product? 
    @Binding var selectedCompanyId: String
    
    var body: some View {
        NavigationSplitView {
            ProductsListView(selection: $selection,
                             selectedCompanyId: selectedCompanyId)
        } detail: {
            if let pr = selection {
                ProductDetailView(product: pr)
            } else {
                ContentUnavailableView {
                    Label("No hay producto Seleccionado", systemImage: "list.bullet.rectangle.fill")
                } description: {
                    Text("Seleccione un producto para ver los detalles")
                }
            }
        }
       
    }
}


#Preview (traits: .sampleProducts){
    ProductsViewWrapper()
}

private struct ProductsViewWrapper: View {
    @State private var selectedCompanyId: String = ""
    
    var body: some View {
        ProductsView( selectedCompanyId: $selectedCompanyId)
    }
}
