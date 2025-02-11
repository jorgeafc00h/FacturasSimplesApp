//
//  Home.swift
//  App
//
//  Created by Jorge Flores on 10/14/24.
//

import SwiftUI
import SwiftData

struct Home: View {
    
    @State var isActive : Bool = false
    
    var body: some View {
        ZStack{
            
            if self.isActive{
                mainView()
            }
            else{
                SplashView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
        
        
    }
    
    
    init(){
       
        UITabBar.appearance().isTranslucent = true
        
    }
    
    
    
    
    
}

struct mainView : View{
    //    @State var selectedTab:Int = 2
    //    @State var isAuthenticated: Bool = false
    //    @State var selectedCompanyId: String = ""
    
    @Environment(\.modelContext) var modelContext
    
    @State var viewModel = MainViewModel()
    
    var body: some View{
        
        if viewModel.isAuthenticated{
            
            if viewModel.requiresOnboarding{
                OnboardingView(requiresOnboarding: $viewModel.requiresOnboarding, selectedCompanyId: $viewModel.selectedCompanyId)
            }
            else{
                HomeTab
            }
        }
        else{
            LoginView(isAuthenticated: $viewModel.isAuthenticated)
            
        }
    }
    
    private var HomeTab : some View{
        TabView(selection: $viewModel.selectedTab){
            ProfileView(selectedCompanyId: $viewModel.selectedCompanyId)
                .navigationBarHidden(true).navigationBarBackButtonHidden(true)
                .tabItem {
                    Image(systemName: "person")
                    Text("Perfil")
                }.tag(0)
            CustomersView(selectedCompanyId: $viewModel.selectedCompanyId)
                .tabItem {
                    Image(systemName: "person.crop.badge.magnifyingglass.fill")
                    Text("Clientes")
                }.tag(1)
            InvoicesView(selectedCompanyId: $viewModel.selectedCompanyId)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("Facturas")
                }.tag(2)
            ProductsView(selectedCompanyId: $viewModel.selectedCompanyId)
            // .font(.system(size: 30, weight: .bold, design: .rounded))
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Productos")
                }.tag(3)
        }
        .toolbarColorScheme(.dark, for: .tabBar)
        .accentColor(.darkCyan)
        .task {
            RefreshRequiresOnboardingPage()
        }
    }
}
    
    struct HomeView_Previews: PreviewProvider {
        static var previews: some View {
            mainView()
        }
    }
    
    
    #Preview {
        Home()
    }
