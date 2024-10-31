 

import SwiftUI

struct SearchPicker :View {
    @Environment(\.dismiss) private var dismiss
    @Binding var  options : [CatalogOption]
    
    @Binding var selection : CatalogOption?
    
    @State var keywords : String = ""
    var title: String = ""
    
    
    init(selection:Binding<CatalogOption?>, options: Binding< [CatalogOption]>,
         title:String){
        _selection = selection
        _options = options
        self.title = title
    }
    
    var body: some View {
        VStack{
            SearchBar()
            List(selection: $selection){
                ForEach(options){option in
                    Text(option.details)
                }
            }
            .searchable(text: $keywords, placement: .sidebar)
            
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selection) {
                dismiss()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
            }.accentColor(.darkCyan)
        }
    }
}
