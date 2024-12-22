//
//  AppApp.swift
//  App
//
//  Created by Jorge Flores on 10/13/24.
//

import SwiftUI
import SwiftData

@main
struct AppApp: App {
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
