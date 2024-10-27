//
//  Home.swift
//  App
//
//  Created by Jorge Flores on 10/14/24.
//

import SwiftUI

struct Home: View {
    @State var selectedTab:Int = 2
    
    var body: some View {
         
            TabView(selection: $selectedTab){
                ProfileView()
                    .navigationBarHidden(true).navigationBarBackButtonHidden(true)
                    .tabItem {
                        Image(systemName: "person")
                        Text("Perfil")
                    }.tag(0)
                CustomersView()
                    .tabItem {
                        Image(systemName: "person.crop.badge.magnifyingglass.fill")
                        Text("Clientes")
                    }.tag(1)
                InvoicesView()
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle.portrait")
                        Text("Inicio")
                    }.tag(2)
                Text("Favoritos")
                // .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tabItem {
                        Image(systemName: "heart")
                        Text("Inicio")
                    }.tag(3)
                
            }.accentColor(.darkCyan)
         
    }
        
    
    init(){
        UITabBar.appearance().barTintColor = UIColor(Color("TabBar-Color"))
        UITabBar.appearance().isTranslucent = true
        
    }
}

 
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}


#Preview {
    Home()
}
