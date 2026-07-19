# Agent notes for QRinajar

This repo ships QRinajar three ways: a Windows/Electron app, a single
offline HTML file, and a native iOS app. Read `README.md` first for a
feature-level overview of all three. If you're picking up iOS work
specifically, read `HANDOFF.md` next — it has current architecture notes,
known gaps, and what's deliberately been left untested.

## Repo layout

- `src/`, `build.mjs` — the web app (`dist/qrinajar.html`), vanilla JS +
  esbuild, no framework.
- `electron/` — the Windows app shell around the built HTML file.
- `ios/QRinajar/` — native SwiftUI app. XcodeGen-managed (`project.yml`
  generates `QRinajar.xcodeproj` — the `.xcodeproj` itself is committed
  but regenerate it after touching `project.yml` or adding/removing
  source files).
- `assets/` — shared brand assets (logo, icon source).
- `test/` — scan-compatibility test harness for the web app (jsQR-based).

## Building

Web app:
```
npm install
npm run build      # -> dist/qrinajar.html
```

Windows app (needs Windows + Developer Mode for `dist:win`):
```
npm run dist:win    # -> release/QRinajarInstaller.exe + portable exe
```

iOS app (needs macOS + Xcode + `brew install xcodegen`):
```
cd ios/QRinajar
xcodegen generate
xcodebuild -project QRinajar.xcodeproj -scheme QRinajar \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Check `xcrun simctl list devices` for what Simulator names actually exist
on the machine before assuming `iPhone 17 Pro` is available.

## Conventions worth knowing

- iOS: no comments explaining *what* code does, only *why* when it's
  non-obvious (see existing files for the level of terseness expected).
  Follow the existing InfoTip/GlassButtonStyle/GroupCard patterns in
  `Views/Controls.swift` rather than introducing new one-off styling.
- iOS: the create flow is a real `NavigationStack` push per step
  (`Views/CreateFlowView.swift`), not `@State`-swapped content — that's
  deliberate, it's what gives the standard edge-swipe-back gesture for
  free. Don't revert to a TabView or single-view-with-state-switch without
  a good reason.
- Don't hand-roll a new AppIcon.appiconset — the app icon is a real
  Icon Composer `.icon` bundle at `ios/QRinajar/AppIcon.icon/`. Edit
  `icon.json` / the layer PNGs in `Assets/` directly if it needs to
  change, following the existing layer structure.
- When you finish a chunk of iOS work, update `HANDOFF.md`'s "Current
  architecture" and "Known issues" sections to match reality — it's the
  living doc the next agent reads first, and it goes stale fast if left
  alone.
