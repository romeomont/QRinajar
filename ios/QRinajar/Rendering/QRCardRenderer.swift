import UIKit
import CoreGraphics
import QRCode

// Wraps QRCode.Document and composes the card (background, border, padding, caption,
// logo) mirroring cardLayout / composeCanvas / composeSvg in src/main.js:388-479.
enum QRCardRenderer {

    // MARK: - Color helpers

    static func cgColor(_ hex: String) -> CGColor {
        UIColor(hexString: hex).cgColor
    }

    // MARK: - Shape mapping (qr-code-styling names -> dagronf/QRCode shapes)

    static func pixelShape(_ name: String) -> any QRCodePixelShapeGenerator {
        switch name {
        case "square": return QRCode.PixelShape.Square()
        case "dots": return QRCode.PixelShape.Circle()
        case "rounded": return QRCode.PixelShape.RoundedRect(cornerRadiusFraction: 0.5)
        case "extra-rounded": return QRCode.PixelShape.RoundedRect(cornerRadiusFraction: 1.0)
        case "classy": return QRCode.PixelShape.Sharp()
        case "classy-rounded": return QRCode.PixelShape.Squircle()
        default: return QRCode.PixelShape.RoundedRect(cornerRadiusFraction: 0.5)
        }
    }

    static func eyeShape(_ name: String) -> any QRCodeEyeShapeGenerator {
        switch name {
        case "", "match": return QRCode.EyeShape.UsePixelShape()
        case "square": return QRCode.EyeShape.Square()
        case "dot", "dots": return QRCode.EyeShape.Circle()
        case "rounded": return QRCode.EyeShape.RoundedRect()
        case "extra-rounded": return QRCode.EyeShape.RoundedOuter()
        case "classy": return QRCode.EyeShape.Leaf()
        case "classy-rounded": return QRCode.EyeShape.Squircle()
        default: return QRCode.EyeShape.RoundedOuter()
        }
    }

    static func pupilShape(_ name: String) -> (any QRCodePupilShapeGenerator)? {
        switch name {
        case "", "match": return QRCode.PupilShape.UsePixelShape()
        case "square": return QRCode.PupilShape.Square()
        case "dot", "dots": return QRCode.PupilShape.Circle()
        case "rounded": return QRCode.PupilShape.RoundedRect()
        case "extra-rounded": return QRCode.PupilShape.Squircle()
        case "classy": return QRCode.PupilShape.Leaf()
        case "classy-rounded": return QRCode.PupilShape.Squircle()
        default: return QRCode.PupilShape.Circle()
        }
    }

    static func errorCorrection(_ ecc: String) -> QRCode.ErrorCorrection {
        switch ecc {
        case "L": return .low
        case "M": return .medium
        case "Q": return .quantize
        case "H": return .high
        default: return .medium
        }
    }

    // MARK: - Document build (mirrors buildOptions in main.js)

