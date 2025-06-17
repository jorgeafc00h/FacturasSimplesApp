//
//  SyncDiagnosticTool.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/16/25.
//

import SwiftUI
import SwiftData
import CloudKit

struct SyncDiagnosticTool: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager = CloudKitSyncManager.shared
    @State private var diagnosticResults: [DiagnosticResult] = []
    @State private var isRunning = false
    @State private var showDetails = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Quick Diagnostic") {
                    Button {
                        Task {
                            await runComprehensiveDiagnostic()
                        }
                    } label: {
                        HStack {
                            if isRunning {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Running diagnostic...")
                            } else {
                                Image(systemName: "stethoscope")
                                Text("Run Full Sync Diagnostic")
                            }
                        }
                    }
                    .disabled(isRunning)
                }
                
                if !diagnosticResults.isEmpty {
                    Section("Diagnostic Results") {
                        ForEach(diagnosticResults, id: \.id) { result in
                            DiagnosticResultRow(result: result)
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Force CloudKit Refresh") {
                        Task {
                            await syncManager.forceSyncRefresh()
                        }
                    }
                    
                    Button("Update Customer Sync Status") {
                        DataSyncFilterManager.shared.updateAllDataSyncStatus(context: modelContext)
                    }
                    
                    Button("Clean Orphaned Data") {
                        let result = DataSyncFilterManager.shared.cleanupOrphanedData(context: modelContext)
                        print("Cleaned up \(result.customersRemoved) orphaned customers")
                    }
                    
                    NavigationLink("Advanced CloudKit Tools") {
                        CloudKitDiagnosticView()
                    }
                }
            }
            .navigationTitle("Sync Diagnostic")
            .refreshable {
                await runComprehensiveDiagnostic()
            }
        }
    }
    
    @MainActor
    private func runComprehensiveDiagnostic() async {
        isRunning = true
        diagnosticResults.removeAll()
        
        // 1. Check CloudKit account status
        await checkCloudKitAccount()
        
        // 2. Check local data state
        checkLocalData()
        
        // 3. Check sync configuration
        checkSyncConfiguration()
        
        // 4. Check for common issues
        await checkCommonIssues()
        
        isRunning = false
    }
    
    private func checkCloudKitAccount() async {
        let (isAvailable, error) = await CloudKitConfiguration.shared.checkAccountStatus()
        
        if isAvailable {
            diagnosticResults.append(DiagnosticResult(
                title: "CloudKit Account",
                status: .success,
                message: "✅ CloudKit account is available and ready",
                details: "iCloud account is properly configured"
            ))
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "CloudKit Account",
                status: .error,
                message: "❌ CloudKit account issue",
                details: error?.localizedDescription ?? "Unknown CloudKit error"
            ))
        }
    }
    
    private func checkLocalData() {
        do {
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            let productionCompanies = allCompanies.filter { !$0.isTestAccount }
            let testCompanies = allCompanies.filter { $0.isTestAccount }
            
            let allCustomers = try modelContext.fetch(FetchDescriptor<Customer>())
            let syncEnabledCustomers = allCustomers.filter { $0.shouldSyncToCloudKit }
            
            diagnosticResults.append(DiagnosticResult(
                title: "Local Data Count",
                status: .info,
                message: "📊 Data inventory complete",
                details: """
                Companies: \(allCompanies.count) total
                - Production: \(productionCompanies.count)
                - Test: \(testCompanies.count)
                
                Customers: \(allCustomers.count) total
                - Sync enabled: \(syncEnabledCustomers.count)
                - Local only: \(allCustomers.count - syncEnabledCustomers.count)
                """
            ))
            
            // Check for data integrity issues
            let productionCompanyIds = Set(productionCompanies.map { $0.id })
            let orphanedCustomers = allCustomers.filter { customer in
                !customer.companyOwnerId.isEmpty && !productionCompanyIds.contains(customer.companyOwnerId)
            }
            
            if !orphanedCustomers.isEmpty {
                diagnosticResults.append(DiagnosticResult(
                    title: "Data Integrity",
                    status: .warning,
                    message: "⚠️ Found orphaned customer data",
                    details: "\(orphanedCustomers.count) customers belong to non-existent companies"
                ))
            } else {
                diagnosticResults.append(DiagnosticResult(
                    title: "Data Integrity",
                    status: .success,
                    message: "✅ Data integrity is good",
                    details: "No orphaned records found"
                ))
            }
            
        } catch {
            diagnosticResults.append(DiagnosticResult(
                title: "Local Data Check",
                status: .error,
                message: "❌ Failed to fetch local data",
                details: error.localizedDescription
            ))
        }
    }
    
    private func checkSyncConfiguration() {
        // Check if DataModel is properly configured
        let modelContainer = DataModel.shared.modelContainer
        let configurations = modelContainer.configurations
        
        let hasCloudKitConfig = configurations.contains { config in
            config.cloudKitDatabase != nil
        }
        
        if hasCloudKitConfig {
            diagnosticResults.append(DiagnosticResult(
                title: "CloudKit Configuration",
                status: .success,
                message: "✅ CloudKit is properly configured",
                details: "ModelContainer has CloudKit configuration"
            ))
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "CloudKit Configuration",
                status: .error,
                message: "❌ CloudKit configuration missing",
                details: "ModelContainer does not have CloudKit database configuration"
            ))
        }
        
        // Check container identifier
        let containerIdentifier = "iCloud.kandangalabs.facturassimples"
        diagnosticResults.append(DiagnosticResult(
            title: "Container Identifier",
            status: .info,
            message: "📱 Using container: \(containerIdentifier)",
            details: "Make sure this matches your app's CloudKit container"
        ))
    }
    
    private func checkCommonIssues() async {
        var issues: [String] = []
        
        // Check 1: Are production companies properly marked?
        do {
            let allCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            let hasProductionCompanies = allCompanies.contains { !$0.isTestAccount }
            
            if !hasProductionCompanies {
                issues.append("No production companies found - only test companies exist")
            }
            
            // Check 2: Are customers properly linked to companies?
            let allCustomers = try modelContext.fetch(FetchDescriptor<Customer>())
            let customersWithoutCompany = allCustomers.filter { $0.companyOwnerId.isEmpty }
            
            if !customersWithoutCompany.isEmpty {
                issues.append("\(customersWithoutCompany.count) customers have no company owner ID")
            }
            
            // Check 3: Are customers marked for sync correctly?
            let productionCompanyIds = Set(allCompanies.filter { !$0.isTestAccount }.map { $0.id })
            let incorrectlySyncedCustomers = allCustomers.filter { customer in
                let shouldSync = productionCompanyIds.contains(customer.companyOwnerId)
                return customer.shouldSyncToCloudKit != shouldSync
            }
            
            if !incorrectlySyncedCustomers.isEmpty {
                issues.append("\(incorrectlySyncedCustomers.count) customers have incorrect sync status")
            }
            
        } catch {
            issues.append("Failed to check for common issues: \(error.localizedDescription)")
        }
        
        if issues.isEmpty {
            diagnosticResults.append(DiagnosticResult(
                title: "Common Issues Check",
                status: .success,
                message: "✅ No common sync issues detected",
                details: "All basic sync requirements are met"
            ))
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "Common Issues Check",
                status: .warning,
                message: "⚠️ Found \(issues.count) potential issues",
                details: issues.joined(separator: "\n• ")
            ))
        }
    }
}

struct DiagnosticResult {
    let id = UUID()
    let title: String
    let status: DiagnosticStatus
    let message: String
    let details: String
}

enum DiagnosticStatus {
    case success, warning, error, info
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct DiagnosticResultRow: View {
    let result: DiagnosticResult
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.status.icon)
                    .foregroundColor(result.status.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.headline)
                    Text(result.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if showDetails {
                Text(result.details)
                    .font(.caption)
                    .padding(.leading, 24)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SyncDiagnosticTool()
}
