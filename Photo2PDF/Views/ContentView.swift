import PhotosUI
import SwiftUI

struct ContentView: View {
    @StateObject private var model = DocumentViewModel()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showInfo = false
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Group {
                if model.pages.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .disabled(model.busy)
            .navigationTitle("PDF Camera")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !model.pages.isEmpty { EditButton().disabled(model.busy) }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("使用说明", systemImage: "info.circle") { showInfo = true }.disabled(model.busy)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !model.pages.isEmpty {
                    Button {
                        Task { await model.generate() }
                    } label: {
                        Label("生成并预览 PDF", systemImage: "doc.richtext")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.buttonStyle(.borderedProminent).disabled(!model.canGenerate)
                        .padding().background(.bar)
                }
            }
            .overlay { processingOverlay }
            .fullScreenCover(isPresented: $model.showScanner) {
                ScannerView { scan in
                    model.showScanner = false
                    Task { await model.importScan(scan) }
                } onCancel: {
                    model.showScanner = false
                } onError: { error in
                    model.showScanner = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(400))
                        model.message = String(localized: "扫描失败：\(error.localizedDescription)")
                    }
                }.ignoresSafeArea()
            }
            .sheet(isPresented: $model.showPreview, onDismiss: model.previewDismissed) {
                if let url = model.pdfURL { PDFPreviewView(model: model, url: url) }
            }
            .sheet(isPresented: $showInfo) { infoView }
            .confirmationDialog("放弃当前文档？未保存的页面将被删除。", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("放弃并清理", role: .destructive) { model.clear() }
            }
            .documentMessageAlert(model: model, title: "提示", enabled: !model.showPreview)
            .onChange(of: selectedPhotos) { _, items in
                guard !items.isEmpty else { return }
                selectedPhotos = []
                Task { await model.importPhotos(items) }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.viewfinder").font(.system(size: 76)).foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("快速创建 PDF").font(.largeTitle.bold())
            Text("扫描试卷、文档和笔记\n或将手机照片合并为 PDF")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            VStack(spacing: 14) {
                Button {
                    model.openScanner()
                } label: {
                    Label("拍照扫描", systemImage: "camera.viewfinder").frame(maxWidth: .infinity).padding(.vertical, 10)
                }.buttonStyle(.borderedProminent)
                photoPicker.buttonStyle(.bordered)
            }.controlSize(.large)
            Spacer()
            Text("免费 · 离线 · 照片留在手机上").font(.footnote).foregroundStyle(.secondary)
        }.padding(28)
    }

    private var documentList: some View {
        List {
            Section {
                ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                    pageRow(index: index, page: page)
                }
                .onMove { model.move(from: $0, to: $1) }
                .onDelete { model.remove(at: $0) }
            } header: {
                Text("共 \(model.pages.count) 页")
            } footer: {
                Text("长按拖动调整顺序，或点击右上角「编辑」排序。")
            }
            Section("继续添加") {
                Button {
                    model.openScanner()
                } label: {
                    Label("拍照扫描", systemImage: "camera.viewfinder")
                }
                photoPicker
            }
            Section("PDF 设置") {
                TextField("文件名", text: $model.filename).submitLabel(.done)
                LabeledContent("纸张") { Text("A4 · 自动横竖方向") }
                Text("每张图片一页，完整显示，四周留白。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Button("放弃当前文档", role: .destructive) { confirmClear = true }
            }
        }
    }

    @ViewBuilder
    private var processingOverlay: some View {
        if model.busy {
            ZStack {
                Color.black.opacity(0.18).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView(value: model.progress)
                    Text(model.status).font(.headline)
                    Text("\(Int(model.progress * 100))%").monospacedDigit().foregroundStyle(.secondary)
                }.padding(28).frame(maxWidth: 290).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            }.accessibilityElement(children: .combine)
        }
    }

    private func pageRow(index: Int, page: DocumentPage) -> some View {
        NavigationLink {
            PageEditorView(model: model, id: page.id)
        } label: {
            HStack(spacing: 16) {
                PageThumbnail(page: page)
                VStack(alignment: .leading, spacing: 5) {
                    Text("第 \(index + 1) 页").font(.headline)
                    Text("点击旋转或查看").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(.vertical, 4)
        }
        .draggable(page.id.uuidString)
        .dropDestination(for: String.self) { values, _ in
            guard let value = values.first, let id = UUID(uuidString: value) else { return false }
            model.movePage(id: id, before: page.id)
            return true
        }
        .contextMenu {
            Button("顺时针旋转", systemImage: "rotate.right") { model.rotate(page.id, by: 1) }
            Button("删除页面", systemImage: "trash", role: .destructive) { model.remove(page.id) }
        }
        .accessibilityAction(named: "上移") {
            if index > 0 { model.move(from: IndexSet(integer: index), to: index - 1) }
        }
        .accessibilityAction(named: "下移") {
            if index + 1 < model.pages.count { model.move(from: IndexSet(integer: index), to: index + 2) }
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhotos, selectionBehavior: .ordered, matching: .images) {
            Label("从相册导入", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var infoView: some View {
        NavigationStack {
            List {
                Section("如何使用") {
                    Text("扫描或选择照片 → 排序与旋转 → 输入文件名 → 生成预览 → 保存到文件。")
                    Text("拍照扫描时，可在系统扫描界面中调整边缘和文档四角。")
                }
                Section("本地处理") {
                    Text("图片和 PDF 在手机上处理，不上传、不登录、没有广告或统计服务。")
                    Text("离线导入需要照片原图已在手机上。保存时选择「我的 iPhone」即可本地保存。")
                    Text("当前编辑内容仅供本次使用，退出后不保证恢复。保存成功或放弃后会清理临时文件；异常退出留下的临时文件会在下次启动时清理。")
                }
                Section("第一版") { Text("支持多页扫描、相册导入、排序、旋转、A4 PDF 预览与导出。") }
            }.navigationTitle("使用说明").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showInfo = false } } }
        }
    }
}

private struct PageThumbnail: View {
    let page: DocumentPage
    var body: some View {
        Group {
            if let image = UIImage(contentsOfFile: page.thumbnailURL.path) {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(width: 58, height: 58).rotationEffect(.degrees(Double(page.quarterTurns) * 90))
            } else {
                Image(systemName: "photo").frame(width: 58, height: 58)
            }
        }.frame(width: 64, height: 70).background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6)).accessibilityHidden(true)
    }
}
