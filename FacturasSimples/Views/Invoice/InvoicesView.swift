//
//  InvoicesView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct SearchSuggestion: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let icon: String
    let category: String
    let secondaryText: String?
    
    init(text: String, icon: String, category: String, secondaryText: String? = nil) {
        self.text = text
        self.icon = icon
        self.category = category
        self.secondaryText = secondaryText
    }
}

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
    @State private var searchSuggestions: [SearchSuggestion] = []
    @Environment(\.modelContext)   var modelContext
    @AppStorage("selectedCompanyIdentifier") var companyIdentifier: String = ""
  
    @State var viewModel = InvoicesViewModel()
    
    var body: some View {
        NavigationSplitView {
            InvoicesListView(
                selection: $selection,
                selectedCompanyId: selectedCompanyId,
                searchText: searchText,
                searchScope: searchScope)
        } detail: {
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
                    AddInvoiceView(selectedInvoice: $selection)
                        .interactiveDismissDisabled()
                }
                .sheet(isPresented: $viewModel.showAddCustomerSheet) {
                    NavigationStack{
                        AddCustomerView().interactiveDismissDisabled()
                    }
                }
            }
        }
        .navigationSplitViewColumnWidth(
            min: 320,     // Minimum sidebar width (more space for invoice cards)
            ideal: 400,   // Preferred sidebar width  
            max: 500      // Maximum sidebar width
        )
        .navigationSplitViewStyle(.balanced)  // Equal space distribution
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Buscar por \(searchScope.rawValue)")
                .searchSuggestions {
                    if !searchSuggestions.isEmpty {
                        ForEach(searchSuggestions) { suggestion in
                            HStack(spacing: 12) {
                                // Icon with background
                                ZStack {
                                    Circle()
                                        .fill(getColorForScope(searchScope).opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: suggestion.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(getColorForScope(searchScope))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.text)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    if let secondaryText = suggestion.secondaryText {
                                        Text(secondaryText)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Category badge
                                Text(suggestion.category)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(getColorForScope(searchScope).opacity(0.1))
                                    .foregroundColor(getColorForScope(searchScope))
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                            .searchCompletion(suggestion.text)
                        }
                    }
                }
                .searchScopes($searchScope) {
                    ForEach(InvoiceSearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        await loadSearchSuggestions()
                    }
                }
                .onChange(of: searchScope) { oldValue, newValue in
                    Task {
                        await loadSearchSuggestions()
                    }
                }
                .task {
                    await loadSearchSuggestions()
                }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CloudKitSyncStatusView()
            }
        }
       
            
    }
   
    @MainActor
    private func loadSearchSuggestions() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchSuggestions = await getRecentSuggestions()
            return
        }
        
        let companyId = selectedCompanyId.isEmpty ? companyIdentifier : selectedCompanyId
        searchSuggestions = await fetchSuggestionsFromData(searchText: searchText, scope: searchScope, companyId: companyId)
    }

}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
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
