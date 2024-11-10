

import Foundation
import SwiftUI
import SwiftData

extension CustomersListView {
    
    @Observable
    class CustomersListViewModel{
       
        var isShowingItemsSheet: Bool = false
        
        //var selection: Customer?
        var customersCount: Int = 0
        
        var isDisabledEdit:Bool {
            customersCount == 0
        }
        
         
        
    }
    
    /// extensions methdos
    
    func deleteCustomers(at offsets: IndexSet) {
        withAnimation {
            offsets.map { customers[$0] }.forEach(deleteCustomer)
        }
    }
    
    func deleteCustomer(_ cust: Customer) {
        /**
         Unselect the item before deleting it.
         */
        if cust.persistentModelID == selection?.persistentModelID {
            selection = nil
        }
        modelContext.delete(cust)
    }
}


extension AddCustomerView{
    
    @Observable
    class AddCustomerViewModel{
        
        var firstName: String = ""
        var lastName: String = ""
        var company: String = ""
        var address: String = ""
        var city: String = ""
        var state: String = ""
        
        var email: String = ""
        
        var phone: String = ""
        var nationalId: String = ""
        var contributorId: String = ""
        var nit: String = ""
        var documentType: String = ""
        var codActividad: String?
        var descActividad: String?
        var departamentoCode: String = ""
        var municipioCode: String = ""
        var departammento: String = ""
        var municipio: String = ""
        
        var hasInvoiceSettings: Bool = false
        var nrc: String = ""
        var displayPickerSheet: Bool = false
        
        
        var ActividadLabel : String {
            descActividad ?? "Seleccione Acvitdad Economica"
        }
        var isSaveCustomerDisabled : Bool {
            firstName.isEmpty || lastName.isEmpty || nationalId.isEmpty || email.isEmpty
        }
    }
    
    // extension methods
    
    func addCustomer() {
        withAnimation {
            
            let dp = departamentos.first(where: { $0.code == viewModel.departamentoCode})!.details
            let mp = municipios.first(where: { $0.code == viewModel.municipioCode && $0.departamento == viewModel.departamentoCode})!.details
            
            
            let newCustomer = Customer( firstName: viewModel.firstName,
                                        lastName: viewModel.lastName,
                                        nationalId: viewModel.nationalId,
                                        email: viewModel.email,
                                        phone: viewModel.phone,
                                        departammento: dp,
                                        municipio: mp,
                                        address: viewModel.address,
                                        company: viewModel.company
            )
            
            newCustomer.departamentoCode  = viewModel.departamentoCode
            newCustomer.municipioCode = viewModel.municipioCode
            
            newCustomer.hasInvoiceSettings = viewModel.hasInvoiceSettings
            newCustomer.descActividad = viewModel.descActividad
            newCustomer.codActividad = viewModel.codActividad
            newCustomer.nit = viewModel.nit
            newCustomer.nrc = viewModel.nrc
            
            
            modelContext.insert(newCustomer)
            try? modelContext.save()
        }
    }
    
}
