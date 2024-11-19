import Foundation
import SwiftUI
import SwiftData

extension EmisorEditView {
    
    
    
    
    @Observable
    class EmisorEditViewModel{
        
        
        var displayCategoryPicker: Bool = false
        
        
        
        var isDisabledSaveChanges: Bool{
            return false
        }
      
    }
    
   
    var filteredMunicipios: [CatalogOption] {
        return emisor.departamento.isEmpty ?
        municipios :
        municipios.filter{$0.departamento == emisor.departamento}
    }
    
    func saveChanges() {
        try? modelContext.save()
        dismiss()
    }
}
