import SwiftUI
import UIKit

// Identifiable wrapper so an exported image can drive `.sheet(item:)`.
// Internal (not private) — CreateFlowView's Share step and LibraryView's
// QR popup both build one of these to hand to ActivityShareSheet.
struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

// Thin UIKit bridge — SwiftUI has no native share sheet. Its built-in
// activities (Save Image, Copy, AirDrop, Mail, etc.) are the whole export
// UI now; there's no separate custom Copy/Save/Share picker to maintain.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
