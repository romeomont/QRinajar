# QR Code Generator

<p align="center">
  <img src="assets/logo.png" alt="QR Code Generator logo" width="180">
</p>

Fully offline QR code generator with heavy styling control (shapes, colors,
gradients, corner eyes, center logo, caption + border) and content presets
for common use cases (website, plain text, Wi-Fi, vCard contact, social
profile).

Available two ways:

- **Windows app** - installer or portable exe, no browser needed.
- **Single HTML file** - `dist/qr-code-generator.html`, zero dependencies at
  runtime. Copy it to a laptop, phone, or USB stick and open it in any
  browser. No internet is ever used: the QR library (qr-code-styling), the
  scan-test decoder (jsQR), and all UI are inlined into the file.

## Windows app

Grab the latest build from `release/`:

- **`QR Code Generator Installer.exe`** - installer. Run it, follow the
  wizard (you can choose the install location). During setup you can
  optionally add a Start Menu entry and/or a Desktop shortcut - neither is
  required. A proper uninstaller is included either way. Uninstalling (via
  **Settings → Apps** or `Uninstall QR Code Generator.exe` in the install
  folder) removes the app files, any shortcuts it created, and its saved
  settings - nothing left behind.
- **`QR Code Generator 1.0.0.exe`** - portable, no install. Just run it.

The app is unsigned, so Windows SmartScreen will show a warning the first
time it runs. Click **More info → Run anyway**. This is expected for
small/independent apps without a paid code-signing certificate.

To build these yourself (requires Windows Developer Mode enabled - see
"Building the Windows app" below):

```
npm install
npm run dist:win     # -> release/QR Code Generator Installer.exe (installer)
                      #    release/QR Code Generator 1.0.0.exe (portable)
```

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
npm run build     # -> dist/qr-code-generator.html
```

`build.mjs` bundles `src/main.js` with esbuild and inlines it into
`src/index.html`.

## Building the Windows app

The Electron shell lives in `electron/main.js` and just loads
`dist/qr-code-generator.html` in a native window.

```
npm start            # build + launch in dev mode
npm run package:win   # -> release/QR Code Generator-win32-x64/ (portable folder, no installer)
npm run dist:win      # -> release/QR Code Generator Installer.exe (installer) + portable exe
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
