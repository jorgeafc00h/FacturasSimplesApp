import SwiftUI
import SwiftData
import Foundation
import UniformTypeIdentifiers

extension AddCompanyView2{
    
    
    @Observable
    class AddcompnayStep2ViewModel{
        var showSelectDepartamentoSheet: Bool = false
        
        var showSelectMunicipioSheet: Bool = false
        
        
    }
  
    func onDepartamentoChange() {
        print("dep: \(company.departamentoCode)")
        company.departamento =
        !company.departamentoCode.isEmpty ?
        departamentos.first(where: { $0.code == company.departamentoCode })!.details
        : ""
        print("dep: \(company.departamento) \(company.departamentoCode)")
    }
    func onMunicipioChange() {
        print("mun \(company.municipioCode)")
        
        if !company.municipioCode.isEmpty &&
           !company.departamentoCode.isEmpty{
            
            let m =  municipios.first(where:{
                $0.departamento == company.departamentoCode && $0.code == company.municipioCode
            })
            
            if m != nil{
                company.municipio = m!.details
            }
            
        }
         
    }
}

extension AddCompanyView4 {

    @Observable
    class AddCompanyViewModel {
        var isBusy: Bool = false
        
        var displayCategoryPicker: Bool = false
        
        var isFileImporterPresented : Bool = false
        
        var isCertificateImporterPresented : Bool = false
        
        var isValidatingCertificateCredentials: Bool = false
        
        var showConfirmUpdatePassword : Bool = false
         
        var showAlertMessage :Bool = false
        var showValidationMessage :Bool = false
        var showConfirmSyncSheet: Bool = false
        var message: String = ""
        
        var selectedUrl : URL?
        
        var password :String = ""
        var confirmPassword :String = ""
       
    }
    
    
    func saveChanges() {
        
        let id = company.id
        
        let descriptor = FetchDescriptor<Company>(predicate: #Predicate { $0.id ==  id })
        
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        if count == 0 {
            modelContext.insert(company)
           
        }
        
        try? modelContext.save()
        selectedCompanyId = id
    }
    
    func updateMHCertificateCredentialValidation(){
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
    
    func updateMHCertificateCredentials() async  {
        viewModel.isValidatingCertificateCredentials = true
        
        let encryptedPassword = try! Cryptographic.encrypt(viewModel.password)
        
        let service = InvoiceServiceClient()
        let result = try? await service.validateCertificate(nit: company.nit, key: encryptedPassword,isProduction: company.isProduction)
        
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
        
        viewModel.isValidatingCertificateCredentials = false
    }
        
    func importFile(_ result : Result<[URL], Error>) {
        switch result {
            
        case .success(let urls):
            if let url = urls.first{
                
                print("url \(url)")
                     
                    //viewModel.nit = company.nit
                    
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
                    
                    let result = try await service.uploadCertificate(data: certificate, nit: company.nit,isProduction: company.isProduction)
                    
                    // now check certificate crecentials if credentials are empty , lets display a warning.
                    viewModel.showAlertMessage = true
                    if(result){
                         
                        viewModel.message = company.certificatePassword.isEmpty ?
                        "El Certificado se actualizao correctamente, Debe establecer una contraseña para el certificado" :
                        "Certificado Actualizado!"
                    }
                    else{
                        viewModel.message = "Error al actualizar el certificado"
                    }
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
