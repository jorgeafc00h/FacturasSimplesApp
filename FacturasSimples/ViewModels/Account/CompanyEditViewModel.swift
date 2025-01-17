import Foundation
import SwiftUI
import SwiftData

extension EmisorEditView {
    
    
    
    
    @Observable
    class CompanyEditViewModel{
        
        
        var displayCategoryPicker: Bool = false
        
        var isFileImporterPresented : Bool = false
         
        var codActividad: String?
        var desActividad: String?
       
         
       
    }
    
   
    var filteredMunicipios: [CatalogOption] {
        return company.departamentoCode.isEmpty ?
        municipios :
        municipios.filter{$0.departamento == company.departamentoCode}
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
    
    
    func loadData() {
        
        if !company.departamentoCode.isEmpty {
            company.departamento = departamentos.first(where: { $0.code == company.departamentoCode })!.details
        }
        if  company.departamentoCode.isEmpty &&
                !company.municipioCode.isEmpty &&
                !company.departamentoCode.isEmpty {
            company.municipio = municipios.first(where: { $0.departamento == company.departamento && $0.code == company.municipioCode })!.details
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
        dismiss()
    }
}
