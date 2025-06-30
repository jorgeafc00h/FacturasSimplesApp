import SwiftUI
import SwiftData

// Enum to track processing status for each document type
enum ProcessingStatus {
    case notStarted
    case generating
    case sending
    case completed
    case error
    
    var displayText: String {
        switch self {
        case .notStarted: return "Pendiente"
        case .generating: return "Generando..."
        case .sending: return "Enviando..."
        case .completed: return "Completado"
        case .error: return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .generating: return .blue
        case .sending: return .orange
        case .completed: return .green
        case .error: return .red
        }
    }
}

@Observable
class RequestProductionAccessViewModel {
        
    // Dependencies
    private var company: Company?
    private var modelContext: ModelContext?
    private var BatchLimit : Int = 75
    private var customerBatchLimit : Int = 10
            
    var invoices: [Invoice] = []
        var generatedInvoices: [Invoice] = []
        var customers: [Customer] = []
        var products: [Product] = []
        var showAlert = false
        var alertMessage = ""
        var progress: Double = 0.0
        var isSyncing = false
        var showConfirmDialog = false
        var hasMinimumInvoices = false
        var hasCompleted: Bool = false
        
        var totalInvoices: Int = 75
        
        // Individual progress tracking for "todo" mode
        var isProcessingAll: Bool = false
        var facturasProgress: Double = 0.0
        var ccfProgress: Double = 0.0
        var creditNotesProgress: Double = 0.0
        var facturasStatus: ProcessingStatus = .notStarted
        var ccfStatus: ProcessingStatus = .notStarted
        var creditNotesStatus: ProcessingStatus = .notStarted
        
        let invoiceService = InvoiceServiceClient()
        var dteService = MhClient()
        
        // Track which types have been processed
        var hasProcessedFacturas: Bool = false
        var hasProcessedCCF: Bool = false
        var hasProcessedCreditNotes: Bool = false
        
        // Flag to force generation even when minimum is met
        var forceGeneration: Bool = false
        
        var isLoadingCertificateStatus: Bool = false
        var isLoadingCredentialsStatus: Bool = false
    var showCertificateInvalidMessage: Bool = false
    var showCredentialsInvalidMessage: Bool = false
    
    // Constructor
    init(company: Company, modelContext: ModelContext) {
        self.company = company
        self.modelContext = modelContext
    }
    
    // Placeholder constructor for SwiftUI initialization
    init() {
        self.company = nil
        self.modelContext = nil
    }
    
    // Method to update dependencies after initialization
    func configure(company: Company, modelContext: ModelContext) {
        self.company = company
        self.modelContext = modelContext
    }
    
    // Safe accessors for dependencies
    private var safeCompany: Company {
        guard let company = company else {
            fatalError("RequestProductionAccessViewModel: company not configured")
        }
        return company
    }
    
    private var safeModelContext: ModelContext {
        guard let modelContext = modelContext else {
            fatalError("RequestProductionAccessViewModel: modelContext not configured")
        }
        return modelContext
    }
        
 
    
    func generateAndSendInvoices() {
        generateInvoices()
        sendInvoices()
        
    }
    func generateInvoices()  {
        prepareCustomersAndProducts()
        
        // This method now acts as a coordinator for all invoice types
        var processed = false
        
        if !self.hasProcessedFacturas {
            generateFacturas()
            processed = true
        }
        
        if !self.hasProcessedCCF {
            generateCreditosFiscales()
            processed = true
        }
        
        if !self.hasProcessedCreditNotes {
            generateCreditNotes()
            processed = true
        }
        
        if processed {
            try? safeModelContext.save()
            self.alertMessage = "Se generaron facturas con datos de prueba."
        } else {
            self.alertMessage = "Todos los tipos de documentos ya han sido procesados."
        }
        
        self.showAlert = true
        validateProductionAccount()
    }
    
