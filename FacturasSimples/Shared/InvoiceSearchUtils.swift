//
//  InvoiceSearchUtils.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 06/03/25.
//

import Foundation
import SwiftData

/// Utility class for creating optimized search predicates for Invoice queries
class InvoiceSearchUtils {
    
    /// Create a predicate based on search scope and text
    static func getSearchPredicate(scope: InvoiceSearchScope, searchText: String, companyId: String) -> Predicate<Invoice> {
        if searchText.isEmpty {
            return getEmptyScopePredicate(scope: scope, companyId: companyId)
        }
        
        if searchText.contains(" ") {
            let components = searchText.split(separator: " ")
            let key1 = String(components.first ?? "")
            let key2 = String(components.last ?? "")
            return getSearchPredicateWithMultipleKeywords(scope: scope, key1: key1, key2: key2, companyId: companyId)
        }
        
        return getSingleKeywordPredicate(scope: scope, searchText: searchText, companyId: companyId)
    }
    
    /// Create a predicate with multiple keywords
    static func getSearchPredicateWithMultipleKeywords(scope: InvoiceSearchScope, key1: String, key2: String, companyId: String) -> Predicate<Invoice> {
        switch scope {
        case .nombre:
            return #Predicate<Invoice> {
                ($0.customer?.firstName.localizedStandardContains(key1) == true &&
                 $0.customer?.lastName.localizedStandardContains(key2) == true) &&
                $0.customer?.companyOwnerId == companyId
            }
        case .nit:
            return #Predicate<Invoice> {
                $0.customer?.nit.contains(key1) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .dui:
            return #Predicate<Invoice> {
                $0.customer?.nationalId.contains(key1) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .nrc:
            return #Predicate<Invoice> {
                $0.customer?.nrc.contains(key1) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .factura:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.Factura)
            return #Predicate<Invoice> {
                $0.documentType == _type &&
                $0.customer?.companyOwnerId == companyId &&
                $0.invoiceNumber.contains(key1)
            }
        case .ccf:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.CCF)
            return #Predicate<Invoice> {
                $0.documentType == _type &&
                $0.customer?.companyOwnerId == companyId &&
                $0.invoiceNumber.contains(key1)
            }
        }
    }
    
    /// Create an optimized predicate for search suggestions based on scope and partial text
    static func getSuggestionsSearchPredicate(scope: InvoiceSearchScope, searchText: String, companyId: String) -> Predicate<Invoice> {
        let searchLower = searchText.lowercased()
        
        switch scope {
        case .nombre:
            return #Predicate<Invoice> {
                ($0.customer?.firstName.localizedStandardContains(searchText) == true ||
                 $0.customer?.lastName.localizedStandardContains(searchText) == true) &&
                $0.customer?.companyOwnerId == companyId
            }
        case .nit:
            return #Predicate<Invoice> {
                $0.customer?.nit.contains(searchText) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .dui:
            return #Predicate<Invoice> {
                $0.customer?.nationalId.contains(searchText) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .nrc:
            return #Predicate<Invoice> {
                $0.customer?.nrc.localizedStandardContains(searchText) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .factura:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.Factura)
            return #Predicate<Invoice> {
                $0.documentType == _type &&
                $0.customer?.companyOwnerId == companyId &&
                ($0.invoiceNumber.contains(searchText) || 
                 ($0.controlNumber != nil && $0.controlNumber!.contains(searchText)))
            }
        case .ccf:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.CCF)
            return #Predicate<Invoice> {
                $0.documentType == _type &&
                $0.customer?.companyOwnerId == companyId &&
                ($0.invoiceNumber.contains(searchText) || 
                 ($0.controlNumber != nil && $0.controlNumber!.contains(searchText)))
            }
        }
    }
    
    /// Create a predicate for recent items based on scope
    static func getRecentItemsPredicate(scope: InvoiceSearchScope, companyId: String) -> Predicate<Invoice> {
        switch scope {
        case .factura:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.Factura)
            return #Predicate<Invoice> {
                $0.customer?.companyOwnerId == companyId &&
                $0.documentType == _type
            }
        case .ccf:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.CCF)
            return #Predicate<Invoice> {
                $0.customer?.companyOwnerId == companyId &&
                $0.documentType == _type
            }
        default:
            return #Predicate<Invoice> {
                $0.customer?.companyOwnerId == companyId
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private static func getEmptyScopePredicate(scope: InvoiceSearchScope, companyId: String) -> Predicate<Invoice> {
        switch scope {
        case .factura:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.Factura)
            return #Predicate<Invoice> {
                $0.customer?.companyOwnerId == companyId &&
                $0.documentType == _type
            }
        case .ccf:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.CCF)
            return #Predicate<Invoice> {
                $0.customer?.companyOwnerId == companyId &&
                $0.documentType == _type
            }
        default:
            return #Predicate<Invoice> {
                $0.customer?.companyOwnerId == companyId
            }
        }
    }
    
    private static func getSingleKeywordPredicate(scope: InvoiceSearchScope, searchText: String, companyId: String) -> Predicate<Invoice> {
        switch scope {
        case .nombre:
            return #Predicate<Invoice> {
                ($0.customer?.firstName.localizedStandardContains(searchText) == true ||
                 $0.customer?.lastName.localizedStandardContains(searchText) == true) &&
                $0.customer?.companyOwnerId == companyId
            }
        case .nit:
            return #Predicate<Invoice> {
                $0.customer?.nit.contains(searchText) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .dui:
            return #Predicate<Invoice> {
                $0.customer?.nationalId.contains(searchText) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .nrc:
            return #Predicate<Invoice> {
                $0.customer?.nrc.localizedStandardContains(searchText) == true &&
                $0.customer?.companyOwnerId == companyId
            }
        case .factura:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.Factura)
            return #Predicate<Invoice> {
                $0.documentType == _type &&
                $0.customer?.companyOwnerId == companyId &&
                $0.invoiceNumber.contains(searchText)
            }
        case .ccf:
            let _type = Extensions.documentTypeFromInvoiceType(InvoiceType.CCF)
            return #Predicate<Invoice> {
                $0.documentType == _type &&
                $0.customer?.companyOwnerId == companyId &&
                $0.invoiceNumber.contains(searchText)
            }
        }
    }
}
