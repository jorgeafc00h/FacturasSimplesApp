import SwiftUI

struct ProfileView: View {
    
    
    @State var nombreUsuario:String = "Joe Cool"
    @State var imagenPerfil:UIImage = UIImage(named: "perfilEjemplo")!
    
    @State var isToggleOn = true
    
    
    var body: some View {
        NavigationSplitView{
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
                    Settings
                    Spacer()
                }
            } .onAppear{loadUserProfileImage()}
        }
        detail:{
            
        }
    }
    
    private var Settings : some View {
        VStack{
            
            NavigationLink {EmisorEditView()}
            label: {
                NavigationLabel(title:"Perfil Ministerio de Hacienda",imagename: "person.crop.circle.fill")
            }
            NavigationLink {EditProfileView()}
            label: {
                NavigationLabel(title:"Usuario y contraseña",imagename: "person.badge.key.fill")
            }
            NavigationLink {CertificateUpdate()}
            label: {
                NavigationLabel(title:"Contraseña Cerficado",imagename:  "lock.fill")
            }
            NavigationLink {EditProfileView()}
            label: {
                NavigationLabel(title:"Facturas",imagename: "document.badge.gearshape.fill")
            }
            Button(action: {}, label: {
                HStack {
                    Image(systemName: "bell.fill").padding(.horizontal, 5.0)
                        .foregroundColor(Color.white)
                    Text("Notificaciones")
                        .foregroundColor(Color.white)
                    Spacer()
                    
                    Toggle("", isOn: $isToggleOn)
                    
                }.padding()
            }) .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
        }
    }
    
    
    
}

 

private struct NavigationLabel : View {
    
    var title : String
    var imagename : String
    var body: some View {
        
        HStack {
            Image(systemName: imagename).padding(.horizontal, 5.0)
                .foregroundColor(Color.white)
            Text(title).foregroundColor(Color.white)
            Spacer()
        }.padding()
            .background(Color("Blue-Gray"))
            .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
        
    }
}


 

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
