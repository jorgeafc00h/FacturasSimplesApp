import SwiftUI
import SwiftData

extension ContingencyRequestView {
    
    @Observable
    class ContingencyRequestViewModel {
        var startDate: Date = Date() // Set to today's date
        var endDate: Date = Date()
        var startTime: Date = Date()
        var endTime: Date = Date()
        
        var availableInvoices: [Invoice] = []
        var selectedInvoices: Set<Invoice.ID> = []
        var isLoadingInvoices: Bool = false
        var isSubmittingRequest: Bool = false
        var isSyncingInvoices: Bool = false
        
        var showingAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        
        var contingencyDetails: String = ""
        var nombreResponsable: String = ""
        var duiResponsable: String = ""
        
        var uploadProgress: Double = 0.0
        var currentInvoiceIndex: Int = 0
        var totalInvoices: Int = 0
        var syncProgressText: String = ""
        
        private let invoiceService = InvoiceServiceClient()
        private let dteService = MhClient()
        
        /// Load invoices with status "nueva" within the selected date range
        func loadInvoices(from modelContext: ModelContext, companyId: String) {
            print("📋 ContingencyRequestViewModel: Loading invoices for date range")
            isLoadingInvoices = true
            
            Task { @MainActor in
                do {
                    let startOfDay = Calendar.current.startOfDay(for: startDate)
                    let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
                    
                    // Simplified predicate to avoid compiler timeout
                    let predicate = #Predicate<Invoice> { invoice in
                        invoice.customer?.companyOwnerId == companyId
                    }
                    
                    let descriptor = FetchDescriptor<Invoice>(predicate: predicate)
                    let allInvoices = try modelContext.fetch(descriptor)
                    
                    // Filter in memory to avoid complex predicate compilation issues
                    let filteredInvoices = allInvoices.filter { invoice in
                        invoice.status == .Nueva &&
                        invoice.date >= startOfDay &&
                        invoice.date <= endOfDay
                    }
                    
                    self.availableInvoices = filteredInvoices.sorted { $0.date > $1.date }
                    print("✅ ContingencyRequestViewModel: Loaded \(filteredInvoices.count) invoices with status 'nueva'")
                    
                } catch {
                    print("❌ ContingencyRequestViewModel: Error loading invoices: \(error)")
                    self.showAlert(title: "Error", message: "No se pudieron cargar las facturas: \(error.localizedDescription)")
                }
                
                self.isLoadingInvoices = false
            }
        }
        
        /// Generate control numbers for invoices that don't have them
        private func generateControlNumbers(for invoices: [Invoice], company: Company, modelContext: ModelContext) throws {
            for invoice in invoices {
                if invoice.controlNumber?.isEmpty != false || invoice.generationCode?.isEmpty != false {
                    print("📋 Generating control number for invoice: \(invoice.invoiceNumber)")
                    
                    // Generate control number and generation code
                    Extensions.generateControlNumberAndCode(invoice)
                    
                    // Ensure document type is set
                    if invoice.documentType.isEmpty {
                        invoice.documentType = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
                    }
                }
            }
            
            // Save all changes
            try modelContext.save()
            print("✅ Control numbers generated for all invoices")
        }
        
        /// Sync individual invoice using the same logic as InvoiceDetailViewModel
        private func syncInvoice(_ invoice: Invoice, company: Company, modelContext: ModelContext) async throws -> DTEResponseWrapper? {
            print("📋 Syncing invoice: \(invoice.invoiceNumber)")
            
            // Generate DTE using MhClient
            let environmentCode = company.isProduction ? "01" : "00"
            let dte = try MhClient.mapInvoice(invoice: invoice, company: company, environmentCode: environmentCode)
            
            let credentials = ServiceCredentials(
                user: dte.emisor.nit,
                credential: company.credentials,
                key: company.certificatePassword,
                invoiceNumber: invoice.invoiceNumber
            )
            
            let response = try await invoiceService.Sync(
                dte: dte,
                credentials: credentials,
                isProduction: company.isProduction
            )
            
            // Update invoice status based on response
            await MainActor.run {
                if response.estado == "PROCESADO" {
                    invoice.status = .Completada
                    invoice.receptionSeal = response.selloRecibido
                    
                    // Save changes for this specific invoice
                    do {
                        try modelContext.save()
                        print("✅ Invoice \(invoice.invoiceNumber) synced and saved successfully")
                    } catch {
                        print("❌ Failed to save invoice \(invoice.invoiceNumber): \(error)")
                    }
                } else {
                    print("❌ Invoice \(invoice.invoiceNumber) sync failed: \(response.estado ?? "Unknown")")
                }
            }
            
            return response
        }
        
