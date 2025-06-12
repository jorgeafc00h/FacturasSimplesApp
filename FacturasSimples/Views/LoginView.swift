//
//  ContentView.swift
//  App
//
//  Created by Jorge Flores on 10/13/24.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State var tipoInicioSesion: Bool = true
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(isAuthenticated: Binding<Bool>) {
        _isAuthenticated = isAuthenticated
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 18/255, green: 31/255, blue: 61/255),
                        Color(red: 25/255, green: 42/255, blue: 86/255),
                        Color(red: 31/255, green: 54/255, blue: 112/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating particles background effect
                backgroundParticles()
                
                if isIPad {
                    iPadLayout(geometry: geometry)
                } else {
                    iPhoneLayout(geometry: geometry)
                }
            }
        }
    }
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    private func iPadLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left side - Hero section
            VStack {
                Spacer()
                
                VStack(spacing: 30) {
                    // App logo with glow effect
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 300, height: 300)
                        
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 0)
                    }
                    
                    VStack(spacing: 16) {
                        Text("Facturas Simples")
                            .font(.custom("Bradley Hand", size: 48))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Text("Gestiona tus facturas de manera simple y elegante")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.5)
            
            // Right side - Login form
            VStack {
                Spacer()
                
                VStack(spacing: 30) {
                    // Welcome message
                    VStack(spacing: 12) {
                        Text("Bienvenido")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Accede a tu cuenta para continuar")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Login tabs
                    //modernLoginTabs
                    
                    // Login content with glass morphism effect
                    VStack {
                        if tipoInicioSesion {
                            LoginSectionView(isAuthenticated: $isAuthenticated)
                        } else {
                            RegistroView()
                        }
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.5)
        }
    }
    
    private func iPhoneLayout(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer(minLength: 60)
                
                // Logo section
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: min(geometry.size.width * 0.6, 250))
                        .shadow(color: .white.opacity(0.3), radius: 10)
                    
                    Text("Facturas Simples")
                        .font(.custom("Bradley Hand", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Login section
                VStack(spacing: 24) {
                    //modernLoginTabs
                    
                    VStack {
                        if tipoInicioSesion {
                            LoginSectionView(isAuthenticated: $isAuthenticated)
                        } else {
                            RegistroView()
                        }
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 40)
            }
        }
    }
    
//    private var modernLoginTabs: some View {
//        HStack(spacing: 0) {
//            Button(action: { 
//                withAnimation(.easeInOut(duration: 0.3)) {
//                    tipoInicioSesion = true
//                }
//            }) {
//                Text("INICIAR SESIÓN")
//                    .font(.subheadline)
//                    .fontWeight(.semibold)
//                    .foregroundColor(tipoInicioSesion ? .white : .white.opacity(0.6))
//                    .padding(.vertical, 12)
//                    .frame(maxWidth: .infinity)
//                    .background(
//                        RoundedRectangle(cornerRadius: 25)
//                            .fill(tipoInicioSesion ? Color.white.opacity(0.2) : Color.clear)
//                    )
//            }
//            
//            Button(action: { 
//                withAnimation(.easeInOut(duration: 0.3)) {
//                    tipoInicioSesion = false
//                }
//            }) {
//                Text("REGÍSTRATE")
//                    .font(.subheadline)
//                    .fontWeight(.semibold)
//                    .foregroundColor(tipoInicioSesion ? .white.opacity(0.6) : .white)
//                    .padding(.vertical, 12)
//                    .frame(maxWidth: .infinity)
//                    .background(
//                        RoundedRectangle(cornerRadius: 25)
//                            .fill(tipoInicioSesion ? Color.clear : Color.white.opacity(0.2))
//                    )
//            }
//        }
//        .padding(4)
//        .background(
//            RoundedRectangle(cornerRadius: 28)
//                .stroke(Color.white.opacity(0.3), lineWidth: 1)
//        )
//        .padding(.horizontal, isIPad ? 0 : 20)
//    }
    
    private func backgroundParticles() -> some View {
        ZStack {
            ForEach(0..<20, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...8))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 20...40))
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
    }
    
    private var LoginViews: some View {
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
        
    }
}



struct LoginSectionView: View {
    
