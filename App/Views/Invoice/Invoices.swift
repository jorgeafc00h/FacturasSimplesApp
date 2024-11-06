//
//  Invoices.swift
//  App
//
//  Created by Jorge Flores on 10/21/24.
//

import SwiftUI
import SwiftData
//struct Invoices: View {
//    var body: some View {
//        ZStack {
//            
//            Color("Marine").ignoresSafeArea().navigationBarHidden(true)
//                .navigationBarBackButtonHidden(true)
//            VStack{
//                SearchBar().padding(.horizontal,20)
//                List {
//                    ForEach((1...10), id: \.self) { _ in
//                        let inv = Invoice()
//
//                        .previewLayout(.sizeThatFits)
//                    }.listRowBackground(Color(.marine))
//                }
//                .background(Color.clear)
//                .scrollContentBackground(.hidden)
//
//                
//            }
//        }.navigationBarHidden(true)
//    }
//}
struct InvoiceCardView: View {
    // Sample data for an invoice
    var invoice : Invoice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("#\(invoice.invoiceNumber)")
                    .font(.headline)
                    .fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Text("\(invoice.status)")
                    .font(.subheadline)
                    .foregroundColor(invoice.statusColor)
                    .padding(7)
                    .background(invoice.statusColor.opacity(0.1))
                    .cornerRadius(8)
            }
          
            Text("\(invoice.customer.fullName)")
                .font(.headline).foregroundColor(.white)
        
            
            Text(invoice.date, style: .date)
                .font(.subheadline)
                .foregroundColor(.gray)
            
 
            HStack {
                Text("$: \(invoice.totalAmount)")
                    .font(.subheadline)
                    .foregroundColor(.darkCyan)
                Spacer()
                Text("Productos: \(invoice.totalItems)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .background(Color.clear)
        .padding(.horizontal,5)
        .padding(.vertical, 7)
            .background(.darkBlue)
        .cornerRadius(10)
        .shadow(color:.darkCyan, radius: 2)
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            return 0
        }
        
        
    }
    
}
 
 

#Preview(traits: .sampleInvoices) {
    @Previewable @Query var invs: [Invoice]
    List {
        InvoiceCardView(invoice: invs.first!)
    }
}
