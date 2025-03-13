//
//  EmisorEditView.swift
//  App
//
//  Created by Jorge Flores on 11/18/24.
//

import SwiftUI
import SwiftData

struct EmisorEditView: View {
    @Environment(\.modelContext)   var modelContext
    
    @Environment(\.dismiss)   var dismiss
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-012"})
    var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-013"})
    var municipios : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-008"})
    var tipo_establecimientos : [CatalogOption]
    
    @State var company : Company
    
    @State var viewModel   = CompanyEditViewModel()
    
    var body: some View {
        NavigationStack {
            EditEmisorForm
        }
    }
    
    
    private var EditEmisorForm: some View {
        Form {
            Section("Información General") {
                TextField("Nombre", text: $company.nombre)
                TextField("Nombre o Razón Social", text: $company.nombreComercial)
                TextField("NIT", text: $company.nit)
                    .keyboardType(.numberPad)
                TextField("NRC", text: $company.nrc)
            }
            
            Section("Dirección") {
                Picker("Departamento", selection: $company.departamentoCode) {
                    ForEach(departamentos, id: \.self) { dep in
                        Text(dep.details).tag(dep.code)
                    }
                }
                .onChange(of: company.departamentoCode) {
                    onDepartamentoChange()
                }
                
                Picker("Municipio", selection: $company.municipioCode) {
                    ForEach(filteredMunicipios, id: \.self) { munic in
                        Text(munic.details).tag(munic.code)
                    }
                }
                .onChange(of: company.municipioCode) {
                    onMunicipioChange()
                }
                
                TextField("Dirección", text: $company.complemento)
            }
            
            Section("Contacto") {
                TextField("Correo Electrónico", text: $company.correo)
                    .keyboardType(.emailAddress)
                TextField("Teléfono", text: $company.telefono)
                    .keyboardType(.phonePad)
            }
            
            Section("Actividad Económica") {
                Button(company.actividadEconomicaLabel) {
                    viewModel.displayCategoryPicker.toggle()
                }
                
                Picker("Tipo Establecimiento", selection: $company.tipoEstablecimiento) {
                    ForEach(tipo_establecimientos, id: \.self) { dep in
                        Text(dep.details).tag(dep.code)
                    }
                }
                .onChange(of: company.tipoEstablecimiento) {
                    onDepartamentoChange()
                }
            }

            Section("Certificado Hacienda") {
                Button(action: {
                    viewModel.isCertificateImporterPresented = true
                    viewModel.isFileImporterPresented = true
                }) {
                    HStack {
                        if viewModel.isBusy {
                            ProgressView()
                                .tint(.darkCyan)
                            Text("Actualizando...")
                        } else {
                            Text("Actualizar Certificado")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.darkCyan)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.darkCyan, lineWidth: 2)
                    )
                }
                .disabled(viewModel.isBusy)
                
                if company.certificatePath != "" {
                    Label("Certificado Activo", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .scrollContentBackground(.hidden)
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
                    saveChanges()
                }
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
            Button("Ok", role: .cancel) { }
        }
        .confirmationDialog(
            "¿Desea actualizar el certificado?",
            isPresented: $viewModel.showConfirmSyncSheet,
            titleVisibility: .visible
        ) {
            Button {
                viewModel.isBusy = true
                Task {
                    _ = await uploadAsync()
                }
            } label: {
                Text("Guardar Cambios")
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
    
    private var SyncCertButonLabel: some View {
        VStack{
            if viewModel.isBusy{
                HStack {
                    Image(systemName: "circle.hexagonpath")
                        .symbolEffect(.rotate, options: .repeat(.continuous))
                    Text(" Actualizando.....")
                }
            }
            else{
                Text("Actualizar Certificado")
                    .foregroundColor(.darkCyan)
                    
            }
        }.fontWeight(.bold)
            .foregroundColor(.blueGray)
            .frame( maxWidth: .infinity, alignment: .center)
            .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(Color("Dark-Cyan"), lineWidth: 3).shadow(color: .white, radius: 6))
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
