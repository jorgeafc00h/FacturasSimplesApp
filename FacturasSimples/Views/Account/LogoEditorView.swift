import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@Observable
class LogoEditorViewModel {
    var isFileImporterPresented = false
    var showAlertMessage = false
    var message = ""
    
    var alertTitle: String {
        "Confirmación"
    }
    
    func reset() {
        message = ""
        showAlertMessage = false
    }
}

struct LogoEditorView: View {
    @Bindable var company: Company
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LogoEditorViewModel()
    
    var body: some View {
        Form {
            Section("Logo Facturas") {
                VStack(spacing: 16) {
                    Button("Seleccionar Imagen") {
                        viewModel.isFileImporterPresented = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    if !company.invoiceLogo.isEmpty {
                        if let data = Data(base64Encoded: company.invoiceLogo),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .frame(height: 120)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                    Text("Sin logo seleccionado")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Dimensiones del Logo") {
                HStack {
                    Label("Ancho", systemImage: "arrow.left.and.right")
                    Spacer()
                    TextField("Ancho", value: $company.logoWidht, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                
                HStack {
                    Label("Alto", systemImage: "arrow.up.and.down")
                    Spacer()
                    TextField("Alto", value: $company.logoHeight, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            
            Section {
                Button(action: saveChanges) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Guardar Cambios")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .navigationTitle("Editar Logo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    saveChanges()
                }
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlertMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.message)
        }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false,
            onCompletion: importImageLogo
        )
        .onDisappear {
            viewModel.reset()
        }
    }
    
    private func importImageLogo(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                let access = url.startAccessingSecurityScopedResource()
                do {
                    if access {
                        let imageData = try Data(contentsOf: url)
                        company.invoiceLogo = imageData.base64EncodedString()
                        url.stopAccessingSecurityScopedResource()
                        try modelContext.save()
                        viewModel.message = "Logo actualizado correctamente"
                        viewModel.showAlertMessage = true
                    }
                } catch {
                    viewModel.message = "Error al cargar la imagen: \(error.localizedDescription)"
                    viewModel.showAlertMessage = true
                }
            }
        case .failure(let error):
            viewModel.message = "Error al seleccionar archivo: \(error.localizedDescription)"
            viewModel.showAlertMessage = true
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
            viewModel.message = "Los cambios se guardaron correctamente"
            viewModel.showAlertMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                viewModel.reset()
                dismiss()
            }
        } catch {
            viewModel.message = "Error al guardar los cambios: \(error.localizedDescription)"
            viewModel.showAlertMessage = true
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Company.self, configurations: config)
        let example = Company(nit: "123", nrc: "456", nombre: "Test Company")
        return NavigationStack {
            LogoEditorView(company: example)
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}