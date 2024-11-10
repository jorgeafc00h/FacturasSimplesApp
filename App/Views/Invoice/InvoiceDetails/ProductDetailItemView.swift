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
            
            VStack(alignment: .leading) {
                
                HStack{
                    Text(detail.product.productName)
                    Spacer()
                    Text(detail.productTotal.formatted(.currency(code: "USD")))
                        .contentTransition(.numericText(value: Double(23456789)))
                        
                    
                }.font(.headline)
                
                
                HStack {
                    Button("", systemImage: "minus.circle"){
                        withAnimation{
                            detail.quantity -= 1
                        }
                    }.padding(.horizontal,0)
                    Text("Cantidad:\(detail.quantity)")
                        .contentTransition(.numericText(value: Double(  detail.quantity)))
                        .padding(.horizontal,0)
                        .font(.footnote)
                    Button("", systemImage: "plus.circle"){
                        withAnimation{
                            detail.quantity += 1
                        }
                        
                    }.padding(.leading,13)
                    Spacer()
                    Text("P/U: \(detail.product.unitPrice.formatted(.currency(code: "USD")))")
                        .font(.footnote)
                    
                }.padding(.top,5)
            }
            
        }
        .listRowBackground(Color.clear)
        .buttonStyle(BorderlessButtonStyle())
    }
}


#Preview(traits: .sampleInvoices) {
    @Previewable @Query var invs: [Invoice]
    List {
        ProductDetailItemView(detail: invs.first!.items.first!)
    }
}
