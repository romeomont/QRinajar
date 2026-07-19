import SwiftUI
import UIKit

extension UIColor {
    convenience init(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r, g, b, a: CGFloat
        switch hex.count {
        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255
            a = CGFloat(rgb & 0x000000FF) / 255
        default:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255
            b = CGFloat(rgb & 0x0000FF) / 255
            a = 1
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}

extension Color {
    init(hex: String) { self.init(UIColor(hexString: hex)) }
    var hexString: String { UIColor(self).hexString }
}

// A SwiftUI ColorPicker bound to a hex string in the model.
struct HexColorPicker: View {
    let title: String
    @Binding var hex: String

    var body: some View {
        ColorPicker(title, selection: Binding(
            get: { Color(hex: hex) },
            set: { hex = $0.hexString }
        ), supportsOpacity: false)
    }
}

let brandBlue = Color(hex: "#35b5e5")
