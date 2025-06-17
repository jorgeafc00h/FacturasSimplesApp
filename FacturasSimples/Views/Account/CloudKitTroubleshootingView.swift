//
//  CloudKitTroubleshootingView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI
import SwiftData

struct CloudKitTroubleshootingView: View {
    @State private var diagnosticResult: CloudKitSyncManager.CloudKitDiagnosticResult?
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Quick Fixes") {
                    Button("Run Full Diagnostic") {
                        runDiagnostic()
                    }
                    .disabled(isLoading)
                    
                    if let result = diagnosticResult, result.productionCompanies == 0 && result.testCompanies > 0 {
                        Button("Convert Test Company to Production") {
                            convertFirstTestCompany()
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Button("Force CloudKit Sync") {
                        forceSync()
                    }
                    .disabled(isLoading)
                }
                
                if let result = diagnosticResult {
                    Section("Diagnostic Results") {
                        HStack {
                            Text("CloudKit Account")
                            Spacer()
                            Text(result.accountAvailable ? "Available" : "Not Available")
                                .foregroundColor(result.accountAvailable ? .green : .red)
                        }
                        
                        if let error = result.accountError {
                            Text("Account Error: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Total Companies")
                            Spacer()
                            Text("\(result.totalLocalCompanies)")
                        }
                        
                        HStack {
                            Text("Production Companies")
                            Spacer()
                            Text("\(result.productionCompanies)")
                                .foregroundColor(result.productionCompanies > 0 ? .green : .red)
                        }
                        
                        HStack {
                            Text("Test Companies")
                            Spacer()
                            Text("\(result.testCompanies)")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if !result.localCompanies.isEmpty {
                        Section("Companies Found") {
                            ForEach(result.localCompanies, id: \.id) { company in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(company.name)
                                            .font(.headline)
                                        Spacer()
                                        Text(company.isTest ? "Test" : "Production")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(company.isTest ? Color.blue : Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                    
                                    Text("ID: \(company.id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    let companyCustomers = result.localCustomers.filter { $0.companyId == company.id }
                                    Text("\(companyCustomers.count) customers")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    if let error = result.diagnosticError {
                        Section("Errors") {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Recommended Actions") {
                    if let result = diagnosticResult {
                        if result.productionCompanies == 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("⚠️ No Production Companies Found")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Text("This explains why data isn't syncing. Production companies sync via CloudKit, but test companies stay local.")
                                    .font(.caption)
                                
                                if result.testCompanies > 0 {
                                    Text("• Convert a test company to production")
                                    Text("• Create a new production company")
                                    Text("• Check if production company exists on other device")
                                } else {
                                    Text("• Create a new production company")
                                    Text("• Ensure other device has a production company")
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("✅ Production Companies Found")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Text("Your setup looks correct for CloudKit sync.")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("CloudKit Troubleshooting")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                runDiagnostic()
            }
            .alert("Result", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView("Running diagnostic...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
            }
        }
    }
    
    private func runDiagnostic() {
        isLoading = true
        Task {
            let result = await CloudKitSyncManager.shared.performCloudKitDiagnostic()
            await MainActor.run {
                diagnosticResult = result
                isLoading = false
            }
        }
    }
    
    private func convertFirstTestCompany() {
        guard let result = diagnosticResult,
              let firstTestCompany = result.localCompanies.first(where: { $0.isTest }) else {
            return
        }
        
        isLoading = true
        Task {
            do {
                try await CloudKitSyncManager.shared.convertTestCompanyToProduction(companyId: firstTestCompany.id)
                await MainActor.run {
                    alertMessage = "Successfully converted '\(firstTestCompany.name)' to production company. This data will now sync via CloudKit."
                    showingAlert = true
                    isLoading = false
                }
                // Re-run diagnostic to show updated state
                runDiagnostic()
            } catch {
                await MainActor.run {
                    alertMessage = "Error converting company: \(error.localizedDescription)"
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func forceSync() {
        isLoading = true
        Task {
            await CloudKitSyncManager.shared.forceSyncRefresh()
            await MainActor.run {
                alertMessage = "Force sync completed. Check the diagnostic results."
                showingAlert = true
                isLoading = false
            }
            // Re-run diagnostic after sync
            runDiagnostic()
        }
    }
}

#Preview {
    CloudKitTroubleshootingView()
}
