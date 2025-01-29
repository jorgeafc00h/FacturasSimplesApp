import Foundation
import SwiftData
import SwiftUI

extension ProfileView{
    
    
    @Observable
    class ProfileViewModel{
        
        var showAddCompanySheet: Bool = false
        
        var showSelectCompanySheet: Bool = false
        
        var showOnboardingSheet : Bool = false
    }
    
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
        
        
        let descriptor = FetchDescriptor<Company>(predicate: #Predicate { $0.id == companyId  })
        
        
        if let selectedCompany = try? modelContext.fetch(descriptor).first {
            selection = selectedCompany
            print("selected Company -> \(selectedCompany.nombre)")
        } else {
            print("no selected company identifier: \(selectedCompanyId)")
        }
        
         
    }
}
