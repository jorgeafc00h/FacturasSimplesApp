

import Foundation
import SwiftUI
import SwiftData

extension CustomersListView {
    
    @Observable
    class CustomersListViewModel{
       
        var isShowingItemsSheet: Bool = false
        
        var showDeleteCustomerConfirmation: Bool = false
        
        var offsets: IndexSet = []
        
        //var selection: Customer?
        var customersCount: Int = 0
        
        var toDeleteCustomer: Customer?
        
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        
        var showDeleteAlert : Bool = false
        
        var isDisabledEdit:Bool {
            customersCount == 0
        }
        
        func ConfirmDelete(at offsets: IndexSet){
            self.offsets = offsets
            showDeleteCustomerConfirmation = true
        }
        func showConfirmDelete(customer:Customer){
            toDeleteCustomer = customer
           showDeleteCustomerConfirmation = true
        }
         
        
    }
    
    
    
    func deleteCustomers(at offsets: IndexSet) {
            offsets.map { customers[$0] }.forEach(deleteCustomer)
        
    }
    
    func deleteCustomer(_ cust: Customer) {
        
        let id = cust.persistentModelID
        
        let descriptor = FetchDescriptor<Invoice>(predicate: #Predicate { $0.customer.persistentModelID ==  id })
        
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        if count > 0 {
            viewModel.alertTitle = "Error"
            viewModel.alertMessage = "No se puede eliminar un cliente con _\(count) facturas asociadas"
            viewModel.showAlert = true
            return
        }
        /**
         Unselect the item before deleting it.
         */
        withAnimation{
            if cust.persistentModelID == selection?.persistentModelID {
                selection = nil
            }
            modelContext.delete(cust)
        }
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
            
            let dp = departamentos.first(where: { $0.code == viewModel.departamentoCode})?.details ?? ""
            
            
            let mp = municipios.first(where: { $0.code == viewModel.municipioCode && $0.departamento == viewModel.departamentoCode})?.details ?? ""
            
            
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


extension CustomerEditView {
    
    @Observable
    class CustomerEditViewModel{
        var nrc : String = ""
        var departamento : String = ""
        var municipio : String = ""
        var nit: String = ""
        
        var displayPickerSheet: Bool = false
    
    }
    
    func SaveUpdate() {
        withAnimation {
            
            if customer.hasInvoiceSettings ||
                !viewModel.nrc.isEmpty || !viewModel.nit.isEmpty{
                customer.nrc = viewModel.nrc
                customer.nit = viewModel.nit
            }
            
            if modelContext.hasChanges {
                try! modelContext.save()
            }
        }
    }
    
    func InitCollections(){
        viewModel.departamento = customer.departamentoCode
        viewModel.municipio = customer.municipioCode
        viewModel.nrc = customer.nrc ?? ""
        viewModel.nit = customer.nit ?? ""
    }
    
    func onDepartamentoChange(){
        print("departamento: \(viewModel.departamento)")
        customer.departamentoCode = viewModel.departamento
        
        customer.departammento = departamentos.first(where: {$0.code == viewModel.departamento})!.details
    }
    
    
    func onMunicipioChange(){
        print("municipio code : \(viewModel.municipio)")
        if(!viewModel.municipio.isEmpty){
            customer.municipioCode = viewModel.municipio
            customer.municipio =
            municipios.first(where: {$0.departamento == viewModel.departamento &&  $0.code == viewModel.municipio})!.details
        }
    }
}
