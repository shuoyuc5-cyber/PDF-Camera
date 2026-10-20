# PDF Camera

**Free · Offline · Privacy-first · No watermarks**

A native iPhone document scanner that turns paper and photos into clean PDFs. Scan homework, notes, receipts, or documents; arrange the pages; then save your PDF directly to Files.

**[中文介绍](README.zh-CN.md)** · [Privacy](PRIVACY.md) · [Validation](VALIDATION.md) · [MIT License](LICENSE)

## Why PDF Camera?

| | What you get |
|---|---|
| **Free** | No subscription, paid conversion service, ads, or in-app purchases. MIT-licensed source code. |
| **Offline** | Scan, edit, preview, and generate PDFs on your device. Save to **On My iPhone** without a server. |
| **Privacy-first** | No accounts, analytics SDKs, image uploads, or PDF uploads. Temporary images use iOS file protection and are excluded from backup. |
| **No watermarks** | Your PDF contains your pages. No app logo, branding overlay, or watermark is drawn onto them. |

## Features

- Multi-page document scanning with Apple's native scanner, including edge detection and perspective adjustment during capture.
- Import JPEG, PNG, HEIC, and other static images supported by iOS, in selection order.
- Combine scans and photos in one document; add, reorder, rotate, reset rotation, and delete pages.
- A4 PDFs with automatic portrait/landscape orientation, preserved proportions, and margins.
- PDF preview, custom filenames, progress feedback, and export through the native Files interface.
- English and Simplified Chinese; automatic system light/dark appearance.
- Apple system frameworks only. No third-party dependencies or backend.

## Quick start

**Scan / Import → Arrange → Name → Preview → Save to Files**

For offline use, make sure photo originals are downloaded to the phone, then choose **On My iPhone** when saving. Photos stored only in iCloud may need to download through the system picker. Cloud storage providers can require a connection or sync exported files; those services are outside the app's local processing.

## Build and install

Requires a Mac with Xcode supporting your phone's iOS version, and an iPhone running **iOS 17 or later**. The simulator supports photo/PDF workflows; camera scanning requires a real iPhone.

1. Open `Photo2PDF.xcodeproj` and select the **Photo2PDF** scheme.
2. Add your Apple Account in **Xcode → Settings → Accounts**.
3. Under **Targets → Photo2PDF → Signing & Capabilities**, enable **Automatically manage signing** and select your team. Personal signing identifiers are intentionally not included.
4. Change the Bundle Identifier if necessary to make it unique to your account.
5. Connect and unlock your iPhone, trust the Mac, select the phone in Xcode, and press **Run**. Follow device prompts for Developer Mode and developer certificate trust.

An Apple **Personal Team** can install the app for personal testing without a paid membership. Apple states that these provisioning profiles expire after **7 days**, requiring a rebuild and reinstall; initial signing and renewal can require Internet access. [Apple account documentation](https://developer.apple.com/help/account/basics/about-your-developer-account)

This repository distributes **source code**, not an App Store app or a universally installable signed IPA. Xcode project and module names retain `Photo2PDF`; the installed app is named **PDF Camera**.

## Privacy and local storage

PDF Camera performs its image and PDF processing locally and contains no application network requests. It asks for camera access when scanning and uses the system photo picker instead of requesting access to the entire library. See the [privacy notes](PRIVACY.md) for the exact boundaries.

Temporary source files are separated from exported PDFs and cleaned after successful export or discarding a document. Leftovers from an interrupted session are cleared on the next process launch. Unsaved drafts are **not restored across launches**; export before leaving the app. A saved PDF remains in the location you choose and is managed by Files or that file provider.

## Project structure

```text
Photo2PDF.xcodeproj/   Xcode project and shared scheme
Photo2PDF/
  Models/             Pages, errors, export document
  ViewModels/         Import, editing, generation, export state
  Views/              SwiftUI screens, scanner bridge, shared alerts
  Services/           Local image storage and sequential PDF rendering
  Utilities/          Filename and layout rules
  en.lproj/           English strings and camera permission text
  zh-Hans.lproj/      Simplified Chinese translations
Photo2PDFTests/       XCTest regression suite
Checks/              Standalone layout/localization checks
```

## Validation and scope

The current code passed a simulator build and **all 8 XCTest tests** on 20 October 2026. An earlier build was launched on a physical iPhone. Full physical-device scanning/export acceptance and large-batch performance measurements remain pending; see [VALIDATION.md](VALIDATION.md).

Run tests in Xcode with **⌘U**. Code formatting is configured in `.swift-format`.

Planned additions include manual photo cropping, imported-photo perspective correction, quality presets, grayscale, more paper sizes, and draft recovery. These are not advertised as existing features.

## Contributing and license

Issues and focused pull requests are welcome. Keep processing local, preserve both languages and system appearance, and include a regression test for behavior changes. Do not commit personal photos, PDFs, signing certificates, or credentials.

Released under the **[MIT License](LICENSE)**. Apple frameworks remain subject to Apple's terms.
