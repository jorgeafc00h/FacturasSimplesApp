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
                        .contentTransition(.numericText(value: Double( 233  )))
                    
                }.font(.headline)
                HStack{
                    
                }
            HStack{
                Text(detail.product.unitPrice.formatted(.currency(code: "USD")))
                    //.contentTransition(.numericText(value: Double( 0.00  )))
                    .contentTransition(.numericText(countsDown: true))
                    .contentTransition(.numericText(value: Double(truncating: detail.product.unitPrice as NSNumber)))
                    .font(.footnote)
                Spacer()
                Text("\(detail.quantity)")
                
                    .contentTransition(.numericText(value: Double(truncating: detail.quantity as NSNumber )))
                    .padding()
                    .font(.footnote)
                }
            }
            
        }
        //.listRowBackground(Color.clear)
        .buttonStyle(BorderlessButtonStyle())
    }
}


struct ProductDetailEditView: View {
    
    @Binding var item: InvoiceDetail
    
    var body: some View {
        VStack{
            HStack {
                Text(item.product.productName)
                Spacer()
                Stepper("", value: $item.quantity, in: 1...100)
            }
            HStack{
                Text(item.productTotal.formatted(.currency(code: "USD")))
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.productTotal)
                    .padding()
                    .font(.footnote)
                Spacer()
                Text("x :\(item.quantity)")
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.quantity)
                    .padding()
                    .padding()
                    .font(.footnote)
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
 