    func validateCertificateCredentialasAsync() async  {
        self.isLoadingCertificateStatus = true
        // Reset error state when starting validation
        self.showCertificateInvalidMessage = false
        
        let service = InvoiceServiceClient()
        
        do {
            let result = try await service.validateCertificate(nit: safeCompany.nit, key: safeCompany.certificatePassword, isProduction: safeCompany.isProduction)
            
            print("Certificate Validation Result: \(result)")
            
            if result == false {
                self.showCertificateInvalidMessage = true
                print("❌ Certificate validation failed - invalid credentials")
            } else {
                self.showCertificateInvalidMessage = false
                print("✅ Certificate validation successful")
            }
        } catch {
            // Network or other errors
            self.showCertificateInvalidMessage = true
            print("❌ Certificate validation error: \(error)")
        }
        
        self.isLoadingCertificateStatus = false
    }
    
    func validateCredentialsAsync() async  {
        self.isLoadingCredentialsStatus = true
        // Reset error state when starting validation
        self.showCredentialsInvalidMessage = false
        
        let service = InvoiceServiceClient()
        
        do {
            let result = try await service.validateCredentials(nit: safeCompany.nit,
                                                                password: safeCompany.credentials,
                                                                isProduction: safeCompany.isProduction,
                                                                forceRefresh: false)
            
            print("Credentials Validation Result: \(result)")
            
            if result == false {
                self.showCredentialsInvalidMessage = true
                print("❌ Credentials validation failed - invalid credentials")
            } else {
                self.showCredentialsInvalidMessage = false
                print("✅ Credentials validation successful")
            }
        } catch {
            // Network or other errors
            self.showCredentialsInvalidMessage = true
            print("❌ Credentials validation error: \(error)")
        }
        
        self.isLoadingCredentialsStatus = false
    }
    
    // Helper method to prepare customers and products
    func prepareCustomersAndProducts()  {
        
        // Load existing invoices and customers
        //loadAllInvoices()
       
        // Only create customers and products if they haven't been created yet
        if self.customers.isEmpty {
            let firstNames = ["Juan", "María", "Carlos", "Ana", "Luis", "Sofía", "Miguel", "Lucía", "Javier", "Isabel","Diego","Marcelo", "Antonio", "Verónica", "Pedro", "Natalia"]
            let lastNames = ["Pérez", "García", "Rodríguez", "López", "Martínez", "Hernández", "González", "Ramírez", "Sánchez", "Torres","Flores","Sequeira","Díaz","Vázquez","Jiménez","Álvarez"]
            self.customers = (1...customerBatchLimit).map { i in
                let firstName = firstNames.randomElement()!
                let lastName = lastNames.randomElement()!
                let c = Customer(firstName: firstName, lastName: lastName, nationalId: "03721600\(i)", email: "\(firstName.lowercased())\(i)@yopmail.com", phone: "7700120\(i)")
                c.companyOwnerId = safeCompany.id
                c.departamento = "San Salvador"
                c.departamentoCode = "06"
                c.municipioCode = "14"
                c.address = "TEST #\(i)"
                c.nit = "06141709940015"
                c.nrc = "3174"
                c.descActividad = "Publicidad"
                c.codActividad = "73100"
                c.nationalId = "123456789"
                // Set sync status based on company type - since this is for production test data, it should sync
                c.shouldSyncToCloudKit = !safeCompany.isTestAccount
                return c
            }
        }
        
        if self.products.isEmpty {
            self.products = (1...5).map { i in
                let p = Product(productName: "Producto\(i)", unitPrice: Decimal(Double.random(in: 1...100)))
                p.companyId = safeCompany.id
                // Set sync status based on company type - since this is for production test data, it should sync
                p.shouldSyncToCloudKit = !safeCompany.isTestAccount
                return p
            }
        }
    }
    
