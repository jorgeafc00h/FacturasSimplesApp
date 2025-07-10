import SwiftUI
import SwiftData
import UIKit

struct ProfileView: View {
    
    
//    @State var userName:String = "-"
//    @State var email: String = "@id.com"
//
    @Environment(\.modelContext) var modelContext
   // @EnvironmentObject var storeKitManager: StoreKitManager
    
  
    
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
    @AppStorage("selectedCompanyName")  var selectedCompanyName : String = ""
    
    @AppStorage("showTestEnvironments") var testAccounts: Bool = true
    
    @State var viewModel = ProfileViewModel()
    @State private var showPurchaseView = false
    @State private var showPurchaseHistory = false
    @State private var showProductionRequestSheet = false
    @State private var companyForProductionRequest: Company?
    
    @Binding var selectedCompanyId: String 
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var iPad : Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // MARK: - Computed Properties for Validation
    
    /// Helper to check if current company is a production company
    private var isProductionCompany: Bool {
        guard let company = defaultSectedCompany else { return false }
        return !company.isTestAccount
    }
    
    /// Dynamic subtitle for the credits button
    private var creditsButtonSubtitle: String {
        if let company = defaultSectedCompany, !company.isTestAccount {
            //return "\(storeKitManager.userCredits.availableInvoices) créditos disponibles"
            return "creditos disponibles"
        } else {
            return "Selecciona empresa de producción"
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
                // Refresh credits when company changes to ensure UI is current
                //storeKitManager.refreshUserCredits()
            }
            .onChange(of: companyId) {
                print("🔄 companyId changed to: \(companyId)")
                // The didSet already updates selectedCompanyId, so loadProfileAndSelectedCompany 
                // will be called by the selectedCompanyId onChange
            }        .onAppear{
            loadProfileAndSelectedCompany()
            // Refresh credits to ensure UI shows current balance
            //storeKitManager.refreshUserCredits()
            
            // Add notification observer for production request navigation
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NavigateToProductionRequest"),
                object: nil,
                queue: .main
            ) { notification in
                if let company = notification.object as? Company {
                    companyForProductionRequest = company
                    showProductionRequestSheet = true
                }
            }
        }
        .onDisappear {
            // Remove notification observer
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToProductionRequest"), object: nil)
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
            
            Button(action: {
                // Check if current company is a test account
                if let company = defaultSectedCompany, company.isTestAccount {
                    // Show dialog to select a production company
                    viewModel.showProductionCompanySelectionDialog = true
                } else if defaultSectedCompany == nil {
                    // No company selected, show production company selection
                    viewModel.showProductionCompanySelectionDialog = true
                } else {
                    // Current company is production, proceed with purchase flow
                    showPurchaseView = true
                }
            }, label: {
                HStack {
                    Image(systemName: "creditcard.fill").padding(.horizontal, 5.0)
                        .foregroundColor(Color.white)
                    VStack(alignment: .leading) {
                        Text("Comprar Créditos")
                            .foregroundColor(Color.white)
                        Text(creditsButtonSubtitle)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.white)
                }.padding()
            })
            .background(Color("Blue-Gray"))
                .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
            
            // Purchase History Button
            Button(action: {
                showPurchaseHistory = true
            }, label: {
                HStack {
                    Image(systemName: "doc.text.fill").padding(.horizontal, 5.0)
                        .foregroundColor(Color.white)
                    VStack(alignment: .leading) {
                        Text("Historial de Compras")
                            .foregroundColor(Color.white)
                        Text("Ver transacciones anteriores")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.white)
                }.padding()
            })
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
                //.environmentObject(storeKitManager)
        }
        .sheet(isPresented: $showPurchaseHistory) {
            PurchaseHistoryView(onBrowseBundles: {
                showPurchaseView = true
            })
             //   .environmentObject(storeKitManager)
        }
        .sheet(isPresented: $viewModel.showProductionCompanySelectionDialog) {
            NavigationStack {
                ProductionCompanySelectionView(
                    selectedCompany: $viewModel.selectedProductionCompany,
                    onConfirm: {
                        viewModel.showSetProductionCompanyConfirmDialog = true
                    }
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "¿Desea establecer \(viewModel.selectedProductionCompany?.nombreComercial ?? "") como empresa predeterminada para gestionar facturas y comprar créditos?",
            isPresented: $viewModel.showSetProductionCompanyConfirmDialog,
            titleVisibility: .visible
        ) {
            Button("Confirmar", action: setProductionCompanyAsDefault)
            Button("Cancelar", role: .cancel) {
                viewModel.selectedProductionCompany = nil
            }
        }
        .sheet(isPresented: $showProductionRequestSheet) {
            if let company = companyForProductionRequest {
                NavigationStack {
                    RequestProductionView(company: company) { createdProductionCompany in
                        // On completion, handle the created production company
                        showProductionRequestSheet = false
                        companyForProductionRequest = nil
                        
                        if let productionCompany = createdProductionCompany {
                            // Set the created production company as default
                            setCreatedProductionCompanyAsDefault(productionCompany)
                        } else {
                            // Just refresh the view if no company was created
                            loadProfileAndSelectedCompany()
                        }
                    }
                }
                .presentationDragIndicator(.visible)
            }
        }
        
        
    }
    
    // New function for setting production company as default
    private func setProductionCompanyAsDefault() {
        guard let company = viewModel.selectedProductionCompany else { return }
        
        withAnimation {
            companyId = company.id
            selectedCompanyId = company.id
            selectedCompanyName = company.nombreComercial
            defaultSectedCompany = company
            
            print("✅ Set production company as default: \(company.nombre)")
            print("🏢 Company Type: \(company.isTestAccount ? "TEST" : "PRODUCTION")")
        }
        
        // Close dialogs
        viewModel.showSetProductionCompanyConfirmDialog = false
        viewModel.showProductionCompanySelectionDialog = false
        
        // Refresh credits after company change
        //storeKitManager.refreshUserCredits()
        
        // Now show the purchase view
        showPurchaseView = true
    }
    
    // Function for setting created production company as default and showing purchase view
    private func setCreatedProductionCompanyAsDefault(_ company: Company) {
        withAnimation {
            companyId = company.id
            selectedCompanyId = company.id
            selectedCompanyName = company.nombreComercial
            defaultSectedCompany = company
            
            print("✅ Set created production company as default: \(company.nombre)")
            print("🏢 Company Type: \(company.isTestAccount ? "TEST" : "PRODUCTION")")
        }
        
        // Refresh credits after company change
        //storeKitManager.refreshUserCredits()
        
        // Refresh the view to update UI
        loadProfileAndSelectedCompany()
        
        // Show the purchase view automatically
        showPurchaseView = true
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
            //.environmentObject(StoreKitManager())
    }
}
