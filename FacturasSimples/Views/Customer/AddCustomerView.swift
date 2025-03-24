/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 A SwiftUI view that adds a new trip.
 */

import SwiftUI
import SwiftData

struct AddCustomerView: View {
    @Environment(\.modelContext)  var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    
    
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-012"})
    var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-013"})
    var municipios : [CatalogOption]
    
    @AppStorage("selectedCompanyIdentifier")  var selectedCompanyId : String = ""
    
    @State var viewModel = AddCustomerViewModel()
    
    var body: some View {
        CustomerForm {
            Section(header: Text("Cliente")) {
                Group {
                    TextField("Nombre", text: $viewModel.firstName)
                    TextField("Apellido", text: $viewModel.lastName)
                   
                    TextField("DUI", text: $viewModel.nationalId)
                        .keyboardType(.numberPad)
                    TextField("Teléfono", text: $viewModel.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }
            }
            
            AddressSection(departamentos: departamentos,
                           municipios: municipios,
                           departamentoCode: $viewModel.departamentoCode,
                           municipioCode: $viewModel.municipioCode,
                           address: $viewModel.address)
            
            Section(header: Text("Information del Negocio")) {
                CustomerGroupBox {
                    
                    Toggle("Configuracion de Facturación", isOn: $viewModel.hasInvoiceSettings)
                    
                    if viewModel.hasInvoiceSettings {
                        
                        TextField("Empresa" , text: $viewModel.company)
                        TextField("NIT" , text:  $viewModel.nit )
                            .keyboardType(.numberPad)
                        TextField("NRC", text: $viewModel.nrc)
                            .keyboardType(.numberPad)
                        
                        Button(viewModel.ActividadLabel){
                            viewModel.displayPickerSheet.toggle()
                        }
                        
                        Toggle("Gran Contributente",isOn: $viewModel.hasContributorRetention)
                        
                        if viewModel.hasContributorRetention{
                            Text("La categoría de gran contribuyente en el Ministerio de Hacienda es requerida")
                        }
                    }
                }
            }
            
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Nuevo Cliente" )
        .navigationBarTitleDisplayMode(.automatic)
        .sheet(isPresented: $viewModel.displayPickerSheet){
            SearchPicker(catalogId: "CAT-019",
                         selection: $viewModel.codActividad,
                         selectedDescription: $viewModel.descActividad,
                         showSearch: $viewModel.displayPickerSheet,
                         title:"Actividad Económica")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar",action:{viewModel.showConfirmCancel.toggle()})
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar") {
                    addCustomer()
                    //WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
                .disabled(viewModel.isSaveCustomerDisabled)
            }
        }
        .confirmationDialog(
            "¿Esta seguro , todos los cambios no guardados se perderan?",
            isPresented: $viewModel.showConfirmCancel,
            titleVisibility: .visible
        ) {
            Button("Ok Cerrar!",action: {dismiss()})
            
            Button("Cancelar", role: .cancel) {}
        }.accentColor(.darkCyan)
    }
}
 

private struct AddressSection: View {
    
    
    @State  var departamentos :[CatalogOption]
    @State  var municipios: [CatalogOption]
    @Binding var departamentoCode: String
    @Binding var municipioCode: String
    @Binding var address : String
    
    var filteredMunicipios: [CatalogOption] {
        return departamentoCode.isEmpty ?
        municipios :
        municipios.filter{$0.departamento == departamentoCode}
    }
    
    var body: some View {
        Section(header: Text("Dirección")) {
            CustomerGroupBox {
                Picker("Departamento",selection: $departamentoCode){
                    ForEach(departamentos,id:\.self){
                        dep in
                        Text(dep.details).tag(dep.code)
                    }
                }.pickerStyle(.menu)
                
                Picker("Municipio",selection:$municipioCode){
                    ForEach(filteredMunicipios,id:\.self){
                        munic in
                        Text(munic.details).tag(munic.code)
                    }
                }.pickerStyle(.menu)
                
                TextField("Dirección" , text: $address)
            }
            
        }
    }
}



#Preview(traits: .sampleOptions) {
    AddCustomerView()
}

