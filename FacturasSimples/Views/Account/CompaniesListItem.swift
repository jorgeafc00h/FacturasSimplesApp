import SwiftUI
import SwiftData

struct CompaniesListItem: View {
    var company: Company
    var isSelected: Bool = false
    
    var body: some View {
        NavigationLink(value: company){
            HStack {
                Circle()
                    .fill(Color(isSelected ? .amarello : .darkBlue))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: company.isTestAccount ? "testtube.2" : "widget.small")
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
                    
                    HStack {
                        Text(company.isTestAccount ? "Ambiente Pruebas" : "Ambiente Productivo")
                            .font(.subheadline)
                            .foregroundColor(company.isTestAccount ? .amarello : .green)
                            .padding(7)
                            .background(.amarello.opacity(0.09))
                            .cornerRadius(8)
                        Spacer()
                        Image(systemName: company.isTestAccount ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(company.isTestAccount ? .amarello : .green)
                            .foregroundStyle(.background)
                            .symbolEffect(.breathe, options: .nonRepeating)
                    }
                    
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
            .padding(3)
           
            
        }
    }
}

#Preview (traits: .sampleCompanies) {
    @Previewable @Query var companies: [Company]
    List{
        CompaniesListItem(company: companies.first!)
    }
}