    // Generate Facturas
    func generateFacturas(forceGenerate: Bool = false) {
        if !forceGenerate && self.invoices.count(where: { $0.invoiceType == .Factura && $0.status == .Completada }) >= self.totalInvoices {
            self.hasProcessedFacturas = true
            self.alertMessage = "Ya existen suficientes Facturas completadas."
            self.showAlert = true
            return
        }
        
        var invoiceIndex = getNextInoviceNumber()
        
        for _ in 1...self.totalInvoices {  
            let customer = self.customers.randomElement()!
            let invoiceNumber = String(format: "%05d", invoiceIndex)
            let invoice = Invoice(invoiceNumber: invoiceNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .Factura)
            invoice.items = self.products.map { product in
                InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
            }
            // Set sync status based on company type
            invoice.shouldSyncToCloudKit = !safeCompany.isTestAccount
            invoiceIndex += 1
            //safeModelContext.insert(invoice)
            self.generatedInvoices.append(invoice)
            //return invoice
        }
        
        //try? safeModelContext.save()
        
        self.hasProcessedFacturas = true
        self.alertMessage = "Se generaron \(self.totalInvoices) Facturas con datos de prueba."
        self.showAlert = true
    }
    
    // Generate Creditos Fiscales
    func generateCreditosFiscales(forceGenerate: Bool = false) {
        if !forceGenerate && self.invoices.count(where: { $0.invoiceType == .CCF && $0.status == .Completada }) >= self.totalInvoices {
            self.hasProcessedCCF = true
            self.alertMessage = "Ya existen suficientes Créditos Fiscales completados."
            self.showAlert = true
            return
        }
        
        var invoiceIndex = getNextInoviceNumber()
        
        for _ in 1...self.totalInvoices { 
            let customer = self.customers.randomElement()!
            let invoiceNumber = String(format: "%05d", invoiceIndex)
            let ccf = Invoice(invoiceNumber: invoiceNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .CCF)
            ccf.items = self.products.map { product in
                InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
            }
            // Set sync status based on company type
            ccf.shouldSyncToCloudKit = !safeCompany.isTestAccount
            invoiceIndex += 1
            self.generatedInvoices.append(ccf)
            //safeModelContext.insert(ccf)
            //return ccf
        }
        
        //try? safeModelContext.save()
        
        self.hasProcessedCCF = true
        self.alertMessage = "Se generaron \(self.totalInvoices) Créditos Fiscales con datos de prueba."
        self.showAlert = true
    }
    
    // Generate Credit Notes
    func generateCreditNotes(forceGenerate: Bool = false) {
        if !forceGenerate && self.invoices.count(where: { $0.invoiceType == .NotaCredito && $0.status == .Completada }) >= BatchLimit {
            self.hasProcessedCreditNotes = true
            self.alertMessage = "Ya existen suficientes Notas de Crédito completadas."
            self.showAlert = true
            return
        }
        
        // Check if we have enough CCF to generate credit notes
        let calendar = Calendar.current
        _ = calendar.startOfDay(for: Date())
        
        let hasCCFAvailable = self.invoices.count(where: { 
            $0.invoiceType == .CCF && 
            $0.status == .Nueva && 
            calendar.isDate($0.date, inSameDayAs: Date())
        }) >= BatchLimit
        
        if !hasCCFAvailable {
            // Generate more CCF first if needed
            generateCreditosFiscales(forceGenerate: forceGenerate)
        }
        
        // Filter to get only today's CCF invoices for credit notes
        let ccfInvoices = self.invoices.filter { 
            $0.invoiceType == .CCF && 
            $0.status == .Nueva &&
            calendar.isDate($0.date, inSameDayAs: Date())
        }.suffix(BatchLimit)
        
        var invoiceIndex = getNextInoviceNumber()
        
        // If we don't have enough from today, create a new CCF then a note
        if ccfInvoices.count < BatchLimit {
            // Use a simple for loop instead of map
            for _ in 1...self.totalInvoices {
                // Create a new CCF
                let customer = self.customers.randomElement()!
                let invoiceNumber = String(format: "%05d", invoiceIndex)
                let ccf = Invoice(invoiceNumber: invoiceNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .CCF)
                
                // Add items to the CCF
                ccf.items = self.products.map { product in
                    InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
                }
                // Set sync status based on company type
                ccf.shouldSyncToCloudKit = !safeCompany.isTestAccount
                invoiceIndex += 1
                
                // Set control numbers
                Extensions.generateControlNumberAndCode(ccf)
                
                self.generatedInvoices.append(ccf)
                
                // Create a credit note for this CCF
                let note = generateCreditNotefromInvoice(ccf, invoiceNumber: String(format: "%05d", invoiceIndex))
                invoiceIndex += 1
                self.generatedInvoices.append(note)
            }
        } else {
            // Use existing CCF invoices
            for ccf in ccfInvoices {
                let note = generateCreditNotefromInvoice(ccf, invoiceNumber: String(format: "%05d", invoiceIndex))
                invoiceIndex += 1
                self.generatedInvoices.append(note)
            }
        }
        
        self.hasProcessedCreditNotes = true
        self.alertMessage = "Se generaron 50 Notas de Crédito con datos de prueba."
        self.showAlert = true
    }
    
