import SwiftUI

struct ProfileView: View {
    
    
    @State var userName:String = "-"
    @State var email: String = "@id.com"
    @State var imagenPerfil:UIImage = UIImage(named: "perfilEjemplo")!
    
    @State var isToggleOn = true
    
   @State   var selection: Company?
   
   
   @State var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationSplitView{
            ZStack {
                
                Color("Marine").ignoresSafeArea().navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
                VStack{
                    VStack{ 
                        Image(uiImage: imagenPerfil ).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                        Text(userName)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                        Text(email)
                            .fontWeight(.ultraLight)
                            .foregroundStyle(Color.white)
                        
                    }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    ScrollView{
                        Text("configuración")
                            .fontWeight(.bold)
                            .foregroundColor(Color.white).frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,  alignment: .leading).padding(.leading,18)
                        
                        SelectedCompany
                        Settings
                         
                    }
                }
            }
            .navigationTitle("configuración")
            .onAppear{loadUserProfileImage()}
        }
        detail:{
            CompaniesView(selection: $selection)
        }
    }
    
    private var Settings : some View {
        VStack{
            
            NavigationLink {CompaniesView(selection: $selection)}
            label: {
                NavigationLabel(title:"Aministracion Empresas",imagename: "widget.small")
            }
            NavigationLink {EditProfileView()}
            label: {
                NavigationLabel(title:"Usuario y contraseña",imagename: "person.badge.key.fill")
            }
            NavigationLink {CertificateUpdate()}
            label: {
                NavigationLabel(title:"Contraseña Certificado",imagename:  "lock.fill")
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
    
    private var SelectedCompany : some View {
        Button(action: {}, label: {
            
            if let company = selection {
                HStack {
                    Circle()
                        .fill(Color(.darkCyan ))
                        .frame(width: 55, height: 55)
                        .overlay {
                            Image(systemName: "widget.small")
                                .font(.system(size: 30))
                                .foregroundStyle(.background)
                                .symbolEffect(.breathe, options: .nonRepeating)
                        }
                    
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Text(company.nombreComercial)
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        Text(company.nombre)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(company.correo)
                            .font(.headline)
                            .foregroundColor(.white)
                        if case let (id?, p?) = (company.nit, company.telefono) {
                            Divider()
                            HStack {
                                Image(systemName: "widget.small")
                                    .foregroundColor(.white)
                                Text(id).font(.headline).foregroundColor(.white)
                                Image(systemName: "phone")
                                    .foregroundColor(.white)
                                Text(p).font(.headline).foregroundColor(.white)
                            }
                            .font(.caption)
                        }
                    }.padding(.leading, 10.0)
                    // Spacer()
                }.padding()
            }
            else{
                HStack {
                    Image(systemName: "dollarsign.bank.building").padding(.horizontal, 5.0)
                        .foregroundColor(Color.white)
                    Text("Seleccione Empresa")
                        .foregroundColor(Color.white)
                    Spacer()
                     
                    
                }.padding()
            }
        }) .background(Color( selection == nil ? .clear : .darkBlue))
            .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
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


 
#Preview (traits: .sampleCompanies) {
    ProfileView()
}
