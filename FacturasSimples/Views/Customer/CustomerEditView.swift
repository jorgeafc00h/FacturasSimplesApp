//
//  CustomerEditView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct CustomerEditView: View {
    
    @Bindable var customer: Customer
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-012"})
    var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog?.id == "CAT-013"})
    var municipios : [CatalogOption]
      
    @State var viewModel = CustomerEditViewModel()
    
    
    var filteredMunicipios : [CatalogOption] {
        if viewModel.departamento.isEmpty {
             return []
        }
        
        return municipios.filter( {$0.departamento  == viewModel.departamento})
    }
    var body: some View {
        CustomerForm {
            Section(header: Text("Cliente")) {
                CustomerGroupBox {
                    TextField("Nombre", text: $customer.firstName)
                    TextField("Apellido", text: $customer.lastName)
                    
                    TextField("DUI" ,text: $customer.nationalId)
                        .keyboardType(.numberPad)
                    TextField("Teléfono" ,text:  $customer.phone)
                        .keyboardType(.phonePad)
                    TextField("Correo", text: $customer.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }
            }
            
            AddressSection
            
            Section(header: Text("Information del Negocio")) {
                
                
                CustomerGroupBox {
                    Toggle("Configuracion de Facturación", isOn: $customer.hasInvoiceSettings)
                    if customer.hasInvoiceSettings {
                        
                        TextField("Empresa" , text: $customer.company)
                        TextField("NIT" , text:  $viewModel.nit )
                            .onChange(of: viewModel.nit){customer.nit = viewModel.nit}
                        
                        TextField("NRC", text: $viewModel.nrc)
                            .onChange(of: viewModel.nrc){ customer.nrc = viewModel.nrc}
                        
                        Button(customer.descActividad ?? "Actividad Económica"){
                            viewModel.displayPickerSheet.toggle()
                        }
                        Toggle("Gran Contributente",isOn: $customer.hasContributorRetention)
                        
                        if customer.hasContributorRetention{
                            Text("La categoría de gran contribuyente en el Ministerio de Hacienda es requerida")
                        }
                    }
                }
            }
        }
        .onAppear{
            InitCollections()
        }
        .navigationTitle("Editar Cliente" )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar", systemImage: "checkmark") {
                    SaveUpdate()
                    dismiss()
                }.buttonStyle(BorderlessButtonStyle())
            }
        }
        .accentColor(.darkCyan)
        .sheet(isPresented: $viewModel.displayPickerSheet){
                SearchPicker(catalogId: "CAT-019",
                             selection: $customer.codActividad,
                             selectedDescription: $customer.descActividad,
                             showSearch: $viewModel.displayPickerSheet,
                             title:"Actividad Económica")
        }
        .accentColor(.darkCyan)
        
        
    }
    
    private var AddressSection: some View {
        
        Section(header: Text("Dirección")) {
                CustomerGroupBox {
                    Picker("Departamento",selection: $viewModel.departamento){
                        ForEach(departamentos,id:\.self){
                            dep in
                            Text(dep.details).tag(dep.code)
                        }
                    }.onChange(of: viewModel.departamento){
                        onDepartamentoChange()
                    }
                    
                    Picker("Municipio",selection:$viewModel.municipio){
                        
                        ForEach(filteredMunicipios,id:\.self){
                            munic in
                            Text(munic.details).tag(munic.code)
                        }
                    }
                    .onChange(of:viewModel.municipio){
                        onMunicipioChange()
                    }
                    
                    
                    TextField("Dirección" , text: $customer.address)
                }
                
            }
        
    }
    
}





#Preview(traits: .sampleCustomers) {
    @Previewable @Query var custs:[Customer]
    @Previewable @Query var options :[CatalogOption]
    CustomerEditView(customer: custs.first!)
}
