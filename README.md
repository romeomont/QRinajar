# Mesh QR Generator

Fully offline, single-file QR code generator for LoRa mesh field work
(MeshCore channel/contact links, node info, junction box tags, gateway Wi-Fi,
plain text).

## The deliverable

**`dist/mesh-qr-generator.html`** — one ~200 KB file, zero dependencies at
runtime. Copy it to a laptop, phone, or USB stick and open it in any browser.
No internet is ever used: the QR library (qr-code-styling), the scan-test
decoder (jsQR), and all UI are inlined into the file.

## Features

- **Content presets** — junction box tag (default: a plain-text "what this box
  is / who to contact" notice that needs no internet to read after scanning),
  MeshCore channel/contact link (paste from the MeshCore app), node info,
  Wi-Fi AP, plain text
- **Shape & layout** — square or circle overall shape, size, quiet-zone margin
- **Module styles** — square, dots, rounded, extra-rounded, classy, classy-rounded
- **Colors** — solid or linear/radial gradient dots, custom corner-eye colors,
  solid or transparent background
- **Corner eyes** — independent outer/inner eye style and color
- **Center logo** — drag & drop any image (processed locally via FileReader,
  never uploaded), adjustable size/margin, optional dot clearing behind it
- **Export** — PNG / SVG / JPEG download, copy-to-clipboard
- **Test scan** — decodes the rendered code with jsQR in-page so you can verify
  a style combo actually scans before printing. (The "Dots" style is the
  riskiest for scanners; the tester will tell you.)
- **Presets** — save your styling as the default (localStorage, offline)

## Rebuilding

```
npm install
npm run build     # -> dist/mesh-qr-generator.html
```

`build.mjs` bundles `src/main.js` with esbuild and inlines it into
`src/index.html`.

## Scan-compatibility test harness

`test/decode-test.js` renders a matrix of style combinations and decodes each
with jsQR:

```
npm test          # bundles the harness
# then open test/decode-test.html in a browser; title shows ALL PASS / FAILURES
```
