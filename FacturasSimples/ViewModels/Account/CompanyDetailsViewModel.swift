import SwiftUI
import Foundation
import SwiftData

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
        
        var showCannotDeleteDialog : Bool = false
        
        var showDeleteConfirmDialog : Bool = false
        
        var summary: [InvoiceSummary] = []
        
        var requiresToGenerateTestInvoices: Bool = false
        
    }
    
    func setLoadingLabels(){
        print("set loading labels.......")
        viewModel.isLoadingCertificateStatus = true
        viewModel.isLoadingCertificateStatus = true
        viewModel.showCertificateInvalidMessage = true
        viewModel.showCredentialsInvalidMessage = true
    }
    
    // set default company
    func SetAsDefaultCompany(){
        withAnimation { 
            companyId = company.id
            selection = company
            selectedCompanyName = company.nombreComercial
            //Constants.IS_PRODUCTION = company.isTestAccount == false
            isProduction = company.isTestAccount == false
        }
    }
    func validateCertificateCredentialasAsync() async  {
        viewModel.isLoadingCertificateStatus = true
        
        let service = InvoiceServiceClient()
        
        
        let result = try? await service.validateCertificate(nit: company.nit, key: company.certificatePassword,isProduction: company.isProduction)
        
        print("Certificate Validation Result: \(String(describing: result))")
        
        if(result == nil || result! == false){
            
            viewModel.showCertificateInvalidMessage = true
        }
        else{
            viewModel.showCertificateInvalidMessage = false
        }
        viewModel.isLoadingCertificateStatus = false
    }
    
    func validateCredentialsAsync() async  {
        viewModel.isLoadingCredentialsStatus = true
        
        let service = InvoiceServiceClient()
        
        let result = try? await service.validateCredentials(nit: company.nit,
                                                            password: company.credentials,
                                                            isProduction: company.isProduction,
                                                            forceRefresh: false)
        print("Credentials Validation Result: \(String(describing: result))")
        
        if( result == nil || result! == false){
            viewModel.showCredentialsInvalidMessage = true
        }
        else{
            viewModel.showCredentialsInvalidMessage = false
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
    
    
    
    func hasNoInvoicesToRequestAccess() -> Bool {
        let id = company.id
        let fetchRequest = FetchDescriptor<Invoice>(predicate: #Predicate { $0.customer?.companyOwnerId == id })
        let count = (try? modelContext.fetchCount(fetchRequest)) ?? 0
        return count < 100
    }
    
    func hasInvoices() -> Bool {
        let id = company.id
        let fetchRequest = FetchDescriptor<Invoice>(predicate: #Predicate {  $0.customer?.companyOwnerId == id })
        let count = (try? modelContext.fetchCount(fetchRequest)) ?? 0
         
        return count > 0
    }
    
    func deleteCompany() {
        // Remove this company from SwiftData
        modelContext.delete(company)
        
        // If this was the selected company, clear the selection
        if selectedCompanyId == company.id {
            companyId = ""
            selectedCompanyName = ""
        }
        
       try? modelContext.save()
        // Navigate back after deletion
        dismiss()
    }
    
    func refreshLabels() {
        setLoadingLabels()
        viewModel.requiresToGenerateTestInvoices = hasNoInvoicesToRequestAccess()
        viewModel.summary = []
        
//        let invoiceTypes: [InvoiceType] = [.Factura, .CCF]
//        for type in invoiceTypes {
//            print("type raw:\(type.rawValue)")
//            
//            let fetchRequest = FetchDescriptor<Invoice>(predicate: #Predicate {
//                $0.invoiceType.hashValue == type.hashValue  && $0.customer.companyOwnerId == id
//            })
//            let count = (try? modelContext.fetchCount(fetchRequest)) ?? 0
//            let summary = InvoiceSummary(total: count, invoiceType:  type.stringValue())
//            viewModel.summary.append(summary)
//        }
//
        let id = company.id
        // ALL COUNT
        let fetchRequest = FetchDescriptor<Invoice>(predicate: #Predicate { $0.customer?.companyOwnerId == id })
        let count = (try? modelContext.fetchCount(fetchRequest)) ?? 0
        let summary = InvoiceSummary(total: count, invoiceType:  "Total Documentos Generados")
        viewModel.summary.append(summary)
        
        Task{
          await validateCertificateCredentialasAsync()
            await validateCredentialsAsync()
        }
    }
}
