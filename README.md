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
- **iOS app** - native SwiftUI app for iPhone/iPad, see [iOS app](#ios-app)
  below.

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

Native SwiftUI port in `ios/QRinajar/`, targeting iOS 18+ and following
iOS 26 Liquid Glass design conventions. Uses the
[dagronf/QRCode](https://github.com/dagronf/QRCode) Swift package for
rendering.

The whole app is one guided flow instead of a tab bar: pick what you're
sharing → enter the details → style it → save/export, each step with a
pinned live preview, progress bar, and (i) info tips explaining what every
style control does and how it affects scannability. Back-navigation is a
real `NavigationStack` push per step, so swiping from the left edge pops
back like any other iOS screen — and backing out of the Style step with
unsaved changes prompts to save or discard first.

Other things worth knowing:

- **Share step** - three actions centered at the bottom: a plus button on
  the left starts another design (always asks to confirm first, since it
  discards the current one, with an occasional slow "New" callout that
  crossfades over the icon every 30s to point it out), a SAVE pill in the
  middle goes straight to the Library - prompts for a name (pre-filled
  with a default), shows a brief "Added to Library" toast instead of
  jumping there, or "Already in Library" if nothing's changed since the
  last save - and a Share icon on the right opens the native iOS share
  sheet as an independent option, not something gated behind Save.
- **Library** - saved presets (reachable from any step via the
  `books.vertical` toolbar icon, which shows a plain red dot rather than a
  count whenever there's something new); tap a row to load it and return
  to editing, or tap its QR icon for a quick full-preview in a bottom
  popup card (share it straight from there, drag its handle down or tap
  outside to dismiss). Swipe a row left to delete it - only a full
  swipe-through with real inertia (a fast flick) deletes; a slow drag
  that merely crosses the halfway point just reveals the Delete button
  (tap it to confirm) rather than deleting outright, no confirmation
  alert either way; shake the device to undo. Deleting exits sharply in
  the same direction as the swipe/tap, in one continuous motion, rather
  than snapping back to place before disappearing. Swipe a row right to
  rename it - reveals a blue pencil button, or a full swipe-through/fast
  flick to the right opens the rename prompt immediately. Both reveals
  span the full width of the row, edge to edge. A swipe that's only
  partly completed stays open rather than snapping shut on its own; it
  only closes if you tap the row or swipe it back. Any preset saved since
  the Library was last closed shows a small red "NEW" tag on its row;
  closing the Library clears those tags and the toolbar's dot together.
  The first row demos both gestures (delete, then rename) the very first
  time the Library is ever opened, then only resurfaces occasionally
  (after a couple of weeks) as a quiet reminder, not on every visit. The
  Library itself has a drag handle above its title (matching the QR
  popup's) and an X in the top-right - dragging the handle down closes it
  with a lighter touch than the QR popup needs, and both handles use a
  quick interactive spring to snap back so the motion stays smooth rather
  than lagging.
- **Style step** - only the Square/Rounded/Custom preset picker shows by
  default; the full set of fine-tune panels (module style, eyes,
  background, logo, border/caption) only appears once Custom is chosen.
- **Error correction** - an inline L/M/Q/H thermometer on the "Enter the
  details" step (scrolls with the rest of the form rather than staying
  pinned with the live preview, with a blue bracket calling out that Q
  and H are the two levels best suited to a center logo); the unselected
  levels carry a slow, subtle gradient pulse toward their end so they
  don't read as empty. Below it, a small illustration shows roughly how
  much of the code can be missing, dirty, or covered by a logo at each
  level and still scan - the illustration pulses gently and bumps when
  you change levels, to draw the eye to it.
- **QR scanner** - a floating button on every step opens the camera to scan
  a QR code and open it in Safari; first use explains why the camera
  permission is needed before the system prompt appears, and a success
  haptic confirms a code was found.
- **Appearance** - a single toolbar icon (sun in dark mode, moon in light
  mode) switches straight to the opposite mode, no settings screen in the
  way; also asked on first launch, after a splash screen and a one-time
  welcome screen explaining what the app does.
- **App icon** - a hand-authored Icon Composer `.icon` bundle
  (`ios/QRinajar/AppIcon.icon/`) rather than a flat PNG, so it renders with
  real specular/translucency on iOS 26 instead of a static image.

Requires Xcode with the iOS 18+ SDK and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`) to generate the `.xcodeproj` from `project.yml`:

```
cd ios/QRinajar
xcodegen generate
open QRinajar.xcodeproj
```

Or build headless for the Simulator:

```
xcodebuild -project ios/QRinajar/QRinajar.xcodeproj -scheme QRinajar \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
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
