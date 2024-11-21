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
    @State var searchText: String = ""
    
    var body: some View {
        NavigationSplitView {
            ProductsListView(selection: $selection,
                           searchText: searchText)
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
        .searchable(text: $searchText, placement: .sidebar)
    }
}

#Preview (traits: .sampleProducts) {
    ProductsView()
}
