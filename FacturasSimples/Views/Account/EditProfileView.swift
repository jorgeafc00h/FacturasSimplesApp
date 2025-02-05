//
//  EditProfileView.swift
//  App
//
//  Created by Jorge Flores on 10/20/24.
//

import SwiftUI

struct EditProfileView: View {
    
    @State var imagenPerfil: Image? = Image("perfilEjemplo")
    @State var isCameraActive = false
    
    @Binding var selection : Company?
    @Environment(\.modelContext)   var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State var viewModel =  EditProfileViewModel()
    var body: some View {
        ZStack {
            Color("Marine").ignoresSafeArea()
            ScrollView{
                    VStack(alignment: .center){
                        
                        Button(action: {isCameraActive = true}, label: {
                            ZStack{
                                
                                imagenPerfil!.resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 118.0, height: 118.0)
                                    .clipShape(Circle())
                                    .sheet(isPresented: $isCameraActive, content: {
//                                    SUImagePickerView(sourceType: .camera , image: self.$imagenPerfil, isPresented: $isCameraActive)
                                })
                                
                                Image(systemName: "camera").foregroundColor(.white)
               
                                
                            }
                        })
                        
                        Text("Elije una foto de perfíl")
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)

                    }.padding(.bottom,18)
                    
                  EditUserCredentials
            }
        }
    }
    
    private var  EditUserCredentials: some View {
      
       VStack(alignment: .leading){
                
                Text("Contraseña").foregroundColor(.white)
                
                
                ZStack(alignment: .leading){
                    if viewModel.password.isEmpty { Text("Introduce tu nueva contraseña").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                    
                    SecureField("", text: $viewModel.password).foregroundColor(.white)
                    
                }
                
                Divider()
                    .frame(height: 1)
                    .background(Color("Dark-Cyan")).padding(.bottom)
                
                Text("Confirmar Contraseña").foregroundColor(.white)
                
                
                ZStack(alignment: .leading){
                    if viewModel.confirmPassword.isEmpty { Text("Introduce tu nueva contraseña").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                    
                    SecureField("", text: $viewModel.confirmPassword).foregroundColor(.white)
                    
                }
                
                Divider()
                    .frame(height: 1)
                    .background(Color("Dark-Cyan")).padding(.bottom,32)
                
           Button(action:{ viewModel.showConfirmDialog.toggle() }) {
               VStack{
                   if viewModel.isBusy{
                       HStack {
                           Label("Actualiando...",systemImage: "progress.indicator")
                               .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                       }
                   }
                   else{
                       Text("Actualiza contraseña")
                   }
               }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame( maxWidth: .infinity, alignment: .center)
                        .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color("Dark-Cyan"), lineWidth: 3).shadow(color: .white, radius: 6))
                }.padding(.bottom)
                
            }
       .padding(.horizontal, 42.0)
       .confirmationDialog(
           "¿Desea actualizar las credenciales de hacienda?",
           isPresented: $viewModel.showConfirmDialog,
           titleVisibility: .visible
       ) {
           Button{
               Task{
                   
                await SaveProfileChanges()
                   
               }
           }
           
           label: {
               Text("Guardar Cambios").foregroundColor(.darkBlue)
           }
           
           Button("Cancelar", role: .cancel) {}
       }
       .frame(maxWidth: .infinity)
       
       .padding()
       .cornerRadius(10)
       .alert(viewModel.message, isPresented: $viewModel.showAlertMessage) {
                  Button("OK", role: .cancel) {
                       //dismiss()
                  }
              }
    }

}






#Preview (traits: .sampleCompanies){
    EditProfileViewWrapper()
}

private struct EditProfileViewWrapper: View {
   @State private var selectedCompany: Company? = nil
   @State private var selectedCompanyId: String = ""
   
   var body: some View {
       EditProfileView(selection: $selectedCompany)
   }
}
