
import SwiftUI
import SwiftData

struct AddCompanyView: View {
    
    @Query(filter: #Predicate<Catalog> { $0.id == "CAT-012"}, sort: \Catalog.id)
    var catalog: [Catalog]
    
    @Binding var company : Company
    @Binding var intro: PageIntro
    @Environment(\.modelContext)  var modelContext
    
    var syncService = InvoiceServiceClient()
    var body: some View {
        
        
        VStack(spacing:10){
            CustomTextField(text:$company.nit, hint:"NIT", leadingIcon: "person.text.rectangle.fill", hintColor: intro.hintColor)
            CustomTextField(text:$company.nombre, hint:"Nombres y Apellidos", leadingIcon:"person.fill",hintColor: intro.hintColor)
            CustomTextField(text:$company.nombreComercial, hint:"Nombre Comercial", leadingIcon:"widget.small",hintColor: intro.hintColor)
            CustomTextField(text:$company.nrc, hint:"NRC", leadingIcon: "building.columns.circle",hintColor: intro.hintColor)
            
            Spacer()
            
            Spacer(minLength: 5)
        }
        .onChange(of: [company.nit,company.nrc,company.nombreComercial]){
            intro.canContinue = canContinue()
        }
        .onAppear(){
            intro.canContinue = canContinue()
            intro.hintColor = .tabBar
        }
        .task {await SyncCatalogsAsync() }
        
        
        
        
    }
    func canContinue()->Bool{
        return !company.nit.isEmpty && !company.nombre.isEmpty && !company.nrc.isEmpty && !company.nombreComercial.isEmpty
    }
    
    func SyncCatalogsAsync() async {
        
        if(catalog.isEmpty){
            do{
                let collection = try await syncService.getCatalogs()
                
                for c in collection{
                    modelContext.insert(c)
                }
                
                try? modelContext.save()
            }
            catch{
                print(error)
            }
        }
    }
    
     
}

struct AddCompanyView2: View {
    
    @Binding var company : Company
    @Binding var intro: PageIntro
      
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-012"})
    var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-013"})
    var municipios : [CatalogOption]
    
    @State var viewModel = AddcompnayStep2ViewModel()
   
    var filteredMunicipios: [CatalogOption] {
        return company.departamentoCode.isEmpty ?
        municipios :
        municipios.filter{$0.departamento == company.departamentoCode}
    }
    
    var body: some View {
        VStack(spacing:10){
            CustomTextField(text:$company.correo,hint:"Correo Electrónico", leadingIcon: "envelope.fill",hintColor: intro.hintColor)
            CustomTextField(text:$company.telefono,hint:"Telefono", leadingIcon: "phone",hintColor: intro.hintColor)
            CustomTextField(text:$company.complemento,hint:"Direccion", leadingIcon: "house.fill",hintColor: intro.hintColor)
            
            Button(action: { viewModel.showSelectDepartamentoSheet.toggle()}) {
                
                Text(company.departamento.isEmpty ? "Seleccione Departamento" : company.departamento)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .frame( maxWidth: .infinity, alignment: .center)
                    .padding(EdgeInsets(top: 11, leading: 18, bottom: 15, trailing: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("Dark-Cyan"), lineWidth: 3)
                            .shadow(color: Color("Dark-Cyan"), radius: 6)
                    )
                
                
            }.padding(.bottom)
            
            Button(action: { viewModel.showSelectMunicipioSheet.toggle()}) {
                
                Text(company.municipio.isEmpty ? "Seleccione Municipio" : company.municipio)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .frame( maxWidth: .infinity, alignment: .center)
                    .padding(EdgeInsets(top: 11, leading: 18, bottom: 15, trailing: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("Dark-Cyan"), lineWidth: 3)
                            .shadow(color: Color("Dark-Cyan"), radius: 6)
                    )
                
                
            }.padding(.bottom)
            Spacer(minLength: 10)
 
        }
        .onChange(of: company.departamentoCode){
            onDepartamentoChange()
           
        }
        .onChange(of: company.municipioCode){
            onMunicipioChange()
        }
        .onChange(of: [company.correo,company.telefono,company.complemento]){
            intro.canContinue = canContinue()
        }
        .onAppear(){
            intro.canContinue = canContinue()
            intro.hintColor = .tabBar
        }
        .sheet(isPresented: $viewModel.showSelectDepartamentoSheet){
            SearchPickerFromCatalogView(catalogId: "CAT-012",
                                        options: departamentos,
                                        selection: $company.departamentoCode,
                                        selectedDescription: $company.departamento,
                                        showSearch:$viewModel.showSelectDepartamentoSheet,
                                        title:"Seleccione Departamento")
        }
        .sheet(isPresented: $viewModel.showSelectMunicipioSheet){
            SearchPickerFromCatalogView(catalogId: "CAT-013",
                                        options: filteredMunicipios,
                                        selection: $company.municipioCode,
                                        selectedDescription: $company.municipio,
                                        showSearch:$viewModel.showSelectMunicipioSheet,
                                        title:"Seleccione Departamento")
        }
    }
    func canContinue()->Bool{
        return !company.correo.isEmpty && !company.telefono.isEmpty && !company.complemento.isEmpty
    }
    
}


struct AddCompanyView3: View {
    
    @Binding var company : Company
    @Binding var intro: PageIntro
    @Binding var requiresOnboarding : Bool
    var size: CGSize
    @Binding var selectedCompanyId : String
    
   
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-012"})
    var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-013"})
    var municipios : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-008"})
    var tipo_establecimientos : [CatalogOption]
    
    @State var viewModel = AddCompanyViewModel()
    
    @Environment(\.modelContext)  var modelContext
    
    var body: some View {
        VStack(spacing:10){
           
            
            EconomicActivitySelect
            Spacer(minLength: 10)
            Button{
                if intro.canContinue{
                    saveChanges()
                    requiresOnboarding = false
                }
                else{
                    intro.hintColor = .red
                }
            }
            label:{
                Text("Continuar")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .frame(width: size.width * 0.4)
                    .background{
                        Capsule().fill(.black)
                    }
            }.frame(maxWidth: .infinity)
            
        }.sheet(isPresented: $viewModel.displayCategoryPicker){
            SearchPicker(catalogId: "CAT-019",
                         selection: $viewModel.codActividad,
                         selectedDescription: $viewModel.desActividad,
                         showSearch: $viewModel.displayCategoryPicker,
                         title:"Actividad Economica")
        }
        .onChange(of: viewModel.codActividad){
            company.descActividad = viewModel.desActividad ?? ""
            company.codActividad = viewModel.codActividad ?? ""
        }
        .onChange(of: [company.correo,company.telefono,company.complemento]){
            intro.canContinue = canContinue()
        }
        .onAppear(){
            intro.canContinue = canContinue()
            intro.hintColor = .tabBar
        }
    }
    func canContinue()->Bool{
        return !company.correo.isEmpty && !company.telefono.isEmpty && !company.complemento.isEmpty
    }
    
    private var EconomicActivitySelect : some View {
        Button(action: { viewModel.displayCategoryPicker.toggle()}) {
            
            Text(company.actividadEconomicaLabel)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .frame( maxWidth: .infinity, alignment: .center)
                .padding(EdgeInsets(top: 11, leading: 18, bottom: 15, trailing: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Dark-Cyan"), lineWidth: 3)
                        .shadow(color: Color("Dark-Cyan"), radius: 6)
                )
            
            
        }.padding(.bottom)
    }
}



