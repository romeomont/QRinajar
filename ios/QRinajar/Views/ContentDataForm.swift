import SwiftUI

// Data-entry step: type-specific fields + error correction, extracted so the
// create flow's "Enter details" step can embed it directly.
struct ContentDataForm: View {
    @Environment(QRDesign.self) private var design
    @State private var showECC = false

    var body: some View {
        @Bindable var design = design
        VStack(spacing: 20) {
            GroupCard {
                switch design.contentType {
                case .website:
                    LabeledField("Website URL") {
                        TextField("https://example.com", text: $design.websiteURL)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                case .text:
                    LabeledField("Text") {
                        TextField("Hello, world!", text: $design.textBody, axis: .vertical)
                            .lineLimit(3...8)
                    }
                case .social:
                    LabeledField("Profile URL") {
                        TextField("https://instagram.com/yourhandle", text: $design.socialURL)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                case .wifi:
                    LabeledField("Network name (SSID)") {
                        TextField("MyWiFiNetwork", text: $design.wifiSSID).autocorrectionDisabled()
                    }
                    LabeledField("Password") {
                        TextField("password", text: $design.wifiPassword).autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Picker("Security", selection: $design.wifiSecurity) {
                        Text("WPA/WPA2").tag("WPA")
                        Text("WEP").tag("WEP")
                        Text("None").tag("nopass")
                    }
                    Toggle("Hidden network", isOn: $design.wifiHidden)
                case .contact:
                    HStack {
                        LabeledField("First") { TextField("Jane", text: $design.contactFirst) }
                        LabeledField("Last") { TextField("Doe", text: $design.contactLast) }
                    }
                    LabeledField("Organization") { TextField("Example Org", text: $design.contactOrg) }
                    LabeledField("Title") { TextField("Field Technician", text: $design.contactTitle) }
                    LabeledField("Phone") {
                        TextField("+1 555 0100", text: $design.contactPhone).keyboardType(.phonePad)
                    }
                    LabeledField("Email") {
                        TextField("jane@example.com", text: $design.contactEmail)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.emailAddress)
                    }
                    LabeledField("URL") {
                        TextField("https://example.com", text: $design.contactURL)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    }
                }
            }

            HStack {
                Button {
                    showECC = true
                } label: {
                    HStack {
                        Label("Error correction", systemImage: "checkmark.shield")
                        Spacer()
                        Text(design.ecc).foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                InfoTip(
                    title: "Error correction",
                    text: "How much of the code can be damaged, dirty, or covered by a logo and still scan. Higher levels survive more damage but pack the code with denser modules. M is a good default; use Q or H if you're adding a center logo."
                )
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        }
        .sheet(isPresented: $showECC) {
            ECCSheet(ecc: $design.ecc)
                .presentationDetents([.medium])
        }
    }
}

struct ECCSheet: View {
    @Binding var ecc: String
    @Environment(\.dismiss) private var dismiss

    private let options: [(String, String)] = [
        ("L", "7% recovery — max capacity"),
        ("M", "15% recovery — recommended default"),
        ("Q", "25% recovery — good with a logo"),
        ("H", "30% recovery — best with a logo"),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(options, id: \.0) { opt in
                        Button {
                            ecc = opt.0; dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(opt.0).font(.headline)
                                    Text(opt.1).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if ecc == opt.0 { Image(systemName: "checkmark").foregroundStyle(brandBlue) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Error correction")
                } footer: {
                    Text("Use Q or H when embedding a center logo. Long text makes a denser code — run Test scan before printing.")
                }
            }
            .navigationTitle("Error correction")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
