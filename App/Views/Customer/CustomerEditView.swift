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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext)   private var modelContext
 
    @State private var departamento : String = ""
    @State private var municipio :String = ""
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-012"})
    private var departamentos : [CatalogOption]
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == "CAT-013"})
    private var municipios : [CatalogOption]

    
    @State private var displayPickerSheet: Bool = false
    @State private var nrc : String = ""
    @State private var nit: String = ""
    
    
    var body: some View {
        CustomerForm {
            Section(header: Text("Cliente")) {
                CustomerGroupBox {
                    TextField("Nombre", text: $customer.firstName)
                    TextField("Apellido", text: $customer.lastName)
                    
                    TextField("NIT" ,text: $customer.nationalId)
                    TextField("Telefono" ,text:  $customer.phone)
                    TextField("Correo", text: $customer.email)
                }
            }
              
            AddressSection(customer: customer,
                           departamentos: departamentos,
                           municipios: municipios,
                           departamento: $departamento,
                           municipio: $municipio)
            
            Section(header: Text("Information del Negocio")) {
            
                     
                CustomerGroupBox {
                    Toggle("Configuracoin de Facturacion", isOn: $customer.hasInvoiceSettings)
                         
                    if customer.hasInvoiceSettings {
                        
                        TextField("Empresa" , text: $customer.company)
                        TextField("NIT" , text:  $nit )
                            .onChange(of: nit){customer.nit = nit}
                        
                        TextField("NRC", text: $nrc)
                            .onChange(of: nrc){ customer.nrc = nrc}
                        
                        Button(customer.descActividad ?? "Actividad Economica"){
                            displayPickerSheet.toggle()
                        }
                    }
                }
            }
        }
        .onAppear{
            InitCollections()
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Editar Cliente" )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar", systemImage: "checkmark") {
                    //SaveUpdate()
                    dismiss()
                }.buttonStyle(BorderlessButtonStyle())
            }
        }.accentColor(.darkCyan)
        .sheet(isPresented: $displayPickerSheet){
            SearchPicker(catalogId: "CAT-019",
                         selection: $customer.codActividad,
                         selectedDescription: $customer.descActividad,
                         showSearch: $displayPickerSheet,
                         title:"Actividad Economica")
        }
        .accentColor(.darkCyan)
        
    
    }
        
    private func SaveUpdate() {
         withAnimation {
             
             if customer.hasInvoiceSettings ||
                    !nrc.isEmpty || !nit.isEmpty{
                 customer.nrc = nrc
                 customer.nit = nit
             }
             
             if modelContext.hasChanges {
                try! modelContext.save()
             }
         }
    }
     
    private func InitCollections(){
        departamento = customer.departamentoCode
        municipio = customer.municipioCode
        nrc = customer.nrc ?? ""
        nit = customer.nit ?? ""
    }
    
}

private struct AddressSection: View {
    
    @Bindable var customer: Customer
    @State var departamentos :[CatalogOption]
    @State var municipios: [CatalogOption]
    @Binding var departamento: String
    @Binding var municipio: String

    var body: some View {
        Section(header: Text("Direccion")) {
            CustomerGroupBox {
                Picker("Departamento",selection: $departamento){
                    ForEach(departamentos,id:\.self){
                       dep in
                        Text(dep.details).tag(dep.code)
                    }
                }.onChange(of: departamento){
                    print("departamento: \(departamento)")
                    customer.departamentoCode = departamento
                     
                    customer.departammento = departamentos.first(where: {$0.code == departamento})!.details
                }.pickerStyle(.navigationLink)
                
                if( !departamento.isEmpty){
                    Picker("Municipio",selection:$municipio){
                        
                        ForEach(municipios.filter{$0.departamento == departamento},id:\.self){
                            munic in
                            Text(munic.details).tag(munic.code)
                        }
                    }
                    .onChange(of:municipio){
                            print("municipio code : \(municipio)")
                        if(!municipio.isEmpty){
                            customer.municipioCode = municipio
                            customer.municipio =
                            municipios.first(where: {$0.departamento == departamento &&  $0.code == municipio})!.details
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                TextField("Direccion" , text: $customer.address)
            }
            
        }
    }
}



#Preview(traits: .sampleCustomers) {
    @Previewable @Query var custs:[Customer]
    @Previewable @Query var options :[CatalogOption]
    CustomerEditView(customer: custs.first!)
}
