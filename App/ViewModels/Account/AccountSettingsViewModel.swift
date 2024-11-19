//
//  AccountSettingsViewModel.swift
//  App
//
//  Created by Jorge Flores on 11/18/24.
//
import Foundation
import SwiftUI

extension ProfileView {
    
    
    func returnUiImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    func loadUserProfileImage() {
        // check saved user profile
        if returnUiImage(named: "fotoperfil") != nil {
            
            imagenPerfil = returnUiImage(named: "fotoperfil")!
            
        }else{
            print("no profile picture available")
            
        }
        print("check user defaults..")
        
        if UserDefaults.standard.object(forKey: "datosUsuario") != nil {
            
            nombreUsuario = UserDefaults.standard.stringArray(forKey: "datosUsuario")![2]
            print("UserName-> \(nombreUsuario)")
        }else{
            
            print("user not found")
            
        }
    }
}
