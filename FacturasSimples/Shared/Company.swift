import Foundation
import SwiftData
import CloudKit

@Model class Company {
    
    // Remove @Attribute(.unique) for CloudKit compatibility
    var id: String = UUID().uuidString
    
    // CloudKit can encrypt sensitive business data
    @Attribute(.allowsCloudEncryption)
    var nit: String = ""
    
    @Attribute(.allowsCloudEncryption)
    var nrc: String = ""
    
    var nombre: String = ""
    var codActividad: String = ""
    var descActividad: String = ""
    var nombreComercial: String = ""
    var tipoEstablecimiento: String = ""
    var establecimiento: String = ""
    
    var telefono: String = ""
    var correo: String = ""
    var codEstableMH: String = ""
    var codEstable: String = ""
    var codPuntoVentaMH: String = ""
    var codPuntoVenta: String = ""
    
    // Dirección
    var departamento: String = ""
    var departamentoCode: String = ""
    var municipio: String = ""
    var municipioCode: String = ""
    var complemento: String = ""
    
    // CloudKit handles large text data well
    var invoiceLogo: String = ""
    var logoWidht: Double = 100
    var logoHeight: Double = 100
    
    // Sensitive certificate data - encrypt in CloudKit
    @Attribute(.allowsCloudEncryption)
    var certificatePath: String = ""
    
    @Attribute(.allowsCloudEncryption)
    var certificatePassword: String = ""
    
    @Attribute(.allowsCloudEncryption)
    var credentials: String = ""
    
    var isTestAccount: Bool = true
    
    // CloudKit sync indicator - ALL companies now sync to CloudKit
    // The filtering will happen at the related data level (customers, invoices, etc.)
    var shouldSyncToCloudKit: Bool {
        return true  // Always sync companies so devices can see all company options
    }
    
    // Subscription and Purchase Tracking (only for production accounts)
    var hasActiveSubscription: Bool = false
    var subscriptionProductId: String = ""
    var subscriptionExpiryDate: Date?
    var availableInvoiceCredits: Int = 0
    var totalPurchasedCredits: Int = 0
    var lastPurchaseDate: Date?
    
    var isProduction: Bool {
        return isTestAccount == false
    }
    
    // Helper property to check if company requires paid services
    var requiresPaidServices: Bool {
        return isProduction && !isTestAccount
    }
    
    // Helper property to check if company can create invoices
    var canCreateInvoices: Bool {
        // Test accounts can always create invoices
        if isTestAccount {
            return true
        }
        
        // Production accounts need either active subscription or available credits
        return hasActiveSubscription || availableInvoiceCredits > 0
    }
    
    // Helper property to check if subscription is still active
    var isSubscriptionActive: Bool {
        guard hasActiveSubscription else { return false }
        
        if let expiryDate = subscriptionExpiryDate {
            return Date() < expiryDate
        }
        
        return hasActiveSubscription
    }
    
    // Helper method to use invoice credit
    func useInvoiceCredit() -> Bool {
        // Test accounts don't consume credits
        if isTestAccount {
            return true
        }
        
        // For production accounts, check if they have active subscription or credits
        if isSubscriptionActive {
            return true
        }
        
        guard availableInvoiceCredits > 0 else {
            return false
        }
        
        availableInvoiceCredits -= 1
        return true
    }
    
    // Helper method to add purchased credits
    func addPurchasedCredits(_ count: Int) {
        // Only production accounts track credits
        if requiresPaidServices {
            availableInvoiceCredits += count
            totalPurchasedCredits += count
            lastPurchaseDate = Date()
        }
    }
    
    // Helper method to activate subscription
    func activateSubscription(productId: String, expiryDate: Date?) {
        // Only production accounts can have subscriptions
        if requiresPaidServices {
            hasActiveSubscription = true
            subscriptionProductId = productId
            subscriptionExpiryDate = expiryDate
        }
    }
    
    // Helper method to deactivate subscription
    func deactivateSubscription() {
        hasActiveSubscription = false
        subscriptionProductId = ""
        subscriptionExpiryDate = nil
    }
    
    var actividadEconomicaLabel: String {
        descActividad == "" ? "Seleccione una actividad económica" : descActividad
    }
   
    init(
        nit: String,
        nrc: String,
        nombre: String,
        descActividad: String = "",
        nombreComercial: String = "",
        tipoEstablecimiento: String = "",
        establecimiento: String = "",
        telefono: String = "",
        correo: String = "",
        codEstableMH: String = "",
        codEstable: String = "",
        codPuntoVentaMH: String = "",
        codPuntoVenta: String = "",
        departamento: String = "",
        municipio: String = "",
        complemento: String = "",
        invoiceLogo: String = "",
        departamentoCode: String = "",
        municipioCode: String = "",
        codActividad: String = "",
        certificatePath: String = "",
        certificatePassword: String = "",
        credentials: String = "",
        isTestAccount:Bool = true
    ) {
        self.nit = nit
        self.nrc = nrc
        self.nombre = nombre
        self.codActividad = codActividad
        self.descActividad = descActividad
        self.nombreComercial = nombreComercial
        self.tipoEstablecimiento = tipoEstablecimiento
        self.establecimiento = establecimiento
        self.telefono = telefono
        self.correo = correo
        self.codEstableMH = codEstableMH
        self.codEstable = codEstable
        self.codPuntoVentaMH = codPuntoVentaMH
        self.codPuntoVenta = codPuntoVenta
        self.departamento = departamento
        self.municipio = municipio
        self.complemento = complemento
        self.departamentoCode = departamentoCode
        self.municipioCode = municipioCode
        self.invoiceLogo = invoiceLogo
        self.certificatePath = certificatePath  
        self.certificatePassword = certificatePassword
        self.credentials = credentials
        self.isTestAccount = isTestAccount
        
        // Initialize subscription/purchase properties
        self.hasActiveSubscription = false
        self.subscriptionProductId = ""
        self.subscriptionExpiryDate = nil
        self.availableInvoiceCredits = 0
        self.totalPurchasedCredits = 0
        self.lastPurchaseDate = nil
    }
}



extension Company{
    
    
    
    static var prewiewCompanies: [Company] {
        [
            Company(nit: "1234567890",nrc:"2342342", nombre: "Empresa 1",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567891",nrc:"34563456", nombre: "Empresa 2",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567892",nrc:"345634562", nombre: "Empresa 3",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567893",nrc:"345634563", nombre: "Empresa 4",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567894",nrc:"345634564", nombre: "Empresa 5",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567892",nrc:"345634562", nombre: "Empresa 6",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567893",nrc:"345634563", nombre: "Empresa 7",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567892",nrc:"345634562", nombre: "Empresa 8",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567893",nrc:"345634563", nombre: "Empresa 9",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567892",nrc:"345634562", nombre: "Empresa 10",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567893",nrc:"345634563", nombre: "Empresa 2",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567892",nrc:"345634562", nombre: "Empresa 3.1416 e",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567893",nrc:"345634563", nombre: "Empresa 4, E 3.1416",nombreComercial: "Nombre comercial"),
        ]
    }
}

