import SwiftUI
import UIKit

// Share/save + scan self-test — the flow's final "Export" step content.
struct ExportPanel: View {
    @Environment(QRDesign.self) private var design
    @State private var scanResult: ScanTester.Result?
    @State private var saveMessage: String?

    private func stamp() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return "qrinajar-" + f.string(from: Date())
    }

    private func exportURL(ext: String, data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(stamp()).\(ext)")
        do { try data.write(to: url); return url } catch { return nil }
    }

    var body: some View {
        VStack(spacing: 20) {
            GroupCard {
                PanelHeader(title: "Share & save", systemImage: "square.and.arrow.up")

                HStack(spacing: 12) {
                    if let d = QRCardRenderer.pngData(design.snapshot), let url = exportURL(ext: "png", data: d) {
                        ShareLink(item: url) { exportLabel("PNG", "photo") }
                    }
                    if let d = QRCardRenderer.jpegData(design.snapshot), let url = exportURL(ext: "jpg", data: d) {
                        ShareLink(item: url) { exportLabel("JPEG", "photo.on.rectangle") }
                    }
                    if let s = QRCardRenderer.svgString(design.snapshot),
                       let url = exportURL(ext: "svg", data: Data(s.utf8)) {
                        ShareLink(item: url) { exportLabel("SVG", "curlybraces") }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        saveToPhotos()
                    } label: { exportLabel("Save to Photos", "square.and.arrow.down") }
                    .buttonStyle(.borderedProminent)

                    Button {
                        copyImage()
                    } label: { exportLabel("Copy", "doc.on.doc") }
                    .buttonStyle(.bordered)
                }

                if let saveMessage {
                    Text(saveMessage).font(.caption).foregroundStyle(.secondary)
                }
            }

            GroupCard {
                PanelHeader(title: "Scan self-test", systemImage: "qrcode.viewfinder")
                Text("Renders the code and decodes it offline with Vision to confirm it scans.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Test scan") { runScanTest() }
                    .buttonStyle(.bordered)
                if let scanResult { scanResultView(scanResult) }
            }
        }
    }

    private func exportLabel(_ text: String, _ symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).font(.title3)
            Text(text).font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func scanResultView(_ r: ScanTester.Result) -> some View {
        switch r {
        case .ok:
            Label("Decodes correctly — safe to print", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green).font(.callout)
        case .mismatch:
            Label("Decodes, but data mismatch — check payload", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange).font(.callout)
        case .failed:
            Label("Test decoder failed — try a different dot style, higher error correction, or more contrast.",
                  systemImage: "xmark.circle.fill")
                .foregroundStyle(.red).font(.callout)
        }
    }

    private func runScanTest() {
        guard let cg = QRCardRenderer.cgImage(design.snapshot, opaque: true) else {
            scanResult = .failed; return
        }
        scanResult = ScanTester.test(image: cg, expected: design.payload)
    }

    private func saveToPhotos() {
        guard let ui = QRCardRenderer.composeImage(design.snapshot, opaque: false) else { return }
        UIImageWriteToSavedPhotosAlbum(ui, nil, nil, nil)
        saveMessage = "Saved to Photos ✓"
    }

    private func copyImage() {
        guard let ui = QRCardRenderer.composeImage(design.snapshot, opaque: false) else { return }
        UIPasteboard.general.image = ui
        saveMessage = "Copied to clipboard ✓"
    }
}
