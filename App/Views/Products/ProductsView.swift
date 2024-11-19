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
                    Label("No Product Selected", systemImage: "box.fill")
                } description: {
                    Text("Select a product from the list to view its details")
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar)
    }
}

#Preview (traits: .sampleProducts) {
    ProductsView()
}
