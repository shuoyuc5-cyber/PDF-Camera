import PDFKit
import SwiftUI

struct PDFPreviewView: View {
    @ObservedObject var model: DocumentViewModel
    let url: URL
    @State private var exporting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFViewer(url: url)
                .navigationTitle("PDF 预览")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("返回编辑") { dismiss() } }
                    ToolbarItem(placement: .primaryAction) {
                        Button("保存到文件") { exporting = true }.fontWeight(.semibold)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Text("选择「我的 iPhone」中的文件夹即可离线保存。")
                        .font(.footnote).foregroundStyle(.secondary).padding()
                        .frame(maxWidth: .infinity).background(.bar)
                }
                .fileExporter(
                    isPresented: $exporting, document: PDFExportDocument(url: url),
                    contentType: .pdf, defaultFilename: DocumentRules.filename(model.filename)
                ) {
                    model.exportCompleted($0)
                }
                .documentMessageAlert(model: model, title: "保存提示")
        }
    }
}

private struct PDFViewer: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = PDFDocument(url: url)
        return view
    }
    func updateUIView(_ view: PDFView, context: Context) {}
}

// Presentation callbacks may run during a view update; defer observable mutations.
private struct DocumentMessageAlert: ViewModifier {
    @ObservedObject var model: DocumentViewModel
    let title: LocalizedStringKey
    let enabled: Bool

    func body(content: Content) -> some View {
        content.alert(
            title,
            isPresented: Binding(
                get: { enabled && model.message != nil },
                set: { presented in
                    guard !presented, let dismissedMessage = model.message else { return }
                    Task { @MainActor in
                        guard model.message == dismissedMessage else { return }
                        model.dismissMessage()
                    }
                }
            )
        ) {
            if model.cameraDenied {
                Button("打开设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("好", role: .cancel) { model.dismissMessage() }
        } message: {
            Text(model.message ?? "")
        }
    }
}

extension View {
    func documentMessageAlert(
        model: DocumentViewModel, title: LocalizedStringKey,
        enabled: Bool = true
    ) -> some View {
        modifier(DocumentMessageAlert(model: model, title: title, enabled: enabled))
    }
}
