/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that adds a new trip.
*/

import SwiftUI
import SwiftData

struct AddCustomerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var company: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    
    @State private var email: String = ""
    
    @State private var phone: String = ""
    @State private var nationalId: String = ""
    @State private var contributorId: String = ""
    @State private var nit: String = ""
    @State private var documentType: String = ""
    @State private var codActividad: String = ""
    @State private var descActividad: String = ""
    @State private var departamentoCode: String = ""
    @State private var municipioCode: String = ""
    @State private var departammento: String = ""
    @State private var municipio: String = ""
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-012"})
    private var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-013"})
    private var municipios : [CatalogOption]
    

    var body: some View {
        CustomerForm {
            Section(header: Text("Cliente")) {
                CustomerGroupBox {
                    TextField("Nombre", text: $firstName)
                    TextField("Apellido", text: $lastName)
                    
                    TextField("DUI", text: $nationalId)
                    TextField("Telefono", text: $phone)
                    TextField("Email", text: $email)
                }
            }
            
            AddressSection(departamentos: departamentos,
                           municipios: municipios,
                           departamentoCode: $departamentoCode,
                           municipioCode: $municipioCode,
                           address: $address)
            
            Section(header: Text("Information del Negocio")) {
                CustomerGroupBox {
                    TextField("Empresa", text: $company)
                }
            }
             
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Nuevo Cliente" )
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar") {
                    addCustomer()
                    //WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
                .disabled(firstName.isEmpty || nationalId.isEmpty)
            }
        }.accentColor(.darkCyan)
    }

    private func addCustomer() {
        withAnimation {
            
            let dp = departamentos.first(where: { $0.code == departamentoCode})!.details
            let mp = municipios.first(where: { $0.code == municipioCode && $0.departamento == departamentoCode})!.details
            
            
            let newCustomer = Customer( firstName: firstName,
                                       lastName: lastName,
                                       nationalId: nationalId,
                                       email: email,
                                       phone: phone,
                                       departammento: dp,
                                       municipio: mp,
                                       address: address,
                                       company: company
                                      )
          
            newCustomer.departamentoCode  = departamentoCode
            newCustomer.municipioCode = municipioCode
            
            
            modelContext.insert(newCustomer)
            try? modelContext.save()
        }
    }
}

private struct AddressSection: View {
    
   
    @State  var departamentos :[CatalogOption]
    @State  var municipios: [CatalogOption]
    @Binding var departamentoCode: String
    @Binding var municipioCode: String
    @Binding var address : String

    var body: some View {
        Section(header: Text("Direccion")) {
            CustomerGroupBox {
                Picker("Departamento",selection: $departamentoCode){
                    ForEach(departamentos,id:\.self){
                       dep in
                        Text(dep.details).tag(dep.code)
                    }
                }.pickerStyle(.menu)
                if( !departamentoCode.isEmpty){
                    Picker("Municipio",selection:$municipioCode){
                        
                        ForEach(municipios.filter{$0.departamento == departamentoCode},id:\.self){
                            munic in
                            Text(munic.details).tag(munic.code)
                        }
                    }.pickerStyle(.menu)
                }
                TextField("Direccion" , text: $address)
            }
            
        }
    }
}



#Preview(traits: .sampleCustomers) {
    AddCustomerView()
}

