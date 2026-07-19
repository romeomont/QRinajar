import SwiftUI
import Observation

// Mirrors the web app's FACTORY settings object (src/main.js:17-47) plus the
// structured content-form fields the native app adds on top of the raw `data` string.

enum ContentType: String, CaseIterable, Codable, Identifiable {
    case website, text, wifi, contact, social
    var id: String { rawValue }
    var label: String {
        switch self {
        case .website: return "Website"
        case .text: return "Text"
        case .wifi: return "Wi-Fi"
        case .contact: return "Contact"
        case .social: return "Social"
        }
    }
    var symbol: String {
        switch self {
        case .website: return "globe"
        case .text: return "text.alignleft"
        case .wifi: return "wifi"
        case .contact: return "person.crop.square"
        case .social: return "at"
        }
    }
}

// Codable snapshot used for persistence and preset storage.
struct DesignSnapshot: Codable, Equatable {
    // Content
    var contentType: ContentType = .website
    var data: String = "https://example.com"
    var ecc: String = "M"

    // Wi-Fi fields
    var wifiSSID: String = "MyWiFiNetwork"
    var wifiPassword: String = "changeme123"
    var wifiSecurity: String = "WPA"     // WPA / WEP / nopass
    var wifiHidden: Bool = false

    // vCard / contact fields
    var contactFirst: String = "Jane"
    var contactLast: String = "Doe"
    var contactOrg: String = "Example Org"
    var contactTitle: String = "Field Technician"
    var contactPhone: String = "+1 555 0100"
    var contactEmail: String = "jane.doe@example.com"
    var contactURL: String = "https://example.com"

    // Website / social / text single-field payloads
    var websiteURL: String = "https://example.com"
    var socialURL: String = "https://instagram.com/yourhandle"
    var textBody: String = "Hello, world!"

    // Shape & layout
    var shape: String = "square"
    var size: Int = 800
    var margin: Int = 16
    var borderRadius: Int = 14

    // Dots
    var dotStyle: String = "rounded"
    var dotColor: String = "#0d1b2a"
    var dotGradient: Bool = false
    var dotColor2: String = "#35b5e5"
    var gradientType: String = "linear"
    var gradientRot: Int = 45

    // Eyes
    var cornerSquareStyle: String = "extra-rounded"
    var cornerDotStyle: String = "dot"
    var cornerSquareColor: String = "#0d1b2a"
    var cornerDotColor: String = "#35b5e5"

    // Background
    var bgColor: String = "#ffffff"
    var bgTransparent: Bool = false

    // Logo (PNG data, base64 in JSON)
    var logoPNG: Data? = nil
    var logoSize: Double = 0.35
    var logoMargin: Int = 6
    var hideDots: Bool = true

    // Caption / card
    var caption: String = ""
    var captionColor: String = "#0d1b2a"
    var captionSize: Int = 20
    var borderEnabled: Bool = true
    var borderColor: String = "#0d1b2a"
    var borderWidth: Int = 4
    var cardPadding: Int = 24

    static let factory = DesignSnapshot()
}

@Observable
final class QRDesign {
    var contentType: ContentType
    var data: String
    var ecc: String

    var wifiSSID: String
    var wifiPassword: String
    var wifiSecurity: String
    var wifiHidden: Bool

    var contactFirst: String
    var contactLast: String
    var contactOrg: String
    var contactTitle: String
    var contactPhone: String
    var contactEmail: String
    var contactURL: String

    var websiteURL: String
    var socialURL: String
    var textBody: String

    var shape: String
    var size: Int
    var margin: Int
    var borderRadius: Int

    var dotStyle: String
    var dotColor: String
    var dotGradient: Bool
    var dotColor2: String
    var gradientType: String
    var gradientRot: Int

    var cornerSquareStyle: String
    var cornerDotStyle: String
    var cornerSquareColor: String
    var cornerDotColor: String

    var bgColor: String
    var bgTransparent: Bool

    var logoPNG: Data?
    var logoSize: Double
    var logoMargin: Int
    var hideDots: Bool

    var caption: String
    var captionColor: String
    var captionSize: Int
    var borderEnabled: Bool
    var borderColor: String
    var borderWidth: Int
    var cardPadding: Int

    init(_ s: DesignSnapshot = .factory) {
        contentType = s.contentType
        data = s.data
        ecc = s.ecc
        wifiSSID = s.wifiSSID
        wifiPassword = s.wifiPassword
        wifiSecurity = s.wifiSecurity
        wifiHidden = s.wifiHidden
        contactFirst = s.contactFirst
        contactLast = s.contactLast
        contactOrg = s.contactOrg
        contactTitle = s.contactTitle
        contactPhone = s.contactPhone
        contactEmail = s.contactEmail
        contactURL = s.contactURL
        websiteURL = s.websiteURL
        socialURL = s.socialURL
        textBody = s.textBody
        shape = s.shape
        size = s.size
        margin = s.margin
        borderRadius = s.borderRadius
        dotStyle = s.dotStyle
        dotColor = s.dotColor
        dotGradient = s.dotGradient
        dotColor2 = s.dotColor2
        gradientType = s.gradientType
        gradientRot = s.gradientRot
        cornerSquareStyle = s.cornerSquareStyle
        cornerDotStyle = s.cornerDotStyle
        cornerSquareColor = s.cornerSquareColor
        cornerDotColor = s.cornerDotColor
        bgColor = s.bgColor
        bgTransparent = s.bgTransparent
        logoPNG = s.logoPNG
        logoSize = s.logoSize
        logoMargin = s.logoMargin
        hideDots = s.hideDots
        caption = s.caption
        captionColor = s.captionColor
        captionSize = s.captionSize
        borderEnabled = s.borderEnabled
        borderColor = s.borderColor
        borderWidth = s.borderWidth
        cardPadding = s.cardPadding
    }

