import SwiftUI
import SwiftData

extension PreProdStep1{
    
    @Observable
    class RequestProductionAccessViewModel {
        
        var invoices: [Invoice] = []
        var customers: [Customer] = []
        var products: [Product] = []
        var showAlert = false
        var alertMessage = ""
        var progress: Double = 0.0
        var isSyncing = false
        var showConfirmDialog = false
        var hasMinimumInvoices = false
        var hasCompleted: Bool = false
        
        
        let invoiceService = InvoiceServiceClient()
        var dteService = MhClient()
        
    }
    
    func generateAndSendInvoices() {
        generateInvoices()
        sendInvoices()
        
    }
    func generateInvoices() {
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
        
        viewModel.products = (1...7).map { i in
            let p = Product(productName: "Producto\(i)", unitPrice: Decimal(Double.random(in: 1...100)))
            p.companyId = company.id
            return p
        }
        
        let invoiceTypes: [InvoiceType] = [.CCF, .Factura]
        viewModel.invoices = invoiceTypes.flatMap { type in
            (1...50).map { i in
                let customer = viewModel.customers.randomElement()!
                let invoice = Invoice(invoiceNumber: "\(i)", date: Date(), status: .Nueva, customer: customer, invoiceType: type)
                invoice.items = viewModel.products.map { product in
                    InvoiceDetail(quantity: Decimal( Int.random(in: 1...5)), product: product)
                }
                return invoice
            }
        }
        viewModel.alertMessage = "Se generaron 50 facturas por tipo con datos de prueba."
        let productionCompanyAccount = Company(nit: company.nit, nrc: company.nrc, nombre: company.nombre)
        productionCompanyAccount.isTestAccount = false
        modelContext.insert(productionCompanyAccount)
        viewModel.showAlert = true
    }
    
    func sendInvoices() {
        viewModel.isSyncing = true
        viewModel.progress = 0.0
        Task {
            for (index, invoice) in viewModel.invoices.enumerated() {
                do {
                    try await Sync(invoice)
                    invoice.status = .Completada
                    modelContext.insert(invoice)
                } catch {
                    print("Error syncing invoice: \(error)")
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
        
        if viewModel.hasCompleted {
            dismiss()
        }
        
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
        viewModel.hasCompleted = true
    }
    
    private func Sync(_ invoice: Invoice) async throws {
        do {
            let dte = GenerateInvoiceReferences(invoice)
            
            let credentials = ServiceCredentials(user: dte!.emisor.nit,
                                                 credential: company.credentials,
                                                 key: company.certificatePassword,
                                                 invoiceNumber: invoice.invoiceNumber)
            
            let dteResponse = try await viewModel.invoiceService.Sync(dte: dte!, credentials: credentials,isProduction: company.isProduction)
            
            print("\(dteResponse.estado)")
            print("SELLO \(dteResponse.selloRecibido)")
        } catch(let error) {
            print("error \(error.localizedDescription)")
            throw error
        }
    }
    
    func GenerateInvoiceReferences(_ invoice: Invoice) -> DTE_Base? {
        if invoice.controlNumber == nil || invoice.controlNumber == "" {
            invoice.controlNumber = invoice.isCCF ?
            try? Extensions.generateString(baseString: "DTE-03", pattern: nil) :
            try? Extensions.generateString(baseString: "DTE", pattern: "^DTE-01-[A-Z0-9]{8}-[0-9]{15}$")
        }
        
        if invoice.generationCode == nil || invoice.generationCode == "" {
            invoice.generationCode = try? Extensions.getGenerationCode()
        }
        
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
}
