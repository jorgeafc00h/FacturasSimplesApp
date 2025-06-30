import SwiftUI
import SwiftData
import CloudKit

@MainActor
class DataSyncFilterManager {
    static let shared = DataSyncFilterManager()
    
    private init() {}
    
    // MARK: - Company Management
    
    /// Get all companies that should be visible in the UI
    func getVisibleCompanies(context: ModelContext) -> [Company] {
        let descriptor = FetchDescriptor<Company>()
        let allCompanies = (try? context.fetch(descriptor)) ?? []
        
        // Return all companies since we want to see all options
        return allCompanies
    }
    
    /// Get only production companies for business operations
    func getProductionCompanies(context: ModelContext) -> [Company] {
        let descriptor = FetchDescriptor<Company>(
            predicate: #Predicate { company in
                !company.isTestAccount
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Get test companies
    func getTestCompanies(context: ModelContext) -> [Company] {
        let descriptor = FetchDescriptor<Company>(
            predicate: #Predicate { company in
                company.isTestAccount
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Customer Management
    
    /// Get customers for a specific company
    func getCustomersForCompany(companyId: String, context: ModelContext) -> [Customer] {
        let descriptor = FetchDescriptor<Customer>(
            predicate: #Predicate { customer in
                customer.companyOwnerId == companyId
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Get only customers from production companies (for business operations)
    func getProductionCustomers(context: ModelContext) -> [Customer] {
        let productionCompanies = getProductionCompanies(context: context)
        let productionCompanyIds = Set(productionCompanies.map { $0.id })
        
        // Get all customers and filter in memory due to SwiftData predicate limitations
        let descriptor = FetchDescriptor<Customer>()
        let allCustomers = (try? context.fetch(descriptor)) ?? []
        
        return allCustomers.filter { customer in
            productionCompanyIds.contains(customer.companyOwnerId)
        }
    }
    
    // MARK: - Product Management
    
    /// Get products for a specific company
    func getProductsForCompany(companyId: String, context: ModelContext) -> [Product] {
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { product in
                product.companyId == companyId
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Get only products from production companies (for business operations)
    func getProductionProducts(context: ModelContext) -> [Product] {
        let productionCompanies = getProductionCompanies(context: context)
        let productionCompanyIds = Set(productionCompanies.map { $0.id })
        
        // Get all products and filter in memory due to SwiftData predicate limitations
        let descriptor = FetchDescriptor<Product>()
        let allProducts = (try? context.fetch(descriptor)) ?? []
        
        return allProducts.filter { product in
            productionCompanyIds.contains(product.companyId)
        }
    }
    
    // MARK: - Invoice Management
    
    /// Get invoices for a specific company
    func getInvoicesForCompany(companyId: String, context: ModelContext) -> [Invoice] {
        // Get all invoices and filter in memory due to SwiftData predicate limitations
        let descriptor = FetchDescriptor<Invoice>()
        let allInvoices = (try? context.fetch(descriptor)) ?? []
        
        return allInvoices.filter { invoice in
            invoice.customer?.companyOwnerId == companyId
        }
    }
    
    /// Get only invoices from production companies (for business operations)
    func getProductionInvoices(context: ModelContext) -> [Invoice] {
        let productionCompanies = getProductionCompanies(context: context)
        let productionCompanyIds = Set(productionCompanies.map { $0.id })
        
        // Get all invoices and filter in memory since SwiftData predicates need to be simple
        let descriptor = FetchDescriptor<Invoice>()
        let allInvoices = (try? context.fetch(descriptor)) ?? []
        
        return allInvoices.filter { invoice in
            if let customerId = invoice.customer?.companyOwnerId {
                return productionCompanyIds.contains(customerId)
            }
            return false
        }
    }
    
    // MARK: - Data Sync Management
    
    /// Mark customers as sync-enabled based on their company type
    func updateCustomerSyncStatus(context: ModelContext) {
        let allCustomers = try? context.fetch(FetchDescriptor<Customer>())
        let productionCompanies = getProductionCompanies(context: context)
        let productionCompanyIds = Set(productionCompanies.map { $0.id })
        
        allCustomers?.forEach { customer in
            customer.shouldSyncToCloudKit = productionCompanyIds.contains(customer.companyOwnerId)
        }
        
        try? context.save()
    }
    
    /// Mark products as sync-enabled based on their company type
    func updateProductSyncStatus(context: ModelContext) {
        let allProducts = try? context.fetch(FetchDescriptor<Product>())
        let productionCompanies = getProductionCompanies(context: context)
        let productionCompanyIds = Set(productionCompanies.map { $0.id })
        
        allProducts?.forEach { product in
            product.shouldSyncToCloudKit = productionCompanyIds.contains(product.companyId)
        }
        
        try? context.save()
    }
    
    /// Mark invoices as sync-enabled based on their company type
    func updateInvoiceSyncStatus(context: ModelContext) {
        let allInvoices = try? context.fetch(FetchDescriptor<Invoice>())
        let productionCompanies = getProductionCompanies(context: context)
        let productionCompanyIds = Set(productionCompanies.map { $0.id })
        
        allInvoices?.forEach { invoice in
            if let customerId = invoice.customer?.companyOwnerId {
                invoice.shouldSyncToCloudKit = productionCompanyIds.contains(customerId)
            } else {
                invoice.shouldSyncToCloudKit = false
            }
        }
        
        try? context.save()
    }
    
    /// Update sync status for all data types
    func updateAllDataSyncStatus(context: ModelContext) {
        updateCustomerSyncStatus(context: context)
        updateProductSyncStatus(context: context)
        updateInvoiceSyncStatus(context: context)
    }
    
    /// Clean up orphaned data (customers without valid companies)
    func cleanupOrphanedData(context: ModelContext) -> (customersRemoved: Int, productsRemoved: Int, invoicesRemoved: Int, error: String?) {
        do {
            let allCustomers = try context.fetch(FetchDescriptor<Customer>())
            let allProducts = try context.fetch(FetchDescriptor<Product>())
            let allInvoices = try context.fetch(FetchDescriptor<Invoice>())
            let allCompanies = try context.fetch(FetchDescriptor<Company>())
            let validCompanyIds = Set(allCompanies.map { $0.id })
            
            // Clean orphaned customers
            let orphanedCustomers = allCustomers.filter { customer in
                !validCompanyIds.contains(customer.companyOwnerId)
            }
            
            // Clean orphaned products
            let orphanedProducts = allProducts.filter { product in
                !validCompanyIds.contains(product.companyId)
            }
            
            // Clean orphaned invoices (customers with invalid company IDs)
            let orphanedInvoices = allInvoices.filter { invoice in
                if let customerId = invoice.customer?.companyOwnerId {
                    return !validCompanyIds.contains(customerId)
                }
                return true // invoices without customers are also orphaned
            }
            
            // Delete orphaned data
            orphanedCustomers.forEach { context.delete($0) }
            orphanedProducts.forEach { context.delete($0) }
            orphanedInvoices.forEach { context.delete($0) }
            
            try context.save()
            return (customersRemoved: orphanedCustomers.count, 
                   productsRemoved: orphanedProducts.count,
                   invoicesRemoved: orphanedInvoices.count, 
                   error: nil)
            
        } catch {
            return (customersRemoved: 0, productsRemoved: 0, invoicesRemoved: 0, error: error.localizedDescription)
        }
    }
    
    // MARK: - Onboarding Logic
    
    /// Check if app should show onboarding
    func shouldShowOnboarding(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Company>()
        let companyCount = (try? context.fetchCount(descriptor)) ?? 0
        
        // Debug logging
        print("🏢 shouldShowOnboarding: Found \(companyCount) companies")
        
        if companyCount > 0 {
            // Log details about existing companies
            let companies = (try? context.fetch(descriptor)) ?? []
            let productionCount = companies.filter { !$0.isTestAccount }.count
            let testCount = companies.filter { $0.isTestAccount }.count
            print("🏢 Company breakdown: \(productionCount) production, \(testCount) test")
        }
        
        // Skip onboarding if ANY companies exist (regardless of type)
        // This allows CloudKit sync to work properly
        let shouldShow = companyCount == 0
        print("🔄 shouldShowOnboarding result: \(shouldShow)")
        return shouldShow
    }
     
    /// Check if there are any production companies available
    func hasProductionCompanies(context: ModelContext) -> Bool {
        let productionCompanies = getProductionCompanies(context: context)
        return !productionCompanies.isEmpty
    }
    
    // MARK: - Current Company Management
    
    /// Get the current active company, preferring production companies
    func getCurrentActiveCompany(context: ModelContext, currentCompanyId: String?) -> Company? {
        // First, try to get the currently selected company
        if let currentId = currentCompanyId, !currentId.isEmpty {
            // Get all companies and filter in memory for better compatibility
            let descriptor = FetchDescriptor<Company>()
            let allCompanies = (try? context.fetch(descriptor)) ?? []
            
            if let currentCompany = allCompanies.first(where: { $0.id == currentId }) {
                return currentCompany
            }
        }
        
        // If no current company or it doesn't exist, prefer production companies
        let productionCompanies = getProductionCompanies(context: context)
        if !productionCompanies.isEmpty {
            return productionCompanies.first
        }
        
        // Fall back to any company if no production companies exist
        let allCompanies = try? context.fetch(FetchDescriptor<Company>())
        return allCompanies?.first
    }
    
    /// Set a production company as the current company
    func setProductionCompanyAsCurrent(context: ModelContext) -> Company? {
        let productionCompanies = getProductionCompanies(context: context)
        return productionCompanies.first
    }
}
