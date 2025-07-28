import Foundation
import PDFKit
import SwiftUI
import CoreImage.CIFilterBuiltins

class InvoicePDFGenerator {
    
    @AppStorage("IsProduction") static var isProduction: Bool = false
    
    static var environmentCode : String {
        get{
            return isProduction ? Constants.EnvironmentCode_PRD : Constants.EnvironmentCode
        }
    }
    
    static var qr_url : String {
        get{
            return isProduction ?
            Constants.qrUrlBase_PRD : Constants.qrUrlBase
        }
    }
    static func generatePDF(from invoice: Invoice, company: Company) -> (Data) {
        let fileName = "\(invoice.invoiceType.stringValue())-\(invoice.invoiceNumber).pdf"
        let pdfMetaData = [
            kCGPDFContextCreator: "Facturas Simples",
            kCGPDFContextAuthor: "K Labs.",
            kCGPDFContextTitle: fileName
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Letter size page dimensions (8.5" x 11" in points)
        let pageWidth: CGFloat = 8.5 * 72.0  // 612 points
        let pageHeight: CGFloat = 11.0 * 72.0 // 792 points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Define fonts
            let titleFont = UIFont.boldSystemFont(ofSize: 8.0)
            let subtitleFont = UIFont.boldSystemFont(ofSize: 7.5)
            let regularFont = UIFont.systemFont(ofSize: 7.0)
            //let smallFont = UIFont.systemFont(ofSize: 6.0)
            let footerFont = UIFont.systemFont(ofSize: 7.0)
            let headerRegularFont = UIFont.systemFont(ofSize: 9.0)  // Original size for header
            
            // Define colors
            let darkGray = UIColor.darkGray
            
            // Define common attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: darkGray
            ]
            let headerRegularAttributes = [NSAttributedString.Key.font: headerRegularFont]  // Original attributes for header
            let subtitleAttributes = [NSAttributedString.Key.font: subtitleFont]
            let regularAttributes = [NSAttributedString.Key.font: regularFont]
            //let smallerAttributes = [NSAttributedString.Key.font: smallFont]
            let footerAttributes = [NSAttributedString.Key.font: footerFont]
            
            // Company Header - Restored original spacing
            company.nombreComercial.uppercased().draw(at: CGPoint(x: 30, y: 10), withAttributes: titleAttributes)
            "NIT: \(company.nit)  NRC: \(company.nrc)".draw(at: CGPoint(x: 30, y: 22), withAttributes: headerRegularAttributes)
            "Actividad Económica: \(company.descActividad)".draw(at: CGPoint(x: 30, y: 34), withAttributes: headerRegularAttributes)
            "Dirección: \(company.complemento)".draw(at: CGPoint(x: 30, y: 46), withAttributes: headerRegularAttributes)
            "Correo Electrónico: \(company.correo)".draw(at: CGPoint(x: 30, y: 58), withAttributes: headerRegularAttributes)
            "Teléfono: \(company.telefono)      Tipo de Establecimiento: \(company.establecimiento)".draw(at: CGPoint(x: 30, y: 70), withAttributes: headerRegularAttributes)
            
            // Logo - Restored original size
            let logoRect = CGRect(x: pageWidth - 120, y: 5, width: 75, height: 75)
            if !company.invoiceLogo.isEmpty {
                if let imageData = Data(base64Encoded: company.invoiceLogo),
                   let image = UIImage(data: imageData) {
                    image.draw(in: logoRect)
                }
                
            }
            else
            {
                let image = UIImage(named: "logo")
                image?.draw(in:  CGRect(x: pageWidth - 80, y: 5, width: 40, height: 50))
            }
            
            // Document Title Section
            let titleRect = CGRect(x: 0, y: 85, width: pageWidth, height: 30)
            context.cgContext.setFillColor(darkGray.cgColor)
            context.cgContext.fill(titleRect)
            
            let whiteTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white
            ]
            
            "DOCUMENTO TRIBUTARIO ELECTRÓNICO".draw(at: CGPoint(x: pageWidth/2 - 120, y: 90), withAttributes: whiteTitleAttributes)
            invoice.invoiceType.stringValue().draw(at: CGPoint(x: pageWidth/2 - (invoice.isCCF ? 110 : 50), y: 102), withAttributes: whiteTitleAttributes)
            
            // Document Metadata Section with gray background
            let metadataRect = CGRect(x: 0, y: 115, width: pageWidth, height: 90)
            context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
            context.cgContext.fill(metadataRect)
            
