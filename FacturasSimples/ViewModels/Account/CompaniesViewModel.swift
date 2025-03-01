import SwiftUI
import Foundation

extension CompaniesView{
 
    @Observable
    class CompaniesViewModel{
         
        var isShowingAddCompany: Bool = false
        var isShowingEditCompany: Bool = false
        var isShowingEditCertificateCredentials : Bool = false
                var showRequestProductionAccessSheet :  Bool = false
        
        var showEditCredentialsSheet : Bool  = false
      
        var environmentFilter: EnvironmentType = .Produccion
        
        var environments : [EnvironmentType] = [.Produccion,.Pruebas]
        
         
    }
}
