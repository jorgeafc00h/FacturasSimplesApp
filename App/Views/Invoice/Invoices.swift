//
//  Invoices.swift
//  App
//
//  Created by Jorge Flores on 10/21/24.
//

import SwiftUI

struct Invoices: View {
    var body: some View {
        ZStack {
            
            Color("Marine").ignoresSafeArea().navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
            VStack{
                SearchBar().padding(.horizontal,20)
                List {
                    ForEach((1...10), id: \.self) { _ in

                        InvoiceCardView(invoiceNumber: "12345",
                                        invoiceDate: "2023-10-21",
                                        customerName: "John Doe",
                                        invoiceStatus: "Nueva",
                                        totalProducts: 10,
                                        total: 123.39)
                        .previewLayout(.sizeThatFits)
                    }.listRowBackground(Color(.marine))
                }
                .background(Color.clear)
                .scrollContentBackground(.hidden)

                
            }
        }.navigationBarHidden(true)
    }
}
struct InvoiceCardView: View {
    // Sample data for an invoice
    var invoiceNumber: String
    var invoiceDate: String
    var customerName: String
    var invoiceStatus: String
    var totalProducts: Int
    var total: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("#\(invoiceNumber)")
                    .font(.headline)
                    .fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Text(invoiceStatus)
                    .font(.subheadline)
                    .foregroundColor(invoiceStatusColor())
                    .padding(16)
                    .background(invoiceStatusColor().opacity(0.1))
                    .cornerRadius(8)
            }
          
            Text("\(customerName)")
                .font(.headline).foregroundColor(.white)
        
            
            Text("\(invoiceDate)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
          
            HStack {
                Text("$: \(total)")
                    .font(.subheadline)
                    .foregroundColor(.darkCyan)
                Spacer()
                Text("Productos: \(totalProducts)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }.background(Color.clear)
            .padding(20)
            .background(Color.marine)
        .cornerRadius(15)
        .shadow(color:.darkCyan, radius: 2)
        
        
    }
    // Function to determine status color
    func invoiceStatusColor() -> Color {
        switch invoiceStatus.lowercased() {
        case "Completada":
            return Color.green
        case "Nueva":
            return Color.orange
        case "Cancelada":
            return Color.red
        default:
            return Color.gray
        }
    }
}
 
 

#Preview {
    Invoices()
}