            // Generate QR URL Format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy"
            let _date = dateFormatter.string(from: invoice.date).replacingOccurrences(of: "/", with: "-")
            let qrUrlFormat = invoice.generationCode != "" ?
                        "\(qr_url)?ambiente=\(environmentCode)&codGen=\(invoice.generationCode ?? "")&fechaEmi=\(_date)" :
                        ""
            // QR Code
            let qrRect = CGRect(x: 30, y: 120, width: 75, height: 75)
            let qrImage = generateQRCode(from: qrUrlFormat)
            qrImage.draw(in: qrRect)
            
            // Metadata Grid Layout
            let metadataY: CGFloat = 122
            let col1X: CGFloat = 130
            let col2X: CGFloat = pageWidth/2
            let col3X: CGFloat = pageWidth * 0.75
            let labelSpacing: CGFloat = 20
            
            let grayAttributes: [NSAttributedString.Key: Any] = [
                .font: regularFont,
                .foregroundColor: UIColor.gray
            ]
            
            // Column 1
            "Modelo de Facturación:".draw(at: CGPoint(x: col1X, y: metadataY), withAttributes: grayAttributes)
            "MODELO FACTURACIÓN PREVIO".draw(at: CGPoint(x: col1X, y: metadataY + 10), withAttributes: regularAttributes)
            
