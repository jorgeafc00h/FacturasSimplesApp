//
//  DataIntegrityTestView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/16/25.
//

import SwiftUI
import SwiftData

struct DataIntegrityTestView: View {
    @Environment(\.modelContext) var modelContext
    @AppStorage("selectedCompanyIdentifier") var selectedCompanyId: String = ""
    
    @State private var diagnosticResults = ""
    @State private var isShowingResults = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Data Integrity Test")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Run Full Diagnostic") {
                runDiagnostic()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Test Customer Creation") {
                testCustomerCreation()
            }
            .buttonStyle(.bordered)
            
            if !diagnosticResults.isEmpty {
                ScrollView {
                    Text(diagnosticResults)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding()
        .navigationTitle("Data Integrity Debug")
    }
    
    private func runDiagnostic() {
        let debugger = DataIntegrityDebugger()
        diagnosticResults = debugger.getDiagnosticString()
    }
    
    private func testCustomerCreation() {
        diagnosticResults = ""
        
        // Check current selected company
        diagnosticResults += "=== TESTING CUSTOMER CREATION ===\n"
        diagnosticResults += "Selected Company ID: '\(selectedCompanyId)'\n"
        
        if selectedCompanyId.isEmpty {
            diagnosticResults += "❌ ERROR: No company selected!\n"
            return
        }
        
        // Check if the selected company exists
        do {
            let companies = try modelContext.fetch(FetchDescriptor<Company>())
            let validCompanyIds = Set(companies.map { $0.id })
            
            diagnosticResults += "All companies in database:\n"
            for company in companies {
                diagnosticResults += "  - \(company.nombre) (ID: \(company.id), Test: \(company.isTestAccount))\n"
            }
            
            if !validCompanyIds.contains(selectedCompanyId) {
                diagnosticResults += "❌ ERROR: Selected company ID '\(selectedCompanyId)' does not exist!\n"
                diagnosticResults += "Available company IDs: \(validCompanyIds)\n"
                return
            }
            
            // Find the actual company
            guard let selectedCompany = companies.first(where: { $0.id == selectedCompanyId }) else {
                diagnosticResults += "❌ ERROR: Could not find company with ID '\(selectedCompanyId)'\n"
                return
            }
            
            diagnosticResults += "✅ Selected company found: \(selectedCompany.nombre)\n"
            diagnosticResults += "   Is Test Account: \(selectedCompany.isTestAccount)\n"
            
            // Test customer creation exactly like AddCustomerView does
            diagnosticResults += "\n=== CREATING TEST CUSTOMER ===\n"
            
            let testCustomer = Customer(
                firstName: "Test",
                lastName: "Debug Customer",
                nationalId: "99999999",
                email: "test@debug.com",
                phone: "99999999",
                departamento: "Test Dept",
                municipio: "Test City",
                address: "123 Test St",
                company: "Test Company Inc"
            )
            
            // This is the critical line - exactly what AddCustomerView does
            testCustomer.companyOwnerId = selectedCompanyId
            diagnosticResults += "Set customer.companyOwnerId = '\(selectedCompanyId)'\n"
            
            // Set sync status exactly like AddCustomerView does
            let isProductionCompany = !selectedCompanyId.isEmpty && 
                                    DataSyncFilterManager.shared.getProductionCompanies(context: modelContext)
                                        .contains { $0.id == selectedCompanyId }
            testCustomer.shouldSyncToCloudKit = isProductionCompany
            
            diagnosticResults += "Customer sync status will be: \(testCustomer.shouldSyncToCloudKit)\n"
            diagnosticResults += "Is production company: \(isProductionCompany)\n"
            
            // Insert and save
            modelContext.insert(testCustomer)
            try modelContext.save()
            
            diagnosticResults += "✅ Test customer inserted and saved\n"
            
            // Now verify it's not orphaned by re-fetching data
            let updatedCompanies = try modelContext.fetch(FetchDescriptor<Company>())
            let updatedValidCompanyIds = Set(updatedCompanies.map { $0.id })
            let isOrphaned = !updatedValidCompanyIds.contains(testCustomer.companyOwnerId)
            
            diagnosticResults += "\n=== VERIFICATION ===\n"
            diagnosticResults += "Customer.companyOwnerId: '\(testCustomer.companyOwnerId)'\n"
            diagnosticResults += "Valid company IDs after save: \(updatedValidCompanyIds)\n"
            diagnosticResults += "Is orphaned: \(isOrphaned)\n"
            
            if isOrphaned {
                diagnosticResults += "❌ PROBLEM FOUND: Customer was created as orphaned!\n"
                
                // Additional debugging
                diagnosticResults += "\nDEBUG INFO:\n"
                diagnosticResults += "Original selectedCompanyId: '\(selectedCompanyId)'\n"
                diagnosticResults += "Customer.companyOwnerId: '\(testCustomer.companyOwnerId)'\n"
                diagnosticResults += "Are they equal? \(selectedCompanyId == testCustomer.companyOwnerId)\n"
                
                // Check if the company ID changed somehow
                if let originalCompany = companies.first(where: { $0.id == selectedCompanyId }) {
                    let refetchedCompany = updatedCompanies.first(where: { $0.nombre == originalCompany.nombre })
                    if let refetched = refetchedCompany {
                        diagnosticResults += "Original company ID: '\(selectedCompanyId)'\n"
                        diagnosticResults += "Refetched company ID: '\(refetched.id)'\n"
                        diagnosticResults += "Did company ID change? \(selectedCompanyId != refetched.id)\n"
                    }
                }
            } else {
                diagnosticResults += "✅ SUCCESS: Customer is properly linked!\n"
            }
            
            // Clean up by deleting the test customer
            modelContext.delete(testCustomer)
            try modelContext.save()
            diagnosticResults += "\n✅ Test customer cleaned up\n"
            
        } catch {
            diagnosticResults += "❌ ERROR: \(error.localizedDescription)\n"
        }
    }
}

#Preview {
    DataIntegrityTestView()
}
