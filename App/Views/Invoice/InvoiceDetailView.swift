//
//  InvoiceDetailView.swift
//  App
//
//  Created by Jorge Flores on 11/4/24.
//

import SwiftUI
import SwiftData

struct InvoiceDetailView: View {

    @Bindable var invoice: Invoice
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview(traits: .sampleInvoices) {
    @Previewable @Query var invoices: [Invoice]
    InvoiceDetailView(invoice: invoices.first!)
}
