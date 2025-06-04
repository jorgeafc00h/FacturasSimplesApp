import Foundation
import SwiftData
import SwiftUI

extension InvoicesView{
    
    @Observable
    class InvoicesViewModel{
        var showAddInvoiceSheet: Bool = false
        var showAddCustomerSheet: Bool = false
        
        var showAddTestInvoices: Bool = false
         
    }
    // MARK: - Helper Methods
    
    func getColorForScope(_ scope: InvoiceSearchScope) -> Color {
        switch scope {
        case .nombre:
            return .blue
        case .nit:
            return .green
        case .dui:
            return .orange
        case .nrc:
            return .purple
        case .factura:
            return .teal
        case .ccf:
            return .pink
        }
    }
    
    func getIconForScope(_ scope: InvoiceSearchScope) -> String {
        switch scope {
        case .nombre:
            return "person.fill"
        case .nit:
            return "number.circle.fill"
        case .dui:
            return "doc.text.fill"
        case .nrc:
            return "building.2.fill"
        case .factura:
            return "doc.plaintext.fill"
        case .ccf:
            return "doc.badge.plus"
        }
    }
    
    func getRecentSuggestions() async -> [SearchSuggestion] {
        let companyId = selectedCompanyId.isEmpty ? companyIdentifier : selectedCompanyId
        
        let descriptor = FetchDescriptor<Invoice>(
            predicate: InvoiceSearchUtils.getRecentItemsPredicate(scope: searchScope, companyId: companyId),
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let recentInvoices = try modelContext.fetch(descriptor).prefix(15)
            var suggestions: [SearchSuggestion] = []
            
            switch searchScope {
            case .nombre:
                for invoice in recentInvoices {
                    let fullName = "\(invoice.customer.firstName) \(invoice.customer.lastName)".trimmingCharacters(in: .whitespaces)
                    if !fullName.isEmpty {
                        suggestions.append(SearchSuggestion(
                            text: fullName,
                            icon: "person.fill",
                            category: "Reciente",
                            secondaryText: "Cliente"
                        ))
                    }
                }
            case .nit:
                for invoice in recentInvoices {
                    if !invoice.customer.nit.isEmpty {
                        suggestions.append(SearchSuggestion(
                            text: invoice.customer.nit,
                            icon: "number.circle.fill",
                            category: "Reciente",
                            secondaryText: invoice.customer.firstName
                        ))
                    }
                }
            case .dui:
                for invoice in recentInvoices {
                    if !invoice.customer.nationalId.isEmpty {
                        suggestions.append(SearchSuggestion(
                            text: invoice.customer.nationalId,
                            icon: "doc.text.fill",
                            category: "Reciente",
                            secondaryText: invoice.customer.firstName
                        ))
                    }
                }
            case .nrc:
                for invoice in recentInvoices {
                    if !invoice.customer.nrc.isEmpty {
                        suggestions.append(SearchSuggestion(
                            text: invoice.customer.nrc,
                            icon: "building.2.fill",
                            category: "Reciente",
                            secondaryText: invoice.customer.company
                        ))
                    }
                }
            case .factura:
                for invoice in recentInvoices.filter({ $0.invoiceType == .Factura }) {
                    suggestions.append(SearchSuggestion(
                        text: invoice.invoiceNumber,
                        icon: "doc.plaintext.fill",
                        category: "Reciente",
                        secondaryText: "Factura - \(invoice.customer.firstName)"
                    ))
                }
            case .ccf:
                for invoice in recentInvoices.filter({ $0.invoiceType == .CCF }) {
                    suggestions.append(SearchSuggestion(
                        text: invoice.invoiceNumber,
                        icon: "doc.badge.plus",
                        category: "Reciente",
                        secondaryText: "CCF - \(invoice.customer.firstName)"
                    ))
                }
            }
            
            return Array(Set(suggestions.map(\.text))).prefix(15).map { text in
                suggestions.first { $0.text == text }!
            }.map { $0 }
            
        } catch {
            return []
        }
}
    
    func fetchSuggestionsFromData(searchText: String, scope: InvoiceSearchScope, companyId: String) async -> [SearchSuggestion] {
        // Use optimized predicate for better performance
        let descriptor = FetchDescriptor<Invoice>(
            predicate: InvoiceSearchUtils.getSuggestionsSearchPredicate(scope: scope, searchText: searchText, companyId: companyId),
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let invoices = try modelContext.fetch(descriptor).prefix(50) // Limit to 50 for performance
            var suggestions: [SearchSuggestion] = []
            
            // Process results based on scope for better suggestion generation
            switch scope {
            case .nombre:
                suggestions = generateNameSuggestions(from: Array(invoices), searchText: searchText)
            case .nit:
                suggestions = generateNITSuggestions(from: Array(invoices))
            case .dui:
                suggestions = generateDUISuggestions(from: Array(invoices))
            case .nrc:
                suggestions = generateNRCSuggestions(from: Array(invoices))
            case .factura:
                suggestions = generateFacturaSuggestions(from: Array(invoices))
            case .ccf:
                suggestions = generateCCFSuggestions(from: Array(invoices))
            }
            
            // Remove duplicates and limit to 8 suggestions
            let uniqueSuggestions = Array(Set(suggestions.map(\.text))).prefix(8).compactMap { text in
                suggestions.first { $0.text == text }
            }
            
            return uniqueSuggestions.sorted { $0.text < $1.text }
            
        } catch {
            return []
        }
    }
    
