//
//  ContentView.swift
//  App
//
//  Created by Jorge Flores on 10/13/24.
//

import SwiftUI

import AuthenticationServices


struct LoginView: View {
    
    @Binding var isAuthenticated:Bool
    
    @State var tipoInicioSesion:Bool = true
    
    init(isAuthenticated:Binding<Bool>)
    {
        _isAuthenticated = isAuthenticated
    }
    
    var body: some View {
        ZStack{
            Color(red: 18/255, green: 31/255, blue: 61/255, opacity: 100).ignoresSafeArea()
            
            VStack{
                Spacer()
                Image("AppLogo").resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 400)
                    .padding(.bottom, 1.0)
                Text("Facturas Simples")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom,10)
                Spacer()
                VStack{
                    
                    HStack{
                        
                        Spacer()
                        
                        Button("INICIAR SESIÓN"){
                            tipoInicioSesion = true
                        }
                        .foregroundColor(tipoInicioSesion ? .white : .gray)
                        Spacer()
                        
                        Button("REGÍSTRATE"){
                            tipoInicioSesion = false
                        }
                        .foregroundColor(tipoInicioSesion ? .gray : .white)
                        Spacer()
                    }
                    
                    
                    Spacer(minLength: 42)
                    
                    
                    if(tipoInicioSesion){
                        LoginSectionView(isAuthenticated: $isAuthenticated)
                    }else{
                        RegistroView()
                    }
                    
                }
                
            }
            
        }
    }
}



struct LoginSectionView: View {
    
    @State var userEmail:String = ""
    @State var userName: String = ""
    @State var contraseña:String = ""
    @State var accountId: String = ""
    @Binding var isAuthenticated:Bool
    
    init(isAuthenticated:Binding<Bool>){
        _isAuthenticated = isAuthenticated
    }
     
    var body: some View {
        
        
        ScrollView{
            
            VStack(alignment: .leading){
                
                Text("Correo electrónico")
                    .foregroundColor(Color("Marine"))
                
                ZStack(alignment: .leading){
                    if userEmail.isEmpty { Text("ejemplo@gmail.com").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                    
                    TextField("", text: $userEmail).foregroundColor(.white)
                }
                
                Divider()
                    .frame(height: 2)
                    .background(Color("Dark-Cyan")).padding(.bottom)
                
                
                Text("Contraseña").foregroundColor(.white)
                
                
                ZStack(alignment: .leading){
                    if contraseña.isEmpty { Text("Escribe tu contraseña").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                    
                    SecureField("", text: $contraseña).foregroundColor(.white)
                    
                }
                
                Divider()
                    .frame(height: 1)
                    .background(Color("Dark-Cyan"))
                
                Text("¿Olvidaste tu contraseña?")
                    .font(.footnote)
                    .frame(width: 300,  alignment: .trailing)
                    .foregroundColor(Color("Dark-Cyan"))
                    .padding(.bottom)
                
                Button(action: iniciarSesion) {
                    Text("Iniciar Sesión")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame( maxWidth: .infinity, alignment: .center)
                        .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("Dark-Cyan"), lineWidth: 3).shadow(color: .white, radius: 6))
                }.padding(.bottom)
                
                SignInWithAppleButton(.signIn){ request in
                    onRequest(request)
                       } onCompletion: { result in
                           switch result {
                           case .success(let authorization):
                                handleSuccessfulLogin(with: authorization)
                           case .failure(let error):
                               handleLoginError(with: error)
                           }
                       }
                // black button
                    .signInWithAppleButtonStyle(.black)
                    .frame( maxWidth: .infinity,minHeight: 50, alignment: .center)
                
                
                
            }
            .padding(.horizontal, 42.0)
            .task {
                await Authorize()
            }
            
            
        }
    }
     
    @AppStorage("storedName")   var storedName : String = ""{
        didSet{
            userName = storedName
        }
    }
    @AppStorage("storedEmail")   var storedEmail : String = ""{
        didSet{
            userEmail = storedEmail
        }
    }
    @AppStorage("userID")  var userID : String = ""{
        didSet{
            accountId = userID
        }
    }
}

struct RegistroView: View {
    
    @State var correo:String = ""
    @State var contraseña:String = ""
    @State var confirmacionContraseña:String = ""
    
    
    var body: some View {
        
        
        ScrollView{
            
            VStack(alignment: .leading){
                
                VStack{
                    
                    Text("Correo electrónico")
                        .foregroundColor(Color(red: 63/255, green: 202/255, blue: 160/255, opacity: 1.0))
                    
                    ZStack(alignment: .leading){
                        if correo.isEmpty { Text("ejemplo@gmail.com").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                        
                        TextField("", text: $correo).foregroundColor(.white)
                    }
                    
                    Divider()
                        .frame(height: 1)
                        .background(Color("Dark-Cyan")).padding(.bottom)
                    
                    Text("Contraseña").foregroundColor(.white)
                    
                    ZStack(alignment: .leading){
                        if contraseña.isEmpty {
                            Text("Introduce tu contraseña").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                        
                        SecureField("", text: $contraseña).foregroundColor(.white)
                        
                    }
                    
                    Divider()
                        .frame(height: 1)
                        .background(Color("Dark-Cyan"))
                    
                    Text("Confirmar contraseña*").foregroundColor(.white)
                    
                    
                    ZStack(alignment: .leading){
                        if confirmacionContraseña.isEmpty { Text("Reintroduce tu contraseña").font(.caption).foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                        
                        SecureField("", text: $confirmacionContraseña).foregroundColor(.white)
                        
                    }
                    
                    Divider()
                        .frame(height: 1)
                        .background(Color("Dark-Cyan"))
                        .padding(.bottom)
                    
                    
                }
                
                
                Button(action: registrarse) {
                    
                    Text("REGÍSTRATE")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame( maxWidth: .infinity, alignment: .center)
                        .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color("Dark-Cyan"), lineWidth: 3)
                                .shadow(color: Color("Dark-Cyan"), radius: 6)
                        )
                    
                    
                }.padding(.bottom)
                
                
                
                
            }.padding(.horizontal, 42.0)
            
            
        }
        
        
    }
    
    
    func tomarFoto()  {
        print("Tomo foto")
        //logica de tomar fotos.
    }
    
    //Puede llamarse como gustes, ya sea registrate o registrarse, el punto es que sea una acción.
    func registrarse()  {
        
        print("Me registro con el correo \(correo), la contraseña \(contraseña) y confirmación de contraseña \(confirmacionContraseña)")
        
        //Logica de validación
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        @State var isAuthenticated: Bool = true
        Group{
            LoginView(isAuthenticated: $isAuthenticated )
            LoginSectionView(isAuthenticated: $isAuthenticated)
                .background(Color(red: 18/255, green: 31/255, blue: 61/255, opacity: 100).ignoresSafeArea())
        }
    }
}

//#Preview {
//    LoginView()
//}
