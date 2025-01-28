import SwiftUI
import Foundation

extension EditProfileView {
    
    @Observable
    class EditProfileViewModel{
        var password = ""
        var confirmPassword = ""
        var correo: String = ""
        var showConfirmDialog: Bool = false
        var showAlertMessage: Bool = false
        var message: String = ""
    }
    
    func SaveProfileChanges(){
        
        if(viewModel.confirmPassword != viewModel.password){
            viewModel.showAlertMessage = true
            viewModel.message = "Las contraseñas no coinciden"
            return
        }
        if let company = selection{ 
            company.credentials = viewModel.password
        }
        try? modelContext.save()
        
        viewModel.showAlertMessage = true
        viewModel.message = "Actualizado con éxito"
        
    }
}