    var snapshot: DesignSnapshot {
        var s = DesignSnapshot()
        s.contentType = contentType
        s.data = data
        s.ecc = ecc
        s.wifiSSID = wifiSSID
        s.wifiPassword = wifiPassword
        s.wifiSecurity = wifiSecurity
        s.wifiHidden = wifiHidden
        s.contactFirst = contactFirst
        s.contactLast = contactLast
        s.contactOrg = contactOrg
        s.contactTitle = contactTitle
        s.contactPhone = contactPhone
        s.contactEmail = contactEmail
        s.contactURL = contactURL
        s.websiteURL = websiteURL
        s.socialURL = socialURL
        s.textBody = textBody
        s.shape = shape
        s.size = size
        s.margin = margin
        s.borderRadius = borderRadius
        s.dotStyle = dotStyle
        s.dotColor = dotColor
        s.dotGradient = dotGradient
        s.dotColor2 = dotColor2
        s.gradientType = gradientType
        s.gradientRot = gradientRot
        s.cornerSquareStyle = cornerSquareStyle
        s.cornerDotStyle = cornerDotStyle
        s.cornerSquareColor = cornerSquareColor
        s.cornerDotColor = cornerDotColor
        s.bgColor = bgColor
        s.bgTransparent = bgTransparent
        s.logoPNG = logoPNG
        s.logoSize = logoSize
        s.logoMargin = logoMargin
        s.hideDots = hideDots
        s.caption = caption
        s.captionColor = captionColor
        s.captionSize = captionSize
        s.borderEnabled = borderEnabled
        s.borderColor = borderColor
        s.borderWidth = borderWidth
        s.cardPadding = cardPadding
        return s
    }

    func apply(_ s: DesignSnapshot) {
        let n = QRDesign(s)
        // copy field-by-field into self so observers fire
        contentType = n.contentType; data = n.data; ecc = n.ecc
        wifiSSID = n.wifiSSID; wifiPassword = n.wifiPassword; wifiSecurity = n.wifiSecurity; wifiHidden = n.wifiHidden
        contactFirst = n.contactFirst; contactLast = n.contactLast; contactOrg = n.contactOrg
        contactTitle = n.contactTitle; contactPhone = n.contactPhone; contactEmail = n.contactEmail; contactURL = n.contactURL
        websiteURL = n.websiteURL; socialURL = n.socialURL; textBody = n.textBody
        shape = n.shape; size = n.size; margin = n.margin; borderRadius = n.borderRadius
        dotStyle = n.dotStyle; dotColor = n.dotColor; dotGradient = n.dotGradient; dotColor2 = n.dotColor2
        gradientType = n.gradientType; gradientRot = n.gradientRot
        cornerSquareStyle = n.cornerSquareStyle; cornerDotStyle = n.cornerDotStyle
        cornerSquareColor = n.cornerSquareColor; cornerDotColor = n.cornerDotColor
        bgColor = n.bgColor; bgTransparent = n.bgTransparent
        logoPNG = n.logoPNG; logoSize = n.logoSize; logoMargin = n.logoMargin; hideDots = n.hideDots
        caption = n.caption; captionColor = n.captionColor; captionSize = n.captionSize
        borderEnabled = n.borderEnabled; borderColor = n.borderColor; borderWidth = n.borderWidth
        cardPadding = n.cardPadding
    }

    // The encoded payload string, rebuilt from the structured content fields.
    var payload: String { PayloadBuilder.build(from: self) }

    // Apply a style preset (square / rounded) mirroring STYLE_SQUARE / STYLE_ROUNDED.
    func applyStyle(_ preset: StylePreset) {
        dotStyle = preset.dotStyle
        cornerSquareStyle = preset.cornerSquareStyle
        cornerDotStyle = preset.cornerDotStyle
        borderRadius = preset.borderRadius
    }

    var activeStyle: StylePreset.Kind {
        if StylePreset.square.matches(self) { return .square }
        if StylePreset.rounded.matches(self) { return .rounded }
        return .custom
    }
}

struct StylePreset {
    enum Kind: String, CaseIterable, Identifiable { case square, rounded, custom; var id: String { rawValue } }
    var dotStyle: String
    var cornerSquareStyle: String
    var cornerDotStyle: String
    var borderRadius: Int

    func matches(_ d: QRDesign) -> Bool {
        d.dotStyle == dotStyle && d.cornerSquareStyle == cornerSquareStyle
            && d.cornerDotStyle == cornerDotStyle && d.borderRadius == borderRadius
    }

    static let square = StylePreset(dotStyle: "square", cornerSquareStyle: "square", cornerDotStyle: "square", borderRadius: 0)
    static let rounded = StylePreset(dotStyle: "rounded", cornerSquareStyle: "extra-rounded", cornerDotStyle: "dot", borderRadius: 14)
}
