import SwiftUI
import SwiftData

struct CompaniesListItem: View {
    
    var company : Company
    
    var isSelected : Bool = false
    
    var body: some View {
        
        //NavigationLink(destination: EmisorEditView(company: company)){
            HStack {
                Circle()
                    .fill(Color(isSelected ? .amarello :   .darkBlue))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "widget.small")
                            .font(.system(size: 38))
                            .foregroundStyle(.background)
                            .symbolEffect(.breathe, options: .nonRepeating)
                    }
                
                Circle()
                    .fill(isSelected ? .blue : .clear)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading) {
                    HStack{
                        
                        
                        Text(company.nombre)
                            .font(.headline)
                    }
                    Text(company.nombreComercial)
                        .font(.subheadline)
                    if case let (id?, p?) = (company.nit, company.telefono) {
                        Divider()
                        HStack {
                            Image(systemName: "widget.small")
                            Text(id)
                            Image(systemName: "phone")
                            Text(p)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    //}
}

#Preview (traits: .sampleCompanies) {
    @Previewable @Query var companies: [Company]
    List{
        CompaniesListItem(company: companies.first!)
    }
}

