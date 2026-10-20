import SwiftUI

struct PageEditorView: View {
    @ObservedObject var model: DocumentViewModel
    let id: UUID
    @State private var image: UIImage?
    @State private var loadError: String?
    @State private var confirmDelete = false
    @Environment(\.dismiss) private var dismiss
    private var page: DocumentPage? { model.pages.first { $0.id == id } }

    var body: some View {
        VStack(spacing: 24) {
            GeometryReader { proxy in
                if let image, let page {
                    let size =
                        page.quarterTurns % 2 == 0
                        ? image.size : CGSize(width: image.size.height, height: image.size.width)
                    let scale = min(proxy.size.width / size.width, proxy.size.height / size.height)
                    Image(uiImage: image).resizable()
                        .frame(width: image.size.width * scale, height: image.size.height * scale)
                        .rotationEffect(.degrees(Double(page.quarterTurns) * 90))
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        .accessibilityLabel("当前页面预览")
                } else if let loadError {
                    ContentUnavailableView("无法显示图片", systemImage: "photo", description: Text(loadError))
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            HStack(spacing: 12) {
                Button {
                    model.rotate(id, by: -1)
                } label: {
                    Label("左转", systemImage: "rotate.left")
                }
                Button {
                    model.rotate(id, by: 1)
                } label: {
                    Label("右转", systemImage: "rotate.right")
                }
                Button("恢复") { model.resetRotation(id) }
            }.buttonStyle(.bordered).controlSize(.small)
            Text("扫描时可在系统相机中调整文档四角。")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding().navigationTitle("编辑页面").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("删除", systemImage: "trash", role: .destructive) { confirmDelete = true }
            }
        }
        .confirmationDialog("删除这一页？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除页面", role: .destructive) {
                model.remove(id)
                dismiss()
            }
        }
        .task {
            guard let page else { return }
            do {
                image = try await Task.detached(priority: .userInitiated) {
                    try ImageStore.load(page.imageURL, maxPixelSize: 1600)
                }.value
            } catch { loadError = error.localizedDescription }
        }
    }
}
