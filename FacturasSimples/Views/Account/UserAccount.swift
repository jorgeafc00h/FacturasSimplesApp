import SwiftUI
import SwiftData

struct UserAccountView: View {
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
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
    
    // MARK: - Color Palette
    private var colors: UserAccountColors {
        UserAccountColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // User Info Card
                userInfoCard
                    .padding(.horizontal, 20)
                
                // Company Data Section
                companySectionView
                    .padding(.horizontal, 20)
                
                // Action Buttons Section
                actionButtonsSection
                    .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
            }
        }
        .background(colors.background)
        .onAppear {
            loadInvoiceCounts()
        }
        .alert("Cuenta Desactivada", isPresented: $showDeactivationSuccessAlert) {
            Button("Entendido", role: .destructive) {
                clearUserData()
                dismiss()
            }
        } message: {
            Text("Su cuenta ha sido desactivada correctamente. Para volver a usar esta increíble aplicación, necesitará reiniciar la app e iniciar sesión nuevamente.")
        }
        .alert("Cuenta Eliminada", isPresented: $showDeletionSuccessAlert) {
            Button("Entendido", role: .destructive) {
                clearUserData()
                dismiss()
            }
        } message: {
            Text("Su cuenta ha sido eliminada permanentemente. Toda su información ha sido borrada de nuestros sistemas.")
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [colors.primaryGradientStart, colors.primaryGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 160)
            .overlay(
                VStack(spacing: 12) {
                    // Profile Icon
                    ZStack {
                        Circle()
                            .fill(colors.headerIconBackground)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(colors.headerIconForeground)
                    }
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // Title
                    Text("Mi Cuenta")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .padding(.top, 40)
            )
            
            // Curved bottom edge
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: 0))
                path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: 40))
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: 40),
                    control: CGPoint(x: UIScreen.main.bounds.width / 2, y: 0)
                )
                path.closeSubpath()
            }
            .fill(colors.background)
            .frame(height: 40)
            .offset(y: -1)
        }
    }
    
    private var userInfoCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colors.primary)
                
                Text("Información Personal")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(colors.cardHeader)
            
            // Content
            VStack(spacing: 20) {
                // Name Row
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(colors.iconBackground)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nombre completo")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(colors.textSecondary)
                        
                        Text(storedName.isEmpty ? "No especificado" : storedName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.textPrimary)
                    }
                    
                    Spacer()
                }
                
                // Email Row
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(colors.iconBackground)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Correo electrónico")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(colors.textSecondary)
                        
                        Text(storedEmail.isEmpty ? "No especificado" : storedEmail)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.textPrimary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(colors.cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: colors.shadowColor, radius: 8, x: 0, y: 4)
        .offset(y: -20)
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Deactivate Button
            Button(action: {
                showDeactivateAlert = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Desactivar Cuenta")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [colors.warningGradientStart, colors.warningGradientEnd]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: colors.warningGradientStart.opacity(0.3), radius: 8, x: 0, y: 4)
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
            
            // Delete Button
            Button(action: {
                showDeleteAlert = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Eliminar Cuenta")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [colors.dangerGradientStart, colors.dangerGradientEnd]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: colors.dangerGradientStart.opacity(0.3), radius: 8, x: 0, y: 4)
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
    }
    
    private var companySectionView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colors.primary)
                
                Text("Mis Empresas")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                // Company count badge
                if !companies.isEmpty {
                    Text("\(companies.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(colors.primary)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(colors.cardHeader)
            
            // Content
            if companies.isEmpty {
                emptyCompaniesView
            } else {
                companiesListView
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: colors.shadowColor, radius: 8, x: 0, y: 4)
    }
    
    private var emptyCompaniesView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(colors.iconBackground)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "building.2")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(colors.textSecondary)
            }
            
            VStack(spacing: 8) {
                Text("No hay empresas registradas")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                
                Text("Las empresas que registres aparecerán aquí con el resumen de facturas creadas")
                    .font(.system(size: 15))
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(colors.cardBackground)
    }
    
    private var companiesListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(companies.enumerated()), id: \.element.id) { index, company in
                CompanyInvoiceSummary(
                    company: company,
                    invoicesCreated: invoiceCountsByCompany[company.id] ?? 0,
                    colors: colors
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                if index < companies.count - 1 {
                    Divider()
                        .padding(.horizontal, 20)
                        .background(colors.cardBackground)
                }
            }
        }
        .background(colors.cardBackground)
    }
    
    func loadInvoiceCounts() {
        for company in companies {
            let id = company.id
            let descriptor = FetchDescriptor<Invoice>(predicate: #Predicate { $0.customer.companyOwnerId == id  })
            let createdCount = try? modelContext.fetchCount(descriptor)
            invoiceCountsByCompany[company.id] = createdCount
        }
    }
    
    func deactivateAccount() {
        print("Cuenta desactivada")
        Task{
            try? await invoiceSerivce.deactivateAccount(email: storedEmail, userId: userID, isProduction: true)
        }
        showDeactivationSuccessAlert = true
    }
    
    func deleteAccount() {
        print("Cuenta eliminada")
        Task {
            try? await invoiceSerivce.deleteAccount(email: storedEmail, userId: userID, isProduction: true)
        }
        showDeletionSuccessAlert = true
    }
    
    func clearUserData() {
        userID = ""
    }
}

