# Validation / 验证记录

**2026-10-20 · iPhone 17 Simulator · Xcode 27.1**

The current code passed its simulator build and all eight XCTest tests:

1. Creating another image store preserves active-session files.
2. Export cleanup failure notices survive preview dismissal.
3. Only Cocoa user-cancellation errors are ignored.
4. English and Simplified Chinese resources resolve correctly.
5. Repeated alert dismissal does not publish redundant state changes.
6. Chinese and unsafe filenames are handled correctly.
7. A4 layout preserves proportions, margins, centering and orientation.
8. PDF rendering checks page count, ordered orientations, rotation and failed-output cleanup.

An earlier build launched on a physical iPhone. Full physical-device camera/export acceptance, complete flight-mode acceptance, system appearance switching and large high-resolution batches remain to be verified. Simulator tests do not establish camera behavior or a measured performance/security guarantee.

当前代码通过模拟器编译和全部 8 项自动测试，覆盖临时目录隔离、保存提示、取消操作、本地化、提示框状态、文件名、A4 排版及 PDF 渲染。较早版本已在真实 iPhone 启动；完整真机扫描与导出、飞行模式、系统外观切换和大批量高清照片仍待验收。

Run / 运行：打开 `Photo2PDF.xcodeproj`，选择可用 iPhone 模拟器，按 **⌘U**。
