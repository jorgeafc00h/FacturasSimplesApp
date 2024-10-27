//
//  ProfileView.swift
//  App
//
//  Created by Jorge Flores on 10/20/24.
//

import SwiftUI

struct ProfileView: View {
    
    
    @State var nombreUsuario:String = "Joe Cool"
    @State var imagenPerfil:UIImage = UIImage(named: "perfilEjemplo")!
    
    
    var body: some View {
        
        
        ZStack {
            
            Color("Marine").ignoresSafeArea().navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
            
            VStack{
                
                VStack{
                    
                    Image(uiImage: imagenPerfil ).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 180.0, height: 180.0)
                        .clipShape(Circle())
                    Text(nombreUsuario)
                        .fontWeight(.bold)
                        .foregroundColor(Color.white)
                    
                    
                }.padding(EdgeInsets(top: 64, leading: 0, bottom: 32, trailing: 0))
                
                
                Text("Configuracion")
                    .fontWeight(.bold)
                    .foregroundColor(Color.white).frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,  alignment: .leading).padding(.leading,18)
                
                
                Settings()
                
                Spacer()
            }
            
            
        } .onAppear(
            
            perform: {
                
                //validar cuando no hay foto guardada
                
                
                
                if returnUiImage(named: "fotoperfil") != nil {
                    
                    imagenPerfil = returnUiImage(named: "fotoperfil")!
                    
                }else{
                    print("no profile picture available")
                    
                }
                
                
                
                
                print("check user defaults..")
                
                if UserDefaults.standard.object(forKey: "datosUsuario") != nil {
                    
                    nombreUsuario = UserDefaults.standard.stringArray(forKey: "datosUsuario")![2]
                    print("UserName-> \(nombreUsuario)")
                }else{
                    
                    print("user not found")
                    
                }
                
            }
            
            
        )
        
    }
    
    
    func returnUiImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    
    
}


struct Settings:View {
    
    @State var isToggleOn = true
    @State var isEditProfileViewActive = false
    
    var body: some View{
        
        
        VStack{
            
            Button(action: {}, label: {
                HStack { Text("Perfil Hacienda")
                        .foregroundColor(Color.white)
                    Spacer()
                    Text(">")
                    .foregroundColor(Color.white)}.padding()
            }) .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
            
            Button(action: {}, label: {
                HStack { Text("Notificaciones")
                        .foregroundColor(Color.white)
                    Spacer()
                    
                    Toggle("", isOn: $isToggleOn)
                    
                }.padding()
            }) .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
            
            Button(action: {isEditProfileViewActive = true}, label: {
                HStack { Text("Usuario y contraseña")
                        .foregroundColor(Color.white)
                    Spacer()
                    Text(">")
                    .foregroundColor(Color.white)}.padding()
            }) .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
            
            
            Button(action: {}, label: {
                HStack { Text("Actualizar Contraseña Cerficado")
                        .foregroundColor(Color.white)
                    Spacer()
                    Text(">")
                    .foregroundColor(Color.white)}.padding()
            }) .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
            
            NavigationLink(""){}
                .navigationDestination(isPresented: $isEditProfileViewActive){
                    EditProfileView()
                }
            
            //            NavigationLink(
            //                destination: EditProfileView()
            //                ,
            //                isActive: $isEditProfileViewActive,
            //                label: {
            //                    EmptyView()
            //                })
            
        }
        
        
    }
}

 

struct ProfileOption: Hashable {
    
    let Label:String
    let color: Color
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
