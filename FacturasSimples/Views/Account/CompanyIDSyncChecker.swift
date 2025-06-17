//
//  CompanyIDSyncChecker.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI
import SwiftData

struct CompanyIDSyncChecker: View {
    @Environment(\.modelContext) private var modelContext
    @State private var syncResults: [CompanyIdResult] = []
    @State private var isChecking = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Company ID Sync Check") {
                    Button("Check Company IDs") {
                        checkCompanyIds()
                    }
                    .disabled(isChecking)
                    
                    if isChecking {
                        HStack {
                            ProgressView()
                            Text("Checking...")
                        }
                    }
                }
                
                if !syncResults.isEmpty {
                    Section("Results") {
                        ForEach(syncResults, id: \.companyName) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(result.companyName)
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: result.isTestAccount ? "testtube.2" : "checkmark.seal")
                                        .foregroundColor(result.isTestAccount ? .orange : .green)
                                }
                                
                                Text("ID: \(result.companyId)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                                
                                Text("NIT: \(result.nit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Customers: \(result.customerCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if !result.sampleCustomers.isEmpty {
                                    Text("Sample Customers:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    ForEach(result.sampleCustomers, id: \.self) { customer in
                                        Text("• \(customer)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 8)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Company ID Check")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Copy All IDs") {
                        let allIds = syncResults.map { "\($0.companyName): \($0.companyId)" }.joined(separator: "\n")
                        UIPasteboard.general.string = allIds
                    }
                    .disabled(syncResults.isEmpty)
                }
            }
        }
    }
    
    private func checkCompanyIds() {
        isChecking = true
        syncResults = []
        
        do {
            let companies = try modelContext.fetch(FetchDescriptor<Company>())
            var results: [CompanyIdResult] = []
            
            for company in companies {
                // Get customers for this company
                let companyId = company.id
                let customerDescriptor = FetchDescriptor<Customer>(
                    predicate: #Predicate { $0.companyOwnerId == companyId }
                )
                let customers = try modelContext.fetch(customerDescriptor)
                
                let result = CompanyIdResult(
                    companyId: company.id,
                    companyName: company.nombre,
                    nit: company.nit,
                    isTestAccount: company.isTestAccount,
                    customerCount: customers.count,
                    sampleCustomers: customers.prefix(3).map { "\($0.firstName) \($0.lastName)" }
                )
                
                results.append(result)
            }
            
            syncResults = results.sorted { !$0.isTestAccount && $1.isTestAccount }
            
        } catch {
            print("Error checking company IDs: \(error)")
        }
        
        isChecking = false
    }
}

struct CompanyIdResult {
    let companyId: String
    let companyName: String
    let nit: String
    let isTestAccount: Bool
    let customerCount: Int
    let sampleCustomers: [String]
}

#Preview {
    CompanyIDSyncChecker()
}