    static func makeDocument(_ s: DesignSnapshot) -> QRCode.Document? {
        let payload = PayloadBuilder.build(from: QRDesign(s))
        guard let doc = try? QRCode.Document(utf8String: payload.isEmpty ? " " : payload) else { return nil }
        doc.errorCorrection = errorCorrection(s.ecc)

        doc.design.shape.onPixels = pixelShape(s.dotStyle)
        doc.design.shape.eye = eyeShape(s.cornerSquareStyle)
        if let p = pupilShape(s.cornerDotStyle) { doc.design.shape.pupil = p }

        // Dots fill: solid or gradient
        if s.dotGradient {
            let pins = [
                DSFGradient.Pin(cgColor(s.dotColor), 0),
                DSFGradient.Pin(cgColor(s.dotColor2), 1),
            ]
            if let grad = try? DSFGradient(pins: pins) {
                let angle = CGFloat(s.gradientRot) * .pi / 180
                let dx = cos(angle), dy = sin(angle)
                let start = CGPoint(x: 0.5 - 0.5 * dx, y: 0.5 - 0.5 * dy)
                let end = CGPoint(x: 0.5 + 0.5 * dx, y: 0.5 + 0.5 * dy)
                if s.gradientType == "radial" {
                    doc.design.style.onPixels = QRCode.FillStyle.RadialGradient(grad, centerPoint: CGPoint(x: 0.5, y: 0.5))
                } else {
                    doc.design.style.onPixels = QRCode.FillStyle.LinearGradient(grad, startPoint: start, endPoint: end)
                }
            }
        } else {
            doc.design.style.onPixels = QRCode.FillStyle.Solid(cgColor(s.dotColor))
        }

        doc.design.style.eye = QRCode.FillStyle.Solid(cgColor(s.cornerSquareColor))
        doc.design.style.pupil = QRCode.FillStyle.Solid(cgColor(s.cornerDotColor))

        // Background of the QR area itself. The card compositor also paints the card
        // background; keeping the QR background transparent lets the card show through.
        doc.design.style.background = QRCode.FillStyle.Solid(CGColor(gray: 0, alpha: 0))

        // Quiet-zone margin: map the 0-80px web control onto module units.
        doc.design.additionalQuietZonePixels = UInt(max(0, min(12, Int((Double(s.margin) / 80.0 * 12).rounded()))))

        // Center logo
        if let png = s.logoPNG, let ui = UIImage(data: png), let cg = ui.cgImage {
            let sz = CGFloat(s.logoSize)
            let rect = CGRect(x: 0.5 - sz / 2, y: 0.5 - sz / 2, width: sz, height: sz)
            let path = CGPath(rect: rect, transform: nil)
            doc.logoTemplate = QRCode.LogoTemplate(
                image: cg,
                path: path,
                inset: CGFloat(s.logoMargin),
                masksQRCodePixels: s.hideDots
            )
        }
        return doc
    }

    // MARK: - Card layout (mirrors cardLayout)

    struct CardLayout {
        var bw: CGFloat
        var pad: CGFloat
        var lines: [String]
        var lineHeight: CGFloat
        var innerW: CGFloat
        var totalW: CGFloat
        var totalH: CGFloat
    }

    static func captionFont(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    static func wrapCaption(_ text: String, maxWidth: CGFloat, font: UIFont) -> [String] {
        var lines: [String] = []
        for para in text.components(separatedBy: "\n") {
            if para.isEmpty { lines.append(""); continue }
            let words = para.components(separatedBy: " ")
            var cur = ""
            for word in words {
                let test = cur.isEmpty ? word : cur + " " + word
                let w = (test as NSString).size(withAttributes: [.font: font]).width
                if !cur.isEmpty && w > maxWidth {
                    lines.append(cur); cur = word
                } else {
                    cur = test
                }
            }
            if !cur.isEmpty { lines.append(cur) }
        }
        return lines
    }

    static func layout(_ s: DesignSnapshot) -> CardLayout {
        let bw = CGFloat(s.borderEnabled ? s.borderWidth : 0)
        let pad = CGFloat(s.cardPadding)
        let captionText = s.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let font = captionFont(CGFloat(s.captionSize))
        let lines = captionText.isEmpty ? [] : wrapCaption(captionText, maxWidth: CGFloat(s.size), font: font)
        let lineHeight = CGFloat(s.captionSize) * 1.3
        let captionBlock = lines.isEmpty ? 0 : 14 + CGFloat(lines.count) * lineHeight
        let innerW = CGFloat(s.size)
        let innerH = innerW + captionBlock
        let totalW = innerW + pad * 2 + bw * 2
        let totalH = innerH + pad * 2 + bw * 2
        return CardLayout(bw: bw, pad: pad, lines: lines, lineHeight: lineHeight,
                          innerW: innerW, totalW: totalW, totalH: totalH)
    }

    // MARK: - Raster compose (mirrors composeCanvas)

    static func composeImage(_ s: DesignSnapshot, opaque: Bool) -> UIImage? {
        guard let doc = makeDocument(s),
              let qrCG = try? doc.cgImage(dimension: s.size) else { return nil }
        let L = layout(s)
        let radius = CGFloat(s.borderRadius)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = opaque
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: L.totalW, height: L.totalH), format: format)

