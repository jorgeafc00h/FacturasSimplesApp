//
//  FacturasSimplesApp.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/16/25.
//

import SwiftUI
import SwiftData

@main
struct FacturasSimplesApp: App {
    let modelContainer = DataModel.shared.modelContainer
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
        }
        .modelContainer(modelContainer)
    }
}
