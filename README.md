# QRinajar

<p align="center">
  <img src="assets/logo.png" alt="QRinajar logo" width="180">
</p>

<p align="center">
  <a href="https://github.com/romeomont/QRinajar/releases/latest">
    <img src="https://img.shields.io/badge/Download-latest%20release-35b5e5?style=for-the-badge" alt="Download latest release">
  </a>
</p>

Fully offline QR code generator with heavy styling control (shapes, colors,
gradients, corner eyes, center logo, caption + border) and content presets
for common use cases (website, plain text, Wi-Fi, vCard contact, social
profile).

Available three ways:

- **Windows app** - installer or portable exe, no browser needed.
- **Single HTML file** - `dist/qrinajar.html`, zero dependencies at
  runtime. Copy it to a laptop, phone, or USB stick and open it in any
  browser. No internet is ever used: the QR library (qr-code-styling), the
  scan-test decoder (jsQR), and all UI are inlined into the file.
- **iOS app** - native SwiftUI app for iPhone/iPad. Moved out to its own
  private repo, `romeomont/ios-QRinajar` (branch `dev`) - not in this repo
  anymore.

## Windows app

Grab the latest build from the [Releases page](https://github.com/romeomont/QRinajar/releases/latest):

- **`QRinajarInstaller.exe`** - installer. Run it, follow the
  wizard (you can choose the install location). During setup you can
  optionally add a Start Menu entry and/or a Desktop shortcut - neither is
  required. A proper uninstaller is included either way. Uninstalling (via
  **Settings → Apps** or `Uninstall QRinajar.exe` in the install
  folder) removes the app files, any shortcuts it created, and its saved
  settings - nothing left behind.
- **`QRinajarPortable.exe`** - portable, no install. Just run it.

The first time the app launches, it shows a brief splash screen (icon,
version, links to the license and this repo) with a "Don't show this again"
option; after that it opens straight to the editor unless you choose to see
it again.

The app is unsigned, so Windows SmartScreen will show a warning the first
time it runs. Click **More info → Run anyway**. This is expected for
small/independent apps without a paid code-signing certificate.

To build these yourself (requires Windows Developer Mode enabled - see
"Building the Windows app" below):

```
npm install
npm run dist:win     # -> release/QRinajarInstaller.exe (installer)
                      #    release/QRinajarPortable.exe (portable)
```

## iOS app

Moved to its own private repo: `romeomont/ios-QRinajar`, working branch
`dev`. It's a native SwiftUI port targeting iOS 18+, following iOS 26
Liquid Glass design conventions, using
[dagronf/QRCode](https://github.com/dagronf/QRCode) for rendering. See
that repo's own README/HANDOFF for the full feature rundown and dev
setup — this repo no longer contains the iOS project.

## Features

- **Content presets** - website, plain text, Wi-Fi network, vCard contact
  card, social profile
- **Shape & layout** - square or circle overall shape, size, quiet-zone margin
- **Module styles** - square, dots, rounded, extra-rounded, classy, classy-rounded
- **Colors** - solid or linear/radial gradient dots, custom corner-eye colors,
  solid or transparent background
- **Corner eyes** - independent outer/inner eye style and color
- **Center logo** - drag & drop any image (processed locally via FileReader,
  never uploaded), adjustable size/margin, optional dot clearing behind it
- **Caption & border** - optional text under the QR code and a configurable
  card border/padding/corner-rounding, baked into every export (not just the
  on-screen preview)
- **Export** - PNG / SVG / JPEG download, copy-to-clipboard - all include the
  caption and border
- **Test scan** - decodes the rendered code with jsQR in-page so you can verify
  a style combo actually scans before printing. (The "Dots" style is the
  riskiest for scanners; the tester will tell you.)
- **Presets** - save your styling as the default (localStorage, offline)

## Rebuilding the HTML file

```
npm install
npm run build     # -> dist/qrinajar.html
```

`build.mjs` bundles `src/main.js` with esbuild and inlines it into
`src/index.html`.

## Building the Windows app

The Electron shell lives in `electron/main.js`. It shows a splash screen
(`electron/splash.html`) before loading `dist/qrinajar.html` in the main
window.

```
npm start            # build + launch in dev mode
npm run package:win   # -> release/QRinajar-win32-x64/ (portable folder, no installer)
npm run dist:win      # -> release/QRinajarInstaller.exe (installer) + portable exe
```

`dist:win` (electron-builder, NSIS) needs Windows Developer Mode turned on
(**Settings → Privacy & security → For developers**) so it can create
symlinks while unpacking its bundled tooling. Without it, the build fails
with a "Cannot create symbolic link" error. `package:win` (electron-packager)
has no such requirement but only produces a portable folder, not an
installer/uninstaller.

## Scan-compatibility test harness

`test/decode-test.js` renders a matrix of style combinations and decodes each
with jsQR:

```
npm test          # bundles the harness
# then open test/decode-test.html in a browser; title shows ALL PASS / FAILURES
```

## License

This project is licensed under the [ISC License](LICENSE).

It bundles two third-party libraries directly into the shipped app
(`qr-code-styling`, MIT, and `jsQR`, Apache-2.0) - see
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for their full license
texts. Both files are also copied next to the `.exe` in every Windows build
(installer and portable), alongside Electron's own bundled license notices.

All other dependencies (esbuild, electron, electron-builder,
electron-packager, pngjs, and their transitive dependencies) are build/dev
tooling only and are not included in the distributed app; they're under
permissive licenses (MIT/ISC/Apache-2.0/BSD).