// MARK: - Company Invoice Summary Component
struct CompanyInvoiceSummary: View {
    let company: Company
    let invoicesCreated: Int
    let colors: UserAccountColors
    
    private var companyInitials: String {
        let words = company.nombre.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else {
            return String(company.nombre.prefix(2)).uppercased()
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Company Avatar
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [colors.primaryGradientStart, colors.primaryGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                Text(companyInitials)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .shadow(color: colors.primaryGradientStart.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Company Info
            VStack(alignment: .leading, spacing: 6) {
                Text(company.nombre)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("NIT:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colors.textSecondary)
                    
                    Text(company.nit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colors.textPrimary)
                }
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(company.isProduction ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(company.isProduction ? "Producción" : "Pruebas")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Invoice Count Display
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(invoicesCreated)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(colors.primary)
                
                Text("Facturas")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colors.textSecondary)
            }
        }
    }
}

// MARK: - Color System
struct UserAccountColors {
    let colorScheme: ColorScheme
    
    // Primary Colors
    var primary: Color {
        colorScheme == .dark ? Color(red: 0.4, green: 0.6, blue: 1.0) : Color(red: 0.2, green: 0.4, blue: 0.8)
    }
    
    // Background Colors
    var background: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white
    }
    
    var cardHeader: Color {
        colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray6)
    }
    
    var iconBackground: Color {
        colorScheme == .dark ? Color(UIColor.systemGray4) : Color(UIColor.systemGray5)
    }
    
    // Text Colors
    var textPrimary: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    var textSecondary: Color {
        colorScheme == .dark ? Color(UIColor.systemGray2) : Color.secondary
    }
    
    // Header Colors
    var headerIconBackground: Color {
        Color.white.opacity(0.2)
    }
    
    var headerIconForeground: Color {
        Color.white
    }
    
    // Gradient Colors
    var primaryGradientStart: Color {
        colorScheme == .dark ? Color(red: 0.3, green: 0.5, blue: 0.9) : Color(red: 0.2, green: 0.4, blue: 0.8)
    }
    
    var primaryGradientEnd: Color {
        colorScheme == .dark ? Color(red: 0.5, green: 0.3, blue: 0.9) : Color(red: 0.4, green: 0.2, blue: 0.6)
    }
    
    var warningGradientStart: Color {
        Color(red: 1.0, green: 0.6, blue: 0.0)
    }
    
    var warningGradientEnd: Color {
        Color(red: 1.0, green: 0.8, blue: 0.2)
    }
    
    var dangerGradientStart: Color {
        Color(red: 0.9, green: 0.2, blue: 0.3)
    }
    
    var dangerGradientEnd: Color {
        Color(red: 1.0, green: 0.4, blue: 0.4)
    }
    
    // Shadow Color
    var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

// MARK: - Preview
struct UserAccountView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserAccountView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            UserAccountView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
