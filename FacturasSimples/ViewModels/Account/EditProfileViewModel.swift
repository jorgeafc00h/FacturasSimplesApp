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
         
        func validateCredentialsAsync(nit: String,password: String, isProduction: Bool) async throws -> Bool {
            
             
                let serviceClient  = InvoiceServiceClient()
                
                return try await serviceClient.validateCredentials(nit: nit,
                                                                   password: password,
                                                                   isProduction: isProduction,
                                                                   forceRefresh: true)
        }
        
        var areEquals: Bool {
            return password == confirmPassword
        }
        
        var disableUpdateCredentialsButton: Bool{
            return password.isEmpty && confirmPassword.isEmpty
        }
        
        var showCredentialsCheckerView : Bool = false
         
        
        var isValidCredentials : Bool = false
        
        
    }
    
    func SaveProfileChanges() async -> Bool{
        
        if !viewModel.areEquals{
            viewModel.showAlertMessage = true
            viewModel.message = "Las contraseñas no coinciden"
             return false
        }
         
        viewModel.isBusy = true
            
            do{
                let areValid = try await viewModel.validateCredentialsAsync(nit: selection.nit, password: viewModel.password,isProduction: selection.isProduction)
                
                if areValid{
                    selection.credentials = viewModel.password
                    
                    try? modelContext.save()
                    isPresented = false // close sheet
                    areInvalidCredentials = false // close invalid credentials view
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
                
        
        viewModel.showAlertMessage = true
        viewModel.message = "Actualizado con éxito"
        viewModel.isBusy = false
        
        return true
    }
    
    func EvaluateDisplayCredentialsCheckerView(){
        
        viewModel.showCredentialsCheckerView = !selection.credentials.isEmpty
        print("\(viewModel.showCredentialsCheckerView) Display Credentials checker")
        
    }
    
    func CheckCredentials() async  {
        viewModel.isBusy = true
       
            do{
                let areValid = try await viewModel.validateCredentialsAsync(nit: selection.nit, password: selection.credentials,isProduction: selection.isProduction)
                
                if !areValid{
                    viewModel.showAlertMessage = true
                    viewModel.message = "Contraseña incorrecta"
                    viewModel.isBusy = false
                    viewModel.isValidCredentials = false
                    viewModel.showCredentialsCheckerView = false// display edit credentials form
                }
                else{
                    viewModel.isValidCredentials = true
                }
                viewModel.isBusy = false
            }
            catch(let errorMessage)
            {
                print("\(errorMessage.localizedDescription)")
                viewModel.showAlertMessage = true
                viewModel.isBusy = false
                viewModel.message = "Error  las credenciales no coinciden con las registradas en Hacienda"
                 
            }
                
        
        
    }
}
