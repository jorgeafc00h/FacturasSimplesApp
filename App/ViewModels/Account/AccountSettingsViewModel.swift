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
            
            userName = UserDefaults.standard.stringArray(forKey: "datosUsuario")![2]
            print("UserName-> \(userName)")
        }else{
            
            print("user not found")
            
        }
        let localStorage = LocalStorageService()
        
        let data = localStorage.getProfileData()
        if  data.isEmpty {
            
            email=data[0]
            userName=data[1]
            print("email-> \(email)")
            
        }
        
    }
}
