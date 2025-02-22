
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
            CustomTextField(text:$company.nit,
                            hint:"NIT",
                            leadingIcon: "person.text.rectangle.fill",
                            hintColor: intro.hintColor,
                            keyboardType: .numberPad)
            
            CustomTextField(text:$company.nombre,
                            hint:"Nombres y Apellidos",
                            leadingIcon:"person.fill",
                            hintColor: intro.hintColor,
                            keyboardType: .default)
            
            CustomTextField(text:$company.nombreComercial,
                            hint:"Nombre Comercial",
                            leadingIcon:"widget.small",
                            hintColor: intro.hintColor,
                            keyboardType: .default)
            
            CustomTextField(text:$company.nrc,
                            hint:"NRC",
                            leadingIcon: "building.columns.circle",
                            hintColor: intro.hintColor,
                            keyboardType: .numberPad)
            
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

private struct ButtonPicker: View {
    
    @Binding var action : Bool
    @Binding var title: String
    var hint : String = ""
    
    var body: some View {
        Button(action: { action.toggle()}) {
            
            Text(title.isEmpty ? hint : title)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .frame( maxWidth: .infinity, alignment: .center)
                .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 10))
                //.padding(.top,10)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.gray), lineWidth: 1)
                        .shadow(color: Color(.darkBlue), radius: 6)
                )
            
            
        }.padding(.top)
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
            CustomTextField(text:$company.correo,
                            hint:"Correo Electrónico",
                            leadingIcon: "envelope.fill",
                            hintColor: intro.hintColor,
                            keyboardType: .emailAddress)
            
            CustomTextField(text:$company.telefono,
                            hint:"Telefono",
                            leadingIcon: "phone",
                            hintColor: intro.hintColor,
                            keyboardType: .numberPad)
            
            CustomTextField(text:$company.complemento,
                            hint:"Direccion",
                            leadingIcon: "house.fill",
                            hintColor: intro.hintColor,
                            keyboardType:.default)
            
            ButtonPicker(action:$viewModel.showSelectDepartamentoSheet,
                         title: $company.departamento,
                         hint: "Seleccione Departamento")
            
            ButtonPicker(action:$viewModel.showSelectMunicipioSheet,
                         title: $company.municipio,
                         hint: "Seleccione Municipio")
            
            Spacer(minLength: 7)
 
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
                                        selection: $company.departamentoCode,
                                        selectedDescription: $company.departamento,
                                        showSearch:$viewModel.showSelectDepartamentoSheet,
                                        title:"Seleccione Departamento")
        }
        .sheet(isPresented: $viewModel.showSelectMunicipioSheet){
            SearchPickerFromCascadeFilterView(options: municipios.filter{$0.departamento == company.departamentoCode},
                                        selection: $company.municipioCode,
                                        selectedDescription: $company.municipio,
                                        showSearch:$viewModel.showSelectMunicipioSheet,
                                        title:"Seleccione Departamento"
                                         )
        }
    }
    func canContinue()->Bool{
        return !company.correo.isEmpty && !company.telefono.isEmpty && !company.complemento.isEmpty
    }
    
    
}

struct AddCompanyView3:  View {
    
    @Binding var company : Company
    @Binding var intro: PageIntro
   
    @Environment(\.modelContext)  var modelContext
    
    @State var displayCategoryPicker : Bool = false
    @State var displayTypePicker : Bool = false
    
    var body: some View {
        VStack(spacing:10){
           
            //Link("Hacienda Facturación Electrónica", destination: URL(string: "https://admin.factura.gob.sv/login")!)
            EconomicActivitySelect
            TypeSelect
           
            Spacer(minLength: 5)
           
            
        }.sheet(isPresented: $displayCategoryPicker){
            SearchPickerFromCatalogView(catalogId: "CAT-019",
                         selection: $company.codActividad,
                         selectedDescription: $company.descActividad,
                         showSearch: $displayCategoryPicker,
                         title:"Actividad Economica")
        }
        .sheet(isPresented: $displayTypePicker){
            SearchPickerFromCatalogView(catalogId: "CAT-008",
                         selection: $company.tipoEstablecimiento,
                         selectedDescription: $company.establecimiento,
                         showSearch: $displayTypePicker,
                         title:"Tipo Establecimiento")
        }
        .onAppear(){
//            if !company.tipoEstablecimiento.isEmpty {
//                let typeCode = company.tipoEstablecimiento
//                
//                let descriptor = FetchDescriptor<CatalogOption>(predicate: #Predicate {
//                    $0.catalog.id == "CAT-008" && $0.code == typeCode
//                })
//                
//                if let _catalogOption = try? modelContext.fetch(descriptor).first {
//                    selectedType = _catalogOption.details
//                } else {
//                    print("no selected tipoEstablecimiento identifier: ")
//                }
//            }
        }
    }
    
