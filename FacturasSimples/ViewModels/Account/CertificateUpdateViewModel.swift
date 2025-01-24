
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
        
        var IsDisabledSaveCertificate : Bool {
            return password.isEmpty || confirmPassword.isEmpty
        }
    }
    
    func updateCert()  {
       
        if(viewModel.confirmPassword != viewModel.password){
            viewModel.showAlertMessage = true
            viewModel.message="Passwords no coinciden"
            return
        }
        
        if let company = selection{
            company.certificatePassword = viewModel.password
            //modelContext.save(options: .atomic)
            viewModel.showAlertMessage = true
            viewModel.message = "Contraseña del certificado actualizada"
            try? modelContext.save()
            
        }
        else{
            viewModel.showAlertMessage = true
            viewModel.message = ""
        }
    }
    
    func importFile(_ result : Result<[URL], Error>) {
        switch result {
            
        case .success(let urls):
            if let url = urls.first{
                
                print("url \(url)")
                    if let company = selection{
                        viewModel.nit = company.nit
                    }
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
                    
                    let result = try await service.uploadCertificate(data: certificate, nit: viewModel.nit)
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
//    func getDocumentsDirectory() -> URL {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
// 
}
