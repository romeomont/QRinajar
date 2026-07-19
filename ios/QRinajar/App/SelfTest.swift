import Foundation

// Headless functional smoke checks, run when QRINAJAR_SELFTEST is set (see
// capture_screenshots.sh's sibling invocation). Exercises the same paths the
// plan's Verification section calls for: style-control changes reflected in
// the design snapshot, PNG/SVG export validity, scan self-test decode
// correctness, and preset save/load round-trip. Prints PASS/FAIL lines then
// exits.
enum SelfTest {
    static func run() {
        var failures = 0

        func check(_ name: String, _ ok: Bool, _ detail: String = "") {
            if ok {
                print("PASS \(name)")
            } else {
                failures += 1
                print("FAIL \(name) \(detail)")
            }
        }

        // 1. Style-control change reflected in design + activeStyle.
        let design = QRDesign(.factory)
        design.applyStyle(StylePreset.square)
        check("style-apply-square", design.activeStyle == .square,
              "dotStyle=\(design.dotStyle) corner=\(design.cornerSquareStyle)")
        design.applyStyle(StylePreset.rounded)
        check("style-apply-rounded", design.activeStyle == .rounded)

        // 2. PNG export validity: non-nil data, valid PNG magic bytes.
        let snap = design.snapshot
        let pngData = QRCardRenderer.pngData(snap)
        let pngMagic: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        check("export-png", pngData != nil && Array(pngData!.prefix(4)) == pngMagic,
              "bytes=\(pngData?.count ?? -1)")

        // 3. SVG export validity: well-formed root element.
        let svg = QRCardRenderer.svgString(snap)
        check("export-svg", svg != nil && svg!.hasPrefix("<svg") && svg!.hasSuffix("</svg>"),
              "len=\(svg?.count ?? -1)")

        // 4. Scan self-test: render the payload and decode it back.
        design.contentType = .website
        design.websiteURL = "https://example.com/selftest"
        let scanSnap = design.snapshot
        if let cg = QRCardRenderer.cgImage(scanSnap, opaque: true) {
            let result = ScanTester.test(image: cg, expected: design.payload)
            switch result {
            case .ok: check("scan-selftest", true)
            case .mismatch(let got): check("scan-selftest", false, "decoded=\(got) expected=\(design.payload)")
            case .failed: check("scan-selftest", false, "no barcode decoded")
            }
        } else {
            check("scan-selftest", false, "render failed")
        }

        // 5. Preset save/load round-trip.
        let store = PresetStore()
        let beforeCount = store.presets.count
        let name = "SelfTest-\(UUID().uuidString.prefix(8))"
        store.save(name: name, design: scanSnap)
        let saved = store.presets.first
        check("preset-save", store.presets.count == beforeCount + 1 && saved?.name == name)
        check("preset-round-trip", saved?.design == scanSnap)
        if let saved {
            store.delete(saved)
        }
        check("preset-cleanup", store.presets.count == beforeCount)

        print("SELFTEST_DONE failures=\(failures)")
        exit(failures == 0 ? 0 : 1)
    }
}
