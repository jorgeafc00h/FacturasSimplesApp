import Foundation

class MhClient {
    
    
    
    static func mapInvoice(invoice: Invoice, company: Company, environmentCode: String)throws -> DTE_Base {
        
        if(invoice.invoiceType == .NotaCredito || invoice.invoiceType == .NotaDebito) {
            return try mapCreditNote(invoice: invoice, company: company, environmentCode: environmentCode)
        }
        
        if invoice.invoiceType == .SujetoExcluido {
            return try mapSujetoExcluido(invoice:invoice, company: company, environmentCode: environmentCode)
        }
        
        var index = 1
        
        let items = (invoice.items ?? []).map { detail -> CuerpoDocumento in
            var item = formatFromProductDetail(detail: detail, isCCF: invoice.isCCF)
            item.numItem = index
            index += 1
            return item
        }
        
        let emisor = mapEmisor(company)
        //
        let resumen = mapResumen(invoice: invoice, items: items)
        
        let documentType = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
        let version =  invoice.invoiceType == .Factura ? 1 : 3
        
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
            documentoRelacionado: nil,
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
        
        let productTotal = (detail.quantity * (detail.product?.unitPrice ?? 0)).rounded()
        let tax = (productTotal - (productTotal / Decimal(1.13))).rounded()
        
        return CuerpoDocumento(
            ivaItem: isCCF ? nil : tax,
            cantidad: detail.quantity,
            numItem: 0,
            codigo: isCCF ? nil : "1", // ???
            codTributo: nil,
            descripcion: detail.product?.productName ?? "Unknown Product",
            precioUni: isCCF ?
            ((detail.product?.unitPrice ?? 0) / Decimal(1.13))
                .rounded():
                detail.product?.unitPrice ?? 0,
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
        
        
        let nrc = invoice.isCCF ? customer?.nrc : nil
        
        let receptor = Receptor(
            nrc: nrc,
            nombre: customer?.fullName ?? "Unknown Customer",
            nombreComercial: invoice.isCCF ?
            customer?.company :nil,
            codActividad: invoice.isCCF ?
            customer?.codActividad : nil,
            descActividad: invoice.isCCF ?
            customer?.descActividad : nil,
            direccion: Direccion(
                departamento: customer?.departamentoCode,
                municipio: customer?.municipioCode,
                complemento: customer?.address),
            telefono: customer?.phone,
            correo : customer?.email,
            tipoDocumento: invoice.invoiceType == .Factura ? "13" : nil,
            numDocumento: invoice.isCCF ? nil :
                try Extensions.formatNationalId(customer?.nationalId ?? ""),
            nit: invoice.isCCF ? customer?.nit : nil
        )
        return receptor
    }
    
    private static func mapResumen(invoice: Invoice, items: [CuerpoDocumento]) -> Resumen {
        
        let total =
        invoice.customer?.hasContributorRetention ?? false ?
        (invoice.totalAmount.asDoubleRounded - invoice.ivaRete1.asDoubleRounded) :
        invoice.totalAmount.asDoubleRounded
        
        
        let totalLabel = Extensions.numberToWords(total)
        
        //let totalIva =  items.compactMap { $0.ivaItem ?? 0 }.reduce(0, +)
        
        let taxItems = (invoice.items ?? []).map { detail -> Decimal in
            let productTotal = (detail.quantity * (detail.product?.unitPrice ?? 0)).rounded()
            let tax = (productTotal - (productTotal / Decimal(1.13))).rounded()
            return tax
        }
        
        let totalIva = taxItems.compactMap { $0 }.reduce(0, +)
        
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
                     valor: iva)]
            : nil,
            subTotal: invoice.subTotal.rounded(),
            ivaRete1: invoice.customer?.hasContributorRetention ?? false ? invoice.ivaRete1 :  0.0,
            reteRenta: 0.0,
            montoTotalOperacion: invoice.totalAmount,
            totalNoGravado: 0.0,
            totalPagar: Decimal(total).rounded(),
            totalLetras: totalLabel,
            totalIva: iva,
            saldoFavor: 0.0,
            condicionOperacion: 1,
            pagos: nil,
            numPagoElectronico: nil
        )
        
        return resumen
    }
    
    private static func mapResumenForCreditNote(invoice: Invoice, items: [CuerpoDocumento],isCCF: Bool) -> Resumen {
        
        let total = invoice.totalAmount.asDoubleRounded
        
        
        let totalLabel = Extensions.numberToWords(total)
        
        
        let taxItems = (invoice.items ?? []).map { detail -> Decimal in
            let productTotal = (detail.quantity * (detail.product?.unitPrice ?? 0)).rounded()
            let tax = (productTotal - (productTotal / Decimal(1.13))).rounded()
            return tax
        }
        
        let totalIva = taxItems.compactMap { $0 }.reduce(0, +)
        
        let iva =  totalIva.rounded()
        
        print("Total iva: \(iva) isCCF: \(isCCF)")
        
        let resumen = Resumen(
            totalNoSuj: 0.0,
            totalExenta: 0.0,
            totalGravada: isCCF ?
            invoice.totalWithoutTax : invoice.totalAmount,
            subTotalVentas: isCCF ?
            invoice.totalWithoutTax : invoice.totalAmount,
            descuNoSuj: 0.0,
            descuExenta: 0.0,
            descuGravada: 0.0,
            porcentajeDescuento: nil,
            totalDescu: 0.0,
            tributos:  isCCF ?
            [Tributo(codigo: "20",
                     descripcion: "Impuesto al Valor Agregado 13%",
                     valor: iva) ]
            : nil,
            subTotal: invoice.subTotal.rounded(),
            ivaRete1: 0.0,
            reteRenta: 0.0,
            montoTotalOperacion: invoice.totalAmount,
            totalNoGravado: nil,
            totalPagar: nil,
            totalLetras: totalLabel,
            totalIva: nil,
            saldoFavor: nil,
            condicionOperacion: 1,
            //pagos: nil,
            //numPagoElectronico: nil,
            ivaPerci1: iva
        )
        
        return resumen
    }
    
    static func mapCreditNote(invoice: Invoice, company: Company, environmentCode: String)throws -> DTE_Base {
        var index = 1
        
        // check if the related document is a CCF
        let isCCF = invoice.relatedInvoiceType == .CCF
        
        let items = (invoice.items ?? []).map { detail -> CuerpoDocumento in
            var item = formatFromProductDetail(detail: detail, isCCF: isCCF)
            
            let productTotal = (detail.quantity * (detail.product?.unitPrice ?? 0)).rounded()
            
            item.numeroDocumento = invoice.relatedDocumentNumber
            item.numItem = index
            item.ventaGravada = productTotal
            index += 1
            return item
        }
        
        let emisor = mapEmisor(company)
        
        let resumen = mapResumenForCreditNote(invoice: invoice, items: items,isCCF: isCCF)
        
        let documentType = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
        //let version =  (documentType as NSString).integerValue
        
        let identificacion = Identificacion(
            version: 3,// hardcoded version credit note
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
        
        let relatedDoc =  DocumentoRelacionado(tipoDocumento: invoice.relatedDocumentType!,
                                               tipoGeneracion: 2,
                                               numeroDocumento: invoice.relatedDocumentNumber!,
                                               fechaEmision : invoice.relatedDocumentDate! )
        
        let customer = invoice.customer
        
        let nrc = isCCF ? customer?.nrc : nil
        
        let receptor = Receptor(
            nrc: nrc,
            nombre: customer?.fullName ?? "Unknown Customer",
            nombreComercial: isCCF ?
            customer?.company :nil,
            codActividad: isCCF ?
            customer?.codActividad : nil,
            descActividad: isCCF ?
            customer?.descActividad : nil,
            direccion: Direccion(
                departamento: customer?.departamentoCode,
                municipio: customer?.municipioCode,
                complemento: customer?.address),
            telefono: customer?.phone,
            correo : customer?.email,
            tipoDocumento: invoice.invoiceType == .Factura ? "13" : nil,
            numDocumento: isCCF ? nil :
                try Extensions.formatNationalId(customer?.nationalId ?? ""),
            nit: isCCF ? customer?.nit : nil
        )
        
        let dte = DTE_Base(
            identificacion: identificacion,
            documentoRelacionado: [relatedDoc],
            emisor: emisor,
            receptor: receptor,
            otrosDocumentos: nil,
            cuerpoDocumento: items,
            resumen: resumen
        )
        
        return dte
    }
    
    static func mapInvalidationModel(invoice: Invoice, company: Company,motivo:Motivo,nombreEstablecimiento: String, environmentCode: String) throws -> DTE_InvalidationRequest {
        
        let _emisor = mapEmisor(company)
        
        let emisor = EmisorInvalidate(nit: _emisor.nit,
                                      nombre: _emisor.nombre,
                                      tipoEstablecimiento: _emisor.tipoEstablecimiento,
                                      nomEstablecimiento: nombreEstablecimiento,
                                      codEstableMH: _emisor.codEstableMH,
                                      codEstable: _emisor.codEstable,
                                      codPuntoVentaMH: _emisor.codPuntoVentaMH,
                                      codPuntoVenta: _emisor.codPuntoVenta,
                                      telefono: _emisor.telefono,
                                      correo: _emisor.correo)
        
        let identification = IdentificationInvalidate(version:2,
                                                      ambiente: environmentCode,
                                                      codigoGeneracion: try Extensions.getGenerationCode(),
                                                      fecAnula: Extensions.generateDateString(),
                                                      horAnula: Extensions.generateTimeString())
        
        let docNumber = invoice.isCCF ?
        (invoice.customer?.nit ?? "") :
        (invoice.customer?.nationalId ?? "")
        
        
        let model = DTE_InvalidationRequest(identificacion: identification,
                                            emisor: emisor,
                                            documento: Documento(
                                                tipoDte: invoice.documentType,
                                                codigoGeneracion: invoice.generationCode!,
                                                selloRecibido: invoice.receptionSeal!,
                                                numeroControl: invoice.controlNumber!,
                                                fecEmi: Extensions.generateDateString(date: invoice.date),
                                                montoIva: invoice.tax,
                                                codigoGeneracionR: nil,
                                                tipoDocumento:"13", //invoice.isCCF ? "36" : "13",
                                                numDocumento: docNumber,
                                                nombre: invoice.customer?.fullName ?? "Unknown Customer",
                                                telefono: invoice.customer?.phone,
                                                correo: invoice.customer?.email ?? ""
                                            ),
                                            motivo:motivo)
        
        return model
        
    }
    
    static func mapSujetoExcluido(invoice:Invoice, company: Company, environmentCode: String) throws -> DTE_Base {
        
        var index = 1
        
        let items = (invoice.items ?? []).map { detail -> CuerpoDocumento in
            let item = CuerpoDocumento(
                ivaItem: nil,
                cantidad: detail.quantity,
                numItem: index,
                codigo: nil, // ???
                codTributo: nil,
                descripcion: detail.product?.productName ?? "Unknown Product",
                precioUni: detail.product?.unitPrice.rounded() ?? 0,
                ventaGravada: 0,
                psv: 0,
                noGravado: 0,
                montoDescu: 0,
                ventaNoSuj: 0,
                uniMedida: 99, // 59 unidad, 99 otro
                tributos: nil,
                ventaExenta: 0,
                tipoItem: 2, // 1 producto, 2 Servicios
                numeroDocumento: nil,
                compra: ((detail.product?.unitPrice.rounded() ?? 0) * detail.quantity).rounded(),
            )
            
            //let productTotal = (detail.quantity * (detail.product?.unitPrice ?? 0)).rounded()
          
            index += 1
            return item
        }
        
        let emisor = mapEmisor(company)
        
        //let total = invoice.totalAmount.asDoubleRounded
        //let totalLabel = Extensions.numberToWords(total)
        
        let resumen = Resumen(
            totalNoSuj: 0.0,
            totalExenta: 0.0,
            totalGravada: 0,
            subTotalVentas: 0,
            descuNoSuj: 0.0,
            descuExenta: 0.0,
            descuGravada: 0.0,
            porcentajeDescuento: nil,
            totalDescu: 0.0,
            tributos: nil,
            subTotal: invoice.totalAmount.rounded(),
            ivaRete1: 0.0,
            reteRenta: invoice.reteRenta.rounded(),
            montoTotalOperacion: 0,
            totalNoGravado: nil,
            totalPagar: invoice.totalPagar.rounded(),
            totalLetras: Extensions.numberToWords(invoice.totalPagar.asDoubleRounded),
            totalIva: nil,
            saldoFavor: nil,
            condicionOperacion: 1,
            pagos: [
                Pago(codigo:"99",montoPago: invoice.totalPagar.rounded(),referencia: nil,plazo: nil,periodo: 0.0)
            ],
            //numPagoElectronico: nil,
            ivaPerci1: nil,
            totalCompra: invoice.totalAmount.rounded()
        )
        
        let documentType = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
        //let version =  (documentType as NSString).integerValue
        
        let identificacion = Identificacion(
            version: 1,// hardcoded version sujeto e.
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
        let customer = invoice.customer
        
        var isCompany = !customer!.nrc.isEmpty && !customer!.nit.isEmpty
        
        let sujeto = Receptor(
            nrc: customer?.nrc,
            nombre: customer?.fullName ?? "",
            nombreComercial: isCompany ?
                            customer?.company :nil,
            codActividad: isCompany ?
            customer?.codActividad : nil,
            descActividad: isCompany ?
            customer?.descActividad : nil,
            direccion: Direccion(
                departamento: customer?.departamentoCode,
                municipio: customer?.municipioCode,
                complemento: customer?.address),
            telefono: customer?.phone,
            correo : customer?.email,
            tipoDocumento: isCompany ? "36" :  "36",
            //numDocumento: isCompany ? nil : customer?.nationalId ?? "",
            numDocumento: customer?.nationalId,
            nit: isCompany ? customer?.nit : nil
        )
        
        let dte = DTE_Base(
            identificacion: identificacion,
            documentoRelacionado: [],
            emisor: emisor,
            receptor: sujeto,
            otrosDocumentos: nil,
            cuerpoDocumento: items,
            resumen: resumen,
            sujetoE: sujeto
        )
        
        
        
        return dte
    }

}
