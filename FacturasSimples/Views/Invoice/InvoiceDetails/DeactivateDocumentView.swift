import SwiftUI
import SwiftData

struct DeactivateDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showConfirmation = false
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccessMessage = false
    
    // Invoice reference
    @Bindable var invoice: Invoice
    @Bindable var company: Company
    
    var invoiceService = InvoiceServiceClient()
    
    // Form fields based on Motivo model
    @State private var tipoAnulacion: Int = 1
    @State private var motivoAnulacion: String = ""
    
    // Responsable fields
    @AppStorage("nombreResponsable") private var nombreResponsable: String = ""
    @State private var tipDocResponsable: String = "13" // Default to DUI
    @AppStorage("numDocResponsable") private var numDocResponsable: String = ""
    
    
    // Solicitante fields
    @AppStorage("deactivateDocName") private var nombreSolicita: String = ""
    @AppStorage("deactivateDocPhone") private var telefonoSolicita: String = ""
    @AppStorage("deactivateDocEmail") private var correoSolicita: String = ""
    @State private var tipDocSolicita: String = "13" // Default to DUI
    @AppStorage("numDocSolicita") private var numDocSolicita: String = ""
    
    @AppStorage("nomEstablecimiento")private var nomEstablecimiento: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Motivo de Anulación")) {
                    Picker("Tipo de Anulación", selection: $tipoAnulacion) {
                        Text("Anulación Normal").tag(2)
                        Text("Anulación por Error en Datos").tag(3)
                        Text("Anulación por Causa Judicial").tag(4)
                    }
                    TextField("Motivo de Anulación", text: $motivoAnulacion)
                        .multilineTextAlignment(.leading)
                }
                
                Section(header: Text("Información del Responsable")) {
                    TextField("Nombre del Responsable", text: $nombreResponsable)
                        .textContentType(.name)
                    
                    Picker("Tipo de Documento", selection: $tipDocResponsable) {
                        Text("DUI").tag("13")
                        Text("NIT").tag("36")
                    }
                    
                    TextField("Número de Documento", text: $numDocResponsable)
                        .keyboardType(.namePhonePad)
                    
                }
                
                Section(header: Text("Información del Solicitante")) {
                    TextField("Nombre del Solicitante", text: $nombreSolicita)
                        .textContentType(.name)
                    
                    TextField("Teléfono", text: $telefonoSolicita)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    TextField("Correo", text: $correoSolicita)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                    
                    Picker("Tipo de Documento", selection: $tipDocSolicita) {
                        Text("DUI").tag("13")
                        Text("NIT").tag("36")
                    }
                    
                    TextField("Número de Documento", text: $numDocSolicita)
                        .keyboardType(.namePhonePad)
                    
                    
                }
                Section(header: Text("Establecimiento")){
                    TextField("Nombre del Establecimiento",text: $nomEstablecimiento)
                        .multilineTextAlignment(.leading)
                }
                
                
                
                Section {
                    Button(action: {
                        showConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Invalidar Documento")
                                .bold()
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding()
                    .confirmationDialog(
                        "¿Está seguro que desea Invalidar este documento?",
                        isPresented: $showConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Invalidar", role: .destructive) {
                            submitDeactivation()
                        }
                        Button("Cancelar", role: .cancel) {}
                    }
                }
            }
            .navigationTitle("Invalidar Documento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                    .frame(width: 50, height: 50)
                                
                                Circle()
                                    .trim(from: 0, to: 0.7)
                                    .stroke(Color.darkCyan, lineWidth: 4)
                                    .frame(width: 50, height: 50)
                                    .rotationEffect(.degrees(isSubmitting ? 360 : 0))
                                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSubmitting)
                            }
                            
                            Text("Procesando Invalidación...")
                                .font(.headline)
                                .foregroundColor(.gray)
                                
                        }
                        .padding(25)
                        .background(Color(.systemBackground).opacity(0.85))
                        .cornerRadius(15)
                        .shadow(radius: 10)
                    }
                    .transition(.opacity)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("¡Documento anulado con éxito!", isPresented: $showSuccessMessage) {
                Button("Aceptar") {
                    dismiss()
                }
            } message: {
                Text("El documento ha sido anulado correctamente.")
            }
        }
    }
    
   
    private func submitDeactivation()  {
        isSubmitting = true
        
        Task{
            let envCode =  invoiceService.getEnvironmetCode(company.isProduction)
            
            let motivo = Motivo(tipoAnulacion: 2,
                                motivoAnulacion: motivoAnulacion,
                                nombreResponsable: nombreSolicita,
                                tipDocResponsable: tipDocResponsable,
                                numDocResponsable: numDocSolicita,
                                nombreSolicita: nombreSolicita,
                                tipDocSolicita: tipDocSolicita, // DUI
                                numDocSolicita: numDocSolicita)
            
        
            do{
                let dte = try MhClient.mapInvalidationModel(invoice: invoice,
                                                            company: company,
                                                            motivo:motivo,
                                                            nombreEstablecimiento: nomEstablecimiento,
                                                            environmentCode: envCode)
                
          
                let credentials = ServiceCredentials(user: company.nit,
                                                     credential: company.credentials,
                                                     key: company.certificatePassword,
                                                     invoiceNumber: invoice.invoiceNumber)
                let result  = try await invoiceService.invalidateDocumentAsync(dte: dte,
                                                                                credentials: credentials,
                                                                                isProduction: company.isProduction)
                
                if(result){
                    invoice.status = .Cancelada
                    invoice.invalidatedViaApi = true 
                    try? modelContext.save()
                    showSuccessMessage = true
                }
                
                isSubmitting = false 
                 
            }
            catch(let e){
                print("Error al desactivar la factura: \(e)")
                showError = true
                errorMessage = e.localizedDescription
                isSubmitting = false
            }
        }
    }
    
}

#Preview(traits: .sampleInvoices) {
    @Previewable @Query var invoices: [Invoice]
    
    DeactivateDocumentView(invoice: invoices.first!,company: Company.prewiewCompanies.first!)
}