    private var EconomicActivitySelect : some View {
        Button(action: { displayCategoryPicker.toggle()}) {
            
            Text(company.actividadEconomicaLabel)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .frame( maxWidth: .infinity, alignment: .center)
                .padding(EdgeInsets(top: 11, leading: 18, bottom: 15, trailing: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.gray), lineWidth: 3)
                        .shadow(color: Color(.darkBlue), radius: 6)
                )
            
            
        }.padding(.bottom)
    }
    
    private var TypeSelect : some View {
        Button(action: { displayTypePicker.toggle()}) {
            
            Text(company.establecimiento.isEmpty ? "Seleccione tipo Establecimiento" : company.establecimiento)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .frame( maxWidth: .infinity, alignment: .center)
                .padding(EdgeInsets(top: 11, leading: 18, bottom: 15, trailing: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.gray), lineWidth: 3)
                        .shadow(color: Color(.darkBlue), radius: 6)
                )
            
            
        }.padding(.bottom)
    }
}


struct AddCompanyView4: View {
    
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
           
            
            Link("Hacienda Facturación Electrónica", destination: URL(string: "https://admin.factura.gob.sv/login")!)
                .foregroundColor(.blue)
                .padding(.bottom)
            
            Button(action:{
                viewModel.isCertificateImporterPresented.toggle()
            }) {
                SyncCertButonLabel
            }.padding(.bottom)
                .disabled(viewModel.isBusy)
                .help("Seleccione el certificado proporcionado por Hacienda para la facturación electrónica")
            
            CustomTextField(text:$viewModel.password,
                            hint:"Contraseña Certificado",
                            leadingIcon: "lock.fill",
                            isPassword: true,
                            hintColor: intro.hintColor,
                            keyboardType: .emailAddress)
            
            CustomTextField(text:$viewModel.confirmPassword,
                            hint:"Confirmar Contraseña Certificado",
                            leadingIcon: "lock.fill",
                            isPassword: true,
                            hintColor: intro.hintColor,
                            keyboardType: .emailAddress)
            
            EditUserCertificateCredentials
            
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
            
        }
        .fileImporter(isPresented: $viewModel.isCertificateImporterPresented,
                      allowedContentTypes:  [.x509Certificate],
                      allowsMultipleSelection : false,
                      onCompletion:  importFile)
        .confirmationDialog(
            "¿Desea actualizar el certificado?",
            isPresented: $viewModel.showConfirmSyncSheet,
            titleVisibility: .visible
        ) {
            Button{
                viewModel.isBusy = true
                Task{
                    _ =  await uploadAsync()
                }
            }
            label: {
                Text("Guardar Cambios").foregroundColor(.darkBlue)
            }
            
            Button("Cancelar", role: .cancel) {}
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
        .padding()
        .cornerRadius(10)
        .alert(viewModel.message, isPresented: $viewModel.showAlertMessage) {
                   Button("OK", role: .cancel) {
                       
                   }
               }
        
    }
    func canContinue()->Bool{
        return !company.correo.isEmpty && !company.telefono.isEmpty && !company.complemento.isEmpty
    }
     
    private var SyncCertButonLabel: some View {
        VStack{
            if viewModel.isBusy{
                HStack {
                    Label("Actualiando...",systemImage: "progress.indicator")
                  
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                }
            }
            else{
                Text("Seleccionar Certificado")
            }
        }.fontWeight(.bold)
            .foregroundColor(.gray)
            .frame( maxWidth: .infinity, alignment: .center)
            .padding(EdgeInsets(top: 11, leading: 18, bottom: 15, trailing: 15))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.gray), lineWidth: 3).shadow(color: .white, radius: 6))
    }
    
    private var EditUserCertificateCredentials:   some View {
        VStack{
            
            Button(action: updateMHCertificateCredentialValidation ){
                UpdatePasswordCertButonLabel
            }.disabled(viewModel.isValidatingCertificateCredentials)
                .padding(.bottom)
                .confirmationDialog(
                    "¿Desea actualizar la  contraseña de el certificado?",
                    isPresented: $viewModel.showConfirmUpdatePassword,
                    titleVisibility: .visible
                ) {
                    Button{
                        viewModel.isValidatingCertificateCredentials = true
                        Task{
                            _ =  await updateMHCertificateCredentials()
                        }
                    }
                    label: {
                        Text("Guardar Cambios").accentColor(.darkBlue)
                    }
                    
                    Button("Cancelar", role: .cancel) {}
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .alert(viewModel.message, isPresented: $viewModel.showValidationMessage) {
                    Button("OK", role: .cancel){}
                }
             
        }
        
    }
    private var UpdatePasswordCertButonLabel: some View {
        VStack{
            if viewModel.isValidatingCertificateCredentials{
                HStack {
                    Label("Verificando Certificado...",systemImage: "progress.indicator")
                  
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                }
            }
            else{
                Text("Actualizar contraseña")
            }
        }.fontWeight(.bold)
                .foregroundColor(.gray)
                .frame( maxWidth: .infinity, alignment: .center)
                .padding(EdgeInsets(top: 11, leading: 18, bottom: 15, trailing: 15))
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(.gray), lineWidth: 3).shadow(color: .white, radius: 6))
    }
}





#Preview (traits: .sampleCompanies){
    
    // Add sample data
    let company = Company(nit:"123512351",nrc:"1351346",nombre:"Joe Cool",descActividad: "")
    
    let intro = pagesIntros[5]
    
     AddCompanyView4(
        company: .constant(company),
        intro: .constant(intro),
        requiresOnboarding: .constant(true),
        size: CGSize(width: 390, height: 844),
        selectedCompanyId: .constant("")
    )
     
}
