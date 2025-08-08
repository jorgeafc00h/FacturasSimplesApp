import SwiftUI
import SwiftData

struct AddCompanyView: View {
    
    @Query(filter: #Predicate<Catalog> { $0.id == "CAT-012"}, sort: \Catalog.id)
    var catalog: [Catalog]
    
    @Binding var company : Company
    @Binding var intro: PageIntro
    @Environment(\.modelContext)  var modelContext
    
    // Access stored Apple account information
    @AppStorage("storedEmail") var storedEmail: String = ""
    @AppStorage("storedName") var storedName: String = ""
    
    var syncService = InvoiceServiceClient()
    var body: some View {
        
        
        VStack(spacing:10){
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    CustomTextField(text:$company.nit,
                                    hint:"NIT (Opcional)",
                                    leadingIcon: "person.text.rectangle.fill",
                                    hintColor: .tabBar, // Always normal color since optional
                                    keyboardType: .numberPad)
                    
                    InfoTooltipButton(
                        title: "¿Qué es el NIT?",
                        message: "El Número de Identificación Tributaria (NIT) es requerido por el Ministerio de Hacienda para la configuración del sistema de facturación electrónica. Es opcional para uso básico de la app.",
                        icon: "info.circle"
                    )
                }
                Text("Campo opcional - requerido para integración con Ministerio de Hacienda")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            CustomTextField(text:$company.nombre,
                            hint:"Nombres y Apellidos *",
                            leadingIcon:"person.fill",
                            hintColor: getFieldColor(for: company.nombre),
                            keyboardType: .default)
            
            CustomTextField(text:$company.nombreComercial,
                            hint:"Nombre Comercial *",
                            leadingIcon:"widget.small",
                            hintColor: getFieldColor(for: company.nombreComercial),
                            keyboardType: .default)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    CustomTextField(text:$company.nrc,
                                    hint:"NRC (Opcional)",
                                    leadingIcon: "building.columns.circle",
                                    hintColor: .tabBar, // Always normal color since optional
                                    keyboardType: .numberPad)
                    
                    InfoTooltipButton(
                        title: "¿Qué es el NRC?",
                        message: "El Número de Registro de Contribuyente (NRC) es utilizado por el Ministerio de Hacienda para identificar a los contribuyentes en el sistema de facturación electrónica oficial.",
                        icon: "info.circle"
                    )
                }
                Text("Campo opcional - requerido para configuración completa con Hacienda")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Spacer(minLength: 5)
        }
        .onChange(of: [company.nit,company.nrc,company.nombreComercial, company.nombre]) { _, _ in
            intro.canContinue = canContinue()
        }
        .onAppear(){
            // Set default values from Apple account if available and fields are empty
            if company.nombre.isEmpty && !storedName.isEmpty {
                company.nombre = storedName
            }
            
            intro.canContinue = canContinue()
            // Don't set intro.hintColor here as it can interfere with validation colors
        }
        .task {await SyncCatalogsAsync() }
        
        
        
        
    }
    func canContinue()->Bool{
        // Only require nombre and nombreComercial - NIT and NRC are now optional
        return !company.nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               !company.nombreComercial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @MainActor
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
    
    // MARK: - Helper Methods
    
    /// Returns the appropriate color for a field based on validation state
    private func getFieldColor(for fieldValue: String) -> Color {
        let isEmpty = fieldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return isEmpty ? .red : .tabBar
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
      
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-012"})
    var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-013"})
    var municipios : [CatalogOption]
    
    @State var viewModel = AddcompnayStep2ViewModel()
    
    // Access stored Apple email and check if user signed in with Apple
    @AppStorage("storedEmail") var storedEmail: String = ""
    @AppStorage("storedName") var storedName: String = ""
    @State private var isEditingEmail = false
    
    // Check if user signed in with Apple
    var didSignInWithApple: Bool {
        UserDefaults.standard.bool(forKey: "didSignInWithApple")
    }
   
    var filteredMunicipios: [CatalogOption] {
        return company.departamentoCode.isEmpty ?
        municipios :
        municipios.filter{$0.departamento == company.departamentoCode}
    }
    
    var body: some View {
        VStack(spacing:10){
            // Email field - editable with Apple Sign-In context
            if didSignInWithApple && !isEditingEmail {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("Correo Electrónico (desde Apple)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Editar") {
                            isEditingEmail = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text(company.correo.isEmpty ? storedEmail : company.correo)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            isEditingEmail = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text("Puede editar este correo si tiene otro registrado con el Ministerio de Hacienda")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    CustomTextField(text:$company.correo,
                                    hint:"Correo Electrónico",
                                    leadingIcon: "envelope.fill",
                                    hintColor: intro.hintColor,
                                    keyboardType: .emailAddress)
                    if didSignInWithApple {
                        HStack {
                            Text("Editando correo de Apple")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Spacer()
                            Button("Cancelar") {
                                isEditingEmail = false
                                company.correo = storedEmail
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Phone number - now optional
            VStack(alignment: .leading, spacing: 4) {
                CustomTextField(text:$company.telefono,
                                hint:"Teléfono (Opcional)",
                                leadingIcon: "phone.fill",
                                hintColor: .tabBar, // Always use normal color since it's optional
                                keyboardType: .phonePad)
                Text("Este campo es opcional y puede completarlo más tarde")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            CustomTextField(text:$company.complemento,
                            hint:"Dirección",
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
        .onChange(of: company.departamentoCode) { _, _ in
            onDepartamentoChange()
           
        }
        .onChange(of: company.municipioCode) { _, _ in
            onMunicipioChange()
        }
        .onChange(of: [company.correo,company.telefono,company.complemento]) { _, _ in
            intro.canContinue = canContinue()
        }
        .onAppear(){
            // Set default email from Apple account if available and company email is empty
            if company.correo.isEmpty && !storedEmail.isEmpty {
                company.correo = storedEmail
            }
            
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
        // Only require email and address - phone is now optional
        let hasValidEmail = !company.correo.isEmpty || (didSignInWithApple && !storedEmail.isEmpty)
        return hasValidEmail && !company.complemento.isEmpty
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
                         title:"Actividad Económica")
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
    
    @AppStorage("selectedCompanyIdentifier") var companyId: String = ""
    @AppStorage("selectedCompanyName")  var selectedCompanyName : String = ""
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-012"})
    var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-013"})
    var municipios : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-008"})
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
                if intro.canContinue || FeatureFlags.shared.isDemoMode {
                    saveChanges()
                    
                    // In demo mode, pre-populate demo data
                    if FeatureFlags.shared.isDemoMode && company.nit.isEmpty {
                        setupDemoCompanyData()
                    }
                    
                    requiresOnboarding = false
                    companyId = company.id
                    selectedCompanyName = company.nombreComercial
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
    
    // MARK: - Demo Mode Setup
    private func setupDemoCompanyData() {
        // Pre-fill demo data for App Store reviewers
        if company.nit.isEmpty {
            company.nit = "12345678901234"
        }
        if company.nrc.isEmpty {
            company.nrc = "123456"
        }
        if company.certificatePath.isEmpty {
            // Use a placeholder certificate path for demo
            company.certificatePath = "demo_certificate.p12"
            company.certificatePassword = "demo123"
        }
        // Set demo credentials
        viewModel.password = "demo123"
        viewModel.confirmPassword = "demo123"
    }
}

// MARK: - Info Tooltip Button Component
struct InfoTooltipButton: View {
    let title: String
    let message: String
    let icon: String
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            showTooltip = true
        }) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .padding(4)
        }
        .alert(title, isPresented: $showTooltip) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text(message)
        }
    }
}

// MARK: - Fancy Tooltip Component (Alternative Implementation)
struct FancyTooltipButton: View {
    let title: String
    let message: String
    let icon: String
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            showTooltip = true
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .sheet(isPresented: $showTooltip) {
            TooltipModalView(title: title, message: message, showModal: $showTooltip)
        }
    }
}

// MARK: - Tooltip Modal View
struct TooltipModalView: View {
    let title: String
    let message: String
    @Binding var showModal: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header with icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "building.columns")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                
                // Message content
                VStack(alignment: .leading, spacing: 16) {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                    
                    // Additional context
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Este campo es necesario para la facturación electrónica oficial del gobierno.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Información")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        showModal = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
