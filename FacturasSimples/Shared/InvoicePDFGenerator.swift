import Foundation
import PDFKit
import SwiftUI
import CoreImage.CIFilterBuiltins

class InvoicePDFGenerator {
    static func generatePDF(from invoice: Invoice, company: Company) -> (Data) {
        let fileName = "\(invoice.invoiceType.stringValue())-\(invoice.invoiceNumber).pdf"
        let pdfMetaData = [
            kCGPDFContextCreator: "Facturas Simples",
            kCGPDFContextAuthor: "K Labs Inc.",
            kCGPDFContextTitle: fileName
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Define fonts
            let titleFont = UIFont.boldSystemFont(ofSize: 12.0)
            let subtitleFont = UIFont.boldSystemFont(ofSize: 10.0)
            let regularFont = UIFont.systemFont(ofSize: 9.0)
            let smallFont = UIFont.systemFont(ofSize: 7.0)
            
            // Define colors
            let darkGray = UIColor.darkGray
            
            // Define common attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: darkGray
            ]
            let subtitleAttributes = [NSAttributedString.Key.font: subtitleFont]
            let regularAttributes = [NSAttributedString.Key.font: regularFont]
            let smallerAttributes = [NSAttributedString.Key.font: smallFont]
            
            // Company Header
            company.nombreComercial.uppercased().draw(at: CGPoint(x: 30, y: 15), withAttributes: titleAttributes)
            "NIT: \(company.nit)  NRC: \(company.nrc)".draw(at: CGPoint(x: 30, y: 27), withAttributes: regularAttributes)
            "Actividad Económica: \(company.descActividad)".draw(at: CGPoint(x: 30, y: 39), withAttributes: regularAttributes)
            "Dirección: \(company.complemento)".draw(at: CGPoint(x: 30, y: 51), withAttributes: regularAttributes)
            "Correo Electrónico: \(company.correo)".draw(at: CGPoint(x: 30, y: 63), withAttributes: regularAttributes)
            "Teléfono: \(company.telefono)".draw(at: CGPoint(x: 30, y: 75), withAttributes: regularAttributes)
            
            // Logo
            let logoRect = CGRect(x: pageWidth - 120, y: 5, width: 80, height: 80)
            if !company.invoiceLogo.isEmpty {
                if let imageData = Data(base64Encoded: company.invoiceLogo),
                   let image = UIImage(data: imageData) {
                    image.draw(in: logoRect)
                }
            }
            
            // Document Title Section
            let titleRect = CGRect(x: 0, y: 95, width: pageWidth, height: 35)
            context.cgContext.setFillColor(UIColor.darkGray.cgColor)
            context.cgContext.fill(titleRect)
            
            let whiteTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white
            ]
            
            "DOCUMENTO TRIBUTARIO ELECTRÓNICO".draw(at: CGPoint(x: pageWidth/2 - 120, y: 100), withAttributes: whiteTitleAttributes)
            invoice.invoiceType.stringValue().draw(at: CGPoint(x: pageWidth/2 - (invoice.isCCF ? 110 : 30), y: 112), withAttributes: whiteTitleAttributes)
            
            // Document Metadata Section with gray background
            let metadataRect = CGRect(x: 0, y: 140, width: pageWidth, height: 110)
            context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
            context.cgContext.fill(metadataRect)
            
            // Generate QR URL Format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let _date = dateFormatter.string(from: invoice.date).replacingOccurrences(of: "/", with: "-")
            let qrUrlFormat = invoice.generationCode != "" ?
                        "\(Constants.qrUrlBase)?ambiente=\(Constants.EnvironmentCode)&codGen=\(invoice.generationCode ?? "")&fechaEmi=\(_date)" :
                        ""
            // QR Code
            let qrRect = CGRect(x: 30, y: 150, width: 90, height: 90)
            let qrImage = generateQRCode(from: qrUrlFormat)
            qrImage.draw(in: qrRect)
            
            // Metadata Grid Layout
            let metadataY: CGFloat = 150
            let col1X: CGFloat = 130
            let col2X: CGFloat = pageWidth/2
            let col3X: CGFloat = pageWidth * 0.75
            let labelSpacing: CGFloat = 22
            
            let grayAttributes: [NSAttributedString.Key: Any] = [
                .font: regularFont,
                .foregroundColor: UIColor.gray
            ]
            
            // Column 1
            "Modelo de Facturación:".draw(at: CGPoint(x: col1X, y: metadataY), withAttributes: grayAttributes)
            "MODELO FACTURACIÓN PREVIO".draw(at: CGPoint(x: col1X, y: metadataY + 12), withAttributes: regularAttributes)
            
