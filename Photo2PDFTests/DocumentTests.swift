import PDFKit
import UIKit
import XCTest

@testable import Photo2PDF

final class DocumentTests: XCTestCase {
    func testCreatingAnotherStorePreservesActiveFiles() throws {
        let first = try ImageStore()
        let marker = first.directory.appendingPathComponent("active-page")
        try Data("active".utf8).write(to: marker)
        defer { try? FileManager.default.removeItem(at: first.directory) }
        let second = try ImageStore()
        defer { try? FileManager.default.removeItem(at: second.directory) }
        XCTAssertNotEqual(first.directory, second.directory)
        XCTAssertEqual(try Data(contentsOf: marker), Data("active".utf8))
    }

    @MainActor
    func testExportCleanupFailureIsNotOverwrittenBySuccess() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try ImageStore(root: root)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = DocumentViewModel(store: store)
        try FileManager.default.removeItem(at: store.directory)
        model.exportCompleted(.success(root.appendingPathComponent("saved.pdf")))
        model.previewDismissed()
        XCTAssertEqual(model.message, String(localized: "PDF 已保存，但临时文件清理失败。下次启动时会再次清理。"))
        model.dismissMessage()
        model.previewDismissed()
        XCTAssertNil(model.message)
    }

    @MainActor
    func testOnlyCocoaCancellationIsIgnored() {
        let model = DocumentViewModel()
        model.exportCompleted(.failure(CocoaError(.userCancelled)))
        XCTAssertNil(model.message)
        model.exportCompleted(.failure(NSError(domain: "OtherExporter", code: NSUserCancelledError)))
        XCTAssertNotNil(model.message)
    }

    func testLocalizedResources() throws {
        for (language, scanTitle, defaultName) in [
            ("en", "Scan Documents", "Scanned Document"),
            ("zh-Hans", "拍照扫描", "扫描文档"),
        ] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            XCTAssertEqual(bundle.localizedString(forKey: "拍照扫描", value: nil, table: "Localizable"), scanTitle)
            XCTAssertEqual(bundle.localizedString(forKey: "扫描文档", value: nil, table: "Localizable"), defaultName)
            XCTAssertEqual(
                bundle.localizedString(forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist"), "PDF Camera")
            let format = bundle.localizedString(forKey: "第 %lld 页", value: nil, table: "Localizable")
            XCTAssertEqual(String(format: format, 2), language == "en" ? "Page 2" : "第 2 页")
        }
    }

    @MainActor
    func testRepeatedAlertDismissalDoesNotPublishChanges() {
        let model = DocumentViewModel()
        model.dismissMessage()
        var notifications = 0
        let subscription = model.objectWillChange.sink { notifications += 1 }

        model.dismissMessage()
        XCTAssertEqual(notifications, 0)
        model.message = "请重试"
        model.cameraDenied = true
        model.dismissMessage()
        XCTAssertNil(model.message)
        XCTAssertFalse(model.cameraDenied)
        let afterDismissal = notifications
        model.dismissMessage()
        XCTAssertEqual(notifications, afterDismissal)
        withExtendedLifetime(subscription) {}
    }

    func testChineseAndUnsafeFilenames() {
        XCTAssertEqual(DocumentRules.filename("  物理作业.PDF  "), "物理作业")
        XCTAssertEqual(DocumentRules.filename("a/b:c\\d"), "a_b_c_d")
        XCTAssertEqual(DocumentRules.filename("..."), String(localized: "扫描文档"))
        XCTAssertEqual(DocumentRules.filename("\n"), String(localized: "扫描文档"))
        XCTAssertLessThanOrEqual(DocumentRules.filename(String(repeating: "图", count: 200)).count, 80)
    }

    func testAspectFitAndLandscape() {
        let image = CGSize(width: 4000, height: 1000)
        let page = DocumentRules.pageSize(for: image)
        let rect = DocumentRules.fittedRect(image: image, page: page)
        XCTAssertGreaterThan(page.width, page.height)
        XCTAssertEqual(rect.width / rect.height, 4, accuracy: 0.001)
        XCTAssertEqual(rect.midX, page.width / 2, accuracy: 0.001)
        XCTAssertEqual(rect.midY, page.height / 2, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(rect.minX, 18 - 0.001)
        XCTAssertGreaterThanOrEqual(rect.minY, 18 - 0.001)
        XCTAssertEqual(DocumentRules.fittedRect(image: .zero, page: page), .zero)
        XCTAssertEqual(DocumentRules.turns(-1), 3)
        XCTAssertEqual(DocumentRules.turns(4), 0)
    }

    func testRenderOrderRotationAndInvalidInput() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200), format: format).image { context in
            UIColor.red.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 400, height: 200))
        }
        let source = folder.appendingPathComponent("source.jpg")
        try XCTUnwrap(image.jpegData(compressionQuality: 0.8)).write(to: source)
        let first = DocumentPage(id: UUID(), imageURL: source, thumbnailURL: source)
        var second = first
        second.quarterTurns = 1
        let output = folder.appendingPathComponent("output.pdf")
        var progress: [Double] = []
        // The production callback crosses an executor; this local box only records synchronous calls.
        let recorder = ProgressRecorder()
        try PDFService.generate(pages: [first, second], to: output) { recorder.values.append($0) }
        progress = recorder.values
        let pdf = try XCTUnwrap(PDFDocument(url: output))
        XCTAssertEqual(pdf.pageCount, 2)
        let firstBounds = try XCTUnwrap(pdf.page(at: 0)).bounds(for: .mediaBox)
        let secondBounds = try XCTUnwrap(pdf.page(at: 1)).bounds(for: .mediaBox)
        XCTAssertGreaterThan(firstBounds.width, firstBounds.height)
        XCTAssertLessThan(secondBounds.width, secondBounds.height)
        XCTAssertEqual(progress, [0.5, 1])
        XCTAssertThrowsError(try PDFService.generate(pages: [], to: output) { _ in })
        let invalid = DocumentPage(id: UUID(), imageURL: folder.appendingPathComponent("missing"), thumbnailURL: source)
        let failedOutput = folder.appendingPathComponent("failed.pdf")
        XCTAssertThrowsError(try PDFService.generate(pages: [invalid], to: failedOutput) { _ in })
        XCTAssertFalse(FileManager.default.fileExists(atPath: failedOutput.path))
    }
}

private final class ProgressRecorder: @unchecked Sendable {
    // PDFService invokes callbacks serially on its rendering thread.
    var values: [Double] = []
}