    func generateCreditNotefromInvoice(_ invoice: Invoice, invoiceNumber: String) -> Invoice{
        
        
        let note = Invoice(invoiceNumber: invoiceNumber,
                           date: invoice.date,
                           status: invoice.status, customer: invoice.customer,
                           invoiceType: .NotaCredito)
        
        Extensions.generateControlNumberAndCode(note)
        
        let items = (invoice.items ?? []).map { detail -> InvoiceDetail in
            return InvoiceDetail(quantity: detail.quantity, product: detail.product)
            
        }
        
        note.invoiceNumber = invoiceNumber
        note.status = .Nueva
        note.date = Date()
        note.invoiceType = .NotaCredito
        note.documentType = Extensions.documentTypeFromInvoiceType(.NotaCredito)
        note.relatedDocumentNumber = invoice.generationCode
        note.relatedDocumentType = invoice.documentType
        note.relatedInvoiceType = invoice.invoiceType
        note.relatedId = invoice.inoviceId
        note.items = items
        note.relatedDocumentDate = invoice.date
        
        // Set sync status based on company type
        note.shouldSyncToCloudKit = !safeCompany.isTestAccount
        
//        safeModelContext.insert(note)
//        try? safeModelContext.save()
        
        return note
    }
    
    func sendInvoices(onCompletion: (() -> Void)? = nil) {
        self.isSyncing = true
        self.progress = 0.0
        Task {
            await validateCertificateCredentialasAsync()
            await validateCredentialsAsync()
            
            if self.showCertificateInvalidMessage || self.showCredentialsInvalidMessage{
                var errorMessage = "Error de validación: "
                if self.showCertificateInvalidMessage && self.showCredentialsInvalidMessage {
                    errorMessage += "Verifica los datos del certificado y las credenciales de hacienda"
                } else if self.showCertificateInvalidMessage {
                    errorMessage += "Verifica los datos del certificado (NIT y contraseña)"
                } else {
                    errorMessage += "Verifica las credenciales de hacienda"
                }
                
                self.alertMessage = errorMessage
                self.showAlert = true
                self.isSyncing = false
                return
            }
            
            for (index, invoice) in self.generatedInvoices.enumerated() {
                
                if invoice.status == .Completada {
                    self.progress = Double(index + 1) / Double(self.generatedInvoices.count)
                    continue
                }
                
                print("invoice tpe: \(invoice.invoiceType)")
                print("control: \(String(describing: invoice.controlNumber))")
                
                do {
                    try await Sync(invoice)
                    
                    // Extract invoice type before MainActor.run to avoid capturing non-Sendable type
                    let invoiceType = invoice.invoiceType
                    
                    // Update individual progress based on invoice type for single document processing
                    await MainActor.run {
                        updateIndividualProgress(for: invoiceType)
                    }
                    
                } catch {
                    print("ERROR SYNCING INVOICE: \(error)")
                }
                self.progress = Double(index + 1) / Double(self.generatedInvoices.count)
            }
            self.isSyncing = false
            self.alertMessage = "Facturas enviadas y completadas."
            self.showAlert = true
            self.hasCompleted = true
            
            // Call completion callback if process was successful
            if let onCompletion = onCompletion {
                print("✅ RequestProductionAccess: SendInvoices completed successfully, calling completion callback")
                onCompletion()
            }
        }
    }
    
