# Privacy / 隐私说明

## English

PDF Camera has no backend, login, analytics SDK, advertising SDK, or application network request code. Image processing and PDF generation run on the device. The PDF renderer draws the selected images without a watermark or branding overlay.

- **Camera:** requested when starting a scan, for document capture.
- **Photos:** accessed through Apple's system picker for user-selected images; the app does not request full-library authorization.
- **Temporary storage:** source images, thumbnails and intermediate PDFs use local temporary storage. Images and PDFs are marked with iOS complete file protection; session directories are excluded from backup. Protection depends on the device and operating system.
- **Cleanup:** after successful export or discarding, and for interrupted-session leftovers on the next process launch. The operating system can also purge temporary files. Unsaved drafts are not durable storage.
- **Exports:** the app hands the PDF to the system export interface. The destination and any sharing or synchronization are controlled by the user and file provider. Exported PDFs are not automatically deleted by the app.
- **System/cloud boundaries:** iCloud-only photos may download in Apple's picker. Saving to a cloud provider may cause that provider to transfer the file. Signing and developer certificate verification can require an Internet connection.

These are source-level design statements, not an independent security audit or a guarantee against compromised devices. No password protection, end-to-end encryption service, or PDF encryption feature is claimed.

## 中文

PDF Camera 没有后端、账号登录、统计 SDK、广告 SDK 或主动网络请求代码。图片处理和 PDF 生成在本机进行；PDF 渲染器只绘制所选图片，不叠加水印或品牌标识。

- **相机：** 仅在开始扫描时申请，用于拍摄文档。
- **相册：** 使用系统照片选择器读取用户选中的图片，不申请整个相册访问权限。
- **临时存储：** 原图、缩略图及中间 PDF 存放在本地临时目录。图片与 PDF 使用 iOS 完全文件保护，会话目录排除备份；实际保护由设备与系统提供。
- **清理：** 保存成功或放弃文档后清理；异常退出的遗留内容在下一次进程启动时清理。系统也可能回收临时文件，因此草稿不是持久存储。
- **导出：** PDF 交由系统保存界面处理。目标位置、分享和同步由用户与文件提供商决定；应用不会自动删除已导出的 PDF。
- **系统与云服务边界：** 仅存在 iCloud 的照片可能由系统选择器下载；保存到云盘可能触发相应服务上传；签名和开发者证书验证可能需要联网。

上述内容是基于源码的设计说明，不是独立安全审计或对被攻破设备的保证。应用未宣称具备密码保护、端到端加密服务或 PDF 加密功能。
