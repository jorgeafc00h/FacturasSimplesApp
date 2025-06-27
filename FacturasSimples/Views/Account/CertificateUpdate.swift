//
//  CertificateUpdate.swift
//  App
//
//  Created by Jorge Flores on 10/21/24.
//

import SwiftUI
import SwiftData

struct CertificateUpdate: View {
    
    @Environment(\.modelContext)   var modelContext
    
    @State var viewModel = CertificateUpdateViewModel()
    @Environment(\.dismiss)   var dismiss
    
    @Bindable var company : Company
    
    @Binding var areInvalidCredentials: Bool
    
    var body: some View {
            ZStack {
                Color("Marine").ignoresSafeArea()
                 
                ScrollView{
                    VStack(alignment: .center){
                        Image(systemName: "lock.shield.fill")
                            .resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 55.0, height: 55.0)
                            .foregroundColor(.darkCyan)
                            .padding(.top, 10)
                        
                    
                        EditUserCertificateCredentials
                            .fileImporter(isPresented: $viewModel.isCertificateImporterPresented,
                                          allowedContentTypes:  [.x509Certificate],
                                          allowsMultipleSelection : false,
                                          onCompletion:  importFile)
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
                            .alert(viewModel.message, isPresented: $viewModel.showAlertMessage) {
                                       Button("OK", role: .cancel) {
                                           dismiss()
                                       }
                                   }

                    }
                }
            } 
    }
    
    private var EditUserCertificateCredentials:   some View {
        
        VStack(alignment: .leading){
            
            Text("Actualizar contraseña de cerficado Hacienda (firma de DTE)")
                .foregroundColor(.darkCyan)
                .padding(.top, 50)
            
            
            Text("Contraseña").foregroundColor(.white).padding(.top,25)
            
            
            ZStack(alignment: .leading){
                if viewModel.password.isEmpty { Text("Introduce tu nueva contraseña").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                
                SecureField("", text: $viewModel.password).foregroundColor(.white)
                
            }
            
            Divider()
                .frame(height: 1)
                .background(Color("Dark-Cyan")).padding(.bottom)
            
            Text("Confirmar Contraseña").foregroundColor(.white)
            
            
            ZStack(alignment: .leading){
                if viewModel.confirmPassword.isEmpty { Text("Confirma tu nueva contraseña").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                
                SecureField("", text: $viewModel.confirmPassword).foregroundColor(.white)
                
            }
            
            Divider()
                .frame(height: 1)
                .background(Color("Dark-Cyan")).padding(.bottom,32)
            
            Button(action: updateCertCredentialValidation ){
               UpdatePasswordCertButonLabel
            }.disabled(viewModel.isValidatingCertificateCredentials)
             .padding(.bottom)
             .confirmationDialog(
                 "¿Desea actualizar la  contraseña de el certificado?",
                 isPresented: $viewModel.showConfirmUpdatePassword,
                 titleVisibility: .visible
             ) {
                 Button{
                     viewModel.isValidatingCertificateCredentials = true
                     Task{
                         _ =  await updateCertCredentials()
                         areInvalidCredentials = !viewModel.areValidCredentials
                     }
                 }
                 label: {
                     Text("Guardar Cambios").accentColor(.darkBlue)
                 }
                 
                 Button("Cancelar", role: .cancel) {}
             }
             .frame(maxWidth: .infinity)
             .foregroundColor(.white)
                .alert(viewModel.message, isPresented: $viewModel.showValidationMessage) {
                    Button("OK", role: .cancel){}
                   }
             
                
            Button(action:{ viewModel.isCertificateImporterPresented.toggle() }) {
                SyncCertButonLabel
            }.padding(.bottom)
                .disabled(viewModel.isBusy)
            
        }.padding(.horizontal, 42.0)
    }
        
    private var SyncCertButonLabel: some View {
        VStack{
            if viewModel.isBusy{
                HStack {
                    Label("Actualiando...",systemImage: "progress.indicator")
                  
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                }
            }
            else{
                Text("Actualizar Certificado")
            }
        }.fontWeight(.bold)
            .foregroundColor(.white)
            .frame( maxWidth: .infinity, alignment: .center)
            .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(Color("Dark-Cyan"), lineWidth: 3).shadow(color: .white, radius: 6))
    }
    
    private var UpdatePasswordCertButonLabel: some View {
        VStack{
            if viewModel.isValidatingCertificateCredentials{
                HStack {
                    Label("Verificando Certificado...",systemImage: "progress.indicator")
                  
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                }
            }
            else{
                Text("Actualizar contraseña")
            }
        }.fontWeight(.bold)
            .foregroundColor(.white)
            .frame( maxWidth: .infinity, alignment: .center)
            .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(Color("Dark-Cyan"), lineWidth: 3).shadow(color: .white, radius: 6))
    }
}

 
#Preview (traits: .sampleCompanies){
    CertificateUpdateViewWrapper()
}

struct CertificateUpdateViewWrapper: View {
    @Query var companies: [Company]
   
    var body: some View {
        CertificateUpdate(company: companies.first!,areInvalidCredentials: .constant(false))
    }
}
