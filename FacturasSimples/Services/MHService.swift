import Foundation

class MhClient {
    
   
    
    static func mapInvoice(invoice: Invoice, company: Company, environmentCode: String)throws -> DTE_Base {
        var index = 1
        
        let items = invoice.items.map { detail -> CuerpoDocumento in
            var item = formatFromProductDetail(detail: detail, isCCF: invoice.isCCF)
            item.numItem = index
            index += 1
            return item
        }
        
        let emisor = mapEmisor(company)
        
        let resumen = mapResumen(invoice: invoice, items: items)
        
        let documentType = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
        let version =  (documentType as NSString).integerValue
        
        let identificacion = Identificacion(
            version: version,
            ambiente: environmentCode,
            tipoDte: documentType,
            numeroControl: invoice.controlNumber,
            codigoGeneracion: invoice.generationCode,
            tipoModelo: 1,
            tipoOperacion: 1,
            tipoContingencia: nil,
            motivoContin: nil,
            fecEmi: Date(),
            horEmi:try Extensions.generateHourString(date: Date()),
            tipoMoneda: "USD"
        )
        
        let dte = DTE_Base(
            identificacion: identificacion,
            emisor: emisor,
            receptor: try mapReceptor(invoice: invoice),
            cuerpoDocumento: items,
            resumen: resumen
        )
         
        return dte
    }
    
    private static func mapEmisor(_ company: Company) -> Emisor {
        let emisor = Emisor(
            nit: company.nit,
            nrc: company.nrc,
            nombre: company.nombre,
            codActividad: company.codActividad,
            descActividad: company.descActividad,
            nombreComercial: company.nombreComercial,
            tipoEstablecimiento: company.tipoEstablecimiento,
            direccion: Direccion(departamento: company.departamentoCode,
                                 municipio: company.municipioCode,
                                 complemento: company.complemento),
            telefono: Extensions.formatPhoneNumber(telefono: company.telefono),
            correo: company.correo,
            codEstableMH: company.codEstableMH != "" ?
            company.codEstableMH : nil ,
            codEstable: company.codEstable != "" ?
            company.codEstable : nil,
            codPuntoVentaMH: nil,
            codPuntoVenta: nil
        )
        
        return emisor
    }
    
    private static  func formatFromProductDetail(detail: InvoiceDetail, isCCF: Bool) -> CuerpoDocumento {
        
        let productTotal = (detail.quantity * detail.product.unitPrice).rounded()
        let tax = (productTotal - (productTotal / Decimal(1.13))).rounded()
        
        return CuerpoDocumento(
            ivaItem: isCCF ? nil : tax,
            cantidad: detail.quantity,
            numItem: 0,
            codigo: isCCF ? nil : "1", // ???
            codTributo: nil,
            descripcion: detail.product.productName,
            precioUni: isCCF ?
                        (detail.product.unitPrice / Decimal(1.13))
                        .rounded():
                        detail.product.unitPrice,
            ventaGravada: isCCF ? (productTotal - tax) : productTotal,
            psv: 0,
            noGravado: 0,
            montoDescu: 0,
            ventaNoSuj: 0,
            uniMedida: isCCF ? 59 : 99, // 59 unidad, 99 otro
            tributos: isCCF ? ["20"] : nil,
            ventaExenta: 0,
            tipoItem: 2, // 1 producto, 2 Servicios
            numeroDocumento: nil
        )
    }
    
    private static func mapReceptor(invoice: Invoice)throws -> Receptor {
        let customer = invoice.customer
        
        
        let nrc = invoice.isCCF ? customer.nrc : nil
        
        let receptor = Receptor(
            nrc: nrc,
            nombre: customer.fullName,
            nombreComercial: invoice.isCCF ?
            customer.company :nil,
            codActividad: invoice.isCCF ?
            customer.codActividad! : nil,
            descActividad: invoice.isCCF ?
            customer.descActividad : nil,
            direccion: Direccion(
                departamento: customer.departamentoCode,
                municipio: customer.municipioCode,
                complemento: customer.address),
            telefono: customer.phone,
            correo : customer.email,
            tipoDocumento: !invoice.isCCF ? "13" : nil,
            numDocumento: invoice.isCCF ? nil :
                try Extensions.formatNationalId(customer.nationalId),
            nit: invoice.isCCF ? customer.nit : nil
        )
        return receptor
    }
    
    private static func mapResumen(invoice: Invoice, items: [CuerpoDocumento]) -> Resumen {
        
        let total = invoice.totalAmount.asDoubleRounded
        
        
        let totalLabel = Extensions.numberToWords(total)
        
        
        let totalIva =  items.compactMap { $0.ivaItem ?? 0 }.reduce(0, +)
        
        let iva = totalIva.rounded()
           
        print("Total iva: \(iva)")
        
        let isCCF = invoice.isCCF
        
        let resumen = Resumen(
            totalNoSuj: 0.0,
            totalExenta: 0.0,
            totalGravada: invoice.isCCF ?
            invoice.totalWithoutTax : invoice.totalAmount,
            subTotalVentas: invoice.isCCF ?
            invoice.totalWithoutTax : invoice.totalAmount,
            descuNoSuj: 0.0,
            descuExenta: 0.0,
            descuGravada: 0.0,
            porcentajeDescuento: 0.0,
            totalDescu: 0.0,
            tributos:  isCCF ?
                    [Tributo(codigo: "20",
                             descripcion: "Impuesto al Valor Agregado 13%",
                             valor: (iva as NSDecimalNumber).doubleValue)]
                    : nil,
            subTotal: invoice.subTotal.rounded(),
            ivaRete1: 0.0,
            reteRenta: 0.0,
            montoTotalOperacion: invoice.totalAmount,
            totalNoGravado: 0.0,
            totalPagar: invoice.totalAmount,
            totalLetras: totalLabel,
            totalIva: iva,
            saldoFavor: 0.0,
            condicionOperacion: 1,
            pagos: nil,
            numPagoElectronico: nil
        )
        
        return resumen
    }
    
    static func mapCreditNote(invoice: Invoice, company: Company, environmentCode: String)throws -> DTE_Base {
        var index = 1
        
        let items = invoice.items.map { detail -> CuerpoDocumento in
            var item = formatFromProductDetail(detail: detail, isCCF: invoice.isCCF)
            item.numItem = index
            index += 1
            return item
        }
        
        let emisor = mapEmisor(company)
        
        let resumen = mapResumen(invoice: invoice, items: items)
        
        let documentType = Extensions.documentTypeFromInvoiceType(.NotaCredito)
        let version =  (documentType as NSString).integerValue
        
        let identificacion = Identificacion(
            version: version,
            ambiente: environmentCode,
            tipoDte: documentType, //invoice.isCCF ? "03" : invoice.invoiceType == .NotaCredito ? "05" : "01",
            numeroControl: invoice.controlNumber,
            codigoGeneracion: invoice.generationCode,
            tipoModelo: 1,
            tipoOperacion: 1,
            tipoContingencia: nil,
            motivoContin: nil,
            fecEmi: Date(),
            horEmi:try Extensions.generateHourString(date: Date()),
            tipoMoneda: "USD"
        )
        
        let dte = DTE_Base(
            identificacion: identificacion,
            emisor: emisor,
            receptor: try mapReceptor(invoice: invoice),
            cuerpoDocumento: items,
            resumen: resumen
        )
         
        return dte
    }
    
}
