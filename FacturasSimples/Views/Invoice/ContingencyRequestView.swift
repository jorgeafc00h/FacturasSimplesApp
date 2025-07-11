import SwiftUI
import SwiftData

struct ContingencyRequestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedCompanyIdentifier") var companyIdentifier: String = ""
    
    @State private var viewModel = ContingencyRequestViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Date and Time Selection
                    dateTimeSection
                    
                    // Invoice Loading and Selection
                    invoiceSection
                    
                    // Contingency Details
                    detailsSection
                    
                    // Progress Section (when processing)
                    if viewModel.isSubmittingRequest {
                        progressSection
                    }
                    
                    // Submit Button
                    submitSection
                }
                .padding()
            }
            .navigationTitle("Solicitud de Contingencia")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .disabled(viewModel.isSubmittingRequest)
                }
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
                Button("OK") { 
                    if viewModel.alertTitle == "Proceso Completado" {
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.alertMessage)
            }
            .onAppear {
                setupDefaultTimes()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Solicitud de Contingencia")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("Utilice esta función cuando no pueda transmitir documentos al Ministerio de Hacienda debido a problemas de conectividad o del sistema. Todas las facturas seleccionadas serán sincronizadas automáticamente después de enviar la solicitud.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Date and Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Período de Contingencia")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Date Range
                HStack {
                    VStack(alignment: .leading) {
                        Text("Fecha Inicio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Fecha Fin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
                
                // Time Range
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hora Inicio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Hora Fin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                    }
                }
            }
            
            // Load Invoices Button
            Button(action: loadInvoices) {
                HStack {
                    if viewModel.isLoadingInvoices {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(viewModel.isLoadingInvoices ? "Cargando..." : "Cargar Facturas")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoadingInvoices || !viewModel.isDateRangeValid || viewModel.isSubmittingRequest)
            
            if !viewModel.isDateRangeValid {
                Text("La fecha de inicio debe ser anterior o igual a la fecha de fin")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Invoice Section
    private var invoiceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.green)
                Text("Facturas Disponibles")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.availableInvoices.isEmpty {
                    Text("\(viewModel.selectedInvoices.count) de \(viewModel.availableInvoices.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.availableInvoices.isEmpty && !viewModel.isLoadingInvoices {
                Text("Seleccione un rango de fechas y presione 'Cargar Facturas' para ver las facturas disponibles con estado 'nueva'.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if !viewModel.availableInvoices.isEmpty {
                VStack(spacing: 12) {
                    // Selection Controls
                    HStack {
                        Button("Seleccionar Todo") {
                            viewModel.selectAllInvoices()
                        }
                        .font(.caption)
                        .disabled(viewModel.isSubmittingRequest)
                        
                        Spacer()
                        
                        Button("Deseleccionar Todo") {
                            viewModel.deselectAllInvoices()
                        }
                        .font(.caption)
                        .disabled(viewModel.isSubmittingRequest)
                    }
                    
                    // Control Number Warning
                    if !viewModel.invoicesNeedingControlNumbers.isEmpty && !viewModel.selectedInvoices.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("\(viewModel.invoicesNeedingControlNumbers.count) facturas necesitan generar número de control")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // Invoice List
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.availableInvoices, id: \.id) { invoice in
                            InvoiceRowView(
                                invoice: invoice,
                                isSelected: viewModel.selectedInvoices.contains(invoice.id),
                                needsControlNumber: invoice.controlNumber?.isEmpty != false || invoice.generationCode?.isEmpty != false
                            ) {
                                if !viewModel.isSubmittingRequest {
                                    viewModel.toggleInvoiceSelection(invoice)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.purple)
                Text("Detalles de la Contingencia")
                    .font(.headline)
                Spacer()
            }
            
            // Responsible person name
            VStack(alignment: .leading, spacing: 4) {
                Text("Nombre del Responsable (requerido)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Ingrese el nombre completo del responsable", text: $viewModel.nombreResponsable)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isSubmittingRequest)
            }
            
            // DUI field
            VStack(alignment: .leading, spacing: 4) {
                Text("DUI del Responsable (requerido)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("000000000", text: $viewModel.duiResponsable)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .disabled(viewModel.isSubmittingRequest)
                    .onChange(of: viewModel.duiResponsable) { _, newValue in
                        // Limit to 9 digits
                        let filtered = String(newValue.filter { $0.isNumber }.prefix(9))
                        if filtered != newValue {
                            viewModel.duiResponsable = filtered
                        }
                    }
                
                if !viewModel.duiResponsable.isEmpty && viewModel.duiResponsable.count != 9 {
                    Text("El DUI debe tener exactamente 9 dígitos")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Text("Describa el motivo de la contingencia (requerido)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextEditor(text: $viewModel.contingencyDetails)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .disabled(viewModel.isSubmittingRequest)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                        .symbolEffect(.rotate, isActive: true)
                    Text("Procesando Solicitud de Contingencia")
                        .font(.headline)
                    Spacer()
                }
                
                ProgressView(value: viewModel.uploadProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 2)
                
                HStack {
                    Text(viewModel.syncProgressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.uploadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.isSyncingInvoices {
                    Text("Sincronizando factura \(viewModel.currentInvoiceIndex) de \(viewModel.totalInvoices)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Submit Section
    private var submitSection: some View {
        VStack(spacing: 16) {
            Button(action: submitRequest) {
                HStack {
                    if viewModel.isSubmittingRequest {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(viewModel.isSubmittingRequest ? "Procesando..." : "Enviar Solicitud y Sincronizar")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSubmitRequest || viewModel.isSubmittingRequest)
            
            if !viewModel.canSubmitRequest && !viewModel.selectedInvoices.isEmpty {
                Text("Complete todos los campos requeridos para enviar la solicitud")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.canSubmitRequest && !viewModel.invoicesNeedingControlNumbers.isEmpty {
                Text("Se generarán automáticamente los números de control faltantes antes del envío")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupDefaultTimes() {
        let calendar = Calendar.current
        viewModel.startTime = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()
        viewModel.endTime = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
    }
    
    private func loadInvoices() {
        viewModel.loadInvoices(from: modelContext, companyId: companyIdentifier)
    }
    
    private func submitRequest() {
        viewModel.submitContingencyRequest(companyId: companyIdentifier, modelContext: modelContext)
    }
}

// MARK: - Invoice Row View
struct InvoiceRowView: View {
    let invoice: Invoice
    let isSelected: Bool
    let needsControlNumber: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            invoiceRowContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var invoiceRowContent: some View {
        HStack {
            selectionIndicator
            
            VStack(alignment: .leading, spacing: 4) {
                invoiceNumberRow
                customerDateRow
                totalStatusRow
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
    
    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? .blue : .gray)
            .font(.title3)
    }
    
    private var invoiceNumberRow: some View {
        HStack {
            Text("Factura #\(invoice.invoiceNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if needsControlNumber {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                    .help("Necesita generar número de control")
            }
            
            Spacer()
        }
    }
    
    
    private var customerDateRow: some View {
        HStack {
            Text(invoice.customer?.fullName ?? "Cliente no especificado")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(invoice.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var totalStatusRow: some View {
        HStack {
            Text("Total: $\(invoice.totalAmount.asDoubleRounded, specifier: "%.2f")")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let controlNumber = invoice.controlNumber, !controlNumber.isEmpty {
                Text("Control: \(controlNumber)")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Sin control")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContingencyRequestView()
}
