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
    
    var body: some Scene {
        WindowGroup {
            Home()
        }
        .modelContainer(modelContainer)
    }
}
