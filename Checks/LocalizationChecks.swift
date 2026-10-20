import Foundation

@main
struct LocalizationChecks {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        for (language, title, expectedPage) in [
            ("en", "Scan Documents", "Page 2"),
            ("zh-Hans", "拍照扫描", "第 2 页")
        ] {
            guard let bundle = Bundle(path: root.appendingPathComponent("\(language).lproj").path) else {
                fatalError("Missing localization: \(language)")
            }
            precondition(bundle.localizedString(forKey: "拍照扫描", value: nil, table: "Localizable") == title)
            precondition(bundle.localizedString(forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist") == "PDF Camera")
            let format = bundle.localizedString(forKey: "第 %lld 页", value: nil, table: "Localizable")
            precondition(String(format: format, 2) == expectedPage)
            let errorFormat = bundle.localizedString(forKey: "扫描失败：%@", value: nil, table: "Localizable")
            precondition(String(format: errorFormat, "Example").contains("Example"))
            let camera = bundle.localizedString(forKey: "NSCameraUsageDescription", value: nil, table: "InfoPlist")
            precondition(camera.hasPrefix("PDF Camera"))
        }
        print("PASS: English and Chinese resource lookup, display name, camera permission, numbered pages and error interpolation")
    }
}
