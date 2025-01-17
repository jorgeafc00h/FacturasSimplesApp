//
//  CertificateUpdate.swift
//  App
//
//  Created by Jorge Flores on 10/21/24.
//

import SwiftUI

struct CertificateUpdate: View {
    
    @State var viewModel = CertificateUpdateViewModel()
    @Environment(\.dismiss)   var dismiss
    var body: some View {
            ZStack {
                Color("Marine").ignoresSafeArea()
                 
                ScrollView{
                    VStack(alignment: .center){
                        Image(systemName: "lock.shield.fill")
                            .resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 118.0, height: 118.0)
                            .foregroundColor(.darkCyan)
                            .padding(.top, 100)
                        
                        EditUserCertificateCredentials
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
            
            Button(action:{ updateCert()}) {
                Text("Actualizar contraseña")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame( maxWidth: .infinity, alignment: .center)
                    .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Dark-Cyan"), lineWidth: 3).shadow(color: .white, radius: 6))
            }.padding(.bottom)
            
        }.padding(.horizontal, 42.0)
    }
    
}



#Preview {
    CertificateUpdate()
}
