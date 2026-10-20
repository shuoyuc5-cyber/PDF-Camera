import ImageIO
import UIKit

struct ImageStore: Sendable {
    let directory: URL

    private static let sessionRoot: Result<URL, Error> = Result {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("Photo2PDF", isDirectory: true)
        // Run once per process so a second store cannot delete an active session.
        if FileManager.default.fileExists(atPath: root.path) {
            try FileManager.default.removeItem(at: root)
        }
        return root
    }

    init(root: URL? = nil) throws {
        let root = try root ?? Self.sessionRoot.get()
        directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var excluded = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try excluded.setResourceValues(values)
    }

    func importData(_ data: Data) throws -> DocumentPage {
        let id = UUID()
        let original = directory.appendingPathComponent("\(id).image")
        let thumbnail = directory.appendingPathComponent("\(id)-thumb.jpg")
        do {
            try data.write(to: original, options: [.atomic, .completeFileProtection])
            let image = try Self.load(original, maxPixelSize: 360)
            guard let preview = image.jpegData(compressionQuality: 0.8) else {
                throw DocumentError.unreadableImage
            }
            try preview.write(to: thumbnail, options: [.atomic, .completeFileProtection])
            return DocumentPage(id: id, imageURL: original, thumbnailURL: thumbnail)
        } catch {
            try? FileManager.default.removeItem(at: original)
            try? FileManager.default.removeItem(at: thumbnail)
            throw error
        }
    }

    static func load(_ url: URL, maxPixelSize: Int) throws -> UIImage {
        guard
            let source = CGImageSourceCreateWithURL(
                url as CFURL,
                [kCGImageSourceShouldCache: false] as CFDictionary),
            let cgImage = CGImageSourceCreateThumbnailAtIndex(
                source, 0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                    kCGImageSourceShouldCacheImmediately: true,
                ] as CFDictionary)
        else { throw DocumentError.unreadableImage }
        return UIImage(cgImage: cgImage)
    }

    static func rotated(_ image: UIImage, turns: Int) -> UIImage {
        let turns = DocumentRules.turns(turns)
        guard turns != 0 else { return image }
        let sideways = turns % 2 == 1
        let size = sideways ? CGSize(width: image.size.height, height: image.size.width) : image.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            context.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
            context.cgContext.rotate(by: CGFloat(turns) * .pi / 2)
            image.draw(
                in: CGRect(
                    x: -image.size.width / 2, y: -image.size.height / 2,
                    width: image.size.width, height: image.size.height))
        }
    }

    func remove(_ page: DocumentPage) {
        try? FileManager.default.removeItem(at: page.imageURL)
        try? FileManager.default.removeItem(at: page.thumbnailURL)
    }

    func removeAll() throws {
        for url in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