            "Código de Generación:".draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing), withAttributes: grayAttributes)
            invoice.generationCode?.draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing + 10), withAttributes: regularAttributes)
            
            "Número de Control:".draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing * 2), withAttributes: grayAttributes)
            invoice.controlNumber?.draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing * 2 + 10), withAttributes: regularAttributes)
            
            "Sello de Recepción:".draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing * 3), withAttributes: grayAttributes)
            invoice.receptionSeal?.draw(at: CGPoint(x: col1X, y: metadataY + labelSpacing * 3 + 10), withAttributes: regularAttributes)
            
            // Column 2
            "Tipo de Transmisión:".draw(at: CGPoint(x: col2X, y: metadataY), withAttributes: grayAttributes)
            "TRANSMISIÓN NORMAL".draw(at: CGPoint(x: col2X, y: metadataY + 10), withAttributes: regularAttributes)
            
            "Versión de JSON:".draw(at: CGPoint(x: col2X, y: metadataY + labelSpacing), withAttributes: grayAttributes)
            "\(invoice.version)".draw(at: CGPoint(x: col2X, y: metadataY + labelSpacing + 10), withAttributes: regularAttributes)
            
            // Column 3
            "Fecha y Hora de Generación:".draw(at: CGPoint(x: col3X, y: metadataY), withAttributes: grayAttributes)
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            let formattedDate = dateFormatter.string(from: invoice.date)
            formattedDate.draw(at: CGPoint(x: col3X, y: metadataY + 10), withAttributes: regularAttributes)
            
            // Receptor Section Header with gray background
            let receptorHeaderRect = CGRect(x: 0, y: 210, width: pageWidth, height: 20)
            context.cgContext.setFillColor(darkGray.cgColor)
            context.cgContext.fill(receptorHeaderRect)
            
            "RECEPTOR".draw(at: CGPoint(x: pageWidth/2 - 30, y: 217), withAttributes: [
                .font: subtitleFont,
                .foregroundColor: UIColor.white
            ])
            
            // Receptor Content Section with light gray background
            let receptorContentRect = CGRect(x: 0, y: 230, width: pageWidth, height: 60)
            context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
            context.cgContext.fill(receptorContentRect)
            
            // Receptor Info Grid
            let receptorY: CGFloat = 235
            let receptorCol1 = 30.0
            let receptorCol2 = pageWidth/3
            let receptorCol3 = pageWidth * 2/3
            let receptorLabelSpacing: CGFloat = 25
            
            // Column 1
            "Nombre ó Razón Social:".draw(at: CGPoint(x: receptorCol1, y: receptorY), withAttributes: grayAttributes)
            (invoice.customer?.fullName ?? "N/A").draw(at: CGPoint(x: receptorCol1, y: receptorY + 10), withAttributes: regularAttributes)
            
            "NRC:".draw(at: CGPoint(x: receptorCol1, y: receptorY + receptorLabelSpacing), withAttributes: grayAttributes)
            (invoice.customer?.nrc ?? "").draw(at: CGPoint(x: receptorCol1, y: receptorY + receptorLabelSpacing +  CGFloat(10)), withAttributes: regularAttributes)
            
            // Column 2
            "Tipo de Documento:".draw(at: CGPoint(x: receptorCol2, y: receptorY), withAttributes: grayAttributes)
            "DUI/NIT".draw(at: CGPoint(x: receptorCol2, y: receptorY + 10), withAttributes: regularAttributes)
            
            "Actividad Económica:".draw(at: CGPoint(x: receptorCol2, y: receptorY + receptorLabelSpacing), withAttributes: grayAttributes)
            SplitText(invoice.customer?.descActividad ?? "", 35).draw(at: CGPoint(x: receptorCol2, y: receptorY + receptorLabelSpacing + 10), withAttributes: regularAttributes)
            
            // Column 3
            "N° Documento:".draw(at: CGPoint(x: receptorCol3, y: receptorY), withAttributes: grayAttributes)
            
            let documentNumber = (invoice.customer?.hasInvoiceSettings ?? false ) &&
            ((invoice.customer?.nit.isEmpty ?? true) == false ) ?
            invoice.customer?.nit ?? "" : invoice.customer?.nationalId ?? ""
            
            
            (documentNumber).draw(at: CGPoint(x: receptorCol3, y: receptorY + 10), withAttributes: regularAttributes)
            
            "Dirección:".draw(at: CGPoint(x: receptorCol3, y: receptorY + receptorLabelSpacing), withAttributes: grayAttributes)
            SplitText(invoice.customer?.address ?? "", 40).draw(at: CGPoint(x: receptorCol3, y: receptorY + receptorLabelSpacing + 10), withAttributes: regularAttributes)
            
            // Table Header with gray background
            let tableHeaderRect = CGRect(x: 0, y: 295, width: pageWidth, height: 20)
            context.cgContext.setFillColor(darkGray.cgColor)
            context.cgContext.fill(tableHeaderRect)
            
            "CUERPO DEL DOCUMENTO".draw(at: CGPoint(x: pageWidth/2 - 70, y: 302), withAttributes: [
                .font: subtitleFont,
                .foregroundColor: UIColor.white
            ])
            
            // Table Grid
            let tableY: CGFloat = 320
            let columns = ["N°", "Cant.", "Descripción", "Precio\nUnitario", "Descuento\nítem", "Ventas no\nsujetas", "Ventas\nexentas", "Ventas\ngravadas"]
            let columnWidths: [CGFloat] = [25, 35, 220, 60, 60, 60, 60, 60]
            var currentX: CGFloat = 30
            var currentY: CGFloat = tableY
            
            // Draw table header
            for (index, column) in columns.enumerated() {
                column.draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: subtitleAttributes)
                currentX += columnWidths[index]
            }
            
            // Draw items
            currentY = tableY + 25
            for (index, item) in (invoice.items ?? []).enumerated() {
                if index % 2 == 0 {
                    let rowRect = CGRect(x: 0, y: currentY - 3, width: pageWidth, height: 15)
                    context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
                    context.cgContext.fill(rowRect)
                }
                
                currentX = 30
                
                // Draw each column for the item
                "\(index + 1)".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[0]
                
                "\(item.quantity)".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[1]
                
                (item.product?.productName ?? "").draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[2]
                
                
                if(invoice.isCCF){
                    (item.product?.priceWithoutTax ?? 0).formatted(.currency(code: "USD")).draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                    currentX += columnWidths[3]
                }
                else{
                    (item.product?.unitPrice ?? 0).formatted(.currency(code: "USD")).draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                    currentX += columnWidths[3]
                }
                "$0.00".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[4]
                
                "$0.00".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[5]
                
                "$0.00".draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                currentX += columnWidths[6]
                
                item.productTotal.formatted(.currency(code: "USD")).draw(at: CGPoint(x: currentX + 2, y: currentY), withAttributes: regularAttributes)
                
                currentY += 15
            }
            
            // Define smaller font for Resumen section
            let smallerFooterFont = UIFont.systemFont(ofSize: 6.0)
            let smallerFooterAttributes = [NSAttributedString.Key.font: smallerFooterFont]
            
            // Move the tables to the bottom of the page
            let footerY = pageHeight - 165  // Adjusted to move to the bottom
            
            // Draw Extension and Total en Letras table (Left side)
            let leftTableHeaderRect = CGRect(x: 0, y: footerY, width: pageWidth * 0.5, height: 20)
            context.cgContext.setFillColor(darkGray.cgColor)
            context.cgContext.fill(leftTableHeaderRect)
            
            "EXTENSIÓN / TOTAL EN LETRAS".draw(at: CGPoint(x: pageWidth * 0.25 - 60, y: footerY + 3), withAttributes: [
                NSAttributedString.Key.font: subtitleFont,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ])
            
            let leftTableContentRect = CGRect(x: 0, y: footerY + 20, width: pageWidth * 0.5, height: 120)
            context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
            context.cgContext.fill(leftTableContentRect)
            
              currentY = footerY + 20
            let labelX: CGFloat = 10
            let valueX: CGFloat = pageWidth * 0.15
            let rowSpacing: CGFloat = 12
            
            // Extension Rows
            let extensionRows = [
                ("Nombre Entrega:", "-"),
                ("N° Documento:", "-"),
                ("Nombre Recibe:", "-"),
                ("N° Documento:", "-")
            ]
            
            for (label, value) in extensionRows {
                label.draw(at: CGPoint(x: labelX, y: currentY), withAttributes: footerAttributes)
                value.draw(at: CGPoint(x: valueX, y: currentY), withAttributes: footerAttributes)
                currentY += rowSpacing
            }
            
            let total =
            invoice.customer?.hasContributorRetention == true ?
            (invoice.totalAmount.asDoubleRounded - invoice.ivaRete1.asDoubleRounded) :
            invoice.totalAmount.asDoubleRounded
            
            
            // Total en Letras
            "Total en Letras:".draw(at: CGPoint(x: labelX, y: currentY), withAttributes: footerAttributes)
            currentY += rowSpacing
            numberToWords(total).uppercased().draw(at: CGPoint(x: labelX, y: currentY ), withAttributes: smallerFooterAttributes)
            
            // small logo
            let smallLogoRect  = CGRect(x: 3, y: 770, width: 10, height: 13)
            let logoSmall = UIImage(named: "logo")
            logoSmall?.draw(in: smallLogoRect)
            
            "Facturas Simples".draw(at: CGPoint(x: 22, y: 773), withAttributes:  smallerFooterAttributes)
            
            // Draw Resumen table (Right side)
            let rightTableHeaderRect = CGRect(x: pageWidth * 0.5, y: footerY, width: pageWidth * 0.5, height: 20)
            context.cgContext.setFillColor(darkGray.cgColor)
            context.cgContext.fill(rightTableHeaderRect)
            
            "RESUMEN".draw(at: CGPoint(x: pageWidth * 0.75 - 30, y: footerY + 3), withAttributes: [
                NSAttributedString.Key.font: subtitleFont,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ])
            
            let rightTableContentRect = CGRect(x: pageWidth * 0.5, y: footerY + 20, width: pageWidth * 0.5, height: 120)
            context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
            context.cgContext.fill(rightTableContentRect)
            
            currentY = footerY + 25
            let resumenLabelX: CGFloat = pageWidth * 0.5 + 1
            let resumenValueX: CGFloat = pageWidth - 60
            
            // Resumen Rows
            let summaryRows = [
                ("Sumatoria de Ventas", Decimal(total)),
                ("Monto Global de Descuento, Rebajas y Otros a Ventas No Sujetas:", Decimal(0)),
                ("Monto Global de Descuento, Rebajas y Otros a Ventas Exentas:", Decimal(0)),
                ("Monto Global de Descuento, Rebajas y Otros a Ventas Gravadas:", Decimal(0)),
                ("20 - Impuesto al Valor Agregado 13%:",invoice.isCCF ?  invoice.tax : 0),
                ("Sub Total:", invoice.isCCF ? invoice.subTotal: invoice.totalAmount),
                ("(-) IVA Retenido:", invoice.customer?.hasContributorRetention == true ? invoice.ivaRete1 : Decimal(0)),
                ("(-) Retención Renta:", invoice.invoiceType == .SujetoExcluido ? invoice.reteRenta : Decimal(0)),
                ("Monto Total de la Operación:", invoice.totalAmount),
                ("Total Otros Montos No Afectos:", Decimal(0)),
                ("Total a Pagar:",invoice.invoiceType == .SujetoExcluido ? invoice.totalPagar : invoice.totalAmount)
            ]
            
            for (index, (label, amount)) in summaryRows.enumerated() {
                if index % 2 == 0 {
                    let rowRect = CGRect(x: pageWidth * 0.5, y: currentY - 3, width: pageWidth * 0.5, height: rowSpacing)
                     context.cgContext.setFillColor(UIColor(white: 0.98, alpha: 1.0).cgColor)
                    context.cgContext.fill(rowRect)
                }
                
                let _font = summaryRows.count == index - 1 ? footerAttributes : smallerFooterAttributes
                label.draw(at: CGPoint(x: resumenLabelX, y: currentY), withAttributes:  _font)
                amount.formatted(.currency(code: "USD")).draw(at: CGPoint(x: resumenValueX, y: currentY), withAttributes: _font)
                currentY += rowSpacing
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
        //return result.uppercased()
        return SplitText(result.uppercased(),60)
    }
} 
