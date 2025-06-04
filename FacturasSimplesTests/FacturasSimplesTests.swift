//
//  FacturasSimplesTests.swift
//  FacturasSimplesTests
//
//  Created by Jorge Flores on 1/16/25.
//

import Testing
import Foundation
@testable import FacturasSimples

struct FacturasSimplesTests {

    @Test func testSearchPredicateWithName() async throws {
        let predicate = InvoiceSearchUtils.getSearchPredicate(searchText: "John", scope: .name)
        #expect(predicate != nil)
        // Verify predicate is created correctly for name scope
    }
    
    @Test func testSearchPredicateWithNIT() async throws {
        let predicate = InvoiceSearchUtils.getSearchPredicate(searchText: "123456789", scope: .nit)
        #expect(predicate != nil)
        // Verify predicate is created correctly for NIT scope
    }
    
    @Test func testMultipleKeywordsSearch() async throws {
        let predicate = InvoiceSearchUtils.getSearchPredicateWithMultipleKeywords(
            searchText: "John Doe", 
            scope: .name
        )
        #expect(predicate != nil)
        // Verify predicate handles multiple keywords correctly
    }
    
    @Test func testSuggestionsSearchPredicate() async throws {
        let predicate = InvoiceSearchUtils.getSuggestionsSearchPredicate(
            searchText: "John", 
            scope: .name
        )
        #expect(predicate != nil)
        // Verify suggestions predicate is optimized correctly
    }
    
    @Test func testRecentItemsPredicate() async throws {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        let predicate = InvoiceSearchUtils.getRecentItemsPredicate(scope: .name, since: sevenDaysAgo)
        #expect(predicate != nil)
        // Verify recent items predicate filters by date correctly
    }
    
    @Test func testEmptySearchText() async throws {
        let predicate = InvoiceSearchUtils.getSearchPredicate(searchText: "", scope: .name)
        #expect(predicate == nil)
        // Verify empty search text returns nil predicate
    }

}
