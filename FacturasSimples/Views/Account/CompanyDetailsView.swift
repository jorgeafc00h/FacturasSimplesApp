import SwiftUI
import SwiftData

struct CompanyDetailsView : View {
    @Bindable var company: Company
    @Binding var selectedCompanyId: String 
    @State var viewModel = CompanyDetailsViewModel()
    @AppStorage("selectedCompanyIdentifier") var companyId: String = "" {
        didSet {
            selectedCompanyId = companyId
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) { // Increased from 20 for better section separation
                CompanyTopFrame
                
                VStack(spacing: 12) { // Reduced from 16 for tighter button grouping
                    CompanyTabs
                }
                .padding(.horizontal)
                
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
                RequestProductionAccessView().interactiveDismissDisabled()
            }
        }
        .sheet(isPresented: $viewModel.showEditCredentialsSheet) {
            EditProfileView(selection: .constant(company))
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
    }
    
    private var CompanyTabs: some View {
        VStack(spacing: 12) {
            NavigationButton(
                title: "Editar Datos de Empresa",
                icon: "pencil.line",
                color: .darkCyan.opacity(0.95)
            ) {
                EmisorEditView(company: company)
            }
            
            NavigationButton(
                title: "Credenciales de Certificado",
                icon: "lock.fill",
                color: .darkCyan.opacity(0.95)
            ) {
//                CertificateUpdate(selection: Binding(
//                    get: { company },
//                    set: { _ in }
//                ))
            }
            
            Button(action: {
                viewModel.showEditCredentialsSheet.toggle()
            }) {
                MenuButton(
                    title: "Credenciales Hacienda",
                    icon: "key.fill",
                    color:
                        (company.isTestAccount ?
                        Color( .amarello):
                        Color(.green).opacity(0.95))
                )
            }
            
            Button(action: {
                viewModel.showRequestProductionAccessSheet.toggle()
            }) {
                MenuButton(
                    title: "Solicitar Autorización Productiva",
                    icon: "checkmark.seal.fill",
                    color: (company.isTestAccount ?
                            Color( .amarello):
                            Color(.green).opacity(0.95))
                )
            }
            
            Button(action: {
                viewModel.showLogoEditorSheet = true
            }) {
                MenuButton(
                    title: "Editar Logo de Facturas",
                    icon: "photo.on.rectangle",
                    color: .darkCyan.opacity(0.95)
                )
            }
        }
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

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(color)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    
    var body: some View {
        CompanyDetailsView(company: companies.first!, selectedCompanyId: $selectedCompanyId)
    }
}

