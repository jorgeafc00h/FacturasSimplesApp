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
        UITabBar.appearance().barTintColor = UIColor(Color("TabBar-Color"))
        UITabBar.appearance().isTranslucent = true
        
    }
    
    
    
    
    
}

private struct mainView : View{
    @State var selectedTab:Int = 2
    @State var isAuthenticated: Bool = false
    @State var selectedCompanyId: String = ""
    var body: some View{
        
        if isAuthenticated{
            TabView(selection: $selectedTab){
                ProfileView(selectedCompanyId: $selectedCompanyId)
                    .navigationBarHidden(true).navigationBarBackButtonHidden(true)
                    .tabItem {
                        Image(systemName: "person")
                        Text("Perfil")
                    }.tag(0)
                CustomersView(selectedCompanyId: $selectedCompanyId)
                    .tabItem {
                        Image(systemName: "person.crop.badge.magnifyingglass.fill")
                        Text("Clientes")
                    }.tag(1)
                InvoicesView(selectedCompanyId: $selectedCompanyId)
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle.portrait")
                        Text("Facturas")
                    }.tag(2)
                ProductsView(selectedCompanyId: $selectedCompanyId)
                // .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle.fill")
                        Text("Productos")
                    }.tag(3)
                
            }
            .accentColor(.darkCyan)
        }
        else{
            LoginView(isAuthenticated: $isAuthenticated)
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
