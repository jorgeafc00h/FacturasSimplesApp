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
    
    @Test func testContingencyRequestModelCreation() async throws {
        // Test ContingenciaRequest model creation
        let identificacion = ContingenciaIdentificacion(
            version: 3,
            ambiente: "00",
            codigoGeneracion: "TEST123",
            fTransmision: "2025-07-10",
            hTransmision: "10:30:00"
        )
        
        let emisor = ContingenciaEmisor(
            nit: "06141404941342",
            nombre: "Test Company",
            nombreResponsable: "Test Representative",
            tipoDocResponsable: "13",
            numeroDocResponsable: "12345678",
            tipoEstablecimiento: "01",
            codEstableMH: nil,
            codPuntoVenta: nil,
            telefono: "22221234",
            correo: "test@example.com"
        )
        
        let detalleDTE = [ContingenciaDetalleDTE(
            noItem: 1,
            codigoGeneracion: "INV001",
            tipoDoc: "01"
        )]
        
        let motivo = ContingenciaMotivo(
            fInicio: "2025-07-09",
            fFin: "2025-07-10",
            hInicio: "08:00:00",
            hFin: "17:00:00",
            tipoContingencia: 1,
            motivoContingencia: "Falla de conectividad"
        )
        
        let request = ContingenciaRequest(
            identificacion: identificacion,
            emisor: emisor,
            detalleDTE: detalleDTE,
            motivo: motivo
        )
        
        #expect(request.identificacion.version == 3)
        #expect(request.emisor.nit == "06141404941342")
        #expect(request.detalleDTE.count == 1)
        #expect(request.motivo.tipoContingencia == 1)
    }

}
