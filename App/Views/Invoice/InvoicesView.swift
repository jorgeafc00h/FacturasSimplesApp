//
//  InvoicesView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct InvoicesView: View {
    
    @Binding var selectedCompanyId: String
    @State private var selection: Invoice?
    @State private var searchText: String = ""
  
    
    @State var viewModel = InvoicesViewModel()
   
    var body: some View {
        
        NavigationSplitView{
            InvoicesListView(
                selection:$selection,
                selectedCompanyId:selectedCompanyId,
                searchText: searchText)
        }
        detail:{
            if let inv = selection {
                InvoiceDetailView(invoice: inv)
            }
            else{
                ContentUnavailableView {
                    Label("Seleccione una factura", systemImage: "list.bullet.rectangle.fill")
                } description: {
                    Text("si no tiene facturas puede comenzar creando un nuevo cliente y una nueva factura")
                }
                actions: {
                    Button("Crear Factura", systemImage: "plus"){
                        viewModel.showAddInvoiceSheet = true
                    }
                    Button("Crear Cliente", systemImage: "plus"){
                        viewModel.showAddCustomerSheet = true
                    }
                }
                .sheet(isPresented: $viewModel.showAddInvoiceSheet) {
                    AddInvoiceView()
                }
                .sheet(isPresented: $viewModel.showAddCustomerSheet) {
                    NavigationStack{
                        AddCustomerView()
                    }
                }
            }
        } 
        .searchable(text: $searchText, placement: .sidebar)
    }
   
}

#Preview (traits: .sampleInvoices){
    InvoicesViewWrapper()
}

private struct InvoicesViewWrapper: View {
    @State private var selectedCompanyId: String = ""
    
    var body: some View {
        InvoicesView( selectedCompanyId: $selectedCompanyId)
    }
}
