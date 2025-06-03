import SwiftUI
import SwiftData

extension PreProdStep1{
    
    @Observable
    class RequestProductionAccessViewModel {
            
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
        
        var totalInvoices: Int = 50
        
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
        
    }
    
    func loadAllInvoices() {
        let id = company.id
        let _fetchAll = FetchDescriptor<Invoice>(predicate: #Predicate{
            $0.customer.companyOwnerId == id
        })
        
        let _invoices = try? modelContext.fetch(_fetchAll)
        
        let fetchCustomers = FetchDescriptor<Customer>(predicate: #Predicate{
            $0.companyOwnerId == id &&
            $0.nrc != "" &&
            $0.codActividad != ""
        })
                                                       
        let _customers = try? modelContext.fetch(fetchCustomers)
        
        
       
//
        
        viewModel.invoices = _invoices ?? []
        viewModel.customers = _customers ?? []
    }
    
    func generateAndSendInvoices() {
        generateInvoices()
        sendInvoices()
        
    }
    func generateInvoices()  {
        prepareCustomersAndProducts()
        
        // This method now acts as a coordinator for all invoice types
        var processed = false
        
        if !viewModel.hasProcessedFacturas {
            generateFacturas()
            processed = true
        }
        
        if !viewModel.hasProcessedCCF {
            generateCreditosFiscales()
            processed = true
        }
        
        if !viewModel.hasProcessedCreditNotes {
            generateCreditNotes()
            processed = true
        }
        
        if processed {
            try? modelContext.save()
            viewModel.alertMessage = "Se generaron facturas con datos de prueba."
        } else {
            viewModel.alertMessage = "Todos los tipos de documentos ya han sido procesados."
        }
        
        viewModel.showAlert = true
        ValidateProductionAccount()
    }
    
    func validateCertificateCredentialasAsync() async  {
        viewModel.isLoadingCertificateStatus = true
        
        let service = InvoiceServiceClient()
        
        
        let result = try? await service.validateCertificate(nit: company.nit, key: company.certificatePassword,isProduction: company.isProduction)
        
        print("Certificate Validation Result: \(String(describing: result))")
        
        if(result == nil || result! == false){
            
            viewModel.showCertificateInvalidMessage = true
        }
        else{
            viewModel.showCertificateInvalidMessage = false
        }
        viewModel.isLoadingCertificateStatus = false
    }
    
    func validateCredentialsAsync() async  {
        viewModel.isLoadingCredentialsStatus = true
        
        let service = InvoiceServiceClient()
        
        let result = try? await service.validateCredentials(nit: company.nit,
                                                            password: company.credentials,
                                                            isProduction: company.isProduction,
                                                            forceRefresh: false)
        print("Credentials Validation Result: \(String(describing: result))")
        
        if( result == nil || result! == false){
            viewModel.showCredentialsInvalidMessage = true
        }
        else{
            viewModel.showCredentialsInvalidMessage = false
        }
        
        viewModel.isLoadingCredentialsStatus = false
    }
    
    // Helper method to prepare customers and products
    func prepareCustomersAndProducts()  {
        //check MH credentials
       
        // Only create customers and products if they haven't been created yet
        if viewModel.customers.isEmpty {
            let firstNames = ["Juan", "María", "Carlos", "Ana", "Luis", "Sofía", "Miguel", "Lucía", "Javier", "Isabel"]
            let lastNames = ["Pérez", "García", "Rodríguez", "López", "Martínez", "Hernández", "González", "Ramírez", "Sánchez", "Torres"]
            viewModel.customers = (1...5).map { i in
                let firstName = firstNames.randomElement()!
                let lastName = lastNames.randomElement()!
                let c = Customer(firstName: firstName, lastName: lastName, nationalId: "03721600\(i)", email: "\(firstName.lowercased())\(i)@yopmail.com", phone: "7700120\(i)")
                c.companyOwnerId = company.id
                c.departamento = "San Salvador"
                c.departamentoCode = "06"
                c.municipioCode = "14"
                c.address = "TEST #\(i)"
                c.nit = "06141709940015"
                c.nrc = "3174"
                c.descActividad = "Publicidad"
                c.codActividad = "73100"
                return c
            }
        }
        
        if viewModel.products.isEmpty {
            viewModel.products = (1...7).map { i in
                let p = Product(productName: "Producto\(i)", unitPrice: Decimal(Double.random(in: 1...100)))
                p.companyId = company.id
                return p
            }
        }
    }
    
    // Generate Facturas
    func generateFacturas(forceGenerate: Bool = false) {
        if !forceGenerate && viewModel.invoices.count(where: { $0.invoiceType == .Factura && $0.status == .Completada }) >= viewModel.totalInvoices {
            viewModel.hasProcessedFacturas = true
            viewModel.alertMessage = "Ya existen suficientes Facturas completadas."
            viewModel.showAlert = true
            return
        }
        
        var invoiceIndex = getNextInoviceNumber()
        
        for _ in 1...viewModel.totalInvoices {  
            let customer = viewModel.customers.randomElement()!
            let invoiceNumber = String(format: "%05d", invoiceIndex)
            let invoice = Invoice(invoiceNumber: invoiceNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .Factura)
            invoice.items = viewModel.products.map { product in
                InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
            }
            invoiceIndex += 1
            //modelContext.insert(invoice)
            viewModel.generatedInvoices.append(invoice)
            //return invoice
        }
        
        //try? modelContext.save()
        
        viewModel.hasProcessedFacturas = true
        viewModel.alertMessage = "Se generaron \(viewModel.totalInvoices) Facturas con datos de prueba."
        viewModel.showAlert = true
    }
    
    // Generate Creditos Fiscales
    func generateCreditosFiscales(forceGenerate: Bool = false) {
        if !forceGenerate && viewModel.invoices.count(where: { $0.invoiceType == .CCF && $0.status == .Completada }) >= viewModel.totalInvoices {
            viewModel.hasProcessedCCF = true
            viewModel.alertMessage = "Ya existen suficientes Créditos Fiscales completados."
            viewModel.showAlert = true
            return
        }
        
        var invoiceIndex = getNextInoviceNumber()
        
        for _ in 1...viewModel.totalInvoices { 
            let customer = viewModel.customers.randomElement()!
            let invoiceNumber = String(format: "%05d", invoiceIndex)
            let ccf = Invoice(invoiceNumber: invoiceNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .CCF)
            ccf.items = viewModel.products.map { product in
                InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
            }
            invoiceIndex += 1
            viewModel.generatedInvoices.append(ccf)
            //modelContext.insert(ccf)
            //return ccf
        }
        
        //try? modelContext.save()
        
        viewModel.hasProcessedCCF = true
        viewModel.alertMessage = "Se generaron \(viewModel.totalInvoices) Créditos Fiscales con datos de prueba."
        viewModel.showAlert = true
    }
    
    // Generate Credit Notes
    func generateCreditNotes(forceGenerate: Bool = false) {
        if !forceGenerate && viewModel.invoices.count(where: { $0.invoiceType == .NotaCredito && $0.status == .Completada }) >= 50 {
            viewModel.hasProcessedCreditNotes = true
            viewModel.alertMessage = "Ya existen suficientes Notas de Crédito completadas."
            viewModel.showAlert = true
            return
        }
        
        // Check if we have enough CCF to generate credit notes
        let calendar = Calendar.current
        _ = calendar.startOfDay(for: Date())
        
        let hasCCFAvailable = viewModel.invoices.count(where: { 
            $0.invoiceType == .CCF && 
            $0.status == .Nueva && 
            calendar.isDate($0.date, inSameDayAs: Date())
        }) >= 50
        
        if !hasCCFAvailable {
            // Generate more CCF first if needed
            generateCreditosFiscales(forceGenerate: forceGenerate)
        }
        
        // Filter to get only today's CCF invoices for credit notes
        let ccfInvoices = viewModel.invoices.filter { 
            $0.invoiceType == .CCF && 
            $0.status == .Nueva &&
            calendar.isDate($0.date, inSameDayAs: Date())
        }.suffix(50)
        
        var invoiceIndex = getNextInoviceNumber()
        
        // If we don't have enough from today, create a new CCF then a note
        if ccfInvoices.count < 50 {
            // Use a simple for loop instead of map
            for _ in 1...viewModel.totalInvoices {
                // Create a new CCF
                let customer = viewModel.customers.randomElement()!
                let invoiceNumber = String(format: "%05d", invoiceIndex)
                let ccf = Invoice(invoiceNumber: invoiceNumber, date: Date(), status: .Nueva, customer: customer, invoiceType: .CCF)
                
                // Add items to the CCF
                ccf.items = viewModel.products.map { product in
                    InvoiceDetail(quantity: Decimal(Int.random(in: 1...5)), product: product)
                }
                invoiceIndex += 1
                
                // Set control numbers
                Extensions.generateControlNumberAndCode(ccf)
                
                viewModel.generatedInvoices.append(ccf)
                
                // Create a credit note for this CCF
                let note = generateCreditNotefromInvoice(ccf, invoiceNumber: String(format: "%05d", invoiceIndex))
                invoiceIndex += 1
                viewModel.generatedInvoices.append(note)
            }
        } else {
            // Use existing CCF invoices
            for ccf in ccfInvoices {
                let note = generateCreditNotefromInvoice(ccf, invoiceNumber: String(format: "%05d", invoiceIndex))
                invoiceIndex += 1
                viewModel.generatedInvoices.append(note)
            }
        }
        
        viewModel.hasProcessedCreditNotes = true
        viewModel.alertMessage = "Se generaron 50 Notas de Crédito con datos de prueba."
        viewModel.showAlert = true
    }
    
    func generateCreditNotefromInvoice(_ invoice: Invoice, invoiceNumber: String) -> Invoice{
        
        
        let note = Invoice(invoiceNumber: invoiceNumber,
                           date: invoice.date,
                           status: invoice.status, customer: invoice.customer,
                           invoiceType: .NotaCredito)
        
        Extensions.generateControlNumberAndCode(note)
        
        let items = invoice.items.map { detail -> InvoiceDetail in
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
        
        modelContext.insert(note)
        try? modelContext.save()
        
        return note
    }
    
    func sendInvoices() {
        viewModel.isSyncing = true
        viewModel.progress = 0.0
        Task {
            await validateCertificateCredentialasAsync()
            await validateCredentialsAsync()
            
            if viewModel.showCertificateInvalidMessage || viewModel.showCredentialsInvalidMessage{
                viewModel.alertMessage = "Por favor verifica los datos de tu certificado y las credenciales de hacienda"
                viewModel.showAlert = true
                return
            }
            
            for (index, invoice) in viewModel.generatedInvoices.enumerated() {
                
                if invoice.status == .Completada {
                    viewModel.progress = Double(index + 1) / Double(viewModel.invoices.count)
                    continue
                }
                
                print("invoice tpe: \(invoice.invoiceType)")
                print("control: \(String(describing: invoice.controlNumber))")
                
                do {
                    try await Sync(invoice)
                    
                } catch {
                    print("ERROR SYNCING INVOICE: \(error)")
                }
                viewModel.progress = Double(index + 1) / Double(viewModel.invoices.count)
            }
            viewModel.isSyncing = false
            viewModel.alertMessage = "Facturas enviadas y completadas."
            viewModel.showAlert = true
            viewModel.hasCompleted = true
        }
    }
    
    func ValidateProductionAccount() {
        
        
        let nit = company.nit
        let _fetchRequest = FetchDescriptor<Company>(predicate: #Predicate{
            $0.nit == nit && $0.isTestAccount == false
        })
        do {
            let productionAccounts = try modelContext.fetch(_fetchRequest)
            if !productionAccounts.isEmpty {
                viewModel.alertMessage = "La cuenta de producción ya está configurada."
            } else {
                let productionCompanyAccount = Company(
                    nit: company.nit,
                    nrc: company.nrc,
                    nombre: company.nombre,
                    descActividad: company.descActividad,
                    nombreComercial: company.nombreComercial,
                    tipoEstablecimiento: company.tipoEstablecimiento,
                    establecimiento: company.establecimiento,
                    telefono: company.telefono,
                    correo: company.correo,
                    codEstableMH: company.codEstableMH,
                    codEstable: company.codEstable,
                    codPuntoVentaMH: company.codPuntoVentaMH,
                    codPuntoVenta: company.codPuntoVenta,
                    departamento: company.departamento,
                    municipio: company.municipio,
                    complemento: company.complemento,
                    invoiceLogo: company.invoiceLogo,
                    departamentoCode: company.departamentoCode,
                    municipioCode: company.municipioCode,
                    codActividad: company.codActividad,
                    certificatePath: company.certificatePath,
                    certificatePassword: company.certificatePassword,
                    credentials: company.credentials,
                    isTestAccount: false
                )
                modelContext.insert(productionCompanyAccount)
                viewModel.alertMessage = "La cuenta de producción ha sido creada y configurada."
            }
        } catch {
            viewModel.alertMessage = "Error al verificar la cuenta de producción: \(error.localizedDescription)"
        }
        viewModel.showAlert = true
       
        if viewModel.hasCompleted {
            dismiss()
        }
    }
    
    private func Sync(_ invoice: Invoice) async throws {
        do {
            let dte = GenerateInvoiceReferences(invoice)
            
            let credentials = ServiceCredentials(user: dte!.emisor.nit,
                                                 credential: company.credentials,
                                                 key: company.certificatePassword,
                                                 invoiceNumber: invoice.invoiceNumber)
            
            let response = try await viewModel.invoiceService.Sync(dte: dte!, credentials: credentials,isProduction: company.isProduction)
            
            
            
            print("\(response.estado)")
            print("SELLO \(response.selloRecibido)")
            
            
            invoice.status = .Completada
            invoice.statusRawValue = invoice.status.id
            invoice.receptionSeal = response.selloRecibido
            
            modelContext.insert(invoice)
            try? modelContext.save()
            
            if invoice.invoiceType == .NotaCredito {
                
                let id = invoice.relatedId!
                
                let descriptor = FetchDescriptor<Invoice>(
                    predicate: #Predicate<Invoice>{
                        $0.inoviceId == id
                    }
                )
                
                if let relatedInvoice = try? modelContext.fetch(descriptor).first{
                    relatedInvoice.status = .Anulada
                    relatedInvoice.statusRawValue = relatedInvoice.status.id
                    try? modelContext.save()
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
            
            let envCode  = viewModel.invoiceService.getEnvironmetCode(company.isProduction)
            
            let dte = try MhClient.mapInvoice(invoice: invoice, company: company,environmentCode: envCode)
            
            print("DTE Numero control:\(dte.identificacion.numeroControl ?? "")")
            
            return dte
        } catch (let error) {
            print("failed to map invoice to dte \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getNextInoviceNumber() -> Int{
        
        let id = company.id
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate<Invoice>{
                $0.customer.companyOwnerId == id
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let latestInvoice = try? modelContext.fetch(descriptor).first {
            if let currentNumber = Int(latestInvoice.invoiceNumber) {
                return currentNumber
            } else {
                return 1
            }
        } else {
            return 1
        }
        
        
    }
    
    // Helper method to process all document types
    func processAllDocuments(forceGenerate: Bool = false) {
        prepareCustomersAndProducts()
        
        generateFacturas(forceGenerate: forceGenerate)
        generateCreditosFiscales(forceGenerate: forceGenerate)
        generateCreditNotes(forceGenerate: forceGenerate)
        
        viewModel.alertMessage = "Se generaron todos los documentos necesarios con datos de prueba."
        viewModel.showAlert = true
        sendInvoices()
    }
    
    // Helper computed property to check if all document types are processed
    var allProcessed: Bool {
        return viewModel.hasProcessedFacturas && viewModel.hasProcessedCCF && viewModel.hasProcessedCreditNotes
    }
    
    
}
