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
    
    @Binding var selection : Company?
     
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
                        SelectedCompanyButton(selection: $selection)
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
            
            Button(action:{ updateCert()}) {
                Text("Actualizar contraseña")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame( maxWidth: .infinity, alignment: .center)
                    .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Dark-Cyan"), lineWidth: 3).shadow(color: .white, radius: 6))
            }.padding(.bottom)
                .disabled(viewModel.IsDisabledSaveCertificate)
            
            Button(action:{ viewModel.isCertificateImporterPresented.toggle() }) {
                SyncCertButonLabel
            }.padding(.bottom)
            
        }.padding(.horizontal, 42.0)
    }
        
    private var SyncCertButonLabel: some View {
        VStack{
            if viewModel.isBusy{
                HStack {
                    Image(systemName: "circle.hexagonpath")
                        .symbolEffect(.rotate, options: .repeat(.continuous))
                    Text(" Actualizando.....")
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
}


//#Preview {
//    do {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let container = try ModelContainer(for: Company.self, configurations: config)
//        let example = Company.prewiewCompanies.randomElement()!
//        return CertificateUpdate(company: example)
//            .modelContainer(container)
//    } catch {
//        return Text("Failed to create preview: \(error.localizedDescription)")
//    }
//}
#Preview (traits: .sampleCompanies){
    CertificateUpdateViewWrapper()
}

struct CertificateUpdateViewWrapper: View {
    @State private var selectedCompany: Company? = nil
    @State private var selectedCompanyId: String = ""
    
    var body: some View {
        CertificateUpdate(selection: $selectedCompany)
    }
}
