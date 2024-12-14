import SwiftUI
import SwiftData


struct CompanyDetailsView : View {
    
    @State var company: Company
    
   
    
    var body : some View {
        VStack {
            
            List{
                CompanyViewForiOS
            }
            .navigationTitle(Text("Cliente"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        EmisorEditView(company: company)
                    } label: {
                        Image(systemName: "pencil.line")
                            .symbolEffect(.bounce, options: .nonRepeating)
                    }
                }
            }
        }
    }
    
    private var CompanyViewForiOS: some View {
        VStack{
            VStack(alignment: .leading) {
                Text(company.nombre)
                    .font(.title)
                    .bold()
                
                HStack {
                    Text("Telefono")
                    Spacer()
                    Text(company.telefono)
                }
                
                
                HStack {
                    Text("Email")
                    Spacer()
                    Text(company.correo)
                }
                
            }
            NavigationLink {
                EmisorEditView(company: company)
            } label: {
                HStack{
                    Image(systemName: "pencil.line")
                        .symbolEffect(.breathe, options: .nonRepeating)
                    Text("Actualizar datos")
                }.foregroundColor(.darkCyan)
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text(company.departamento)
                        .font(.title)
                        .bold()
                    Text(company.municipio)
                    Text(company.complemento)
                }
                
            } header: {
                Text("Direccion")
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text(company.nombreComercial)
                        .font(.title)
                        .bold()
                    HStack {
                        Text("NIT")
                        Spacer()
                        Text(company.nit)
                    }
                    HStack {
                        Text("NRC")
                        Spacer()
                        Text(company.nrc)
                    }
                    Text("Actividad Economica")
                    VStack {
                        
                        Text(company.descActividad)
                            .font(.subheadline)
                            .bold()
                    }.padding()
                    HStack {
                        Text("Cod Actividad").font(.caption)
                        Spacer()
                        Text(company.codActividad).font(.caption)
                    }
                }
                
            } header: {
                Text("Informacion de Negocio")
            }
        }
    
        }
}
#Preview(traits: .sampleCompanies) {
    @Previewable @Query var companies: [Company]
    CompanyDetailsView(company: companies.first!)
}
 
 
