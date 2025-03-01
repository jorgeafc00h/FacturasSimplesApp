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
    
    @AppStorage("showTestEnvironments") var testAccounts: Bool = true
    //@State var testAccounts: Bool = true
    
    
    init(selection: Binding<Company?>, selectedCompanyId: Binding<String>) {
        
        _selection = selection
        _selectedCompanyId = selectedCompanyId
        
        
        let predicate = #Predicate<Company> {
            searchText.isEmpty ? true :
            $0.nit.contains(searchText) ||
            $0.nrc.contains(searchText) ||
            $0.nombre.contains(searchText) &&
            $0.isTestAccount == testAccounts
            
            
        }
        
        
        _companies = Query(filter: predicate, sort: \Company.nombre)
    }
    
    
    
    var filteredCompanies: [Company] {
        
        if searchText.isEmpty {
            companies.filter{$0.isTestAccount == testAccounts}
        }
        else {
            companies.filter{
                $0.nit.contains(searchText) ||
                $0.nrc.contains(searchText) ||
                $0.nombre.contains(searchText) &&
                $0.isTestAccount == testAccounts
            }
        }
    }
    
    var body: some View {
        
        VStack {
            
            let id = companyId.isEmpty ? selectedCompanyId : companyId
            
            List(selection: $selection) {
                ForEach(filteredCompanies, id:\.self){
                    company in
                    withAnimation{
                        CompaniesListItem(company: company,
                                          isSelected: company.id == id)
                        //                        .onTapGesture {
                        //                            withAnimation {
                        //                                selection = company
                        //                                searchText = ""
                        //                                companyId = company.id
                        //                                selectedCompanyName = company.nombreComercial
                        //                            }
                        //                        }
                    }
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
                
                ToolbarItemGroup(placement: .primaryAction){
                    Button("Agregar Empresa",systemImage: "plus"){
                        viewModel.isShowingAddCompany=true}
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                ToolbarItem(placement: .automatic){
                    Menu{
                        
                        Toggle("Entornos de prueba", isOn: $testAccounts)
                        
                    }label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
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
        
    }
    
    
    private var OverlaySection: some View {
        VStack{
            if companies.isEmpty {
                ContentUnavailableView {
                    Label("Empresas", systemImage: "books.vertical.circle.fill")
                        .symbolEffect(.breathe)
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
