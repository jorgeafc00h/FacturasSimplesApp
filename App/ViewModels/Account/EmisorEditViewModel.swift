import Foundation
import SwiftUI
import SwiftData

extension EmisorEditView {
    
    
    
    
    @Observable
    class EmisorEditViewModel{
        
        
        var displayCategoryPicker: Bool = false
        var emisor: Emisor = Emisor()
         
        
        var isDisabledSaveChanges: Bool{
            return false
        }
        
      
    }
    
   
    var filteredMunicipios: [CatalogOption] {
        return viewModel.emisor.departamentoCode.isEmpty ?
        municipios :
        municipios.filter{$0.departamento == viewModel.emisor.departamentoCode}
    }
    
    
    func onDepartamentoChange() {
        print("dep: \(viewModel.emisor.departamentoCode)")
        viewModel.emisor.departamento =
        !viewModel.emisor.departamentoCode.isEmpty ?
        departamentos.first(where: { $0.code == viewModel.emisor.departamentoCode })!.details
        : ""
        print("dep: \(viewModel.emisor.departamento) \(viewModel.emisor.departamentoCode)")
    }
    func onMunicipioChange() {
        print("mun \(viewModel.emisor.municipioCode)")
        
        if !viewModel.emisor.municipioCode.isEmpty &&
           !viewModel.emisor.departamentoCode.isEmpty{
            
            let m =  municipios.first(where:{
                $0.departamento == viewModel.emisor.departamentoCode && $0.code == viewModel.emisor.municipioCode
            })
            
            if m != nil{
                viewModel.emisor.municipio = m!.details
            }
            
        }
         
    }
    
    
    func loadData() {
        do{
            
            
            let descriptor = FetchDescriptor<Emisor>()
            
            let data = try modelContext.fetch(descriptor)
             
            if data.isEmpty{
                let em  = Emisor()
                modelContext.insert(em)
                viewModel.emisor = em
            }
            else{
                
                viewModel.emisor = data.first!
            }
            
            let em = viewModel.emisor
            
            if !em.departamentoCode.isEmpty {
                em.departamento = departamentos.first(where: { $0.code == viewModel.emisor.departamentoCode })!.details
            }
            if  em.departamentoCode.isEmpty &&
                !em.municipioCode.isEmpty &&
                !em.departamentoCode.isEmpty {
                em.municipio = municipios.first(where: { $0.departamento == viewModel.emisor.departamento && $0.code == viewModel.emisor.municipioCode })!.details
            }
            viewModel.emisor = em
        }
        catch{
            print("error loading emisor data")
        }
    }
    
    func saveChanges() {
        try? modelContext.save()
        dismiss()
    }
}
