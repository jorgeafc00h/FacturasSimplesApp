import SwiftUI
import UIKit

struct ProfileView: View {
    
    
//    @State var userName:String = "-"
//    @State var email: String = "@id.com"
//
    @Environment(\.modelContext) var modelContext
    
  
    
    @State var isToggleOn = true
    
    @State var selection: Company?
    
    @State var defaultSectedCompany : Company?
    
    @AppStorage("storedName")   var userName : String = ""
    @AppStorage("storedEmail")   var email : String = ""
    
    @AppStorage("userID")  var userID : String = ""
    @AppStorage("selectedCompanyIdentifier")  var companyId : String = ""{
        didSet {
            selectedCompanyId = companyId
        }
    }
    
    @AppStorage("showTestEnvironments") var testAccounts: Bool = true
    
    @State var viewModel = ProfileViewModel()
    
    @Binding var selectedCompanyId: String 
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var iPad : Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility){
            ZStack {
                
                Color("Marine").ignoresSafeArea()
                   .navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
                VStack{
                    VStack{ 
                        Image(systemName: "gear.badge.questionmark" )
                            .resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            //.clipShape(Circle())
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
                        
                        SelectedCompanyButton(selection: $defaultSectedCompany)
                        Settings
                         
                    }
                }
            }
            .navigationTitle("configuración")
            .onChange(of: selectedCompanyId){
                if selection == nil{
                    loadProfileAndSelectedCompany()
                }
            }
            .onAppear{
                loadProfileAndSelectedCompany()
            }
        }
        content:{
            NavigationStack{
                CompaniesView(selection: $selection, selectedCompanyId: $selectedCompanyId)
                    .navigationSplitViewColumnWidth(500)
            }
        }
        detail:{
            if let company = selection {
                CompanyDetailsView(company: company,
                                   selection: $selection,
                                   selectedCompanyId: $selectedCompanyId )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            if UIDevice.current.userInterfaceIdiom == .phone {
                columnVisibility = .all
            }
        }
    }
    
    private var Settings : some View {
        VStack{
            
            NavigationLink {
                CompaniesView(selection: $selection,
                              selectedCompanyId:  $selectedCompanyId)
            }
            label: {
                NavigationLabel(title:"Configuración Empresas",imagename: "widget.small")
            }
            
            Button(action: { testAccounts.toggle() }, label: {
                HStack {
                    Image(systemName: "testtube.2").padding(.horizontal, 5.0)
                        .foregroundColor(Color.white)
                    Text("Entorno Pruebas")
                        .foregroundColor(Color.white)
                    Spacer()
                    
                    Toggle("", isOn: $testAccounts)
                    
                }.padding()
            }) .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
            Button(action: { isToggleOn.toggle() }, label: {
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
            
            
            Button(action: {viewModel.showAccountSummary.toggle()}, label: {
                NavigationLabel(title:"resumen cuenta",imagename: "person.2.badge.gearshape.fill")
                                   .foregroundColor(.darkCyan)
                                    .symbolEffect(.breathe)
            }) .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
            Button(action: {viewModel.showOnboardingSheet = true}, label: {
                NavigationLabel(title:"info y ayuda",imagename: "info.circle.fill")
                                   .foregroundColor(.darkCyan)
                                    .symbolEffect(.breathe)
            }) .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
        }
        .sheet(isPresented: $viewModel.showOnboardingSheet) {
             
            OnboardingView(requiresOnboarding: $viewModel.showOnboardingSheet,selectedCompanyId:
                                $selectedCompanyId,
                               reloadCompany: true)
        }
        .sheet(isPresented: $viewModel.showAccountSummary){
            UserAccountView();
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
