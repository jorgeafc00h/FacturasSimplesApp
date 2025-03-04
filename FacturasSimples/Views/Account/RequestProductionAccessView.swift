//
//  RequestProductionAccessView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 2/25/25.
//

import SwiftUI

struct RequestProductionAccessView: View {
    @State private var invoices: [Invoice] = []
    @State private var customers: [Customer] = []
    @State private var products: [Product] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            Text("Solicitar Acceso a Producción")
                .font(.title)
                .padding()
            
            Button(action: generateInvoices) {
                Text("Generar 50 Facturas por Tipo")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Button(action: sendInvoices) {
                Text("Enviar y Completar Facturas")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Button(action: deleteInvoices) {
                Text("Eliminar Facturas Generadas")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Link("Hacienda Facturación Electrónica", destination: URL(string: "https://admin.factura.gob.sv/login")!)
                .foregroundColor(.blue)
                .padding(.bottom)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Información"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func generateInvoices() {
        // Generate 5 random customers
        customers = (1...5).map { i in
            Customer(firstName: "Cliente\(i)", lastName: "Apellido\(i)", nationalId: "ID\(i)", email: "cliente\(i)@example.com", phone: "12345678")
        }
        
        // Generate 7 random products
        products = (1...7).map { i in
            Product(productName: "Producto\(i)", unitPrice: Decimal(Double.random(in: 1...100)))
        }
        
        // Generate 50 invoices per type
        let invoiceTypes: [InvoiceType] = [.Factura, .CCF]
        invoices = invoiceTypes.flatMap { type in
            (1...50).map { i in
                let customer = customers.randomElement()!
                let invoice = Invoice(invoiceNumber: "INV-\(type)-\(i)", date: Date(), status: .Nueva, customer: customer, invoiceType: type)
                invoice.items = products.map { product in
                    InvoiceDetail(quantity: Int.random(in: 1...5), product: product)
                }
                return invoice
            }
        }
        alertMessage = "Se generaron 50 facturas por tipo con datos de prueba."
        showAlert = true
    }
    
    private func sendInvoices() {
        // Logic to send and complete all invoices
        for invoice in invoices {
            invoice.status = .Completada
        }
        alertMessage = "Facturas enviadas y completadas."
        showAlert = true
    }
    
    private func deleteInvoices() {
        // Logic to delete all generated invoices
        invoices.removeAll()
        alertMessage = "Facturas generadas eliminadas."
        showAlert = true
    }
}

#Preview {
    RequestProductionAccessView()
}
