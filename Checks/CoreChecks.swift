import Foundation
import CoreGraphics

@main
struct CoreChecks {
    static func main() {
        precondition(DocumentRules.filename("  物理作业.PDF  ") == "物理作业")
        precondition(DocumentRules.filename("a/b:c\\d") == "a_b_c_d")
        precondition(DocumentRules.filename("...") == "扫描文档")
        precondition(DocumentRules.filename("\n") == "扫描文档")
        precondition(DocumentRules.turns(-1) == 3)
        precondition(DocumentRules.turns(8) == 0)
        for image in [CGSize(width: 4000, height: 1000), CGSize(width: 1000, height: 4000), CGSize(width: 900, height: 900)] {
            let page = DocumentRules.pageSize(for: image)
            let rect = DocumentRules.fittedRect(image: image, page: page)
            precondition(abs(rect.width / rect.height - image.width / image.height) < 0.001)
            precondition(abs(rect.midX - page.width / 2) < 0.001)
            precondition(abs(rect.midY - page.height / 2) < 0.001)
            precondition(rect.minX >= 17.999 && rect.minY >= 17.999)
            precondition(rect.maxX <= page.width - 17.999 && rect.maxY <= page.height - 17.999)
        }
        precondition(DocumentRules.fittedRect(image: .zero, page: DocumentRules.a4) == .zero)
        print("PASS: filename, rotation, A4 orientation and aspect-fit checks")
    }
}
