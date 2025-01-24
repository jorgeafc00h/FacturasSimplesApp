import SwiftUI

struct ProfileView: View {
    
    
//    @State var userName:String = "-"
//    @State var email: String = "@id.com"
//
    @Environment(\.modelContext) var modelContext
    
    @State var imagenPerfil:UIImage = UIImage(named: "perfilEjemplo")!
    
    @State var isToggleOn = true
    
    @State var selection: Company?
    @AppStorage("storedName")   var userName : String = ""
    @AppStorage("storedEmail")   var email : String = ""
    
    @AppStorage("userID")  var userID : String = ""
    @AppStorage("selectedCompanyIdentifier")  var companyId : String = ""{
        didSet {
            selectedCompanyId = companyId
        }
    }
    

    @State var viewModel = ProfileViewModel()
    
    @Binding var selectedCompanyId: String
    
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
                        
                        SelectedCompanyButton(selection: $selection)
                        Settings
                         
                    }
                }
            }
            .navigationTitle("configuración")
            .onAppear{loadUserProfileImage()}
        }
        detail:{
            CompaniesView(selection: $selection, selectedCompanyId: $selectedCompanyId)
        }
    }
    
    private var Settings : some View {
        VStack{
            
            NavigationLink {
                CompaniesView(selection: $selection,
                              selectedCompanyId:  $selectedCompanyId)
            }
            label: {
                NavigationLabel(title:"Aministracion Empresas",imagename: "widget.small")
            }
            NavigationLink {EditProfileView()}
            label: {
                NavigationLabel(title:"Usuario y contraseña",imagename: "person.badge.key.fill")
            }
            
            NavigationLink {CertificateUpdate(selection: $selection)}
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


#Preview (traits: .sampleCompanies){
    ProfileViewWrapper()
}

struct ProfileViewWrapper: View {
    @State private var selectedCompany: Company? = nil
    @State private var selectedCompanyId: String = ""
    
    var body: some View {
        ProfileView( selectedCompanyId: $selectedCompanyId)
    }
}
