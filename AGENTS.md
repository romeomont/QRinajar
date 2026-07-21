# Agent notes for QRinajar

This repo ships QRinajar two ways: a Windows/Electron app and a single
offline HTML file. Read `README.md` first for a feature-level overview of
both. The native iOS/macOS app used to live here (`ios/QRinajar/`) but has
moved to its own private repo, `romeomont/ios-QRinajar` — work there
happens on `dev` (not `main`), and that repo's own `AGENTS.md`/`HANDOFF.md`
have the iOS-specific notes. `PRIVACY.md` stays in *this* repo regardless,
since it covers the whole QRinajar product line and its GitHub URL is
already registered as the Privacy Policy URL in App Store Connect.

## Repo layout

- `src/`, `build.mjs` — the web app (`dist/qrinajar.html`), vanilla JS +
  esbuild, no framework.
- `electron/` — the Windows app shell around the built HTML file.
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
