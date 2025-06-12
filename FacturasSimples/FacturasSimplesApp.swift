//
//  FacturasSimplesApp.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/16/25.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct FacturasSimplesApp: App {
    // Use unified CloudKit container for all models
    let modelContainer = DataModel.shared.modelContainer
    @StateObject private var storeManager = StoreKitManager()
    @StateObject private var companyStorageManager = CompanyStorageManager.shared
    
    init() {
        let attrs = [
            //Arial Rounded MT Bold
            NSAttributedString.Key.font: UIFont(name: "TrebuchetMS-Bold", size: 23)
        ]
 
        UINavigationBar.appearance().largeTitleTextAttributes = attrs as [NSAttributedString.Key : Any]
    }
    
    var body: some Scene {
        WindowGroup {
            Home()
                .environmentObject(storeManager)
                .environmentObject(companyStorageManager)
        }
        .modelContainer(modelContainer)
    }
}
