import SwiftUI
import Foundation

extension CompanyDetailsView{
    
    @Observable
    class CompanyDetailsViewModel{
        
        var isShowingEditCompany: Bool = false
        var isShowingEditCertificateCredentials : Bool = false
        var showRequestProductionAccessSheet :  Bool = false
        
        var showEditCredentialsSheet : Bool  = false
      
        var showLogoEditorSheet: Bool = false
    }
    // set default company
    func SetAsDefaultCompany(){
        
        companyId = company.id
        
    }
}
