# QRinajar for iOS — native SwiftUI port

> **Historical.** This was the original implementation plan and describes
> a bottom-tab-bar architecture. The shipped app instead uses a single
> guided flow (pick type → enter details → style → export), pushed onto a
> real `NavigationStack`. Kept for context on *why* files are shaped the
> way they are; see `HANDOFF.md` for the current architecture.

## Context
QRinajar (`~/QRinajar`) is a fully offline styled-QR generator currently shipped as an Electron/Windows app and a single HTML file (`src/main.js` + `src/index.html`). The user wants a native iOS app version: functional, attractive, following iOS 26/27 (Liquid Glass era) design conventions, with a bottom tab bar. The port lives in `ios/` inside the QRinajar repo and uses the **dagronf/QRCode** Swift package (SPM) for styled rendering.

## App structure

**Project:** `ios/QRinajar/` — SwiftUI app, iOS 18+ deployment target (uses the modern `Tab` API and glass materials; degrades gracefully). Generate the `.xcodeproj` with XcodeGen (`project.yml`) if installed, otherwise `swift package`-based Xcode workspace or hand-created project — check tooling at implementation time and pick the first that works.

**Tabs (bottom `TabView`):**
1. **Create** — payload editor: segmented content-type presets (Website, Text, Wi-Fi, Contact, Social) with type-specific form fields (e.g. SSID/password/security for Wi-Fi, vCard fields for Contact) instead of raw strings; live QR preview card pinned at top. ECC picker in a detail sheet.
2. **Style** — the live preview stays on top; below it, style preset cards (Square / Rounded / Custom) and, for Custom, grouped controls: dots (shape, color, optional gradient with type+angle), corner eyes (shape + colors), background (color / transparent), logo (PhotosPicker, size/margin/hide-dots), card (caption text/color/size, border on/off/color/width, padding, corner radius). Use native ColorPicker, Slider with value labels, Toggle.
3. **Export** — large final preview, then share/save actions: PNG / JPEG / SVG via `ShareLink`, "Save to Photos", "Copy image", plus the scan self-test (render → decode with Vision `VNDetectBarcodesRequest`, show ✓/⚠/✗ result like the web app).
4. **Library** — saved presets (multiple named presets, an upgrade over the web app's single localStorage slot) stored as Codable JSON in Application Support; tap to load, swipe to delete; "Reset to factory" action.

**Shared state:** one `@Observable` `QRDesign` model mirroring the web `FACTORY` settings struct (same fields/defaults from `src/main.js:17-47`), injected via environment; auto-persist last design on change (like the web app's localStorage).

**Rendering:** a `QRCardRenderer` that wraps `QRCode.Document` (dot/eye styles, gradients, logo) and composes the card — background, rounded border, padding, wrapped caption — mirroring `cardLayout`/`composeCanvas` in `src/main.js:388-448`. Used for both the live preview (SwiftUI view / CGImage) and exports (PNG/JPEG via CGImage; SVG via QRCode's SVG export wrapped in the same card SVG scaffold as `composeSvg`).

## iOS 26/27 design notes
- `TabView` with `Tab(...)` items and SF Symbols (qrcode, paintbrush, square.and.arrow.up, tray.full); system tab bar gets Liquid Glass for free.
- `.scrollEdgeEffectStyle`, `glassEffect`/`.ultraThinMaterial` cards for the preview panel where available (`#available` guards), generous corner radii, `.presentationDetents` sheets for pickers.
- Full light/dark support; app accent color from the QRinajar brand blue `#35b5e5`.
- App icon derived from `assets/logo.png`.

## Files to create (all under `ios/QRinajar/`)
- `project.yml` (XcodeGen) or equivalent project scaffold; SPM dependency `https://github.com/dagronf/QRCode`
- `App/QRinajarApp.swift`, `App/RootTabView.swift`
- `Model/QRDesign.swift` (settings + factory defaults + Codable), `Model/PresetStore.swift`, `Model/PayloadBuilder.swift` (Wi-Fi/vCard/etc. string builders, from `PRESET_DATA`/`VCARD` in main.js)
- `Rendering/QRCardRenderer.swift`, `Rendering/ScanTester.swift` (Vision)
- `Views/CreateView.swift`, `Views/StyleView.swift`, `Views/ExportView.swift`, `Views/LibraryView.swift`, shared `Views/PreviewCard.swift` + small controls
- `Assets.xcassets` (icon, accent color), Info.plist keys (`NSPhotoLibraryAddUsageDescription` for Save to Photos)

## Verification
- Build for iOS Simulator: `xcodebuild -project ios/QRinajar/QRinajar.xcodeproj -scheme QRinajar -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
- Boot the simulator, install & launch, screenshot each tab (`xcrun simctl`) to confirm layout/appearance in light and dark mode.
- Functional checks: change styles → preview updates; export PNG and run the scan self-test (should decode to the entered payload); save/load a preset from Library.
