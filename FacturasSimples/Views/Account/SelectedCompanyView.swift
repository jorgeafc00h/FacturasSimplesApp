import SwiftUI

struct  SelectedCompanyButton: View {
    
    @Binding var selection: Company?
    
    var body: some View {
        
        
        Button(action: {}, label: {
            
            if let company = selection {
                HStack {
                    Circle()
                        .fill(Color(.darkCyan ))
                        .frame(width: 55, height: 55)
                        .overlay {
                            Image(systemName: company.isTestAccount ? "testtube.2" : "widget.small")
                                .font(.system(size: 30))
                                .foregroundStyle(.background)
                                .symbolEffect(.breathe, options: .nonRepeating)
                        }
                    
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Text(company.nombreComercial)
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        Text(company.nombre)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(company.correo)
                            .font(.headline)
                            .foregroundColor(.white)
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
                                    .foregroundColor(.white)
                                Text(id).font(.headline).foregroundColor(.white)
                                Image(systemName: "phone")
                                    .foregroundColor(.white)
                                Text(p).font(.headline).foregroundColor(.white)
                            }
                            .font(.caption)
                        }
                    }.padding(.leading, 10.0)
                    // Spacer()
                }.padding()
            }
            else{
                HStack {
                    Image(systemName: "dollarsign.bank.building").padding(.horizontal, 5.0)
                        .foregroundColor(Color.white)
                    Text("Seleccione Empresa")
                        .foregroundColor(Color.white)
                    Spacer()
                    
                    
                }.padding()
            }
        }) .background(Color( selection == nil ? .clear : .darkBlue))
            .clipShape(RoundedRectangle(cornerRadius: 1.0)).padding(.horizontal, 8.0)
        
    }
}
