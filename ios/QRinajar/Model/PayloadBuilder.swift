import Foundation

// Ports PRESET_DATA / VCARD payload string builders from src/main.js.
enum PayloadBuilder {

    // Escape special characters for the WIFI: string format (\ ; , : ").
    static func wifiEscape(_ s: String) -> String {
        var out = ""
        for ch in s {
            if "\\;,:\"".contains(ch) { out.append("\\") }
            out.append(ch)
        }
        return out
    }

    static func wifiString(ssid: String, password: String, security: String, hidden: Bool) -> String {
        // Matches "WIFI:T:WPA;S:MyWiFiNetwork;P:changeme123;;"
        let t = security // WPA / WEP / nopass
        let s = wifiEscape(ssid)
        let p = security == "nopass" ? "" : wifiEscape(password)
        var out = "WIFI:T:\(t);S:\(s);P:\(p);"
        if hidden { out += "H:true;" }
        out += ";"
        return out
    }

    static func vCard(first: String, last: String, org: String, title: String,
                      phone: String, email: String, url: String) -> String {
        // Matches the VCARD template in main.js (VERSION 3.0, CRLF-free join like the source).
        return """
        BEGIN:VCARD
        VERSION:3.0
        N:\(last);\(first);;;
        FN:\(first) \(last)
        ORG:\(org)
        TITLE:\(title)
        TEL;TYPE=CELL:\(phone)
        EMAIL:\(email)
        URL:\(url)
        END:VCARD
        """
    }

    static func build(from d: QRDesign) -> String {
        switch d.contentType {
        case .website:
            return d.websiteURL
        case .text:
            return d.textBody
        case .social:
            return d.socialURL
        case .wifi:
            return wifiString(ssid: d.wifiSSID, password: d.wifiPassword,
                              security: d.wifiSecurity, hidden: d.wifiHidden)
        case .contact:
            return vCard(first: d.contactFirst, last: d.contactLast, org: d.contactOrg,
                         title: d.contactTitle, phone: d.contactPhone,
                         email: d.contactEmail, url: d.contactURL)
        }
    }
}
