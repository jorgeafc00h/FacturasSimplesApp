import SwiftUI
import PDFKit

struct InvoicePDFPreview: View {
    let pdfData: Data
    let invoice: Invoice
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle("Vista Previa PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    SharePDFSheet(
                        activityItems: [pdfData],
                        invoice: invoice
                    )
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

struct SharePDFSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let invoice: Invoice
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Factura-\(invoice.invoiceNumber).pdf")
        try? (activityItems.first as? Data)?.write(to: tempURL)
        
        let controller = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        controller.title = "Factura \(invoice.invoiceNumber)"
        
        controller.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