    @State var userEmail:String = ""
    @State var userName: String = ""
    @State var contraseña:String = ""
    @State var accountId: String = ""
    @State var token: String = ""
    @Binding var isAuthenticated:Bool
    @State var isLoading = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(isAuthenticated:Binding<Bool>){
        _isAuthenticated = isAuthenticated
    }
    
    var body: some View {
        VStack(spacing: 30) {
            LoginForm
            
            // Sign in with Apple button
            ZStack {
                SignInWithAppleButton(.signIn,
                                      onRequest: onRequest,
                                      onCompletion: onCompletion)
                .signInWithAppleButtonStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 75)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                
                // Loading overlay (only when loading)
                if isLoading {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.black.opacity(0.8))
                        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 75)
                        .overlay(
                            HStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                
                                Text("Iniciando sesión...")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        )
                        .allowsHitTesting(false)
                }
            }
             
        }
        .task {
            await Authorize()
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
    
    @AppStorage("identityToken")  var identityToken : String = ""{
        didSet{
            token = identityToken
        }
    }
    
    private var LoginForm: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Bienvenido!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Inicia sesión con tu cuenta Apple para acceder a todas las funciones de la aplicación")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            
            // Feature highlights
            VStack(spacing: 16) {
                FeatureRow(icon: "doc.text", title: "Gestión de Facturas", description: "Crea y organiza tus facturas fácilmente")
                FeatureRow(icon: "icloud", title: "Sincronización iCloud", description: "Accede a tus datos desde cualquier dispositivo")
                FeatureRow(icon: "shield.checkered", title: "Seguro y Confiable", description: "Tu información protegida con Apple ID")
            }
        }
    }
    
    private func FeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
}

struct RegistroView: View {
    
    @State var correo:String = ""
    @State var contraseña:String = ""
    @State var confirmacionContraseña:String = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Crear cuenta")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Únete a nuestra comunidad y comienza a gestionar tus facturas de manera profesional")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            
            // Form fields
            VStack(spacing: 20) {
                
                ModernTextField(
                    title: "Correo electrónico",
                    text: $correo,
                    placeholder: "ejemplo@gmail.com",
                    keyboardType: .emailAddress
                )
                
                ModernSecureField(
                    title: "Contraseña",
                    text: $contraseña,
                    placeholder: "Introduce tu contraseña"
                )
                
                ModernSecureField(
                    title: "Confirmar contraseña",
                    text: $confirmacionContraseña,
                    placeholder: "Reintroduce tu contraseña"
                )
            }
            
            // Register button
            Button(action: registrarse) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isLoading ? "Creando cuenta..." : "CREAR CUENTA")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 63/255, green: 202/255, blue: 160/255),
                                    Color(red: 31/255, green: 181/255, blue: 143/255)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(red: 63/255, green: 202/255, blue: 160/255).opacity(0.3), 
                               radius: 10, x: 0, y: 4)
                )
            }
            .disabled(isLoading || !isFormValid)
            .opacity(isFormValid ? 1.0 : 0.6)
            
            // Terms text
            Text("Al crear una cuenta, aceptas nuestros términos de servicio y política de privacidad")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .alert("Registro", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        !correo.isEmpty && 
        !contraseña.isEmpty && 
        !confirmacionContraseña.isEmpty &&
        contraseña == confirmacionContraseña &&
        correo.contains("@") &&
        contraseña.count >= 6
    }
    
    func registrarse()  {
        isLoading = true
        
        // Validate form
        guard isFormValid else {
            alertMessage = "Por favor, completa todos los campos correctamente"
            showingAlert = true
            isLoading = false
            return
        }
        
        // Simulate registration process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
            self.alertMessage = "Cuenta creada exitosamente. Por favor, verifica tu correo electrónico."
            self.showingAlert = true
            
            // Reset form
            self.correo = ""
            self.contraseña = ""
            self.confirmacionContraseña = ""
        }
        
        print("Me registro con el correo \(correo), la contraseña \(contraseña) y confirmación de contraseña \(confirmacionContraseña)")
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
            )
        }
    }
}

struct ModernSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                SecureField("", text: $text)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
            )
        }
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
 
