//
//  CustomerEditView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct CustomerEditView: View {
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
    
    var customer : Customer
    
    var body: some View {
        CustomerForm {
            Section(header: Text("Cliente")) {
                TripGroupBox {
                    TextField(customer.firstName.isEmpty ? "Nombre" : customer.firstName, text: $firstName)
                    TextField(customer.lastName.isEmpty ? "Apellido" : customer.lastName, text: $lastName)
                    
                    TextField(customer.nationalId.isEmpty ? "NIT" : customer.nationalId, text: $nationalId)
                    TextField(customer.phone.isEmpty ? "Telefono" : customer.phone, text: $phone)
                    TextField(customer.email.isEmpty ? "Correo" : customer.email, text: $email)
                }
            }
            
            Section(header: Text("Direccion")) {
                TripGroupBox {
                    TextField(customer.departammento.isEmpty ? "Departamento" : customer.departammento , text: $departammento)
                    TextField(customer.municipio.isEmpty ? "Municipio" : customer.municipio, text: $municipio)
                    TextField(customer.address.isEmpty ? "Direccion" : customer.address,text: $address)
                }
            }
            
            Section(header: Text("Information del Negocio")) {
                TripGroupBox {
                    TextField(customer.company.isEmpty ? "Empresa" : customer.company, text: $company)
                }
            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Editar Cliente" )
        .onAppear {
            firstName = customer.firstName
            lastName = customer.lastName
            departammento = customer.departammento
            municipio = customer.municipio
            address = customer.address
            company = customer.company
            nationalId = customer.nationalId
            email = customer.email
            phone = customer.phone
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar") {
                    SaveUpdate()
                    dismiss()
                }
            }
        }.accentColor(.darkCyan)
    }
    
    private func SaveUpdate() {
        withAnimation {
            
            customer.firstName = firstName
            customer.lastName = lastName
            customer.departammento = departammento
            customer.municipio = municipio
            customer.address = address
            customer.company = company
            customer.nationalId = nationalId
            customer.email = email
            customer.phone = phone
            
            
            if modelContext.hasChanges {
                try! modelContext.save()
            }
        }
    }
    
    private func CancelUpdate() {
        withAnimation {
            //let newTrip = Trip(name: name, destination: destination, startDate: startDate, endDate:
            //modelContext.insert(newTrip)
            
            if modelContext.hasChanges {
                modelContext.rollback()
            }
        }
    }
}

#Preview(traits: .sampleCustomers) {
    @Previewable @Query var custs:[Customer]
    CustomerEditView(customer: custs.first!)
}
