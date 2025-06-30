import SwiftUI

// MARK: - Production Company Card
struct ProductionCompanyCard: View {
    let company: Company
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.darkCyan)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "widget.small")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, options: .nonRepeating)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(company.nombreComercial)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(company.nombre)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Text("Ambiente Productivo")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                            
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.darkCyan)
                            .symbolEffect(.bounce, options: .nonRepeating)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                if isSelected {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Esta empresa será establecida como predeterminada")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .background(Color.blue.opacity(0.05))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.darkCyan : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isSelected ? 0.1 : 0.05), radius: isSelected ? 4 : 2)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

#Preview {
    VStack(spacing: 16) {
        ProductionCompanyCard(
            company: Company(
                nit: "12345678-9",
                nrc: "123456-7",
                nombre: "Empresa de Prueba S.A. de C.V.",
                nombreComercial: "Empresa Demo",
                isTestAccount: false
            ),
            isSelected: false,
            onTap: {}
        )
        
        ProductionCompanyCard(
            company: Company(
                nit: "98765432-1",
                nrc: "987654-3",
                nombre: "Compañía Ejemplo Limitada",
                nombreComercial: "Demo Company",
                isTestAccount: false
            ),
            isSelected: true,
            onTap: {}
        )
    }
    .padding()
}
