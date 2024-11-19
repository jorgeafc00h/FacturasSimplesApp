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
    @State var emisor: Emisor  = Emisor()
    @Environment(\.dismiss)   var dismiss
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-012"})
    var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-013"})
    var municipios : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-008"})
    var tipo_establecimientos : [CatalogOption]
    
    @State var viewModel = EmisorEditViewModel()
    
    var body: some View {
        NavigationStack {
            EditEmisorForm
        }
    }
    
    
    private var EditEmisorForm: some View {
        Form {
            Section("Información General") {
                TextField("Nombre", text: $emisor.nombre)
                TextField("Nombre o Razón Social", text: $emisor.nombreComercial)
                TextField("NIT", text: $emisor.nit)
                TextField("NRC", text: $emisor.nrc)
            }.foregroundColor(.darkCyan)
            
            Section("Dirección") {
                Picker("Departamento",selection: $emisor.departamento){
                    ForEach(departamentos,id:\.self){
                        dep in
                        Text(dep.details).tag(dep.code)
                    }
                }.pickerStyle(.menu)
                
                Picker("Municipio",selection:$emisor.municipio){
                    ForEach(filteredMunicipios,id:\.self){
                        munic in
                        Text(munic.details).tag(munic.code)
                    }
                }.pickerStyle(.menu)
                TextField("Direccion", text: $emisor.complemento)
                
            }
            
            Section("Contacto") {
                TextField("Correo Electrónico", text: $emisor.correo)
                TextField("Teléfono", text: $emisor.telefono)
            }.foregroundColor(.darkCyan)
            
            Section("Actividad Economica") {
                Button(emisor.actividadEconomicaLabel){
                    viewModel.displayCategoryPicker.toggle()
                }.foregroundColor(.darkBlue)
                Picker("Tipo Establecimiento",selection: $emisor.tipoEstablecimiento){
                    ForEach(tipo_establecimientos,id:\.self){
                        dep in
                        Text(dep.details).tag(dep.code)
                    }
                }.pickerStyle(.menu)
            }.foregroundColor(.darkCyan)
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
                         selection: $emisor.codActividad,
                         selectedDescription: $emisor.descActividad,
                         showSearch: $viewModel.displayCategoryPicker,
                         title:"Actividad Economica")
        }
       
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Emisor.self, configurations: config)
        let example = Emisor()
        return EmisorEditView(emisor: example)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
