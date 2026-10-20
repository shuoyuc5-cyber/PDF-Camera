import CoreGraphics
import Foundation

// Shared by the renderer and its tests; PDF coordinates use points (72 per inch).
enum DocumentRules {
    static let a4 = CGSize(width: 595.276, height: 841.89)

    static func filename(_ input: String) -> String {
        var name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.lowercased().hasSuffix(".pdf") { name.removeLast(4) }
        let forbidden = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: "/\\:"))
        name = name.components(separatedBy: forbidden).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty || name.allSatisfy({ $0 == "." }) {
            name = NSLocalizedString("扫描文档", comment: "Default PDF filename")
        }
        return String(name.prefix(80))
    }

    static func pageSize(for image: CGSize) -> CGSize {
        image.width > image.height ? CGSize(width: a4.height, height: a4.width) : a4
    }

    static func fittedRect(image: CGSize, page: CGSize, margin: CGFloat = 18) -> CGRect {
        guard image.width > 0, image.height > 0 else { return .zero }
        let scale = min(
            (page.width - margin * 2) / image.width,
            (page.height - margin * 2) / image.height)
        let size = CGSize(width: image.width * scale, height: image.height * scale)
        return CGRect(
            x: (page.width - size.width) / 2, y: (page.height - size.height) / 2,
            width: size.width, height: size.height)
    }

    static func turns(_ value: Int) -> Int { (value % 4 + 4) % 4 }
}
