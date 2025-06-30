import SwiftUI
import SwiftData

// MARK: - Production Company Selection View
struct ProductionCompanySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCompany: Company?
    let onConfirm: () -> Void
    
    @Query(filter: #Predicate<Company> { $0.isTestAccount == false }, sort: \Company.nombreComercial)
    private var productionCompanies: [Company]
    
    @Query(filter: #Predicate<Company> { $0.isTestAccount == true }, sort: \Company.nombreComercial)
    private var testCompanies: [Company]
    
    @State private var selectedTestCompany: Company?
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.darkCyan)
                    .symbolEffect(.bounce, options: .nonRepeating)
                
                Text("Selecciona una empresa configurada para producción")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.primary)
                
                Text("Los créditos solo pueden comprarse para empresas de producción")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            
            if productionCompanies.isEmpty {
                if !testCompanies.isEmpty {
                    // Show test company selector to request production access
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Text("Selecciona una empresa de prueba para solicitar autorización a producción")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(.primary)
                            
                            Text("Primero debes solicitar autorización para convertir una empresa de prueba en producción")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(testCompanies, id: \.id) { company in
                                    TestCompanyCard(
                                        company: company,
                                        isSelected: selectedTestCompany?.id == company.id,
                                        onTap: {
                                            selectedTestCompany = company
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            if let testCompany = selectedTestCompany {
                                dismiss()
                                // Navigate to production request for selected test company
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("NavigateToProductionRequest"), 
                                    object: testCompany
                                )
                            }
                        }) {
                            Text("Solicitar Autorización a Producción")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTestCompany != nil ? Color.darkCyan : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(selectedTestCompany == nil)
                        .padding(.horizontal)
                    }
                } else {
                    // No companies at all
                    ContentUnavailableView {
                        Label("Sin empresas configuradas", systemImage: "building.fill")
                            .symbolEffect(.breathe)
                    } description: {
                        Text("Necesitas configurar al menos una empresa antes de comprar créditos.")
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    } actions: {
                        Button("Cerrar") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(productionCompanies, id: \.id) { company in
                            ProductionCompanyCard(
                                company: company,
                                isSelected: selectedCompany?.id == company.id,
                                onTap: {
                                    selectedCompany = company
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    if selectedCompany != nil {
                        onConfirm()
                        dismiss()
                    }
                }) {
                    Text("Continuar con esta empresa")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedCompany != nil ? Color.darkCyan : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(selectedCompany == nil)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Comprar Créditos")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancelar") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Test Company Card
private struct TestCompanyCard: View {
    let company: Company
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.amarello)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "testtube.2")
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
                            Text("Ambiente de Pruebas")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.amarello)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.amarello.opacity(0.1))
                                .cornerRadius(4)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.amarello)
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
                        Text("Se solicitará autorización para esta empresa")
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

#Preview("With Production Companies") {
    NavigationStack {
        ProductionCompanySelectionView(
            selectedCompany: .constant(nil),
            onConfirm: {
                print("Confirmed selection")
            }
        )
    }
}

#Preview("Test Companies Only") {
    NavigationStack {
        ProductionCompanySelectionView(
            selectedCompany: .constant(nil),
            onConfirm: {
                print("Confirmed selection")
            }
        )
    }
}
