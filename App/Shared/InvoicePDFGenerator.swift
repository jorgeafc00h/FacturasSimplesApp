import Foundation
import PDFKit
import SwiftUI

class InvoicePDFGenerator {
    static func generatePDF(from invoice: Invoice, emisor: Emisor) -> (Data) {
        let fileName = "Factura-\(invoice.invoiceNumber).pdf"
        let pdfMetaData = [
            kCGPDFContextCreator: "Facturas Simples",
            kCGPDFContextAuthor: "Generated Kandanga Labs Inc.",
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
            let titleFont = UIFont.boldSystemFont(ofSize: 16.0)
            let subtitleFont = UIFont.boldSystemFont(ofSize: 14.0)
            let regularFont = UIFont.systemFont(ofSize: 12.0)
            let smallFont = UIFont.systemFont(ofSize: 10.0)
            
            // Define colors
            let wineRed = UIColor(red: 0.5, green: 0.0, blue: 0.1, alpha: 1.0)
            
            // Define common attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: wineRed
            ]
            let subtitleAttributes = [NSAttributedString.Key.font: subtitleFont]
            let regularAttributes = [NSAttributedString.Key.font: regularFont]
            _ = [NSAttributedString.Key.font: smallFont]
            
            // Header section
            "DOCUMENTO TRIBUTARIO ELECTRÓNICO".draw(at: CGPoint(x: 30, y: 30), withAttributes: titleAttributes)
            
            // Add invoice number and date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let formattedDate = dateFormatter.string(from: invoice.date)
            "Factura #: \(invoice.invoiceNumber)        - Fecha: \(formattedDate)".draw(at: CGPoint(x: 30, y: 50), withAttributes: subtitleAttributes)
             
            
            // Logo placeholder
            let logoRect = CGRect(x: pageWidth - 150, y: 30, width: 100, height: 60)
            context.cgContext.stroke(logoRect)
            "".draw(at: CGPoint(x: pageWidth - 130, y: 50), withAttributes: regularAttributes)
            
            // Document details
            let documentDetails = """
            Código Generación: \(invoice.generationCode ?? "")
            Número Control: \(invoice.controlNumber ?? "")
            Sello de recepción: \(invoice.receptionSeal ?? "")
            """
            documentDetails.draw(at: CGPoint(x: 30, y: 80), withAttributes: regularAttributes)
            
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
            
            Nombre: \(emisor.nombre)
            NIT: \(emisor.nit)
            NRC: \(emisor.nrc)
            Dirección: \(SplitText(emisor.complemento,35))
            \(emisor.departamento) \(emisor.municipio)
            Número de teléfono: \(emisor.telefono)
            Correo electrónico: \(emisor.correo)
            Nombre Comercial: \(emisor.nombreComercial)
            Tipo Establecimiento: \(emisor.tipoEstablecimiento)
            """
            sellerInfo.draw(at: CGPoint(x: 30, y: 160), withAttributes: regularAttributes)
            
            // Customer information (right column)
            let customerInfo = """
            CLIENTE
            
            Nombre o razón social: \(invoice.customer.company)
            DUI: \(invoice.customer.nationalId)
            Correo electrónico: \(invoice.customer.email)
            Nombre Comercial: \(invoice.customer.fullName)
            Dirección: 
            \(SplitText(invoice.customer.address,40))
            \(invoice.customer.departamento) \(invoice.customer.municipio)
            """
            customerInfo.draw(at: CGPoint(x: pageWidth/2 + 30, y: 160), withAttributes: regularAttributes)
            
            // Products table header
            let tableY: CGFloat = 350
            let _: [CGFloat] = [80, 250, 100, 100]
            let colX: [CGFloat] = [30, 110, 360, 460]
            
            // Draw table header background
            let headerHeight: CGFloat = 25
            let headerRect = CGRect(x: 30, y: tableY - 5, width: pageWidth - 60, height: headerHeight)
            context.cgContext.setFillColor(wineRed.cgColor)
            context.cgContext.fill(headerRect)
            
            // Draw table header text in white
            let whiteAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.white
            ]
            
            ["Cantidad", "Descripción", "Precio Unit.", "Total"].enumerated().forEach { index, title in
                title.draw(at: CGPoint(x: colX[index], y: tableY), withAttributes: whiteAttributes)
            }
            
            // Draw separator line
            let tablePath = UIBezierPath()
            tablePath.move(to: CGPoint(x: 30, y: tableY + headerHeight))
            tablePath.addLine(to: CGPoint(x: pageWidth - 30, y: tableY + headerHeight))
            tablePath.lineWidth = 0.5
            UIColor.gray.setStroke()
            tablePath.stroke()
            
            // Draw products
            var currentY = tableY + headerHeight + 10
            for item in invoice.items {
                let quantity = "\(item.quantity)"
                let description = item.product.productName
                let unitPrice = item.product.unitPrice.formatted(.currency(code: "USD"))
                let total = item.productTotal.formatted(.currency(code: "USD"))
                
                quantity.draw(at: CGPoint(x: colX[0], y: currentY), withAttributes: regularAttributes)
                description.draw(at: CGPoint(x: colX[1], y: currentY), withAttributes: regularAttributes)
                unitPrice.draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: regularAttributes)
                total.draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: regularAttributes)
                
                currentY += 20
            }
            
            // Draw totals
            currentY += 20
            let totalsX = pageWidth - 200
            "Subtotal: \(invoice.subTotal.formatted(.currency(code: "USD")))".draw(
                at: CGPoint(x: totalsX, y: currentY),
                withAttributes: subtitleAttributes
            )
            
            currentY += 20
            "Total: \(invoice.totalAmount.formatted(.currency(code: "USD")))".draw(
                at: CGPoint(x: totalsX, y: currentY),
                withAttributes: titleAttributes
            )
        }
        
        return data
    }
    private static func SplitText(_ text: String, _ maxLength: Int) -> String {
        return text.count >= maxLength ?
        "\(String(text.prefix(maxLength)))...\n\(String(text.suffix(text.count-maxLength)))":
        text
    }
    
    
    static func generateAndSavePDF(from invoice: Invoice,emisor: Emisor) throws -> URL {
        // Generate the PDF data
        let pdfData = generatePDF(from: invoice, emisor: emisor)
        
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
    
    static func cleanupTemporaryPDF(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
} 
