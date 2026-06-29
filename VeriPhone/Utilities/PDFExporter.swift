import SwiftUI
import UIKit

/// Renderiza una vista SwiftUI a PDF usando `ImageRenderer` + `UIGraphicsPDFRenderer`.
@MainActor
enum PDFExporter {

    static func renderPDF<V: View>(from view: V, pageSize: CGSize = CGSize(width: 612, height: 792)) -> URL? {
        let renderer = ImageRenderer(content: view.frame(width: pageSize.width))
        renderer.scale = UIScreen.main.scale

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VeriPhone-Informe-\(UUID().uuidString).pdf")

        var success = false
        renderer.render { size, context in
            var mediaBox = CGRect(origin: .zero, size: CGSize(width: pageSize.width, height: max(size.height, pageSize.height)))
            guard let consumer = CGDataConsumer(url: url as CFURL),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
            success = true
        }
        return success ? url : nil
    }
}
