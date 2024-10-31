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

    @State var imagenPerfil:UIImage = UIImage(named: "perfilEjemplo")!
    var body: some View {
        VStack{
            
            Image(uiImage: imagenPerfil ).resizable().aspectRatio(contentMode: .fill)
                .frame(width: 76, height: 76)
                .clipShape(Circle())
            
            
        }.background(.clear)//.padding(EdgeInsets(top: 0, leading: , bottom: 32, trailing: 0))
        List {
            
            CustomerViewForiOS()
            
        }
        .navigationTitle(Text("Cliente"))
    }
   
    
    @ViewBuilder
    private func CustomerViewForiOS() -> some View {
       
        VStack(alignment: .leading) {
            Text(customer.fullName)
                .font(.title)
                .bold()
           
            HStack {
                Text("Telefono")
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
            Text("Actualizar datos")
        }
        
        Section {
            VStack(alignment: .leading) {
                Text(customer.departammento)
                    .font(.title)
                    .bold()
                Text(customer.municipio)
                Text(customer.address)
            }
             
        } header: {
            Text("Direccion")
        }
        
        
    }
}
#Preview(traits: .sampleCustomers) {
    @Previewable @Query var customers: [Customer]
    CustomerDetailView(customer: customers.first!)
}
