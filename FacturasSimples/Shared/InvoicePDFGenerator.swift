import Foundation
import PDFKit
import SwiftUI
import CoreImage.CIFilterBuiltins

class InvoicePDFGenerator {
    static func generatePDF(from invoice: Invoice, company: Company) -> (Data) {
        let fileName = "\(invoice.invoiceType.stringValue())-\(invoice.invoiceNumber).pdf"
        let pdfMetaData = [
            kCGPDFContextCreator: "Facturas Simples",
            kCGPDFContextAuthor: "Kandanga Labs Inc.",
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
            _ = UIFont.boldSystemFont(ofSize: 15.5)
            let subtitleFont = UIFont.boldSystemFont(ofSize: 12.0)
            let regularFont = UIFont.systemFont(ofSize: 10.0)
            let smallFont = UIFont.systemFont(ofSize: 8.0)
            
            // Define colors
            let wineRed = UIColor(red: 0.5, green: 0.0, blue: 0.1, alpha: 1.0)
            
            // Define common attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: wineRed
            ]
            let subtitleAttributes = [NSAttributedString.Key.font: subtitleFont]
            let regularAttributes = [NSAttributedString.Key.font: regularFont]
            let smallerAttributes = [NSAttributedString.Key.font: smallFont]
            
          
            // Header section
            "DOCUMENTO TRIBUTARIO ELECTRÓNICO".draw(at: CGPoint(x: 30, y: 10), withAttributes: titleAttributes)
            company.nombreComercial.uppercased().draw(at: CGPoint(x: 30, y: 25), withAttributes: titleAttributes)
            company.descActividad.uppercased().draw(at: CGPoint(x: 30, y: 40), withAttributes: smallerAttributes)
            
            // Add invoice number and date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.locale = Locale(identifier: "es_ES")
            
            let formattedDate = dateFormatter.string(from: invoice.date)
            "\(invoice.invoiceType.stringValue()) #: \(invoice.invoiceNumber)  \nFecha: \(formattedDate) \n".draw(at: CGPoint(x: 30, y: 55), withAttributes: subtitleAttributes)
            
          
            // Logo placeholder
            let logoRect = CGRect(x: pageWidth - 150, y: 7, width: company.logoWidht, height: company.logoHeight)
            context.cgContext.stroke(logoRect,width: 0)
            
            
             //Draw the logo from base64 string
            if !company.invoiceLogo.isEmpty {
                let imageData = Data(base64Encoded: company.invoiceLogo)!
                    let image = UIImage(data: imageData)!
                    image.draw(in: logoRect)
            }
            else {
                if  let logoImage = UIImage(named: "AppIcon"){
                    logoImage.draw(in: logoRect)
                }
            }
            
            
            let qrRect = CGRect(x: pageWidth - 250, y: 25, width: 60, height: 60)
            context.cgContext.stroke(qrRect,width: 0)
            
            dateFormatter.dateStyle = .short
            let _date = dateFormatter.string(from: invoice.date).replacingOccurrences(of: "/", with: "-")
            let qrUrlFormat = invoice.generationCode != "" ?
            "\(Constants.qrUrlBase)?ambiente=\(Constants.EnvironmentCode)&codGen=\(invoice.generationCode ?? "")&fechaEmi=\(_date)" :
            ""
            
            let QR = generateQRCode(from: qrUrlFormat)
            QR.draw(in: qrRect)
            
            // Document details
            let documentDetails = """
            Código Generación:  \(invoice.generationCode ?? "")
            Número Control:      \(invoice.controlNumber ?? "")
            Sello de recepción:  \(invoice.receptionSeal ?? "")
            """
            documentDetails.draw(at: CGPoint(x: 30, y: 100), withAttributes: regularAttributes)
            
            // Draw separator line
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 30, y: 140))
            path.addLine(to: CGPoint(x: pageWidth - 30, y: 140))
            path.lineWidth = 0.5
            UIColor.gray.setStroke()
            path.stroke()
            
            // Seller information (left column)
            let sellerInfo = """
            EMISOR
            
            Nombre: \(company.nombre)
            NIT: \(company.nit)
            NRC: \(company.nrc)
            Dirección: 
            \(SplitText(company.complemento,45))
            \(company.departamento) \(company.municipio)
            Número de teléfono: \(company.telefono)
            Correo electrónico: \(company.correo)
            Nombre Comercial: \(company.nombreComercial)
            Tipo Establecimiento: \(company.tipoEstablecimiento)
            """
            sellerInfo.draw(at: CGPoint(x: 30, y: 160), withAttributes: regularAttributes)
            
            // Customer information (right column)
            let customerInfo = """
            CLIENTE
            
            Nombre o razón social: 
            \(invoice.customer.company)
            \(invoice.isCCF ? "NRC: \(invoice.customer.nrc ?? "")": "") 
            \(invoice.isCCF ? "NIT": "DUI"): \(invoice.customer.nationalId)
            Correo electrónico: \(invoice.customer.email)
            Nombre Comercial: 
            \(invoice.customer.fullName)
            Dirección: 
            \(SplitText(invoice.customer.address,40))
            \(invoice.customer.departamento) \(invoice.customer.municipio)
            """
            customerInfo.draw(at: CGPoint(x: pageWidth/2 + 30, y: 160), withAttributes: regularAttributes)
            
            // Products table header
            let tableY: CGFloat = 340
            let _: [CGFloat] = [80, 250, 100, 100]
            let colX: [CGFloat] = [30, 110, 380, 515]
            
            // Draw table header background
            let headerHeight: CGFloat = invoice.isCCF ? 45 : 25
            let headerRect = CGRect(x: 30, y: tableY - 5, width: pageWidth - 60, height: headerHeight)
            context.cgContext.setFillColor(wineRed.cgColor)
            context.cgContext.fill(headerRect)
            
            // Draw table header text in white
            let whiteAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.white
            ]
            
            let totalColumnName = invoice.isCCF ? "Ventas\nGravadas" : "Total"
            let priceColumnName = invoice.isCCF ? "Precio\nUnitario" : "Precio"
            ["Cantidad", "Descripción",priceColumnName, totalColumnName].enumerated().forEach { index, title in
                title.draw(at: CGPoint(x: colX[index], y: tableY), withAttributes: whiteAttributes)
            }
            
            // Draw separator line
            let tablePath = UIBezierPath()
            tablePath.move(to: CGPoint(x: 30, y: tableY + headerHeight))
            tablePath.addLine(to: CGPoint(x: pageWidth - 25, y: tableY + headerHeight))
            tablePath.lineWidth = 0.5
            UIColor.gray.setStroke()
            tablePath.stroke()
            
            // Draw products
            
            let lineBreakRatio =  CGFloat(10)
            
            var currentY = tableY + headerHeight + 10
            for item in invoice.items {
                let quantity = "\(item.quantity)"
                let description = item.product.productName
                
                let unitPrice = invoice.isCCF ?
                item.product.priceWithoutTax.formatted(.currency(code: "USD")) :
                                item.product.unitPrice.formatted(.currency(code: "USD"))
                
                let total = invoice.isCCF ?
                item.productTotalWithoutTax.formatted(.currency(code: "USD")):
                item.productTotal.formatted(.currency(code: "USD"))
                
                quantity.draw(at: CGPoint(x: colX[0], y: currentY), withAttributes: regularAttributes)
                description.draw(at: CGPoint(x: colX[1], y: currentY), withAttributes: regularAttributes)
                unitPrice.draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: regularAttributes)
                total.draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: regularAttributes)
                
                currentY += lineBreakRatio
            }
            
            // Draw totals
            _ = pageWidth - 200
            currentY += lineBreakRatio
            
            if invoice.isCCF {
                "Suma Total de Operaciones:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: smallerAttributes)
                "\(invoice.subTotal.formatted(.currency(code: "USD")))"
                    .draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: smallerAttributes)
                
                currentY += lineBreakRatio
                "Total IVA 13%:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: smallerAttributes)
                "\(invoice.tax.formatted(.currency(code: "USD")))"
                    .draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: smallerAttributes)
                
                currentY += lineBreakRatio
                "Sub-total:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: smallerAttributes)
                "\(invoice.subTotal.formatted(.currency(code: "USD")))"
                    .draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: smallerAttributes)
                
                currentY += lineBreakRatio
                "IVA Percibido:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: smallerAttributes)
                "$0.00".draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: smallerAttributes)
                
                currentY += lineBreakRatio
                "IVA Retenido:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: smallerAttributes)
                "$0.00".draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: smallerAttributes)
                
                currentY += lineBreakRatio
                "Retencion Renta:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: smallerAttributes)
                "$0.00".draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: smallerAttributes)
                
                currentY += lineBreakRatio
                "Monto Total Operacion:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: smallerAttributes)
                
                "\(invoice.totalAmount.formatted(.currency(code: "USD")))"
                    .draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: smallerAttributes)
                
                currentY += lineBreakRatio
                "Total Otros Montos no afectos:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: smallerAttributes)
                "$0.00".draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: smallerAttributes)
            }
            
            if !invoice.isCCF {
                currentY += lineBreakRatio
                
                "Subtotal:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: subtitleAttributes)
                "\(invoice.subTotal.formatted(.currency(code: "USD")))"
                    .draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: subtitleAttributes)
                
            }
            currentY += lineBreakRatio
            "Total:".draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: subtitleAttributes)
            "\(invoice.totalAmount.formatted(.currency(code: "USD")))"
                .draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: subtitleAttributes)
            
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
} 
