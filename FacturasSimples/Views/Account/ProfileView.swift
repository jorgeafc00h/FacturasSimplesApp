import SwiftUI
import UIKit

struct ProfileView: View {
    
    
//    @State var userName:String = "-"
//    @State var email: String = "@id.com"
//
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var storeKitManager: StoreKitManager
    
  
    
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
    @State private var showPurchaseView = false
    
    @Binding var selectedCompanyId: String 
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var iPad : Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // MARK: - Computed Properties for Validation
    
    /// Determines if the credits button should be disabled
    /// Credits can only be purchased for production companies (isTestAccount = false)
    private var isCreditsButtonDisabled: Bool {
        // If no company is selected, disable the button
        guard let company = defaultSectedCompany else { return true }
        
        // Only production companies (isTestAccount = false) can purchase credits
        return company.isTestAccount
    }
    
    /// Helper to check if current company is a production company
    private var isProductionCompany: Bool {
        guard let company = defaultSectedCompany else { return false }
        return !company.isTestAccount
    }
    
    /// Dynamic subtitle for the credits button
    private var creditsButtonSubtitle: String {
        if isCreditsButtonDisabled {
            return "Solo disponible para empresas de producción"
        } else {
            return "\(storeKitManager.userCredits.availableInvoices) créditos disponibles"
        }
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
            .onChange(of: selectedCompanyId) {
                print("🔄 selectedCompanyId changed to: \(selectedCompanyId)")
                loadProfileAndSelectedCompany()
            }
            .onChange(of: companyId) {
                print("🔄 companyId changed to: \(companyId)")
                // The didSet already updates selectedCompanyId, so loadProfileAndSelectedCompany 
                // will be called by the selectedCompanyId onChange
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
            
            NavigationLink {
                CloudKitSettingsView()
            }
            label: {
                HStack {
                    Image(systemName: "icloud.fill").padding(.horizontal, 5.0)
                        .foregroundColor(Color.white)
                    VStack(alignment: .leading) {
                        Text("iCloud Sync")
                            .foregroundColor(Color.white)
                        HStack {
                            CloudKitSyncStatusView()
                            Text("Sincronización automática")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.white)
                }.padding()
            }
            .background(Color("Blue-Gray"))
            .clipShape(RoundedRectangle(cornerRadius: 1.0))
            .padding(.horizontal, 8.0)
            
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
           
            
            Button(action: {viewModel.showAccountSummary.toggle()}, label: {
                NavigationLabel(title:"Resumen Cuenta",imagename: "person.2.badge.gearshape.fill")
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
            
            Button(action: {showPurchaseView = true}, label: {
                HStack {
                    Image(systemName: "creditcard.fill").padding(.horizontal, 5.0)
                        .foregroundColor(isCreditsButtonDisabled ? Color.gray : Color.white)
                    VStack(alignment: .leading) {
                        Text("Comprar Créditos")
                            .foregroundColor(isCreditsButtonDisabled ? Color.gray : Color.white)
                        Text(creditsButtonSubtitle)
                            .font(.caption)
                            .foregroundColor((isCreditsButtonDisabled ? Color.gray : Color.white).opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(isCreditsButtonDisabled ? Color.gray : Color.white)
                }.padding()
            })
            .disabled(isCreditsButtonDisabled)
            .background(Color("Blue-Gray"))
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
        .sheet(isPresented: $showPurchaseView) {
            InAppPurchaseView()
                .environmentObject(storeKitManager)
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