        /// Submit the contingency request and sync all selected invoices
        func submitContingencyRequest(companyId: String, modelContext: ModelContext) {
            guard !selectedInvoices.isEmpty else {
                showAlert(title: "Error", message: "Debe seleccionar al menos una factura")
                return
            }
            
            guard !contingencyDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showAlert(title: "Error", message: "Debe ingresar los detalles de la contingencia")
                return
            }
            
            guard !nombreResponsable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showAlert(title: "Error", message: "Debe ingresar el nombre del responsable")
                return
            }
            
            guard duiResponsable.count == 9 else {
                showAlert(title: "Error", message: "El DUI del responsable debe tener exactamente 9 dígitos")
                return
            }
            
            print("📋 ContingencyRequestViewModel: Starting contingency request for \(selectedInvoices.count) invoices")
            isSubmittingRequest = true
            uploadProgress = 0.0
            
            Task { @MainActor in
                do {
                    let selectedInvoiceList = availableInvoices.filter { selectedInvoices.contains($0.id) }
                    totalInvoices = selectedInvoiceList.count
                    
                    // Get company information
                    let predicate = #Predicate<Company> { company in
                        company.id == companyId
                    }
                    let descriptor = FetchDescriptor<Company>(predicate: predicate)
                    guard let company = try modelContext.fetch(descriptor).first else {
                        throw NSError(domain: "ContingencyRequest", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se encontró la empresa"])
                    }
                    
                    syncProgressText = "Preparando facturas..."
                    uploadProgress = 0.1
                    
                    // Step 1: Generate control numbers for invoices that need them
                    try generateControlNumbers(for: selectedInvoiceList, company: company, modelContext: modelContext)
                    
                    syncProgressText = "Creando solicitud de contingencia..."
                    uploadProgress = 0.2
                    
                    // Step 2: Create contingency request using MHService
                    let environmentCode = company.isProduction ? "01" : "00"
                    let contingencyRequest = try MhClient.mapContingenciaRequest(
                        invoices: selectedInvoiceList,
                        company: company,
                        environmentCode: environmentCode,
                        startDate: combineDateAndTime(date: startDate, time: startTime),
                        endDate: combineDateAndTime(date: endDate, time: endTime),
                        contingencyType: 1,
                        reason: contingencyDetails,
                        nombreResponsable: nombreResponsable,
                        duiResponsable: duiResponsable
                    )
                    
                    syncProgressText = "Enviando solicitud de contingencia..."
                    uploadProgress = 0.3
                    
                    let credentials = ServiceCredentials(user: company.nit,
                                                         credential: company.credentials,
                                                         key: company.certificatePassword,
                                                         invoiceNumber: "0001")
                    
                    // Step 3: Submit the contingency request
                    let contingencySuccess = try await invoiceService.sendContingencyRequest(
                        contingencyRequest,
                        credentials: credentials,
                        isProduction: company.isProduction
                    )
                    
                    guard contingencySuccess else {
                        throw NSError(domain: "ContingencyRequest", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo enviar la solicitud de contingencia"])
                    }
                    
                    print("✅ Contingency request sent successfully")
                    
                    syncProgressText = "Sincronizando facturas..."
                    uploadProgress = 0.4
                    isSyncingInvoices = true
                    
                    // Step 4: Sync all invoices one by one
                    var successCount = 0
                    var failureCount = 0
                    
                    for (index, invoice) in selectedInvoiceList.enumerated() {
                        currentInvoiceIndex = index + 1
                        syncProgressText = "Sincronizando factura \(currentInvoiceIndex) de \(totalInvoices): \(invoice.invoiceNumber)"
                        
                        do {
                            let response = try await syncInvoice(invoice, company: company, modelContext: modelContext)
                            if response?.estado == "PROCESADO" {
                                successCount += 1
                            } else {
                                failureCount += 1
                            }
                        } catch {
                            print("❌ Failed to sync invoice \(invoice.invoiceNumber): \(error)")
                            failureCount += 1
                        }
                        
                        // Update progress
                        let invoiceProgress = Double(index + 1) / Double(totalInvoices)
                        uploadProgress = 0.4 + (invoiceProgress * 0.6) // From 40% to 100%
                        
                        // Small delay to prevent overwhelming the server
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                    }
                    
                    uploadProgress = 1.0
                    syncProgressText = "Completado"
                    
                    print("✅ ContingencyRequestViewModel: Process completed. Success: \(successCount), Failures: \(failureCount)")
                    
                    let message = """
                    Proceso completado:
                    
                    • Solicitud de contingencia: Enviada exitosamente
                    • Facturas sincronizadas: \(successCount)
                    • Facturas con errores: \(failureCount)
                    
                    Total procesadas: \(totalInvoices)
                    """
                    
                    showAlert(title: "Proceso Completado", message: message)
                    
                    // Clear selections after successful submission
                    selectedInvoices.removeAll()
                    contingencyDetails = ""
                    nombreResponsable = ""
                    duiResponsable = ""
                    
                } catch {
                    print("❌ ContingencyRequestViewModel: Error in contingency process: \(error)")
                    showAlert(title: "Error", message: "Error en el proceso: \(error.localizedDescription)")
                }
                
                isSubmittingRequest = false
                isSyncingInvoices = false
                uploadProgress = 0.0
                syncProgressText = ""
            }
        }
        
        /// Combine date and time into a single Date object
        private func combineDateAndTime(date: Date, time: Date) -> Date {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
            
            var combined = DateComponents()
            combined.year = dateComponents.year
            combined.month = dateComponents.month
            combined.day = dateComponents.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute
            combined.second = timeComponents.second
            
            return calendar.date(from: combined) ?? date
        }
        
        /// Toggle selection of an invoice
        func toggleInvoiceSelection(_ invoice: Invoice) {
            if selectedInvoices.contains(invoice.id) {
                selectedInvoices.remove(invoice.id)
            } else {
                selectedInvoices.insert(invoice.id)
            }
            print("📋 ContingencyRequestViewModel: Invoice \(invoice.invoiceNumber) selection toggled. Total selected: \(selectedInvoices.count)")
        }
        
        /// Select all loaded invoices
        func selectAllInvoices() {
            selectedInvoices = Set(availableInvoices.map { $0.id })
            print("📋 ContingencyRequestViewModel: All \(availableInvoices.count) invoices selected")
        }
        
        /// Deselect all invoices
        func deselectAllInvoices() {
            selectedInvoices.removeAll()
            print("📋 ContingencyRequestViewModel: All invoices deselected")
        }
        
        /// Show alert with title and message
        private func showAlert(title: String, message: String) {
            alertTitle = title
            alertMessage = message
            showingAlert = true
        }
        
        /// Check if the date range is valid
        var isDateRangeValid: Bool {
            startDate <= endDate
        }
        
        /// Check if all required fields are filled
        var canSubmitRequest: Bool {
            !selectedInvoices.isEmpty && 
            !contingencyDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !nombreResponsable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            duiResponsable.count == 9 &&
            isDateRangeValid
        }
        
        /// Get invoices that need control number generation
        var invoicesNeedingControlNumbers: [Invoice] {
            availableInvoices.filter { invoice in
                selectedInvoices.contains(invoice.id) && 
                (invoice.controlNumber?.isEmpty != false || invoice.generationCode?.isEmpty != false)
            }
        }
    }
}
