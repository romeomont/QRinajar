import SwiftUI
import UIKit

// Share/save — the flow's final "Export" step content.
struct ExportPanel: View {
    @Environment(QRDesign.self) private var design
    @State private var saveMessage: String?
    @State private var shareItem: ShareItem?

    var body: some View {
        VStack(spacing: 20) {
            GroupCard {
                PanelHeader(title: "Share & save", systemImage: "square.and.arrow.up")

                HStack(spacing: 12) {
                    Button {
                        copyImage()
                    } label: { exportLabel("Copy", "doc.on.doc") }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 18))

                    Button {
                        saveToPhotos()
                    } label: { exportLabel("Save", "square.and.arrow.down") }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 18))

                    Button {
                        share()
                    } label: { exportLabel("Share", "square.and.arrow.up") }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 18))
                }

                if let saveMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(saveMessage)
                            .foregroundStyle(.primary)
                    }
                    .font(.title3.weight(.semibold))
                }
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityShareSheet(activityItems: [item.image])
        }
    }

    private func share() {
        guard let ui = QRCardRenderer.composeImage(design.snapshot, opaque: false) else { return }
        shareItem = ShareItem(image: ui)
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
        saveMessage = "Saved to Photos"
    }

    private func copyImage() {
        guard let ui = QRCardRenderer.composeImage(design.snapshot, opaque: false) else { return }
        UIPasteboard.general.image = ui
        saveMessage = "Copied to clipboard"
    }
}

// Identifiable wrapper so the exported image can drive `.sheet(item:)`.
private struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

// Thin UIKit bridge — SwiftUI has no native share sheet. Internal (not
// private) since LibraryView's QR popup reuses it too.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
