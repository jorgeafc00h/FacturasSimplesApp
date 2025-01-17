
import SwiftUI
import SwiftData

struct CompaniesView: View {
    
    @Environment(\.modelContext)  var modelContext
    
    @Query(sort: \Company.nrc)
    var companies: [Company]
    
    @Binding var selection: Company?
    @Binding var selectedCompanyId: String
    @State var viewModel = CompaniesViewModel()
    
    @State var searchText = ""
    @AppStorage("selectedCompanyIdentifier")  var companyId : String = ""{
        didSet{
            selectedCompanyId = companyId
        }
    }
    @AppStorage("selectedCompanyName")  var selectedCompanyName : String = ""
    
    init(selection: Binding<Company?>, selectedCompanyId: Binding<String>) {
        
        _selection = selection
        _selectedCompanyId = selectedCompanyId
        
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
                            companyId = c.id
                            selectedCompanyName = c.nombreComercial
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
               if let selected = selection {
                    Button(selected.nombreComercial,systemImage: "pencil"){
                        viewModel.isShowingEditCompany=true
                    }.buttonStyle(BorderlessButtonStyle())
                }
                Button("Agregar Empresa",systemImage: "plus"){
                    viewModel.isShowingAddCompany=true}
                    .buttonStyle(BorderlessButtonStyle())
            }
            
        }
        .overlay {
            OverlaySection
        }
        .onAppear {
            if selectedCompanyId.isEmpty {
                selectedCompanyId = companyId
            }
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

#Preview (traits: .sampleCompanies){
    CompaniesViewWrapper()
}

struct CompaniesViewWrapper: View {
    @State private var selectedCompany: Company? = nil
    @State private var selectedCompanyId: String = ""
    
    var body: some View {
        CompaniesView(selection: $selectedCompany, selectedCompanyId: $selectedCompanyId)
    }
}
