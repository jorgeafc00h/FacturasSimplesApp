//
//  CustomerDetailView.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//

import SwiftUI
import SwiftData

struct CustomerDetailView: View {
    
    var customer : Customer
    
    var body: some View {List {
            CustomerViewForiOS()
        }
        .navigationTitle(Text("Cliente"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CustomerEditView(customer: customer)
                } label: {
                    Image(systemName: "pencil.line")
                        .symbolEffect(.bounce, options: .nonRepeating)
                }
            }
        }
    }
    
    
    @ViewBuilder
    private func CustomerViewForiOS() -> some View {
        
        VStack(alignment: .leading) {
            Section{
                Image(systemName: "person.circle").resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
            Text(customer.fullName)
                .font(.title)
                .bold()
            
            HStack {
                Text("Teléfono")
                Spacer()
                Text(customer.phone)
            }
            HStack {
                Text("DUI")
                Spacer()
                Text(customer.nationalId)
            }
            HStack {
                Text("Email")
                Spacer()
                Text(customer.email)
            }
            
        }
        NavigationLink {
            CustomerEditView(customer: customer)
        } label: {
            HStack{
                Image(systemName: "pencil.line")
                    .symbolEffect(.breathe, options: .nonRepeating)
                Text("Actualizar datos")
            }.foregroundColor(.darkCyan)
        }
        
        Section {
            VStack(alignment: .leading) {
                Text(customer.departamento)
                    .font(.title)
                    .bold()
                Text(customer.municipio)
                Text(customer.address)
            }
            
        } header: {
            Text("Dirección")
        }
        
        Section {
            VStack(alignment: .leading) {
                Text(customer.company)
                    .font(.title)
                    .bold()
                HStack {
                    Text("NIT")
                    Spacer()
                    Text(customer.nit)
                }
                HStack {
                    Text("NRC")
                    Spacer()
                    Text(customer.nrc)
                }
                Text("Actividad Económica")
                VStack {
                     
                    Text(customer.descActividad ?? "N/A")
                        .font(.subheadline)
                        .bold()
                }.padding()
                HStack {
                    Text("Cod Actividad").font(.caption)
                    Spacer()
                    Text(customer.codActividad ?? "N/A").font(.caption)
                }
            }
            
        } header: {
            Text("Información de Negocio")
        }
        
        
    }
}
#Preview(traits: .sampleCustomers) {
    @Previewable @Query var customers: [Customer]
    CustomerDetailView(customer: customers.first!)
}
