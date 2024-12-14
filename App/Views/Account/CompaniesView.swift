
import SwiftUI
import SwiftData

struct CompaniesView: View {
    
    @Environment(\.modelContext)  var modelContext
    
    @Query(sort: \Company.nrc)
    var companies: [Company]
    
    @Binding var selection: Company?
    @State var viewModel = CompaniesViewModel()
    
    @State var searchText = ""
    
    init(selection: Binding<Company?>) {
        
        _selection = selection
        let predicate = #Predicate<Company> {
            searchText.isEmpty ? true :
            $0.nit.contains(searchText) ||
            $0.nrc.contains(searchText) ||
            $0.nombre.contains(searchText)
        }
        _companies = Query(filter: predicate, sort: \Company.nombre)
    }
    
    var body: some View {
        List{
            ForEach(companies){ c in
                CompaniesListItem(company: c, isSelected: selection == c)
                    .onTapGesture {
                        withAnimation {
                            selection = c
                            searchText = ""
                        }
                    }
//                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
//
//                    }
            }
        }
        .searchable(text: $searchText)
        .sheet(isPresented: $viewModel.isShowingAddCompany) {
           EmisorEditView(company: Company(nit:"",nrc:"", nombre:""))
        }
        .sheet(isPresented: $viewModel.isShowingEditCompany){
            if let selected = selection {
                EmisorEditView(company: selected)
            }
        }
        .toolbar{
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                Spacer()
//                if let selected = selection {
//                    
//                    NavigationLink(destination: EmisorEditView(company: selected)) {
//                        Image(systemName: "pencil")
//                            .symbolEffect(.breathe, options: .nonRepeating)
//                    }
//                    .buttonStyle(BorderlessButtonStyle())
//                    
//                }
                Button("Editar Empresa",systemImage: "pencil"){
                    viewModel.isShowingEditCompany=true
                }.buttonStyle(BorderlessButtonStyle())
                Button("Agregar Empresa",systemImage: "plus"){
                    viewModel.isShowingAddCompany=true}
                    .buttonStyle(BorderlessButtonStyle())
            }
            
        }
        .overlay {
            OverlaySection
        }
        .navigationTitle("Empresas")
    }
    
    
    private var OverlaySection: some View {
        VStack{
            if companies.isEmpty {
                ContentUnavailableView {
                    Label("Empresas", systemImage: "books.vertical.circle.fill")
                }description: {
                    Text("El primer paso de configuracion es agregar una empresa luego crear clientes.")
                }actions: {
                    Button("Agregar Empresa"){ viewModel.isShowingAddCompany=true}
                }
                .offset(y: -60)
            }
        }
    }
    
}
//
//#Preview (traits: .sampleCompanies) {
//    CompaniesView(selection: nil)
//}
#Preview (traits: .sampleCompanies){
    CompaniesViewWrapper()
}

struct CompaniesViewWrapper: View {
    @State private var selectedCompany: Company? = nil
    
    var body: some View {
        CompaniesView(selection: $selectedCompany)
    }
}
