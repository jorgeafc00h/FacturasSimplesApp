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

extension AddCompanyView3 {

    @Observable
    class AddCompanyViewModel {
        var isBusy: Bool = false
        
        var displayCategoryPicker: Bool = false
        
        var isFileImporterPresented : Bool = false
        
        var isCertificateImporterPresented : Bool = false
         
        var codActividad: String?
        var desActividad: String?
        
        var showAlertMessage :Bool = false
        var showConfirmSyncSheet: Bool = false
        var message: String = ""
        
        var selectedUrl : URL?
        var nit: String = ""
        
        var step1: Bool = true
        var step2: Bool = false
        var step3: Bool = false
        
        func ShowStep2() {
            step1 = false
            step2 = true
            step3 = false
        }
        
        func ShowStep3() {
            step1 = false
            step2 = false
            step3 = true
        }
       
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
    
    func importImageLogo(_ result : Result<[URL], Error>) {
        
        switch result {
        case .success(let urls):
            if let url = urls.first{
                // get image as Base64
                print("url \(url)")
                
                 
                    let access = url.startAccessingSecurityScopedResource()
                    do {
                       if access {
                           
                           let imageData = try Data(contentsOf: url)
                           let base64String = imageData.base64EncodedString()
                           print("base64String \(base64String)")
                           
                           company.invoiceLogo = base64String
                           
                           url.stopAccessingSecurityScopedResource()
                       }
                    }
                    
                
                
                catch {
                    print("error \(error)")
                }
            }
        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
        }
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
                    
                    let result = try await service.uploadCertificate(data: certificate, nit: viewModel.nit)
                    
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
