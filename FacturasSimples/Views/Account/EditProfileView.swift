import SwiftUI
import SwiftData

struct EditProfileView: View {
    
    @State var applogo: Image? = Image("AppLogo")
    @State var isCameraActive = false
    
    @Bindable var selection : Company
    @Binding var isPresented: Bool
    @Binding var areInvalidCredentials: Bool
    var required: Bool = false
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
                                
                                applogo!.resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 118.0, height: 118.0)
                                     
                                    .sheet(isPresented: $isCameraActive, content: {
                                })
                            }
                        })
                        
                        Text(required ? "Aun no estan configuradas sus credenciales de Hacienda es importante para poder enviar DTE y poder emitir facturas" : "Configurar credenciales")
                            .fontWeight(.bold)
                            .padding(35)
                            .foregroundColor(Color.white)

                    }.padding(.bottom,18)
                 
                if viewModel.showCredentialsCheckerView {
                    CredentialsCheckerView
                }
                else{
                    EditUserCredentials
                }
            }
        }
        .onAppear(){
            EvaluateDisplayCredentialsCheckerView()
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
                }
           .disabled(viewModel.disableUpdateCredentialsButton)
           .padding(.bottom)
                
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
    
    
    private var CredentialsCheckerView: some View {
        VStack(alignment: .leading) {
            if viewModel.isBusy{
                HStack {
                    Label("Verificando...",systemImage: "progress.indicator")
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                }
            }
            else{
                if viewModel.isValidCredentials{
                    HStack {
                        Text("Las Credenciales de Hacienda Son Validas!")
                        Spacer()
                        Circle()
                            .fill(.darkCyan)
                            .frame(width: 8, height: 8)
                        Text("OK")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(7)
                            .background(.green.opacity(0.09))
                            .cornerRadius(8)
                    }.padding()
                }
                Button(action:{
                    Task{
                        await CheckCredentials()
                    }
                }) {
                    VStack{
                        if viewModel.isBusy{
                            HStack {
                                Label("Actualiando...",systemImage: "progress.indicator")
                                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                            }
                        }
                        else{
                            Text("Verificar contraseña de Hacienda")
                        }
                    }
                             .fontWeight(.bold)
                             .foregroundColor(.white)
                             .frame( maxWidth: .infinity, alignment: .center)
                             .padding(EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18))
                             .overlay(RoundedRectangle(cornerRadius: 6)
                                         .stroke(Color("Dark-Cyan"), lineWidth: 3).shadow(color: .white, radius: 6))
                     }
            }
        }
        .padding(.horizontal, 42.0)
    }
}






#Preview (traits: .sampleCompanies){
    EditProfileViewWrapper()
}

private struct EditProfileViewWrapper: View {
    @Query var companies: [Company]
    @State private var showSheet: Bool = false
    @State private var arevalidCredentials: Bool = false
    
   var body: some View {
       EditProfileView(selection: companies.first!, isPresented: $showSheet, areInvalidCredentials: $arevalidCredentials)
   }
}