    func validateProductionAccount(onCompletion: ((Company?) -> Void)? = nil) {
        
        
        let nit = safeCompany.nit
        let _fetchRequest = FetchDescriptor<Company>(predicate: #Predicate{
            $0.nit == nit && $0.isTestAccount == false
        })
        do {
            let productionAccounts = try safeModelContext.fetch(_fetchRequest)
            var createdOrExistingCompany: Company?
            
            if !productionAccounts.isEmpty {
                self.alertMessage = "La cuenta de producción ya está configurada."
                createdOrExistingCompany = productionAccounts.first
            } else {
                let productionCompanyAccount = Company(
                    nit: safeCompany.nit,
                    nrc: safeCompany.nrc,
                    nombre: safeCompany.nombre,
                    descActividad: safeCompany.descActividad,
                    nombreComercial: safeCompany.nombreComercial,
                    tipoEstablecimiento: safeCompany.tipoEstablecimiento,
                    establecimiento: safeCompany.establecimiento,
                    telefono: safeCompany.telefono,
                    correo: safeCompany.correo,
                    codEstableMH: safeCompany.codEstableMH,
                    codEstable: safeCompany.codEstable,
                    codPuntoVentaMH: safeCompany.codPuntoVentaMH,
                    codPuntoVenta: safeCompany.codPuntoVenta,
                    departamento: safeCompany.departamento,
                    municipio: safeCompany.municipio,
                    complemento: safeCompany.complemento,
                    invoiceLogo: safeCompany.invoiceLogo,
                    departamentoCode: safeCompany.departamentoCode,
                    municipioCode: safeCompany.municipioCode,
                    codActividad: safeCompany.codActividad,
                    certificatePath: safeCompany.certificatePath,
                    certificatePassword: safeCompany.certificatePassword,
                    credentials: safeCompany.credentials,
                    isTestAccount: false
                )
                safeModelContext.insert(productionCompanyAccount)
                
                // Save context to trigger iCloud sync for the production company
                do {
                    try safeModelContext.save()
                    self.alertMessage = "La cuenta de producción ha sido creada y configurada."
                    createdOrExistingCompany = productionCompanyAccount
                } catch {
                    self.alertMessage = "Error al guardar la cuenta de producción: \(error.localizedDescription)"
                }
            }
            
            self.showAlert = true
           
            // Always call completion callback when validateProductionAccount is called
            // regardless of hasCompleted status (which is only for invoice processing)
            // Use DispatchQueue to ensure proper timing with alert dismissal
            DispatchQueue.main.async {
                if let onCompletion = onCompletion {
                    print("✅ RequestProductionAccess: ValidateProductionAccount completed successfully, calling completion callback with company: \(createdOrExistingCompany?.nombreComercial ?? "nil")")
                    onCompletion(createdOrExistingCompany)
                }
            }
        } catch {
            self.alertMessage = "Error al verificar la cuenta de producción: \(error.localizedDescription)"
            self.showAlert = true
            
            // Call completion callback with nil in case of error
            DispatchQueue.main.async {
                if let onCompletion = onCompletion {
                    print("❌ RequestProductionAccess: ValidateProductionAccount failed with error, calling completion callback with nil")
                    onCompletion(nil)
                }
            }
        }
    }
    
    private func Sync(_ invoice: Invoice) async throws {
        do {
            let dte = GenerateInvoiceReferences(invoice)
            
            
            let credentials = ServiceCredentials(user: dte!.emisor.nit,
                                                 credential: safeCompany.credentials,
                                                 key: safeCompany.certificatePassword,
                                                 invoiceNumber: invoice.invoiceNumber)
            
            let response = try await self.invoiceService.Sync(dte: dte!, credentials: credentials,isProduction: safeCompany.isProduction)
            
            
            
            print("\(response.estado)")
            print("SELLO \(response.selloRecibido)")
            
            
            invoice.status = .Completada
            invoice.statusRawValue = invoice.status.id
            invoice.receptionSeal = response.selloRecibido
            
//            safeModelContext.insert(invoice)
//            try? safeModelContext.save()
            
            if invoice.invoiceType == .NotaCredito {
                
                let id = invoice.relatedId!
                
                let descriptor = FetchDescriptor<Invoice>(
                    predicate: #Predicate<Invoice>{
                        $0.inoviceId == id
                    }
                )
                
                if let relatedInvoice = try? safeModelContext.fetch(descriptor).first{
                    relatedInvoice.status = .Anulada
                    relatedInvoice.statusRawValue = relatedInvoice.status.id
                    try? safeModelContext.save()
                }
            }
            
            
        } catch(let error) {
            print("error \(error.localizedDescription)")
            throw error
        }
    }
    
    func GenerateInvoiceReferences(_ invoice: Invoice) -> DTE_Base? {
         
        Extensions.generateControlNumberAndCode(invoice)
        
        do {
            
            let envCode  = self.invoiceService.getEnvironmetCode(safeCompany.isProduction)
            
            let dte = try MhClient.mapInvoice(invoice: invoice, company: safeCompany,environmentCode: envCode)
            
            print("DTE Numero control:\(dte.identificacion.numeroControl ?? "")")
            
            return dte
        } catch (let error) {
            print("failed to map invoice to dte \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getNextInoviceNumber() -> Int{
        
        let id = safeCompany.id
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate<Invoice>{
                $0.customer?.companyOwnerId == id
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let latestInvoice = try? safeModelContext.fetch(descriptor).first {
            if let currentNumber = Int(latestInvoice.invoiceNumber) {
                return currentNumber
            } else {
                return 1
            }
        } else {
            return 1
        }
        
        
    }
    
    // Helper method to process all document types with individual progress tracking
    func processAllDocuments(forceGenerate: Bool = false, onCompletion: (() -> Void)? = nil) {
        self.isProcessingAll = true
        self.isSyncing = true
        
        // Reset all progress and statuses
        self.facturasProgress = 0.0
        self.ccfProgress = 0.0
        self.creditNotesProgress = 0.0
        self.facturasStatus = .notStarted
        self.ccfStatus = .notStarted
        self.creditNotesStatus = .notStarted
        
        prepareCustomersAndProducts()
        
        Task {
            // Process each document type sequentially with progress updates
            await processFacturasWithProgress(forceGenerate: forceGenerate)
            await processCCFWithProgress(forceGenerate: forceGenerate)
            await processCreditNotesWithProgress(forceGenerate: forceGenerate)
            
            // Send all invoices at the end
            await sendAllInvoicesWithProgress()
            
            await MainActor.run {
                self.isProcessingAll = false
                self.isSyncing = false
                self.alertMessage = "Se generaron y enviaron todos los documentos necesarios."
                self.showAlert = true
                self.hasCompleted = true
                
                // Call completion callback if process was successful
                if let onCompletion = onCompletion {
                    print("✅ RequestProductionAccess: ProcessAllDocuments completed successfully, calling completion callback")
                    onCompletion()
                }
            }
        }
    }
    
    // Individual processing methods for "todo" mode with progress tracking
    @MainActor
    private func processFacturasWithProgress(forceGenerate: Bool = false) async {
        self.facturasStatus = .generating
        
        if !forceGenerate && self.invoices.count(where: { $0.invoiceType == .Factura && $0.status == .Completada }) >= self.totalInvoices {
            self.hasProcessedFacturas = true
            self.facturasProgress = 1.0
            self.facturasStatus = .completed
            return
        }
        
        var invoiceIndex = getNextInoviceNumber()
        
        for i in 1...self.totalInvoices {
            let customer = self.customers.randomElement()!
            let invoiceNumber = String(format: "%05d", invoiceIndex)
            let invoice = Invoice(invoiceNumber: invoiceNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .Factura)
            invoice.items = self.products.map { product in
                InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
            }
            // Set sync status based on company type
            invoice.shouldSyncToCloudKit = !safeCompany.isTestAccount
            invoiceIndex += 1
            self.generatedInvoices.append(invoice)
            
            // Update progress
            self.facturasProgress = Double(i) / Double(self.totalInvoices)
            
            // Small delay to show progress
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        self.hasProcessedFacturas = true
        self.facturasStatus = .completed
    }
    
    @MainActor
    private func processCCFWithProgress(forceGenerate: Bool = false) async {
        self.ccfStatus = .generating
        
        if !forceGenerate && self.invoices.count(where: { $0.invoiceType == .CCF && $0.status == .Completada }) >= self.totalInvoices {
            self.hasProcessedCCF = true
            self.ccfProgress = 1.0
            self.ccfStatus = .completed
            return
        }
        
        var invoiceIndex = getNextInoviceNumber()
        
        for i in 1...self.totalInvoices {
            let customer = self.customers.randomElement()!
            let invoiceNumber = String(format: "%05d", invoiceIndex)
            let ccf = Invoice(invoiceNumber: invoiceNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .CCF)
            ccf.items = self.products.map { product in
                InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
            }
            // Set sync status based on company type
            ccf.shouldSyncToCloudKit = !safeCompany.isTestAccount
            invoiceIndex += 1
            self.generatedInvoices.append(ccf)
            
            // Update progress
            self.ccfProgress = Double(i) / Double(self.totalInvoices)
            
            // Small delay to show progress
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        self.hasProcessedCCF = true
        self.ccfStatus = .completed
    }
    
    @MainActor
    private func processCreditNotesWithProgress(forceGenerate: Bool = false) async {
        self.creditNotesStatus = .generating
        
        if !forceGenerate && self.invoices.count(where: { $0.invoiceType == .NotaCredito && $0.status == .Completada }) >= 50 {
            self.hasProcessedCreditNotes = true
            self.creditNotesProgress = 1.0
            self.creditNotesStatus = .completed
            return
        }
        
        var invoiceIndex = getNextInoviceNumber()
        let targetCount = 50
        
        for i in 1...targetCount {
            // Create a new CCF for the credit note
            let customer = self.customers.randomElement()!
            let ccfNumber = String(format: "%05d", invoiceIndex)
            let ccf = Invoice(invoiceNumber: ccfNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .CCF)
            
            ccf.items = self.products.map { product in
                InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
            }
            invoiceIndex += 1
            Extensions.generateControlNumberAndCode(ccf)
            
            // Mark the CCF as a helper invoice for credit notes (not to be shown in progress)
            ccf.isHelperForCreditNote = true
            self.generatedInvoices.append(ccf)
            
            // Create a credit note for this CCF
            let note = generateCreditNotefromInvoice(ccf, invoiceNumber: String(format: "%05d", invoiceIndex))
            invoiceIndex += 1
            self.generatedInvoices.append(note)
            
            // Update progress
            self.creditNotesProgress = Double(i) / Double(targetCount)
            
            // Small delay to show progress
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        self.hasProcessedCreditNotes = true
        self.creditNotesStatus = .completed
    }
    
    @MainActor
    private func sendAllInvoicesWithProgress() async {
        // Update all statuses to sending
        self.facturasStatus = .sending
        self.ccfStatus = .sending
        self.creditNotesStatus = .sending
        
        await validateCertificateCredentialasAsync()
        await validateCredentialsAsync()
        
        if self.showCertificateInvalidMessage || self.showCredentialsInvalidMessage {
            self.facturasStatus = .error
            self.ccfStatus = .error
            self.creditNotesStatus = .error
            
            var errorMessage = "Error de validación: "
            if self.showCertificateInvalidMessage && self.showCredentialsInvalidMessage {
                errorMessage += "Verifica los datos del certificado y las credenciales de hacienda"
            } else if self.showCertificateInvalidMessage {
                errorMessage += "Verifica los datos del certificado (NIT y contraseña)"
            } else {
                errorMessage += "Verifica las credenciales de hacienda"
            }
            
            self.alertMessage = errorMessage
            self.showAlert = true
            return
        }
        
        let totalInvoices = self.generatedInvoices.count
        let facturasCount = self.generatedInvoices.filter { $0.invoiceType == .Factura }.count
        // Exclude helper CCFs from the count that are only created for credit notes
        let ccfCount = self.generatedInvoices.filter { $0.invoiceType == .CCF && !$0.isHelperForCreditNote }.count
        let notesCount = self.generatedInvoices.filter { $0.invoiceType == .NotaCredito }.count
        
        var facturasProcessed = 0
        var ccfProcessed = 0
        var notesProcessed = 0
        
        for (index, invoice) in self.generatedInvoices.enumerated() {
            if invoice.status == .Completada {
                continue
            }
            
            do {
                try await Sync(invoice)
                
                // Update individual progress based on invoice type
                switch invoice.invoiceType {
                case .Factura:
                    facturasProcessed += 1
                    if facturasCount > 0 {
                        self.facturasProgress = Double(facturasProcessed) / Double(facturasCount)
                    }
                case .CCF:
                    // Only count CCF progress if it's not a helper CCF for credit notes
                    if !invoice.isHelperForCreditNote {
                        ccfProcessed += 1
                        if ccfCount > 0 {
                            self.ccfProgress = Double(ccfProcessed) / Double(ccfCount)
                        }
                    }
                case .NotaCredito:
                    notesProcessed += 1
                    if notesCount > 0 {
                        self.creditNotesProgress = Double(notesProcessed) / Double(notesCount)
                    }
                default:
                    break
                }
                
            } catch {
                print("ERROR SYNCING INVOICE: \(error)")
                // Mark as error if any fails, but don't mark CCF as error for helper CCFs
                switch invoice.invoiceType {
                case .Factura:
                    self.facturasStatus = .error
                case .CCF:
                    // Only mark CCF as error if it's not a helper CCF for credit notes
                    if !invoice.isHelperForCreditNote {
                        self.ccfStatus = .error
                    }
                case .NotaCredito:
                    self.creditNotesStatus = .error
                default:
                    break
                }
            }
            
            // Update overall progress
            self.progress = Double(index + 1) / Double(totalInvoices)
        }
        
        // Mark completed statuses
        if self.facturasStatus != .error {
            self.facturasStatus = .completed
        }
        // Only mark CCF as completed if there are actual CCF invoices (not just helpers)
        if self.ccfStatus != .error && ccfCount > 0 {
            self.ccfStatus = .completed
        }
        if self.creditNotesStatus != .error {
            self.creditNotesStatus = .completed
        }
    }
    
    // Helper method to update individual progress during single document processing
    private func updateIndividualProgress(for invoiceType: InvoiceType) {
        let totalOfType: Int
        var processedOfType: Int = 0
        
        switch invoiceType {
        case .Factura:
            totalOfType = self.generatedInvoices.filter { $0.invoiceType == .Factura }.count
            processedOfType = self.generatedInvoices.filter { $0.invoiceType == .Factura && $0.status == .Completada }.count
            if totalOfType > 0 {
                self.facturasProgress = Double(processedOfType) / Double(totalOfType)
            }
        case .CCF:
            totalOfType = self.generatedInvoices.filter { $0.invoiceType == .CCF && !$0.isHelperForCreditNote }.count
            processedOfType = self.generatedInvoices.filter { $0.invoiceType == .CCF && !$0.isHelperForCreditNote && $0.status == .Completada }.count
            if totalOfType > 0 {
                self.ccfProgress = Double(processedOfType) / Double(totalOfType)
            }
        case .NotaCredito:
            totalOfType = self.generatedInvoices.filter { $0.invoiceType == .NotaCredito }.count
            processedOfType = self.generatedInvoices.filter { $0.invoiceType == .NotaCredito && $0.status == .Completada }.count
            if totalOfType > 0 {
                self.creditNotesProgress = Double(processedOfType) / Double(totalOfType)
            }
        default:
            break
        }
    }
    
}
