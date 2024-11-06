//
//  ProductDetailItemView.swift
//  App
//
//  Created by Jorge Flores on 11/5/24.
//

import SwiftUI
import SwiftData

struct ProductDetailItemView: View {
    
    var detail: InvoiceDetail
    
    var body: some View {
        HStack {
            Circle()
                .fill(.darkCyan)
                .frame(width: 10, height: 10)
                .padding(.trailing,7)
            
            VStack(alignment: .leading) {
                
                HStack{
                    Text(detail.product.productName)
                        .font(.headline)
                    Spacer()
                    Text(detail.productTotal.formatted(.currency(code: "USD")))
                }
//                Text(detail.quantity)
//                    .font(.subheadline)
                
                if case let (id?, p?) = (detail.quantity, detail.product.unitPrice) {
                     
                    HStack {
                        Text( "cantidad: \(id)")
                        Image(systemName: "arrow.right")
                        Spacer()
                        Text("Precio Unitario: \(p.formatted(.currency(code: "USD")))")
                    }
                    .font(.caption)
                }
            }
        }
    }
}


#Preview(traits: .sampleInvoices) {
    @Previewable @Query var invs: [Invoice]
    List {
        ProductDetailItemView(detail: invs.first!.items.first!)
    }
}
