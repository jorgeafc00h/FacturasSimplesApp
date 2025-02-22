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
                }.pickerStyle(.wheel)
                    .onChange(of: company.tipoEstablecimiento){
                        onDepartamentoChange()
                }
            }.foregroundColor(.darkCyan)
            
            Section("Logo Facturas"){
                Button("Seleccione una imagen"){
                    viewModel.isFileImporterPresented = true
                    viewModel.isCertificateImporterPresented = false
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
            Section("Certificado Hacienda"){
                
                Button(action: {
                    viewModel.isCertificateImporterPresented = true
                    viewModel.isFileImporterPresented = true
                }){
                    SyncCertButonLabel
                }
                .alert(viewModel.message,isPresented: $viewModel.showAlertMessage){
                    Button("Ok",role:.cancel){}
                }
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
                
                if company.certificatePath != "" {
                    
                    Button(action: {},label: {
                        Image(systemName: "checkmark.circle.fill")
                            .contentTransition(.symbolEffect(.replace))
                    })
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
        .fileImporter(isPresented: $viewModel.isFileImporterPresented,
                      allowedContentTypes: viewModel.isCertificateImporterPresented ?  [.x509Certificate] : [.image],
                      allowsMultipleSelection : false,
                      onCompletion: viewModel.isCertificateImporterPresented ? importFile : importImageLogo)

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
