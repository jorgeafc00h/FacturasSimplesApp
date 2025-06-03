//
//  InvoicesView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

enum InvoiceSearchScope: String, CaseIterable {
    case nombre = "Nombre"
    case nit = "NIT"
    case dui = "DUI"
    case nrc = "NRC"
    case factura = "Factura"
    case ccf = "CCF"
}

struct InvoicesView: View {
    
    @Binding var selectedCompanyId: String
    @State private var selection: Invoice?
    @State private var searchText: String = ""
    @State  var searchScope: InvoiceSearchScope = .nombre
  
    @State var viewModel = InvoicesViewModel()
   
    var body: some View {
        
        NavigationSplitView{
            InvoicesListView(
                selection: $selection,
                selectedCompanyId: selectedCompanyId,
                searchText: searchText,
                searchScope: searchScope)
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
                    AddInvoiceView(selectedInvoice: $selection).interactiveDismissDisabled()
                }
                .sheet(isPresented: $viewModel.showAddCustomerSheet) {
                    NavigationStack{
                        AddCustomerView().interactiveDismissDisabled()
                    }
                }
            }
        } 
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Buscar por \(searchScope.rawValue)")
        .searchScopes($searchScope) {
            ForEach(InvoiceSearchScope.allCases, id: \.self) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
    }
}

#Preview (traits: .sampleInvoices){
    InvoicesViewWrapper()
}

private struct InvoicesViewWrapper: View {
    @State private var selectedCompanyId: String = ""
    
    var body: some View {
        InvoicesView(selectedCompanyId: $selectedCompanyId)
    }
}
