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
                            Image(systemName: "widget.small")
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
