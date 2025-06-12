//
//  EmisorEditView.swift
//  App
//
//  Created by Jorge Flores on 11/18/24.
//

import SwiftUI
import SwiftData

struct EmisorEditView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-012"})
    var departamentos: [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-013"})
    var municipios: [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-008"})
    var tipo_establecimientos: [CatalogOption]
    
    @State var company: Company
    @State var viewModel = CompanyEditViewModel()
    
    @AppStorage("selectedCompanyName")  var selectedCompanyName : String = ""
    
    var body: some View {
        NavigationStack {
            EditEmisorForm
                .background(Color(.systemGroupedBackground))
        }
    }
    
    
    private var EditEmisorForm: some View {
        Form {
            GeneralInformationSection
            AddressSection
            ContactSection
            EconomicActivitySection
            CertificateSection
        }
        .formStyle(.grouped)
        .navigationTitle("Editar Información")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    // Save the changes using the view model
                    Task {
                        await saveChanges()
                    }
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $viewModel.displayCategoryPicker) {
            SearchPicker(
                catalogId: "CAT-019",
                selection: $viewModel.codActividad,
                selectedDescription: $viewModel.desActividad,
                showSearch: $viewModel.displayCategoryPicker,
                title: "Actividad Económica"
            )
        }
        .alert(viewModel.message, isPresented: $viewModel.showAlertMessage) {
            Button("OK", role: .cancel) { }
        }
        .confirmationDialog(
            "¿Desea actualizar el certificado?",
            isPresented: $viewModel.showConfirmSyncSheet,
            titleVisibility: .visible
        ) {
            Button("Guardar Cambios") {
                viewModel.isBusy = true
                Task {
                    _ = await uploadAsync()
                }
            }
            Button("Cancelar", role: .cancel) { }
        }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: viewModel.isCertificateImporterPresented ? [.x509Certificate] : [.image],
            allowsMultipleSelection: false,
            onCompletion: viewModel.isCertificateImporterPresented ? importFile : importImageLogo
        )
        .onAppear {
            loadData()
        }
        .onChange(of: company) {
            loadData()
        }
        .onChange(of: viewModel.codActividad) {
            company.descActividad = viewModel.desActividad ?? ""
            company.codActividad = viewModel.codActividad ?? ""
        }
    }
}

extension EmisorEditView {
    // MARK: - Form Sections
    
    private var GeneralInformationSection: some View {
        Section("Información General") {
            TextField("Nombre", text: $company.nombre)
                 
            TextField("Nombre o Razón Social", text: $company.nombreComercial)
               
            TextField("NIT", text: $company.nit)
                .keyboardType(.numberPad)
            
            TextField("NRC", text: $company.nrc)
                .keyboardType(.numberPad)
        }
    }
    
    private var AddressSection: some View {
        Section("Dirección") {
            Picker("Departamento", selection: $company.departamentoCode) {
                Text("Seleccionar").tag("")
                ForEach(departamentos, id: \.self) { dep in
                    Text(dep.details).tag(dep.code)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: company.departamentoCode) {
                onDepartamentoChange()
            }
            
            Picker("Municipio", selection: $company.municipioCode) {
                Text("Seleccionar").tag("")
                ForEach(filteredMunicipios, id: \.self) { munic in
                    Text(munic.details).tag(munic.code)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: company.municipioCode) {
                onMunicipioChange()
            }
            
            TextField("Dirección", text: $company.complemento)
        }
    }
    
    private var ContactSection: some View {
        Section("Contacto") {
            TextField("Correo Electrónico", text: $company.correo)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Teléfono", text: $company.telefono)
                .keyboardType(.phonePad)
        }
    }
    
    private var EconomicActivitySection: some View {
        Section("Actividad Económica") {
            Button(action: {
                viewModel.displayCategoryPicker.toggle()
            }) {
                HStack {
                    Text(company.actividadEconomicaLabel.isEmpty ? "Seleccionar Actividad Económica" : company.actividadEconomicaLabel)
                        .foregroundColor(company.actividadEconomicaLabel.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            
            Picker("Tipo Establecimiento", selection: $company.tipoEstablecimiento) {
                Text("Seleccionar").tag("")
                ForEach(tipo_establecimientos, id: \.self) { tipo in
                    Text(tipo.details).tag(tipo.code)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: company.tipoEstablecimiento) {
                onTipoEstablecimientoChange()
            }
        }
    }

    private var CertificateSection: some View {
        Section("Certificado Hacienda") {
            Button(action: {
                viewModel.isCertificateImporterPresented = true
                viewModel.isFileImporterPresented = true
            }) {
                HStack {
                    if viewModel.isBusy {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Actualizando...")
                    } else {
                        Image(systemName: "doc.badge.plus")
                        Text("Actualizar Certificado")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .cornerRadius(10)
            }
            .disabled(viewModel.isBusy)
            .buttonStyle(.plain)
            
            if !company.certificatePath.isEmpty {
                Label("Certificado Activo", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
}

extension EmisorEditView {
    // MARK: - Methods
    
    @MainActor
    func saveChanges() async {
        let id = company.id
        
        let descriptor = FetchDescriptor<Company>(predicate: #Predicate { $0.id == id })
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        if count == 0 {
            modelContext.insert(company)
        }
        
        try? modelContext.save()
        
        // Notify that company data has been updated
        NotificationCenter.default.post(name: .companyDataUpdated, object: company)
        selectedCompanyName = company.nombreComercial
        dismiss()
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Company.self, configurations: config)
        let example = Company.prewiewCompanies.randomElement()!
        return EmisorEditView(company: example)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