        return renderer.image { context in
            let ctx = context.cgContext
            if opaque {
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: L.totalW, height: L.totalH))
            }
            // Card background + border
            let cardRect = CGRect(x: L.bw / 2, y: L.bw / 2,
                                  width: L.totalW - L.bw, height: L.totalH - L.bw)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: radius)
            if !s.bgTransparent {
                ctx.setFillColor(cgColor(s.bgColor))
                ctx.addPath(path.cgPath); ctx.fillPath()
            }
            if L.bw > 0 {
                ctx.setStrokeColor(cgColor(s.borderColor))
                ctx.setLineWidth(L.bw)
                ctx.addPath(path.cgPath); ctx.strokePath()
            }
            // QR image
            let qrRect = CGRect(x: L.bw + L.pad, y: L.bw + L.pad, width: L.innerW, height: L.innerW)
            ctx.saveGState()
            ctx.translateBy(x: 0, y: L.totalH)
            ctx.scaleBy(x: 1, y: -1)
            let flippedRect = CGRect(x: qrRect.minX, y: L.totalH - qrRect.maxY,
                                     width: qrRect.width, height: qrRect.height)
            ctx.draw(qrCG, in: flippedRect)
            ctx.restoreGState()

            // Caption
            if !L.lines.isEmpty {
                let font = captionFont(CGFloat(s.captionSize))
                let para = NSMutableParagraphStyle(); para.alignment = .center
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(hexString: s.captionColor),
                    .paragraphStyle: para,
                ]
                var y = L.bw + L.pad + L.innerW + 14
                for line in L.lines {
                    let r = CGRect(x: 0, y: y, width: L.totalW, height: L.lineHeight)
                    (line as NSString).draw(in: r, withAttributes: attrs)
                    y += L.lineHeight
                }
            }
        }
    }

    static func cgImage(_ s: DesignSnapshot, opaque: Bool = false) -> CGImage? {
        composeImage(s, opaque: opaque)?.cgImage
    }

    // Bare QR modules only — no card border/padding/caption. Used for the
    // Create tab's live preview, where the surrounding PreviewCard material
    // already provides the visual frame.
    static func qrOnlyImage(_ s: DesignSnapshot) -> UIImage? {
        guard let doc = makeDocument(s), let cg = try? doc.cgImage(dimension: s.size) else { return nil }
        return UIImage(cgImage: cg)
    }

    static func pngData(_ s: DesignSnapshot) -> Data? {
        composeImage(s, opaque: false)?.pngData()
    }

    static func jpegData(_ s: DesignSnapshot) -> Data? {
        composeImage(s, opaque: true)?.jpegData(compressionQuality: 0.95)
    }

    // MARK: - SVG compose (mirrors composeSvg)

    static func escapeXml(_ str: String) -> String {
        str.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func svgString(_ s: DesignSnapshot) -> String? {
        guard let doc = makeDocument(s),
              let inner = try? doc.svg(dimension: s.size) else { return nil }
        let L = layout(s)
        let bgFill = s.bgTransparent ? "none" : s.bgColor
        let strokeAttr = L.bw > 0 ? "stroke=\"\(s.borderColor)\" stroke-width=\"\(Int(L.bw))\"" : "stroke=\"none\""

        var textEls = ""
        if !L.lines.isEmpty {
            var y = L.bw + L.pad + L.innerW + 14 + CGFloat(s.captionSize)
            for line in L.lines {
                textEls += "<text x=\"\(L.totalW / 2)\" y=\"\(y)\" text-anchor=\"middle\" font-family=\"system-ui, sans-serif\" font-weight=\"600\" font-size=\"\(s.captionSize)\" fill=\"\(s.captionColor)\">\(escapeXml(line))</text>"
                y += L.lineHeight
            }
        }

        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(Int(L.totalW))\" height=\"\(Int(L.totalH))\" viewBox=\"0 0 \(Int(L.totalW)) \(Int(L.totalH))\">"
            + "<rect x=\"\(L.bw / 2)\" y=\"\(L.bw / 2)\" width=\"\(L.totalW - L.bw)\" height=\"\(L.totalH - L.bw)\" rx=\"\(s.borderRadius)\" ry=\"\(s.borderRadius)\" fill=\"\(bgFill)\" \(strokeAttr)/>"
            + "<g transform=\"translate(\(L.bw + L.pad), \(L.bw + L.pad))\">\(inner)</g>"
            + textEls
            + "</svg>"
    }
}
