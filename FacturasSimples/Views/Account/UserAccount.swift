import SwiftUI
import SwiftData

struct UserAccountView: View {
    
    @Environment(\.modelContext) var modelContext
    @State private var showDeactivateAlert = false
    @State private var showDeactivationSuccessAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeletionSuccessAlert = false
    @Environment(\.dismiss) private var dismiss
    
    // Access to companies data using SwiftData
    @Query var companies: [Company]
    
    // User information from AppStorage
    @AppStorage("storedName") var storedName: String = ""
    @AppStorage("storedEmail") var storedEmail: String = ""
    @AppStorage("userID") var userID: String = ""
    
    // Local state to store computed values
    @State private var invoiceCountsByCompany: [String: Int] = [:]
    
    let invoiceSerivce = InvoiceServiceClient()
    
    init() {
        // Initialize the query to fetch all companies
        let descriptor = FetchDescriptor<Company>()
        _companies = Query(descriptor)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // User Info Card
                userInfoCard
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // Company Data Section
                companySectionView
                    .padding(.horizontal)
                    .padding(.top, 25)
                
                Spacer(minLength: 30)
                
                // Delete account button
                deactivateButton
                    .padding(.horizontal, 30)
                
                // Deactivate account button
                deleteButton
                    .padding(.horizontal, 30)
                    .padding(.top, 15)
                    .padding(.bottom, 20)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            loadInvoiceCounts()
        }
        // Success alert after deactivation
        .alert("Cuenta Desactivada", isPresented: $showDeactivationSuccessAlert) {
            Button("Entendido", role: .destructive) {
                // Clear user data and return to login
                clearUserData()
                dismiss()
            }
        } message: {
            Text("Su cuenta ha sido desactivada correctamente. Para volver a usar esta increíble aplicación, necesitará reiniciar la app e iniciar sesión nuevamente.")
        }
        // Success alert after deletion
        .alert("Cuenta Eliminada", isPresented: $showDeletionSuccessAlert) {
            Button("Entendido", role: .destructive) {
                // Clear user data and return to login
                clearUserData()
                dismiss()
            }
        } message: {
            Text("Su cuenta ha sido eliminada permanentemente. Toda su información ha sido borrada de nuestros sistemas.")
        }
    }
    
    private var headerView: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color(red: 18/255, green: 31/255, blue: 61/255))
                .frame(height: 120)
            
            HStack {
                Text("Información de la cuenta")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .padding(.leading, 20)
                
                Spacer()
            }
        }
    }
    
    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Información del usuario")
                .font(.headline)
                .padding(.vertical, 15)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(red: 18/255, green: 31/255, blue: 61/255))
                    
                    Text(storedName)
                        .font(.body)
                }
                
                HStack(spacing: 15) {
                    Image(systemName: "envelope.fill")
                        .resizable()
                        .frame(width: 24, height: 18)
                        .foregroundColor(Color(red: 18/255, green: 31/255, blue: 61/255))
                    
                    Text(storedEmail)
                        .font(.body)
                }
                