            "Código de Generación:".draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing), withAttributes: grayAttributes)
            invoice.generationCode?.draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing + 12), withAttributes: regularAttributes)
            
            "Número de Control:".draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing * 2), withAttributes: grayAttributes)
            invoice.controlNumber?.draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing * 2 + 12), withAttributes: regularAttributes)
            
            "Sello de Recepción:".draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing * 3), withAttributes: grayAttributes)
            invoice.receptionSeal?.draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing * 3 + 12), withAttributes: regularAttributes)
            
            // Column 2
            "Tipo de Transmisión:".draw(at: CGPoint(x: col2X, y: metadataY), withAttributes: grayAttributes)
            "TRANSMISIÓN NORMAL".draw(at: CGPoint(x: col2X, y: metadataY + 12), withAttributes: regularAttributes)
            
            "Versión de JSON:".draw(at: CGPoint(x: col2X, y: metadataY + labelSpacing), withAttributes: grayAttributes)
            "3".draw(at: CGPoint(x: col2X, y: metadataY + labelSpacing + 12), withAttributes: regularAttributes)
            
            // Column 3
            "Fecha y Hora de Generación:".draw(at: CGPoint(x: col3X, y: metadataY), withAttributes: grayAttributes)
            //let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            let formattedDate = dateFormatter.string(from: invoice.date)
            formattedDate.draw(at: CGPoint(x: col3X, y: metadataY + 12), withAttributes: regularAttributes)
            
            // Receptor Section Header with gray background
            let receptorHeaderRect = CGRect(x: 0, y: 260, width: pageWidth, height: 25)
            context.cgContext.setFillColor(UIColor.darkGray.cgColor)
            context.cgContext.fill(receptorHeaderRect)
            
            "RECEPTOR".draw(at: CGPoint(x: pageWidth/2 - 30, y: 267), withAttributes: [
                .font: subtitleFont,
                .foregroundColor: UIColor.white
            ])
            
            // Receptor Content Section with light gray background
            let receptorContentRect = CGRect(x: 0, y: 285, width: pageWidth, height: 80)
            context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
            context.cgContext.fill(receptorContentRect)
            
            // Receptor Info Grid
            let receptorY: CGFloat = 290
            let receptorCol1 = 30.0
            let receptorCol2 = pageWidth/3
            let receptorCol3 = pageWidth * 2/3
            
            // Column 1
            "Nombre ó Razón Social:".draw(at: CGPoint(x: receptorCol1, y: receptorY), withAttributes: grayAttributes)
            invoice.customer.company.draw(at: CGPoint(x: receptorCol1, y: receptorY + 12), withAttributes: regularAttributes)
            
            "NRC:".draw(at: CGPoint(x: receptorCol1, y: receptorY + labelSpacing), withAttributes: grayAttributes)
            let _labelSpaceExtra: CGFloat = 12
            (invoice.customer.nrc ?? "").draw(at: CGPoint(x: receptorCol1, y: receptorY + labelSpacing + _labelSpaceExtra), withAttributes: regularAttributes)
            
            // Column 2
            "Tipo de Documento:".draw(at: CGPoint(x: receptorCol2, y: receptorY), withAttributes: grayAttributes)
            "DUI/NIT".draw(at: CGPoint(x: receptorCol2, y: receptorY + 12), withAttributes: regularAttributes)
            
            "Actividad Económica:".draw(at: CGPoint(x: receptorCol2, y: receptorY + labelSpacing), withAttributes: grayAttributes)
            SplitText(invoice.customer.descActividad ?? "", 45).draw(at: CGPoint(x: receptorCol2, y: receptorY + labelSpacing + _labelSpaceExtra), withAttributes: regularAttributes)
            
            // Column 3
            "N° Documento:".draw(at: CGPoint(x: receptorCol3, y: receptorY), withAttributes: grayAttributes)
            invoice.customer.nationalId.draw(at: CGPoint(x: receptorCol3, y: receptorY + 12), withAttributes: regularAttributes)
            
            "Dirección:".draw(at: CGPoint(x: receptorCol3, y: receptorY + labelSpacing), withAttributes: grayAttributes)
            SplitText(invoice.customer.address, 45).draw(at: CGPoint(x: receptorCol3, y: receptorY + labelSpacing + _labelSpaceExtra), withAttributes: regularAttributes)
            
            // Table Header with gray background
            let tableHeaderRect = CGRect(x: 0, y: 370, width: pageWidth, height: 25)
            context.cgContext.setFillColor(UIColor.darkGray.cgColor)
            context.cgContext.fill(tableHeaderRect)
            
            "CUERPO DEL DOCUMENTO".draw(at: CGPoint(x: pageWidth/2 - 70, y: 377), withAttributes: [
                .font: subtitleFont,
                .foregroundColor: UIColor.white
            ])
            
            // Table Grid
            let tableY: CGFloat = 400
            let columns = ["N°", "Cant.", "Unidad", "Descripción", "Precio\nUnitario", "Descuento por\nítem", "Ventas no\nsujetas", "Ventas\nexentas", "Ventas\ngravadas"]
            let columnWidths: [CGFloat] = [25, 35, 40, 120, 60, 60, 60, 60, 60]
            var currentX: CGFloat = 30
            var currentY: CGFloat = tableY
            
            // Draw table header
            for (index, column) in columns.enumerated() {
                column.draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: subtitleAttributes)
                currentX += columnWidths[index]
            }
            
            // Draw items
            currentY = tableY + 25  // Increased spacing after header
            for (index, item) in invoice.items.enumerated() {
                currentX = 30
                
                // Draw each column for the item
                "\(index + 1)".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[0]
                
                "\(item.quantity)".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[1]
                
                "Unidad".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[2]
                
                item.product.productName.draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[3]
                
                item.product.unitPrice.formatted(.currency(code: "USD")).draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[4]
                
                "$0.00".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[5]
                
                "$0.00".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[6]
                
                "$0.00".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[7]
                
                item.productTotal.formatted(.currency(code: "USD")).draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                
                currentY += 20  // Increased row spacing from 15 to 20
            }
            
            // Draw Summary Section
            if invoice.isCCF {
                let summaryY = currentY + 30
                
                // Draw "Total en Letras" section with dark gray background
                let totalLetrasRect = CGRect(x: 0, y: summaryY, width: pageWidth * 0.6, height: 25)
                context.cgContext.setFillColor(UIColor.darkGray.cgColor)
                context.cgContext.fill(totalLetrasRect)
                
                "Total en Letras:".draw(at: CGPoint(x: 30, y: summaryY + 5), withAttributes: [
                    NSAttributedString.Key.font: subtitleFont,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ])
                numberToWords((invoice.totalAmount as NSDecimalNumber).doubleValue).uppercased().draw(at: CGPoint(x: 30, y: summaryY + 25), withAttributes: regularAttributes)
                
                // Draw totals grid with dark gray background
                let totalsGridRect = CGRect(x: pageWidth * 0.6, y: summaryY, width: pageWidth * 0.4, height: 25)
                context.cgContext.setFillColor(UIColor.darkGray.cgColor)
                context.cgContext.fill(totalsGridRect)
                
                let gridStartX = pageWidth * 0.6
                let columnWidth = (pageWidth * 0.4) / 4
                
                // Headers
                let headerY = summaryY + 5
                "Total".draw(at: CGPoint(x: gridStartX + 10, y: headerY), withAttributes: [
                    NSAttributedString.Key.font: subtitleFont,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ])
                "No Sujetas".draw(at: CGPoint(x: gridStartX + columnWidth, y: headerY), withAttributes: [
                    NSAttributedString.Key.font: subtitleFont,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ])
                "Exentas".draw(at: CGPoint(x: gridStartX + columnWidth * 2, y: headerY), withAttributes: [
                    NSAttributedString.Key.font: subtitleFont,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ])
                "Gravadas".draw(at: CGPoint(x: gridStartX + columnWidth * 3, y: headerY), withAttributes: [
                    NSAttributedString.Key.font: subtitleFont,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ])
                
                // Values with light gray background
                let valuesRect = CGRect(x: pageWidth * 0.6, y: summaryY + 25, width: pageWidth * 0.4, height: 25)
                context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
                context.cgContext.fill(valuesRect)
                
                let valuesY = summaryY + 30
                "Operaciones".draw(at: CGPoint(x: gridStartX + 10, y: valuesY), withAttributes: regularAttributes)
                "$0.00".draw(at: CGPoint(x: gridStartX + columnWidth, y: valuesY), withAttributes: regularAttributes)
                "$0.00".draw(at: CGPoint(x: gridStartX + columnWidth * 2, y: valuesY), withAttributes: regularAttributes)
                invoice.totalAmount.formatted(.currency(code: "USD")).draw(at: CGPoint(x: gridStartX + columnWidth * 3, y: valuesY), withAttributes: regularAttributes)
                
                // Draw summary rows with alternating backgrounds
                currentY = summaryY + 60
                let rowSpacing: CGFloat = 25
                let amountX = pageWidth - 120
                
                let summaryRows = [
                    ("Sumatoria de Ventas", invoice.totalAmount),
                    ("Monto Global de Descuento, Bonificación, Rebajas y Otros a Ventas No Sujetas:", Decimal(0)),
                    ("Monto Global de Descuento, Bonificación, Rebajas y Otros a Ventas Exentas:", Decimal(0)),
                    ("Monto Global de Descuento, Bonificación, Rebajas y Otros a Ventas Gravadas:", Decimal(0)),
                    ("20 - Impuesto al Valor Agregado 13%:", invoice.totalAmount * Decimal(0.13)),
                    ("Sub Total:", invoice.totalAmount),
                    ("(-) IVA Retenido:", Decimal(0)),
                    ("(-) Retención Renta:", Decimal(0)),
                    ("Monto Total de la Operación:", invoice.totalAmount * Decimal(1.13)),
                    ("Total Otros Montos No Afectos:", Decimal(0)),
                    ("Total a Pagar:", invoice.totalAmount * Decimal(1.13))
                ]
                
                for (index, (label, amount)) in summaryRows.enumerated() {
                    if index % 2 == 0 {
                        let rowRect = CGRect(x: 0, y: currentY - 5, width: pageWidth, height: rowSpacing)
                        context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
                        context.cgContext.fill(rowRect)
                    }
                    
                    label.draw(at: CGPoint(x: 30, y: currentY), withAttributes: regularAttributes)
                    amount.formatted(.currency(code: "USD")).draw(at: CGPoint(x: amountX, y: currentY), withAttributes: regularAttributes)
                    currentY += rowSpacing
                }
                
                // Draw Observations section with light gray background
                let observationsY = currentY + 10
                let observationsRect = CGRect(x: 0, y: observationsY, width: pageWidth, height: 70)
                context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
                context.cgContext.fill(observationsRect)
                
                "Observaciones:".draw(at: CGPoint(x: 30, y: observationsY + 5), withAttributes: regularAttributes)
                "-".draw(at: CGPoint(x: 30, y: observationsY + 25), withAttributes: regularAttributes)
                
                "Condición de la Operación:".draw(at: CGPoint(x: 30, y: observationsY + 45), withAttributes: regularAttributes)
                "CONTADO".draw(at: CGPoint(x: 150, y: observationsY + 45), withAttributes: regularAttributes)
                
                // Draw Extension section with dark gray header
                let extensionY = observationsY + 80
                let extensionHeaderRect = CGRect(x: 0, y: extensionY, width: pageWidth, height: 25)
                context.cgContext.setFillColor(UIColor.darkGray.cgColor)
                context.cgContext.fill(extensionHeaderRect)
                
                "EXTENSIÓN".draw(at: CGPoint(x: pageWidth/2 - 40, y: extensionY + 5), withAttributes: [
                    NSAttributedString.Key.font: subtitleFont,
                    NSAttributedString.Key.foregroundColor: UIColor.white
                ])
                
                // Draw Extension Content with light gray background
                let extensionContentRect = CGRect(x: 0, y: extensionY + 25, width: pageWidth, height: 100)
                context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
                context.cgContext.fill(extensionContentRect)
                
                let extensionRows = [
                    ("Nombre Entrega:", "-"),
                    ("N° Documento:", "-"),
                    ("Nombre Recibe:", "-"),
                    ("N° Documento:", "-")
                ]
                
                var extensionCurrentY = extensionY + 35
                for (label, value) in extensionRows {
                    label.draw(at: CGPoint(x: 30, y: extensionCurrentY), withAttributes: regularAttributes)
                    value.draw(at: CGPoint(x: 30, y: extensionCurrentY + 12), withAttributes: regularAttributes)
                    extensionCurrentY += 20
                }
            }
        }
        
        return data
    }
    
    private static func SplitText(_ text: String, _ maxLength: Int) -> String {
        return text.count >= maxLength ?
        "\(String(text.prefix(maxLength)))...\n\(String(text.suffix(text.count-maxLength)))":
        text
    }
    
    static func generateAndSavePDF(from invoice: Invoice,company: Company) throws -> URL {
        // Generate the PDF data
        let pdfData = generatePDF(from: invoice, company: company)
        
        // Create a temporary directory URL
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        
        // Create a unique filename using the invoice number
        let fileName = "Factura-\(invoice.invoiceNumber).pdf"
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        do {
            // Write the PDF data to the temporary file
            try pdfData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            throw error
        }
    }
    
    static func generateAndSavePDF(from data: Data, invoiceNumner: String) throws -> URL {
        
        // Create a temporary directory URL
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        
        // Create a unique filename using the invoice number
        let fileName = "Factura-\(invoiceNumner).pdf"
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        do {
            // Write the PDF data to the temporary file
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return fileURL
        }
    }
    
    static func generateQRCode(from string: String) -> UIImage {
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    static func cleanupTemporaryPDF(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    private static func numberToWords(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "es_SV")
        
        let integerPart = Int(number)
        let decimalPart = Int((number * 100).truncatingRemainder(dividingBy: 100))
        
        var result = formatter.string(from: NSNumber(value: integerPart))?.uppercased() ?? ""
        result += " DÓLARES"
        
        if decimalPart > 0 {
            result += " Y " + (formatter.string(from: NSNumber(value: decimalPart))?.uppercased() ?? "")
            result += " CENTAVOS"
        }
        
        return result
    }
} 
