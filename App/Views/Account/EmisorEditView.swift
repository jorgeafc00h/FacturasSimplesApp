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
    
    
    
    @State var viewModel   = EmisorEditViewModel()
     
    var body: some View {
        NavigationStack {
            EditEmisorForm
        }
    }
    
    
    private var EditEmisorForm: some View {
        Form {
            Section("Información General") {
                TextField("Nombre", text: $viewModel.emisor.nombre)
                TextField("Nombre o Razón Social", text: $viewModel.emisor.nombreComercial)
                TextField("NIT", text: $viewModel.emisor.nit)
                    .keyboardType(.numberPad)
                
                TextField("NRC", text: $viewModel.emisor.nrc)
            }.foregroundColor(.darkCyan)
            
            Section("Dirección") {
                Picker("Departamento",selection: $viewModel.emisor.departamentoCode){
                    ForEach(departamentos,id:\.self){
                        dep in
                        Text(dep.details).tag(dep.code)
                    }
                }
                .onChange(of: viewModel.emisor.departamentoCode){
                    onDepartamentoChange()
                }
                .pickerStyle(.menu)
                
                Picker("Municipio",selection:$viewModel.emisor.municipioCode){
                    ForEach(filteredMunicipios,id:\.self){
                        munic in
                        Text(munic.details).tag(munic.code)
                    }
                }
                .onChange(of: viewModel.emisor.municipioCode){
                    onMunicipioChange()
                }
                .pickerStyle(.menu)
                TextField("Direccion", text: $viewModel.emisor.complemento)
                
            }
            
            Section("Contacto") {
                TextField("Correo Electrónico", text: $viewModel.emisor.correo)
                TextField("Teléfono", text: $viewModel.emisor.telefono)
            }.foregroundColor(.darkCyan)
            
            Section("Actividad Economica") {
                Button(viewModel.emisor.actividadEconomicaLabel){
                    viewModel.displayCategoryPicker.toggle()
                }.foregroundColor(.darkCyan)
                Picker("Tipo Establecimiento",selection: $viewModel.emisor.tipoEstablecimiento){
                    ForEach(tipo_establecimientos,id:\.self){
                        dep in
                        Text(dep.details).tag(dep.code)
                    }
                }.pickerStyle(.menu)
            }.foregroundColor(.darkCyan)
            
            Section("Logo Facturas"){
                Button("Seleccione una imagen"){
                    viewModel.isFileImporterPresented.toggle()
                }.foregroundColor(.darkCyan).padding(.vertical , 20)
                
                if !viewModel.emisor.invoiceLogo.isEmpty {
                    
                    Image(viewModel.emisor.invoiceLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 400)
                        .padding(.bottom, 1.0)
                }
            }
            Section{
                Button(action: saveChanges, label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Guardar Cambios")
                    }
                })
                .disabled(viewModel.isDisabledSaveChanges)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(.darkCyan)
                .cornerRadius(10)
            }.foregroundColor(.darkCyan)
            
        }
        .navigationTitle("Editar Información")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Guardar") {
                    saveChanges()
                }
            }
        }
        .sheet(isPresented: $viewModel.displayCategoryPicker){
            SearchPicker(catalogId: "CAT-019",
                         selection: $viewModel.emisor.codActividad,
                         selectedDescription: $viewModel.emisor.descActividad,
                         showSearch: $viewModel.displayCategoryPicker,
                         title:"Actividad Economica")
        }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.emisor.invoiceLogo = url.path
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .onAppear(perform: loadData)
       
    }
}

#Preview {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Emisor.self, configurations: config)
            let example = Emisor()
            return EmisorEditView()
                .modelContainer(container)
        } catch {
            return Text("Failed to create preview: \(error.localizedDescription)")
        }
}
