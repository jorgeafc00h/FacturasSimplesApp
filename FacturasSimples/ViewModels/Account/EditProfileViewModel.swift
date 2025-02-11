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
        
        var isBusy : Bool = false
         
        func validateCredentialsAsync(nit: String,password: String) async throws -> Bool {
            let serviceClient  = InvoiceServiceClient()
                
            return try await serviceClient.validateCredentials(nit: nit, password: password,forceRefresh: true)
        }
        
        var areEquals: Bool {
            return password == confirmPassword
        }
    }
    
    func SaveProfileChanges() async -> Bool{
        
        if !viewModel.areEquals{
            viewModel.showAlertMessage = true
            viewModel.message = "Las contraseñas no coinciden"
             return false
        }
         
        viewModel.isBusy = true
        if let company = selection{
            
            do{
                let areValid = try await viewModel.validateCredentialsAsync(nit: company.nit, password: viewModel.password)
                
                if areValid{
                    company.credentials = viewModel.password
                    
                    try? modelContext.save()
                }
                else{
                    viewModel.showAlertMessage = true
                    viewModel.message = "Contraseña incorrecta"
                    viewModel.isBusy = false
                    return false
                }
            }
            catch(let errorMessage)
            {
                print("\(errorMessage.localizedDescription)")
                viewModel.showAlertMessage = true
                viewModel.isBusy = false
                viewModel.message = "Error al actualizar las credenciales no coinciden con las registradas en Hacienda"
                return false
            }
                
        }
        viewModel.showAlertMessage = true
        viewModel.message = "Actualizado con éxito"
        viewModel.isBusy = false
        
        return true
    }
}
