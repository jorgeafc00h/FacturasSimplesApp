

import SwiftUI
import SwiftData

struct SearchPicker :View {
    @Environment(\.dismiss) private var dismiss
    
    var catalogId: String
     
    
    @Query(filter: #Predicate<CatalogOption> { $0.catalog.id == ""})
    private var options : [CatalogOption]
    
    @Binding var selection : String?
    
    @Binding var selectedDescription : String?
    
    @Binding var showSearch: Bool
    
    var title: String
    
    @State private var searchText: String = ""
    
    var filteredOptions: [CatalogOption] {
        if searchText.isEmpty {
           options
        } else {
            options.filter { $0.details.localizedStandardContains(searchText) }
        }
    }
    init(catalogId: String ,
         selection : Binding<String?>,
         selectedDescription: Binding<String?>,
         showSearch: Binding<Bool>,
         title: String){
        
        self.catalogId = catalogId
        _selection = selection
        _showSearch = showSearch
        self.title = title
        _selectedDescription = selectedDescription
        
        let predicate = #Predicate<CatalogOption> {
            searchText.isEmpty ?
            $0.catalog.id == catalogId :
            $0.catalog.id == catalogId &&
            $0.details.localizedStandardContains(searchText)
            
        }
        _options = Query(filter: predicate, sort: \CatalogOption.details)
    }
    
    var body: some View {
        NavigationView {
            List{
                ForEach(filteredOptions){ option in
                    SearchPickerItem(option: option)
                        .onTapGesture {
                            withAnimation {
                                showSearch = false
                                selection = option.code
                                selectedDescription = option.details
                                searchText = ""
                                
                            }
                        }
                }
            }
            
            .listStyle(.plain)
           
            .frame(idealWidth: LayoutConstants.sheetIdealWidth,
                   idealHeight: LayoutConstants.sheetIdealHeight)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
            }.accentColor(.darkCyan)
        }
        .searchable(text: $searchText, prompt: "Buscar")
    }
}

private struct SearchPickerItem: View {
    
    @State var option: CatalogOption
    
    var body: some View {
        HStack {
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
            
            Text(option.details)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
        }
        
    }
}

#Preview(traits: .sampleOptions) {
    @Previewable @Query var samples: [CatalogOption]
    
    List {
        SearchPickerItem(option: samples.first!)
    }
}
