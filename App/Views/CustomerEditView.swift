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
 
    var body: some View {
        CustomerForm {
            Section(header: Text("Cliente")) {
                TripGroupBox {
                    TextField("Nombre", text: $customer.firstName)
                    TextField("Apellido", text: $customer.lastName)
                    
                    TextField("NIT" ,text: $customer.nationalId)
                    TextField("Telefono" ,text:  $customer.phone)
                    TextField("Correo", text: $customer.email)
                }
            }
            
            Section(header: Text("Direccion")) {
                TripGroupBox {
                    TextField("Departamento" ,text: $customer.departammento)
                    TextField("Municipio" ,  text: $customer.municipio)
                    TextField("Direccion" , text: $customer.address)
                }
            }
            
            Section(header: Text("Information del Negocio")) {
                TripGroupBox {
                    TextField("Empresa" , text: $customer.company)
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Editar Cliente" )
        
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar") {
                    //SaveUpdate()
                    dismiss()
                }
            }
        }.accentColor(.darkCyan)
    }
    
    private func SaveUpdate() {
         withAnimation {
             
             if modelContext.hasChanges {
                try! modelContext.save()
             }
         }
    }
}

#Preview(traits: .sampleCustomers) {
    @Previewable @Query var custs:[Customer]
    CustomerEditView(customer: custs.first!)
}
