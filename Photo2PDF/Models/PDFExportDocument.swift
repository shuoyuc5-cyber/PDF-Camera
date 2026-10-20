import SwiftUI
import UniformTypeIdentifiers

struct PDFExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    let url: URL

    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Keep the temporary source until the system reports successful export.
        FileWrapper(regularFileWithContents: try Data(contentsOf: url, options: .mappedIfSafe))
    }
}
