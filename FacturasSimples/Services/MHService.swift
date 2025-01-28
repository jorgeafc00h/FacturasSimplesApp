import Foundation

class MhClient {
    
    let extensions = Extensions()
    
    func mapInvoice(invoice: Invoice, company: Company)throws -> DTE_Base {
        var index = 1
        
        let items = invoice.items.map { detail -> CuerpoDocumento in
            var item = formatFromProductDetail(detail: detail, isCCF: invoice.isCCF)
            item.numItem = index
            index += 1
            return item
        }
        
        
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
            telefono: extensions.formatPhoneNumber(telefono: company.telefono),
            correo: company.correo,
            codEstableMH: company.codEstableMH != "" ?
            company.codEstableMH : nil ,
            codEstable: company.codEstable != "" ?
            company.codEstable : nil,
            codPuntoVentaMH: nil,
            codPuntoVenta: nil
        )
        
        let resumen = mapResumen(invoice: invoice, items: items)
        
        let identificacion = Identificacion(
            version: invoice.isCCF ? 3 : 1,
            ambiente: Constants.EnvironmentCode,
            tipoDte: invoice.isCCF ? "03" : "01",
            numeroControl: nil,
            codigoGeneracion: nil,
            tipoModelo: 1,
            tipoOperacion: 1,
            tipoContingencia: nil,
            motivoContin: nil,
            fecEmi: Date(),
            horEmi:try extensions.generateHourString(date: Date()),
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
    
    func formatFromProductDetail(detail: InvoiceDetail, isCCF: Bool) -> CuerpoDocumento {
        
        let productTotal = Decimal( detail.quantity) * detail.product.unitPrice
        let tax = productTotal - (productTotal / Decimal(1.13))
        
        return CuerpoDocumento(
            ivaItem: isCCF ? nil : tax,
            cantidad: Decimal( detail.quantity),
            numItem: 0,
            codigo: isCCF ? nil : "1", // ???
            codTributo: nil,
            descripcion: detail.product.productName,
            precioUni: isCCF ? (detail.product.unitPrice / Decimal(1.13)) : detail.product.unitPrice,
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
    
    func mapReceptor(invoice: Invoice)throws -> Receptor {
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
                try extensions.formatNationalId(customer.nationalId),
            nit: invoice.isCCF ? customer.nit : nil
        )
        return receptor
        //            if !invoice.isCCF {
        //                return Receptor(
        //                    nrc: nil,
        //                    numDocumento: extensions.formatNationalId(customer.nationalId),
        //                    tipoDocumento: "13", // customer.documentType ?? "13",
        //                    nombre: customer.fullName,
        //                    correo: customer.email,
        //                    codActividad: customer.codActividad?.isEmpty == false ? customer.codActividad : nil,
        //                    descActividad: customer.descActividad?.isEmpty == false ? customer.descActividad : nil,
        //                    direccion: Direccion(
        //                        departamento: customer.direccion.departamento,
        //                        municipio: customer.direccion.municipio,
        //                        complemento: customer.direccion.complemento
        //                    ),
        //                    telefono: customer.phone
        //                )
        //            } else {
        //                // CCF
        //                return Receptor(
        //                    nrc: customer.nrc ?? customer.contributorId ?? "", // Required
        //                    nombre: customer.fullName,
        //                    correo: customer.email,
        //                    codActividad: customer.codActividad?.isEmpty == false ? customer.codActividad : nil,
        //                    descActividad: customer.descActividad?.isEmpty == false ? customer.descActividad : nil,
        //                    nombreComercial: customer.company,
        //                    direccion: Direccion(
        //                        departamento: customer.direccion.departamento,
        //                        municipio: customer.direccion.municipio,
        //                        complemento: customer.direccion.complemento
        //                    ),
        //                    telefono: customer.phone,
        //                    nit: invoice.isCCF ? customer.nit : nil // Required CCF
        //                )
        //            }
    }
    
    func mapResumen(invoice: Invoice, items: [CuerpoDocumento]) -> Resumen {
        
        let total = NSDecimalNumber(decimal: invoice.totalAmount).doubleValue
        
        let totalLabel = extensions.numberToWords(total)
        
        
        let totalIva = items.compactMap { $0.ivaItem ?? 0 }.reduce(0, +)
        print("Total iva: \(totalIva)")
        
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
            tributos: nil,
            subTotal: invoice.subTotal,
            ivaRete1: 0.0,
            reteRenta: 0.0,
            montoTotalOperacion: invoice.totalAmount,
            totalNoGravado: 0.0,
            totalPagar: invoice.totalAmount,
            totalLetras: totalLabel,
            totalIva: totalIva,
            saldoFavor: 0.0,
            condicionOperacion: 1,
            pagos: nil,
            numPagoElectronico: nil
        )
        
        return resumen
    }
    
    
    
    
}


