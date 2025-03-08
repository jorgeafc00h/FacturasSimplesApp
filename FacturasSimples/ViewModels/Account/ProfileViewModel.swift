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
    func loadProfileAndSelectedCompany() {
    
        print("check user defaults..")
       
        
        let id = companyId.isEmpty ? selectedCompanyId : companyId
        
        let descriptor = FetchDescriptor<Company>(predicate: #Predicate { $0.id == id  })
        
        
        if let selectedCompany = try? modelContext.fetch(descriptor).first {
            defaultSectedCompany = selectedCompany
            
            print("selected Company -> \(selectedCompany.nombre)")
        } else {
            print("no selected company identifier: \(selectedCompanyId)")
        }
        
         
    }
     
}

