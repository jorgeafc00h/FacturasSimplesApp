import Foundation

extension ProfileView{
    
    
    @Observable
    class ProfileViewModel{
        
        var showAddCompanySheet: Bool = false
        
        var showSelectCompanySheet: Bool = false
    }
    
    func SelectedCompanyLabel() -> String{
        if let selectedCompany =  selection{
            return selectedCompany.nombreComercial
        }
        return "Seleccione una empresa"
    }
}
