import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@Observable
class LogoEditorViewModel {
    var isFileImporterPresented = false
    var showAlertMessage = false
    var message = ""
    var isDirty = false
    
    var alertTitle: String {
        isDirty ? "Cambios pendientes" : "Confirmación"
    }
    
    func markDirty() {
        isDirty = true
    }
    
    func reset() {
        isDirty = false
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
                Button("Seleccione una imagen") {
                    viewModel.isFileImporterPresented = true
                }
                .foregroundColor(.darkCyan)
                .padding(.vertical, 20)
                
                if !company.invoiceLogo.isEmpty {
                    if let data = Data(base64Encoded: company.invoiceLogo),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 1.0)
                    }
                }
            }
            .listRowBackground(Color(uiColor: .systemBackground))
            
            Section("Dimensión Logo en pixeles") {
                HStack {
                    Label("Ancho Logo", systemImage: "arrow.left.and.right")
                    TextField("Ancho", value: $company.logoWidht, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: company.logoWidht) { viewModel.markDirty() }
                }
                
                HStack {
                    Label("Alto Logo", systemImage: "arrow.up.and.down")
                    TextField("Alto", value: $company.logoHeight, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: company.logoHeight) { viewModel.markDirty() }
                }
            }
            .listRowBackground(Color(uiColor: .systemBackground))
            .foregroundColor(.darkCyan)
            
            Section {
                Button(action: saveChanges) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Guardar Cambios")
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(.darkCyan)
                .cornerRadius(10)
                .disabled(!viewModel.isDirty)
            }
            .listRowBackground(Color(uiColor: .systemBackground))
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Editar Logo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    if viewModel.isDirty {
                        viewModel.message = "¿Está seguro que desea descartar los cambios?"
                        viewModel.showAlertMessage = true
                    } else {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    saveChanges()
                }
                .disabled(!viewModel.isDirty)
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlertMessage) {
            if viewModel.isDirty {
                Button("Descartar", role: .destructive) {
                    dismiss()
                }
                Button("Cancelar", role: .cancel) { }
            } else {
                Button("Ok", role: .cancel) { }
            }
        } message: {
            Text(viewModel.message)
        }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false,
            onCompletion: importImageLogo
        )
        .presentationDetents([.height(400), .large])
        .presentationDragIndicator(.visible)
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
                        viewModel.markDirty()
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