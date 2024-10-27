//
//  MainView.swift
//  App
//
//  Created by Jorge Flores on 10/23/24.
//

import SwiftUI
import SwiftData


struct MainContainerView: View {
    @State var isAuthenticated: Bool = true

    var body: some View {
        if(isAuthenticated){
            Home()
        }
        else{
            LoginView(isAuthenticated: $isAuthenticated)
        }
    }
    
}



#Preview(traits: .sampleCustomers) {
    MainContainerView()
}
