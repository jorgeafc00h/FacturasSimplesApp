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
            }.foregroundColor(.darkCyan)
            
            Section("Dirección") {
                Picker("Departamento",selection: $company.departamentoCode){
                    ForEach(departamentos,id:\.self){
                        dep in
                        Text(dep.details).tag(dep.code)
                    }
                }
                .onChange(of: company.departamentoCode){
                    onDepartamentoChange()
                }
                .pickerStyle(.menu)
                
                Picker("Municipio",selection: $company.municipioCode){
                    ForEach(filteredMunicipios,id:\.self){
                        munic in
                        Text(munic.details).tag(munic.code)
                    }
                }
                .onChange(of: company.municipioCode){
                    onMunicipioChange()
                }
                .pickerStyle(.menu)
                TextField("Direccion", text: $company.complemento)
                
            }
            
            Section("Contacto") {
                TextField("Correo Electrónico", text: $company.correo)
                TextField("Teléfono", text: $company.telefono)
            }.foregroundColor(.darkCyan)
            
            Section("Actividad Economica") {
                Button(company.actividadEconomicaLabel){
                    viewModel.displayCategoryPicker.toggle()
                }.foregroundColor(.darkCyan)
                Picker("Tipo Establecimiento",selection: $company.tipoEstablecimiento){
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
                
                if !company.invoiceLogo.isEmpty {
                    if let data = Data(base64Encoded: company.invoiceLogo), let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400)
                            .padding(.bottom, 1.0)
                    } else {
                        let _ = print("FAIL")
                    }
                    
                }
                
            }
            Section("Dimensión Logo en pixeles") {
                 
          
            HStack{
                Label("Ancho Logo", systemImage: "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right.fill")
                TextField("Ancho", value: $company.logoWidht, format: .number)
            }
            HStack{
                Label("Alto Logo", systemImage: "arrow.trianglehead.up.and.down.righttriangle.up.righttriangle.down.fill")
                TextField("Ancho", value: $company.logoHeight, format: .number)
            }
            }.foregroundColor(.darkCyan)
            Section{
                Button(action: saveChanges, label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Guardar Cambios")
                    }
                })
                //.disabled(viewModel.isDisabledSaveChanges)
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
                         selection: $viewModel.codActividad,
                         selectedDescription: $viewModel.desActividad,
                         showSearch: $viewModel.displayCategoryPicker,
                         title:"Actividad Economica")
        }
        
        .onAppear {
            loadData()
        }
        .onChange(of: company){
            loadData()
        }
        .onChange(of: viewModel.codActividad){
            company.descActividad = viewModel.desActividad ?? ""
            company.codActividad = viewModel.codActividad ?? ""
        }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // get image as string base64
                        print("url \(url)")
                    
                    do {
                        let imageData = try Data(contentsOf: url)
                        let stringBase64 = imageData.base64EncodedString()
                        print("image path \(url.path)")
                        print("image base64 \(stringBase64)")
                        company.invoiceLogo = stringBase64

                        // Copy file to app storage
//                        let fileManager = FileManager.default
//                        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//                        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
//
//                        do {
//                            if fileManager.fileExists(atPath: destinationURL.path) {
//                                try fileManager.removeItem(at: destinationURL)
//                            }
//                            try fileManager.copyItem(at: url, to: destinationURL)
//                            print("File copied to \(destinationURL.path)")
//                        } catch {
//                            print("Error copying file: \(error.localizedDescription)")
//                        }
                    } catch {
                        print("Error creating imageData: \(error.localizedDescription)")
                    }
                    
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        
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
