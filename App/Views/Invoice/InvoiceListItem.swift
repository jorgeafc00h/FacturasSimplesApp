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
        
        NavigationLink(value: invoice){
            VStack{ 
                HStack{
                    Text("#  \(invoice.invoiceNumber)")
                        .font(.headline)
                    Spacer()
                    Text(invoice.date, style: .date)
                }.padding(.top, 10)
                VStack{
                    HStack {
                        Circle()
                            .fill(invoice.customer.color)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Text(String(invoice.customer.initials))
                                    .font(.system(size: 14))
                                    .foregroundStyle(.background)
                            }
                        Text(invoice.customer.fullName)
                            .font(.headline)
                        
                        Spacer()
                        Text("$\(invoice.totalAmount)")
                            .font(.title2)
                    }.padding(.vertical, 7)
                    
                    
                }
                HStack {
                    
                    
                    VStack(alignment: .leading) {
                        
                        
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
