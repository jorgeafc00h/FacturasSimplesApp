
import SwiftUI
import SwiftData
import Foundation

extension CertificateUpdate{
    
    @Observable
    class CertificateUpdateViewModel{
        
        var isBusy : Bool = false
        var password = ""
        var confirmPassword = ""
        var isCertificateImporterPresented : Bool = false
        var showAlertMessage : Bool = false
        var message : String = ""
        
        var selectedUrl : URL?
        var nit: String = ""
        var showConfirmSyncSheet : Bool = false
        
        var isValidatingCertificateCredentials : Bool = false
        var showConfirmUpdatePassword: Bool = false
        
        var showValidationMessage: Bool = false
        
        
    }
    
    func updateCertCredentialValidation(){
        if(viewModel.confirmPassword != viewModel.password ||
           viewModel.confirmPassword.isEmpty || viewModel.password.isEmpty){
            viewModel.showValidationMessage = true
            viewModel.message="Passwords no coinciden"
            return
        }
        else{
            viewModel.showConfirmUpdatePassword = true
        }
    }
    
    func updateCertCredentials() async  {
        viewModel.isValidatingCertificateCredentials = true
       
            let encryptedPassword = try! Cryptographic.encrypt(viewModel.password)
            
           
            
            let service = InvoiceServiceClient()
            let result = try? await service.validateCertificate(nit: company.nit, key: encryptedPassword)
           
            if(result != nil && result!){
                company.certificatePassword = encryptedPassword
                viewModel.showAlertMessage = true
                viewModel.message = "Contraseña del certificado actualizada"
                try? modelContext.save()
            }
            else{
                viewModel.showValidationMessage = true
                viewModel.message = "Error al actualizar Contraseña, actualize y verifique la contraseña del certificado en el portal de Hacienda"
            }
        
//        else{
//            viewModel.showAlertMessage = true
//            viewModel.message = ""
//        }
        viewModel.isValidatingCertificateCredentials = false
    }
    
    func importFile(_ result : Result<[URL], Error>) {
        switch result {
            
        case .success(let urls):
            if let url = urls.first{
                
                print("url \(url)")
                    
                    viewModel.nit = company.nit
                    
                    viewModel.selectedUrl = url
                
                    print("result \(result)")
                    viewModel.showConfirmSyncSheet = true
                    viewModel.message = ""
                
            }case .failure(let error):
            viewModel.showAlertMessage = true
            viewModel.message = error.localizedDescription
            print("Error selecting file: \(error.localizedDescription)")
        }
    }
    
    func uploadAsync () async -> Bool {
        let service = InvoiceServiceClient()
        viewModel.isBusy = true
            do {
                let url = viewModel.selectedUrl!
                
                _ = url.startAccessingSecurityScopedResource()
                let fileData = try? Data.init(contentsOf: url)
                
                if let certificate = fileData {
                    
                    _ = try await service.uploadCertificate(data: certificate, nit: viewModel.nit)
                    viewModel.showAlertMessage = true
                    viewModel.message = "Certificado Actualizado!"
                }
                viewModel.isBusy = false
                 return true
            } catch (let error){
                viewModel.isBusy = false
                print("File could not be saved")
                viewModel.showAlertMessage = true
                viewModel.message = error.localizedDescription
            }
        
        return false
    }
}
