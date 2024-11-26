import Foundation
import SwiftUI
import SwiftData

extension EmisorEditView {
    
    
    
    
    @Observable
    class EmisorEditViewModel{
        
        
        var displayCategoryPicker: Bool = false
        var emisor: Emisor
        
        
        var isDisabledSaveChanges: Bool{
            return false
        }
        
        init(emisor: Emisor){
            self.emisor = emisor
        }
        
      
    }
    
   
    var filteredMunicipios: [CatalogOption] {
        return viewModel.emisor.departamento.isEmpty ?
        municipios :
        municipios.filter{$0.departamento == viewModel.emisor.departamento}
    }
    
//    func loadData() {
//        do{
//            
//            
//            let descriptor = FetchDescriptor<Emisor>()
//            
//            let data = try modelContext.fetch(descriptor)
//            
//            _ = data.isEmpty ? Emisor() : data.first
//            
//           // viewModel.emisor = _emisor
//        }
//        catch{
//            print("error loading emisor data")
//        }
//    }
    
    func saveChanges() {
        try? modelContext.save()
        dismiss()
    }
}
