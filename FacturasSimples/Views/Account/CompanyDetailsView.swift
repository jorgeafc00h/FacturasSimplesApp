import SwiftUI
import SwiftData

struct CompanyDetailsView : View {
    @Bindable var company: Company
    @Binding var selection : Company?
    
    @Binding var selectedCompanyId: String
    @State var viewModel = CompanyDetailsViewModel()
    @AppStorage("selectedCompanyIdentifier") var companyId: String = "" {
        didSet {
            selectedCompanyId = companyId
        }
    }
    @AppStorage("selectedCompanyName")  var selectedCompanyName : String = ""
    var body: some View {
        ScrollView {
            VStack(spacing: 24) { // Increased from 20 for better section separation
                CompanyTopFrame
                
                VStack(spacing: 12) { // Reduced from 16 for tighter button grouping
                    CompanyTabs
                }
                .padding(.horizontal)
                
                StatusSection
                
                CompanyDetailsSection(company: company)
            }
            .padding(.vertical)
        }
        .navigationTitle(Text(company.nombreComercial))
        .sheet(isPresented: $viewModel.showLogoEditorSheet) {
            NavigationStack {
                LogoEditorView(company: company)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showRequestProductionAccessSheet) {
            NavigationStack {
                RequestProductionAccessView()
            }
        }
        .sheet(isPresented: $viewModel.showEditCredentialsSheet) {
            EditProfileView(selection: company,
                            isPresented: $viewModel.showEditCredentialsSheet,
                            areInvalidCredentials: $viewModel.showCredentialsInvalidMessage)
        }
        .sheet(isPresented: $viewModel.showEditCompanySheet){
            EmisorEditView(company: company)
        }
        .sheet(isPresented: $viewModel.showEditCertificateCredentials){
            CertificateUpdate(company: company)
        }
    }
    
    private var CompanyTopFrame: some View {
        VStack {
            HStack {
                Circle()
                    .fill(Color(.darkCyan))
                    .frame(width: 55, height: 55)
                    .overlay {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce)
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(company.isTestAccount ? "Ambiente Pruebas" : "Ambiente Productivo")
                            .font(.subheadline)
                            .foregroundColor(company.isTestAccount ? .amarello : .green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.amarello).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Spacer()
                        
                        Image(systemName: company.isTestAccount ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .foregroundColor(company.isTestAccount ? .amarello : .green)
                            .symbolEffect(.pulse)
                    }
                    
                    Text(company.nombre)
                        .font(.headline)
                    
                    Text(company.correo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        Label(company.nit, systemImage: "number")
                        Label(company.telefono, systemImage: "phone")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.leading)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2)
        .padding()
        .onAppear(){
            Task{
                await validateCertificateCredentialasAsync()
                await validateCredentialsAsync()
            }
        }
    }
    
    private var CompanyTabs: some View {
        VStack(spacing: 12) {
            
            Button(action: {
                viewModel.showSetAsDefailtConfirmDialog.toggle()
            }) {
                
                let selected = selectedCompanyId == company.id
                
                
                MenuButton(
                    title: selected ? "Empresa Predeterminada": "Establecer Como predeterminada",
                    icon: "widget.small.square.fill",
                    color: selected ?
                    Color(.darkCyan).opacity(0.95):
                        Color(.blue).opacity(0.45)
                )
                
            }.disabled(isDisabledSelectAsPrimary())
            .confirmationDialog(
                "¿Desea Establecer esta empresa como predeterminada para gestionar facturas?",
                isPresented: $viewModel.showSetAsDefailtConfirmDialog,
                titleVisibility: .visible
            ) {
                Button("Confirmar",action: SetAsDefaultCompany)
                    
                
                Button("Cancelar", role: .cancel) {}
            }
            
            Button(action: {
                viewModel.showEditCompanySheet.toggle()
            }) {
                MenuButton(
                    title: "Editar Datos de Empresa",
                    icon: "pencil.line",
                    color: .darkCyan.opacity(0.95),
                    warning: hasAnyMissingField(),
                    warningMessage: "Actualize Datos Incompletos de Empresa"
                )
            }
            
            Button(action: {
                viewModel.showEditCertificateCredentials.toggle()
            }) {
                MenuButton(
                    title: "Credenciales de Certificado",
                    icon: "lock.fill",
                    color: Color(.darkCyan).opacity(0.95),
                    loading: viewModel.isLoadingCertificateStatus,
                    warning: viewModel.showCertificateInvalidMessage,
                    warningMessage: "Actualize Certificado"
                )
            }
            
            Button(action: {
                viewModel.showEditCredentialsSheet.toggle()
            }) {
                MenuButton(
                    title: "Credenciales Hacienda",
                    icon: "key.fill",
                    color: Color(.darkCyan).opacity(0.95),
                    loading: viewModel.isLoadingCredentialsStatus,
                    warning: viewModel.showCredentialsInvalidMessage,
                    warningMessage: "Actualize Contraseña de Hacienda"
                )
            }
            
            if company.isTestAccount {
                
                
                Button(action: {
                    viewModel.showRequestProductionAccessSheet.toggle()
                }) {
                    MenuButton(
                        title: "Solicitar Autorización a Producción",
                        icon: "checkmark.seal.fill",
                        color: Color( .amarello)
                    )
                }
            }
            Button(action: {
                viewModel.showLogoEditorSheet = true
            }) {
                MenuButton(
                    title: "Editar Logo de Facturas",
                    icon: "photo.on.rectangle",
                    color: .darkCyan.opacity(0.95),
                    warning: hasMissingInvoiceLogo(),
                    warningMessage: "Selecciones logo de facturas"
                )
            }
        }
    }
    
    private var StatusSection : some View {
        VStack{
            if viewModel.isLoadingCertificateStatus{
                Label("Verificando Certificado...",systemImage: "progress.indicator")
                    .foregroundColor(.darkCyan)
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
            }
            else{
                VStack{
                    HStack {
                        let color = viewModel.showCertificateInvalidMessage ? Color.red :  Color.darkCyan
                        let label = viewModel.showCertificateInvalidMessage ? "Invalido" : "OK"
                        Text("Certificado Hacienda")
                            .foregroundColor(color)
                        Spacer()
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        Text(label)
                            .font(.subheadline)
                            .foregroundColor(color)
                            .padding(7)
                            .background(color.opacity(0.09))
                            .cornerRadius(8)
                    }
                }
            }
            
            if viewModel.isLoadingCredentialsStatus{
                Label("Verificando Credenciales...",systemImage: "progress.indicator")
                    .foregroundColor(.darkCyan)
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
            }
            else{
                VStack{
                    HStack {
                        let color = viewModel.showCredentialsInvalidMessage ? Color.red :  Color.darkCyan
                        let label = viewModel.showCredentialsInvalidMessage ? "Invalido" : "OK"
                        Text("Credenciales Hacienda")
                            .foregroundColor(color)
                        Spacer()
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        Text(label)
                            .font(.subheadline)
                            .foregroundColor(color)
                            .padding(7)
                            .background(color.opacity(0.09))
                            .cornerRadius(8)
                    }
                }
            }
            
        }.padding(.horizontal,20)
    }
}

struct NavigationButton<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination
    
    init(title: String, icon: String, color: Color, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.icon = icon
        self.color = color
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            MenuButton(title: title, icon: icon, color: color)
        }
    }
}

private struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var loading: Bool = false
    var warning: Bool = false
    var warningMessage : String = ""
    
    var body: some View {
        VStack{
            HStack {
                
                if loading {
                    Label("Verificando credenciales de Certificado...",systemImage: "progress.indicator")
                        .foregroundColor(.white)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                    
                }
                else{
                    Label(warning ? warningMessage : title, systemImage: icon )
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                    
                    }
                }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(loading ? Color(.gray) : warning ? Color(.amarello) :  color)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            ).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct CompanyDetailsSection: View {
    let company: Company
    
    var body: some View {
        VStack(spacing: 20) {
            infoSection(
                title: "Dirección",
                items: [
                    (label: "Departamento", value: company.departamento),
                    (label: "Municipio", value: company.municipio),
                    (label: "Complemento", value: company.complemento)
                ]
            )
            
            infoSection(
                title: "Información de Negocio",
                items: [
                    (label: "Nombre Comercial", value: company.nombreComercial),
                    (label: "NIT", value: company.nit),
                    (label: "NRC", value: company.nrc),
                    (label: "Actividad", value: company.descActividad),
                    (label: "Código Actividad", value: company.codActividad)
                ]
            )
        }
        .padding(.horizontal)
    }
    
    private func infoSection(title: String, items: [(label: String, value: String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .padding(.bottom, 4)
            
            ForEach(items, id: \.label) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.value)
                        .font(.body)
                }
                .padding(.vertical, 4)
                
                if item.label != items.last?.label {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

#Preview(traits: .sampleCompanies) {
    CompanyDetailsWrapper()
}

private struct CompanyDetailsWrapper: View {
    @Query var companies: [Company]
    @State private var selectedCompanyId: String = ""
    @State private var selectedCompany: Company?
    var body: some View {
        CompanyDetailsView(company: companies.first!,
                           selection: $selectedCompany,
                           selectedCompanyId: $selectedCompanyId)
    }
}