    // MARK: - Private Suggestion Generators
    
    private func generateNameSuggestions(from invoices: [Invoice], searchText: String) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        let searchLower = searchText.lowercased()
        
        for invoice in invoices {
            let firstName = invoice.customer.firstName
            let lastName = invoice.customer.lastName
            let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            
            if firstName.lowercased().contains(searchLower) && !firstName.isEmpty {
                suggestions.append(SearchSuggestion(
                    text: firstName,
                    icon: "person.fill",
                    category: "Nombre",
                    secondaryText: "Cliente"
                ))
            }
            
            if lastName.lowercased().contains(searchLower) && !lastName.isEmpty {
                suggestions.append(SearchSuggestion(
                    text: lastName,
                    icon: "person.fill",
                    category: "Apellido", 
                    secondaryText: "Cliente"
                ))
            }
            
            if fullName.lowercased().contains(searchLower) && !fullName.isEmpty && fullName != firstName && fullName != lastName {
                suggestions.append(SearchSuggestion(
                    text: fullName,
                    icon: "person.fill",
                    category: "Completo",
                    secondaryText: "Cliente"
                ))
            }
        }
        
        return suggestions
    }
    
    private func generateNITSuggestions(from invoices: [Invoice]) -> [SearchSuggestion] {
        return invoices.compactMap { invoice in
            let nit = invoice.customer.nit
            guard !nit.isEmpty else { return nil }
            return SearchSuggestion(
                text: nit,
                icon: "number.circle.fill",
                category: "NIT",
                secondaryText: invoice.customer.firstName
            )
        }
    }
    
    private func generateDUISuggestions(from invoices: [Invoice]) -> [SearchSuggestion] {
        return invoices.compactMap { invoice in
            let dui = invoice.customer.nationalId
            guard !dui.isEmpty else { return nil }
            return SearchSuggestion(
                text: dui,
                icon: "doc.text.fill",
                category: "DUI",
                secondaryText: invoice.customer.firstName
            )
        }
    }
    
    private func generateNRCSuggestions(from invoices: [Invoice]) -> [SearchSuggestion] {
        return invoices.compactMap { invoice in
            let nrc = invoice.customer.nrc
            guard !nrc.isEmpty else { return nil }
            return SearchSuggestion(
                text: nrc,
                icon: "building.2.fill",
                category: "NRC",
                secondaryText: invoice.customer.company.isEmpty ? invoice.customer.firstName : invoice.customer.company
            )
        }
    }
    
    private func generateFacturaSuggestions(from invoices: [Invoice]) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        for invoice in invoices {
            // Add invoice number suggestion
            suggestions.append(SearchSuggestion(
                text: invoice.invoiceNumber,
                icon: "doc.plaintext.fill",
                category: "Factura",
                secondaryText: "\(invoice.customer.firstName) - \(DateFormatter.shortDate.string(from: invoice.date))"
            ))
            
            // Add control number suggestion if available
            if let controlNumber = invoice.controlNumber, !controlNumber.isEmpty {
                suggestions.append(SearchSuggestion(
                    text: controlNumber,
                    icon: "doc.plaintext.fill",
                    category: "Control",
                    secondaryText: "Factura \(invoice.invoiceNumber)"
                ))
            }
        }
        
        return suggestions
    }
    
    private func generateCCFSuggestions(from invoices: [Invoice]) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        for invoice in invoices {
            // Add invoice number suggestion
            suggestions.append(SearchSuggestion(
                text: invoice.invoiceNumber,
                icon: "doc.badge.plus",
                category: "CCF",
                secondaryText: "\(invoice.customer.firstName) - \(DateFormatter.shortDate.string(from: invoice.date))"
            ))
            
            // Add control number suggestion if available
            if let controlNumber = invoice.controlNumber, !controlNumber.isEmpty {
                suggestions.append(SearchSuggestion(
                    text: controlNumber,
                    icon: "doc.badge.plus",
                    category: "Control",
                    secondaryText: "CCF \(invoice.invoiceNumber)"
                ))
            }
        }
        
        return suggestions
    }
   
}






