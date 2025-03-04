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
        
        var showEditCompanySheet : Bool = false
        
        var showSetAsDefailtConfirmDialog : Bool = false
        
        var showEditCertificateCredentials: Bool = false
        
        var isLoadingCertificateStatus: Bool = false
        var isLoadingCredentialsStatus: Bool = false
        
        
        
        var showCertificateInvalidMessage: Bool = false
        var showCredentialsInvalidMessage: Bool = false
        
    }
    // set default company
    func SetAsDefaultCompany(){
        withAnimation { 
            companyId = company.id
            selection = company
            selectedCompanyName = company.nombreComercial
        }
    }
    func validateCertificateCredentialasAsync() async  {
        viewModel.isLoadingCertificateStatus = true
        
        let service = InvoiceServiceClient()
        
        let result = try? await service.validateCertificate(nit: company.nit, key: company.certificatePassword)
        
        print("Certificate Validation Result: \(String(describing: result))")
        
        if(result == nil || result! == false){
            
            viewModel.showCertificateInvalidMessage = true
        }
        viewModel.isLoadingCertificateStatus = false
    }
    
    func validateCredentialsAsync() async  {
        viewModel.isLoadingCredentialsStatus = true
        
        let service = InvoiceServiceClient()
        
        let result = try? await service.validateCredentials(nit: company.nit, password: company.credentials,forceRefresh: false)
        print("Credentials Validation Result: \(String(describing: result))")
        
        if( result == nil || result! == false){
            viewModel.showCredentialsInvalidMessage = true
        }
        
        viewModel.isLoadingCredentialsStatus = false
    }
    
    func hasMissingInvoiceLogo() -> Bool {
        return company.invoiceLogo.isEmpty
    }
    
    func hasAnyMissingField() -> Bool {
        
        //        print("nit \(company.nit)")
        //        print("nombre: \(company.nombre)")
        //        print("nombrecomercial \(company.nombreComercial)")
        //        print("nrc: \(company.nrc)")
        //        print("departamentoCode: \(company.departamentoCode)")
        //        print("Departamento: \(company.departamento)")
        //        print("municipioCode: \(company.municipioCode)")
        //        print("complemento: \(company.complemento)")
        //        print("correo: \(company.correo)")
        //        print("tipoEstablecimiento \(company.tipoEstablecimiento)")
        //        print("cod Actividad: \(company.codActividad)")
        //        print("des Actividad \(company.descActividad)")
        //
        return company.nit.isEmpty ||
        company.nombre.isEmpty ||
        company.nombreComercial.isEmpty ||
        company.nrc.isEmpty ||
        company.departamentoCode.isEmpty  ||
        company.municipioCode.isEmpty ||
        company.complemento.isEmpty ||
        company.correo.isEmpty ||
        company.tipoEstablecimiento.isEmpty ||
        company.codActividad.isEmpty  ||
        company.descActividad.isEmpty 
    }
    
    func isDisabledSelectAsPrimary() -> Bool {
        
        let id = companyId.isEmpty ? selectedCompanyId  : companyId
        
        return company.id == id
    }
}
