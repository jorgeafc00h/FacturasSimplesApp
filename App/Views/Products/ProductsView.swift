//
//  ProductsView.swift
//  App
//
//  Created by Jorge Flores on 11/6/24.
//

import SwiftUI
import SwiftData

struct ProductsView: View {
    @State private var selection: Product?
    @State private var searchText: String = ""
    
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationSplitView {
            ProductsListView(selection: $selection,
                           searchText: searchText)
        } detail: {
            if let product = selection {
                ProductDetailView(product: product)
            }
        }
        .searchable(text: $searchText, placement: .sidebar)
    }
}

#Preview {
    ProductsView()
}
