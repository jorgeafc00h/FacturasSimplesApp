//
//  InvoiceListItem.swift
//  App
//
//  Created by Jorge Flores on 11/3/24.
//

import SwiftUI
import SwiftData


struct InvoiceListItem: View {
    var invoice : Invoice
    var body: some View {
        NavigationLink(value: invoice) {
            VStack{
                
                HStack{
                    Text("#:  \(invoice.invoiceNumber)")
                        .font(.headline)
                    Spacer()
                    Text(invoice.date, style: .date)
                }.padding(.top, 10)
                HStack {
                    Circle()
                        .fill(invoice.customer.color)
                        .frame(width: 45, height: 45)
                        .overlay {
                            Text(String(invoice.customer.initials))
                                .font(.system(size: 16))
                                .foregroundStyle(.background)
                        }
                    
                    
                    VStack(alignment: .leading) {
                        
                        HStack{
                            Text(invoice.customer.fullName)
                                .font(.headline)
                            Spacer()
                            Text("$: \(invoice.totalAmount)")
                        }.padding(.top,10)
                        Text("\(invoice.invoiceType)")
                            .font(.caption)
                        //Divider()
                        HStack {
                            Circle()
                                .fill(invoice.statusColor)
                                .frame(width: 8, height: 8)
                            Text("\(invoice.status)")
                                .font(.subheadline)
                                .foregroundColor(invoice.statusColor)
                                .padding(7)
                                .background(invoice.statusColor.opacity(0.09))
                                .cornerRadius(8)
                            Spacer()
                            Text( "Total  Productos: \(invoice.totalItems)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        
                    }
                    
                    
                }
                
            }.padding(.bottom,5)
                .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                    return -viewDimensions.width
                }
            
            
        }
    }
}

#Preview(traits: .sampleInvoices) {
    @Previewable @Query var invs: [Invoice]
    List {
        InvoiceListItem(invoice: invs.first!)
    }
}
