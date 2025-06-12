//
//  CloudKitSettingsView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/10/25.
//

import SwiftUI
import CloudKit

struct CloudKitSettingsView: View {
    @EnvironmentObject private var companyStorageManager: CompanyStorageManager
    @State private var accountStatus: CKAccountStatus = .couldNotDetermine
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var lastSyncDate: Date?
    @State private var productionCompaniesCount = 0
    @State private var testCompaniesCount = 0
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: cloudKitIcon)
                        .foregroundColor(cloudKitColor)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Sincronización iCloud")
                            .font(.headline)
                        Text(cloudKitStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.vertical, 4)
                
                // Company sync status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.blue)
                        Text("Empresas de Producción")
                        Spacer()
                        Text("\(productionCompaniesCount)")
                            .foregroundColor(.secondary)
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "testtube.2")
                            .foregroundColor(.orange)
                        Text("Empresas de Prueba")
                        Spacer()
                        Text("\(testCompaniesCount)")
                            .foregroundColor(.secondary)
                        Image(systemName: "internaldrive")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
                
                if accountStatus == .available {
                    if let lastSync = lastSyncDate {
                        HStack {
                            Text("Última Sincronización")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Sincronizar Ahora") {
                        triggerManualSync()
                    }
                    .disabled(isLoading || productionCompaniesCount == 0)
                }
                
            } header: {
                Text("Estado de Sincronización")
            } footer: {
                Text(cloudKitFooterText)
            }
            
            if accountStatus != .available {
                Section {
                    Button("Ir a Configuración") {
                        openCloudKitSettings()
                    }
                } footer: {
                    Text("Habilita iCloud para esta aplicación en Configuración para sincronizar tus datos entre dispositivos.")
                }
            }
        }
        .navigationTitle("Sincronización iCloud")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkCloudKitStatus()
            loadCompanyCounts()
        }
        .refreshable {
            await refreshCloudKitStatus()
        }
        .alert("Error de CloudKit", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var cloudKitIcon: String {
        switch accountStatus {
        case .available:
            return "icloud.fill"
        case .noAccount:
            return "icloud.slash"
        case .restricted:
            return "icloud.slash.fill"
        case .temporarilyUnavailable:
            return "icloud.and.arrow.down"
        case .couldNotDetermine:
            return "icloud.circle"
        @unknown default:
            return "icloud.circle"
        }
    }
    
    private var cloudKitColor: Color {
        switch accountStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .red
        case .temporarilyUnavailable:
            return .orange
        case .couldNotDetermine:
            return .gray
        @unknown default:
            return .gray
        }
    }
    
    private var cloudKitStatusText: String {
        switch accountStatus {
        case .available:
            return "Activo - Tus datos se sincronizan entre dispositivos"
        case .noAccount:
            return "No hay cuenta de iCloud configurada"
        case .restricted:
            return "El acceso a iCloud está restringido"
        case .temporarilyUnavailable:
            return "Temporalmente no disponible"
        case .couldNotDetermine:
            return "Verificando estado..."
        @unknown default:
            return "Estado desconocido"
        }
    }
    
    private var cloudKitFooterText: String {
        switch accountStatus {
        case .available:
            return "Solo las empresas de producción (no de prueba) se sincronizan con iCloud. Las empresas de prueba permanecen almacenadas localmente en este dispositivo. Tienes \(productionCompaniesCount) empresas de producción sincronizándose con iCloud y \(testCompaniesCount) empresas de prueba almacenadas localmente."
        case .noAccount:
            return "Inicia sesión en iCloud en Configuración para habilitar la sincronización automática de empresas de producción entre tus dispositivos."
        case .restricted:
            return "El acceso a iCloud está restringido. Verifica Tiempo en Pantalla o controles parentales."
        case .temporarilyUnavailable:
            return "iCloud está temporalmente no disponible. Los datos de empresas de producción se sincronizarán cuando el servicio se restaure."
        case .couldNotDetermine:
            return "No se puede determinar el estado de iCloud. Verifica tu conexión a internet."
        @unknown default:
            return "Verifica tu configuración de iCloud y conexión a internet."
        }
    }
    
    private func checkCloudKitStatus() {
        isLoading = true
        Task {
            let (isAvailable, error) = await CloudKitConfiguration.shared.checkAccountStatus()
            
            await MainActor.run {
                isLoading = false
                
                if let error = error {
                    if let cloudKitError = error as? CloudKitError {
                        switch cloudKitError {
                        case .noAccount:
                            accountStatus = .noAccount
                        case .restricted:
                            accountStatus = .restricted
                        case .temporarilyUnavailable:
                            accountStatus = .temporarilyUnavailable
                        case .couldNotDetermine, .unknown:
                            accountStatus = .couldNotDetermine
                        }
                    } else {
                        errorMessage = error.localizedDescription
                        showingError = true
                        accountStatus = .couldNotDetermine
                    }
                } else {
                    accountStatus = isAvailable ? .available : .noAccount
                    if isAvailable {
                        lastSyncDate = Date()
                    }
                }
            }
        }
    }
    
    private func refreshCloudKitStatus() async {
        await checkCloudKitStatus()
    }
    
    private func triggerManualSync() {
        isLoading = true
        Task {
            await CloudKitConfiguration.shared.triggerManualSync()
            await MainActor.run {
                lastSyncDate = Date()
                isLoading = false
            }
        }
    }
    
    private func openCloudKitSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func loadCompanyCounts() {
        Task {
            do {
                let allCompanies = try companyStorageManager.getAllCompanies()
                
                await MainActor.run {
                    productionCompaniesCount = allCompanies.filter { !$0.isTestAccount }.count
                    testCompaniesCount = allCompanies.filter { $0.isTestAccount }.count
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al cargar el conteo de empresas: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CloudKitSettingsView()
    }
}