//                HStack(spacing: 15) {
//                    Image(systemName: "person.badge.key.fill")
//                        .resizable()
//                        .frame(width: 24, height: 24)
//                        .foregroundColor(Color(red: 18/255, green: 31/255, blue: 61/255))
//
//                    Text(userID)
//                        .font(.body)
//                        .lineLimit(1)
//                        .truncationMode(.middle)
//                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var deleteButton: some View {
        Button(action: {
            // Call the delete account function
            deleteAccount()
        }) {
            HStack {
                Spacer()
                Image(systemName: "trash.fill")
                    .font(.headline)
                Text("Eliminar cuenta")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(12)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Confirmación"),
                message: Text("¿Estás seguro de que deseas eliminar tu cuenta?"),
                primaryButton: .destructive(Text("Eliminar")) {
                    deleteAccount()
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
    }
    
    private var companySectionView: some View {
        VStack(spacing: 0) {
            Text("Facturas por empresa")
                .font(.headline)
                .padding(.vertical, 15)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous), corners: [.topLeft, .topRight])
            
            Divider()
            
            if companies.isEmpty {
                emptyCompaniesView
            } else {
                companiesListView
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var emptyCompaniesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
                .padding(.top, 20)
            
            Text("No hay empresas registradas")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Las empresas que registres aparecerán aquí")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous), corners: [.bottomLeft, .bottomRight])
    }
    
    private var companiesListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(companies.enumerated()), id: \.element.id) { index, company in
                VStack(spacing: 0) {
                    CompanyInvoiceSummary(
                        company: company,
                        invoicesCreated: invoiceCountsByCompany[company.id] ?? 0
                    )
                    .padding(.vertical, 15)
                    .padding(.horizontal)
                    
                    if index < companies.count - 1 {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous), corners: [.bottomLeft, .bottomRight])
    }
    
    private var deactivateButton: some View {
        Button(action: {
            showDeactivateAlert = true
        }) {
            HStack {
                Spacer()
                Image(systemName: "person.crop.circle.badge.minus")
                    .font(.headline)
                Text("Desactivar cuenta")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.amarello)
            .cornerRadius(12)
        }
        .alert(isPresented: $showDeactivateAlert) {
            Alert(
                title: Text("Confirmación"),
                message: Text("¿Estás seguro de que deseas desactivar tu cuenta?"),
                primaryButton: .destructive(Text("Desactivar")) {
                    deactivateAccount()
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
    }
    
    func loadInvoiceCounts() {
        // This would typically query SwiftData for invoice counts
        // For now we'll use mock data, but you'd replace this with actual SwiftData queries
        for company in companies {
            // Only getting created invoices, removed completed
            
            let id = company.id
        
            let descriptor = FetchDescriptor<Invoice>(predicate: #Predicate { $0.customer.companyOwnerId == id  })
            
            let createdCount = try? modelContext.fetchCount(descriptor)
            
            //let completed = FetchDescriptor<Invoice>(predicate: #Predicate { $0.customer.companyOwnerId == id && $0.status == .completed })
             
            invoiceCountsByCompany[company.id] = createdCount
        }
    }
    
    func deactivateAccount() {
        // Implement account deactivation logic here
        print("Cuenta desactivada")
        
        Task{
            try? await invoiceSerivce.deactivateAccount(email: storedEmail, userId: userID, isProduction: true)
        }
        
        // After successful deactivation, show the success alert
        showDeactivationSuccessAlert = true
    }
    
    func deleteAccount() {
        // Implement account deletion logic here
        print("Cuenta eliminada")
        
        Task {
            try? await invoiceSerivce.deleteAccount(email: storedEmail, userId: userID, isProduction: true)
        }
        
        // After successful deletion, show the success alert
        showDeletionSuccessAlert = true
    }
    
    func clearUserData() {
        // Clear user data from AppStorage
        //storedName = ""
        //storedEmail = ""
        userID = ""
        
        // You might want to clear other user-specific data as well
    }
}

// Component for displaying company invoice summary
struct CompanyInvoiceSummary: View {
    let company: Company
    let invoicesCreated: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Company icon
            ZStack {
                Circle()
                    .fill(Color(red: 18/255, green: 31/255, blue: 61/255, opacity: 0.9))
                Text(String(company.nombre.prefix(1)))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 50, height: 50)
            
            // Company info
            VStack(alignment: .leading, spacing: 4) {
                Text(company.nombre)
                    .font(.system(size: 17, weight: .semibold))
                
                Text("NIT: \(company.nit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Invoice count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(invoicesCreated)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 18/255, green: 31/255, blue: 61/255))
                
                Text("Facturas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Helper extension for rounded specific corners
extension View {
    func clipShape<S: Shape>(_ shape: S, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(corners: corners, radius: (shape as? RoundedRectangle)?.cornerSize.width ?? 0))
    }
}

struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct UserAccountView_Previews: PreviewProvider {
    static var previews: some View {
        UserAccountView()
    }
}
