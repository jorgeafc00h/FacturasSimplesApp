import SwiftUI
import PDFKit

struct InvoicePDFPreview: View {
    let pdfData: Data
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle("Vista Previa PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
//                    ToolbarItem(placement: .topBarLeading) {
//                        Button("Cerrar") {
//                            dismiss()
//                        }
//                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: pdfData, preview: SharePreview("Factura.pdf")) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
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
