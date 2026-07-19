import SwiftUI

// Live preview of the composed card. Recomputes whenever the design changes.
struct PreviewCard: View {
    @Environment(QRDesign.self) private var design
    var maxHeight: CGFloat = 320
    // When true, renders just the QR modules (no card border/padding/caption) —
    // used on the Create tab, where this card's own material is the frame.
    var bare: Bool = false

    private var image: UIImage? {
        var snap = design.snapshot
        // Render preview at a modest resolution for responsiveness.
        snap.size = min(snap.size, 560)
        return bare ? QRCardRenderer.qrOnlyImage(snap) : QRCardRenderer.composeImage(snap, opaque: false)
    }

    var body: some View {
        ZStack {
            if !bare && design.bgTransparent {
                Checkerboard()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            if let ui = image {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: maxHeight)
                    .padding(bare ? 12 : 0)
                    // A scanned QR always needs a light backing regardless of the
                    // app's own light/dark theme, so give the bare preview its own
                    // fixed-white card rather than relying on the surrounding material.
                    .background(bare ? RoundedRectangle(cornerRadius: 16).fill(.white) : nil)
                    .accessibilityLabel("QR code preview")
            } else {
                ContentUnavailableView("Nothing to render", systemImage: "qrcode")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial)
            } else {
                RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.08)))
    }
}

struct Checkerboard: View {
    var body: some View {
        GeometryReader { geo in
            let n = 20
            let cell = geo.size.width / CGFloat(n)
            Canvas { ctx, size in
                let rows = Int(ceil(size.height / cell))
                for r in 0..<rows {
                    for c in 0..<n {
                        if (r + c) % 2 == 0 {
                            let rect = CGRect(x: CGFloat(c) * cell, y: CGFloat(r) * cell, width: cell, height: cell)
                            ctx.fill(Path(rect), with: .color(.gray.opacity(0.35)))
                        }
                    }
                }
            }
        }
    }
}
