import UIKit

// Sequential rendering keeps memory proportional to one page, rather than the page count.
enum PDFService {
    static func generate(
        pages: [DocumentPage], to url: URL,
        progress: @Sendable (Double) -> Void
    ) throws {
        guard !pages.isEmpty else { throw DocumentError.noPages }
        var completed = false
        defer { if !completed { try? FileManager.default.removeItem(at: url) } }
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator as String: "PDF Camera"]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: DocumentRules.a4), format: format)
        var renderingError: Error?
        try renderer.writePDF(to: url) { context in
            for (index, page) in pages.enumerated() {
                do {
                    try Task.checkCancellation()
                    try autoreleasepool {
                        let original = try ImageStore.load(page.imageURL, maxPixelSize: 3508)
                        let image = ImageStore.rotated(original, turns: page.quarterTurns)
                        let size = DocumentRules.pageSize(for: image.size)
                        let bounds = CGRect(origin: .zero, size: size)
                        context.beginPage(withBounds: bounds, pageInfo: [:])
                        UIColor.white.setFill()
                        context.cgContext.fill(bounds)
                        image.draw(in: DocumentRules.fittedRect(image: image.size, page: size))
                    }
                    progress(Double(index + 1) / Double(pages.count))
                } catch {
                    renderingError = error
                    break
                }
            }
        }
        if let renderingError { throw renderingError }
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        completed = true
    }
}
