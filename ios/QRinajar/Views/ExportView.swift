import SwiftUI
import UIKit

// Share/save — the flow's final "Export" step content.
struct ExportPanel: View {
    @Environment(QRDesign.self) private var design
    @State private var saveMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            GroupCard {
                PanelHeader(title: "Share & save", systemImage: "square.and.arrow.up")

                HStack(spacing: 12) {
                    Button {
                        saveToPhotos()
                    } label: { exportLabel("Save to Photos", "square.and.arrow.down") }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 18))

                    Button {
                        copyImage()
                    } label: { exportLabel("Copy", "doc.on.doc") }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 18))
                }

                if let saveMessage {
                    Text(saveMessage).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func exportLabel(_ text: String, _ symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 34))
            Text(text).font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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
