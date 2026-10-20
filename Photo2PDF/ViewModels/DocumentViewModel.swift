import AVFoundation
import PhotosUI
import SwiftUI
import VisionKit

@MainActor
final class DocumentViewModel: ObservableObject {
    @Published private(set) var pages: [DocumentPage] = []
    @Published private(set) var busy = false
    @Published private(set) var progress = 0.0
    @Published private(set) var status = ""
    @Published var message: String?
    @Published var cameraDenied = false
    @Published var showScanner = false
    @Published var showPreview = false
    @Published private(set) var pdfURL: URL?
    @Published var filename =
        String(localized: "扫描文档") + "_"
        + Date.now.formatted(.dateTime.year().month().day()).replacingOccurrences(of: "/", with: "-")
    private let store: ImageStore?
    private var savedNotice: String?
    private var requestingCamera = false

    init(store: ImageStore? = nil) {
        do {
            self.store = try store ?? ImageStore()
        } catch {
            self.store = nil
            message = String(localized: "无法创建临时目录：\(error.localizedDescription)")
        }
    }

    var canGenerate: Bool { !pages.isEmpty && !busy && store != nil }

    func openScanner() {
        guard !busy, !requestingCamera, !showScanner else { return }
        guard VNDocumentCameraViewController.isSupported else {
            message = DocumentError.scannerUnavailable.localizedDescription
            return
        }
        requestingCamera = true
        Task {
            defer { requestingCamera = false }
            let allowed = await AVCaptureDevice.requestAccess(for: .video)
            if allowed {
                showScanner = true
            } else {
                cameraDenied = true
                message = String(localized: "请在系统设置中允许 PDF Camera 使用相机，或使用相册导入。")
            }
        }
    }

    func importPhotos(_ items: [PhotosPickerItem]) async {
        let failed = await importPages(count: items.count, status: String(localized: "正在导入照片")) { index in
            guard let data = try await items[index].loadTransferable(type: Data.self) else {
                throw DocumentError.unreadableImage
            }
            return data
        }
        if failed > 0 {
            message = String(localized: "有 \(failed) 张照片无法导入，其他照片已保留。请确认原图已下载到手机且格式受支持，然后重试。")
        }
    }

    func importScan(_ scan: VNDocumentCameraScan) async {
        let failed = await importPages(count: scan.pageCount, status: String(localized: "正在导入扫描页")) { index in
            guard
                let data = autoreleasepool(invoking: {
                    scan.imageOfPage(at: index).jpegData(compressionQuality: 0.95)
                })
            else { throw DocumentError.unreadableImage }
            return data
        }
        if failed > 0 {
            message = String(localized: "有 \(failed) 页无法导入，请检查手机剩余空间后重新扫描。其他页面已保留。")
        }
    }

    // Load, save and release one page before requesting the next one.
    private func importPages(
        count: Int, status: String,
        loadData: (Int) async throws -> Data
    ) async -> Int {
        guard count > 0, !busy, let store else { return 0 }
        beginProcessing(status)
        defer { busy = false }
        var failed = 0
        for index in 0..<count {
            do {
                let data = try await loadData(index)
                let page = try await Task.detached(priority: .userInitiated) {
                    try store.importData(data)
                }.value
                pages.append(page)
            } catch { failed += 1 }
            progress = Double(index + 1) / Double(count)
        }
        invalidatePDF()
        return failed
    }

    func move(from source: IndexSet, to destination: Int) {
        guard !busy else { return }
        pages.move(fromOffsets: source, toOffset: destination)
        invalidatePDF()
    }

    func movePage(id: UUID, before target: UUID) {
        guard !busy, id != target,
            let from = pages.firstIndex(where: { $0.id == id }),
            let to = pages.firstIndex(where: { $0.id == target })
        else { return }
        move(from: IndexSet(integer: from), to: from < to ? to + 1 : to)
    }

    func rotate(_ id: UUID, by turns: Int) {
        guard !busy, let index = pages.firstIndex(where: { $0.id == id }) else { return }
        pages[index].quarterTurns = DocumentRules.turns(pages[index].quarterTurns + turns)
        invalidatePDF()
    }

    func resetRotation(_ id: UUID) {
        guard !busy, let index = pages.firstIndex(where: { $0.id == id }) else { return }
        pages[index].quarterTurns = 0
        invalidatePDF()
    }

    func remove(_ id: UUID) {
        guard let index = pages.firstIndex(where: { $0.id == id }) else { return }
        remove(at: IndexSet(integer: index))
    }

    func remove(at offsets: IndexSet) {
        guard !busy else { return }
        let validOffsets = offsets.filter { pages.indices.contains($0) }
        guard !validOffsets.isEmpty else { return }
        for index in validOffsets { store?.remove(pages[index]) }
        pages.remove(atOffsets: IndexSet(validOffsets))
        invalidatePDF()
    }

    func generate() async {
        guard canGenerate, let store else { return }
        beginProcessing(String(localized: "正在生成 PDF"))
        defer { busy = false }
        invalidatePDF()
        let snapshot = pages
        let target = store.directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        do {
            try await Task.detached(priority: .userInitiated) {
                try PDFService.generate(pages: snapshot, to: target) { value in
                    Task { @MainActor in self.progress = value }
                }
            }.value
            pdfURL = target
            showPreview = true
        } catch {
            message = String(localized: "生成失败，页面已保留，请重试。\n\(error.localizedDescription)")
        }
    }

    func exportCompleted(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            savedNotice = String(localized: "PDF 已保存到你选择的位置，可在「文件」App 中打开。")
            showPreview = false
            pages = []
            pdfURL = nil
            do { try store?.removeAll() } catch { savedNotice = String(localized: "PDF 已保存，但临时文件清理失败。下次启动时会再次清理。") }
        case .failure(let error):
            // Some system versions report cancellation as Cocoa's userCancelled error.
            let error = error as NSError
            if error.domain == NSCocoaErrorDomain, error.code == NSUserCancelledError { return }
            message = String(localized: "保存失败，文件已保留，可再次保存。\n\(error.localizedDescription)")
        }
    }

    func previewDismissed() {
        if let savedNotice {
            self.savedNotice = nil
            message = savedNotice
        }
    }

    func dismissMessage() {
        // SwiftUI may dismiss an already-hidden alert during a presentation update.
        if message != nil { message = nil }
        if cameraDenied { cameraDenied = false }
    }

    func clear() {
        guard !busy else { return }
        do {
            try store?.removeAll()
            pages = []
            pdfURL = nil
        } catch { message = String(localized: "清理失败，请重试：\(error.localizedDescription)") }
    }

    private func beginProcessing(_ status: String) {
        busy = true
        progress = 0
        self.status = status
    }

    private func invalidatePDF() {
        if let pdfURL { try? FileManager.default.removeItem(at: pdfURL) }
        pdfURL = nil
    }
}
