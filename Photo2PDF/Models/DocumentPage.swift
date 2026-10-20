import Foundation

struct DocumentPage: Identifiable, Equatable, Sendable {
    let id: UUID
    let imageURL: URL
    let thumbnailURL: URL
    var quarterTurns = 0
}

enum DocumentError: LocalizedError {
    case unreadableImage, noPages, fileWrite, scannerUnavailable

    var errorDescription: String? {
        switch self {
        case .unreadableImage: return String(localized: "无法读取这张图片，请选择已下载到手机的 JPEG、PNG 或 HEIC 照片。")
        case .noPages: return String(localized: "请先添加至少一页。")
        case .fileWrite: return String(localized: "无法写入文件，请检查手机剩余空间后重试。")
        case .scannerUnavailable: return String(localized: "此设备无法使用文档扫描，请改用相册导入。")
        }
    }
}
