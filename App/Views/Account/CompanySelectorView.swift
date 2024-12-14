import SwiftUI
import SwiftData

struct CompanySelectorView: View {
    
    @Environment(\.modelContext)  var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \Company.nrc)
    var companies: [Company]
    
    @Binding var selection: Company?
    @State private var searchText: String = ""
    
    
    var filteredCompanies: [Company] {
        if searchText.isEmpty {
            companies
        } else {
            companies.filter{$0.nrc.contains(searchText) ||
                $0.nit.contains(searchText) ||
                $0.nombre.contains(searchText) ||
                $0.nombreComercial.contains(searchText)}
        }
    }
    
    var body: some View {
        NavigationStack{
                List{
                    ForEach(filteredCompanies, id:\.self){ c in
                        CompanySelectorListItem(company: c, isSelected: selection == c)
                            .onTapGesture {
                                withAnimation{
                                    selection = c
                                    searchText = ""
                                    dismiss()
                                }
                            }
                    }
                }
                .overlay {
                    OverlaySection
                }
            }
            .listStyle(.plain)
            .frame(idealWidth: LayoutConstants.sheetIdealWidth,
                   idealHeight: LayoutConstants.sheetIdealHeight)
            .navigationTitle("Seleccione Empresa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }.accentColor(.darkCyan)
    }
    
    private var OverlaySection: some View {
        VStack{
            if companies.isEmpty {
                ContentUnavailableView {
                    Label("Empresas", systemImage: "books.vertical.circle.fill")
                }description: {
                    Text("El primer paso de configuracion es agregar una empresa luego crear clientes.")
                }
                .offset(y: -60)
            }
        }
    }
    
    
}

private struct CompanySelectorListItem: View {
    
    var company : Company
    
    var isSelected : Bool = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(isSelected ? .darkCyan: .darkBlue))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "widget.small")
                        .font(.system(size: 38))
                        .foregroundStyle(.background)
                }
            
            Circle()
                .fill(isSelected ? .blue : .clear)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading) {
                HStack{
                    
                    
                    Text(company.nombre)
                        .font(.headline)
                }
                Text(company.nombreComercial)
                    .font(.subheadline)
                if case let (id?, p?) = (company.nit, company.telefono) {
                    Divider()
                    HStack {
                        Image(systemName: "widget.small")
                        Text(id)
                        Image(systemName: "phone")
                        Text(p)
                    }
                    .font(.caption)
                }
            }
        }
    }
}
//#Preview (traits: .sampleCompanies) {
//    CompanySelectorView(selection: .init)
//}
