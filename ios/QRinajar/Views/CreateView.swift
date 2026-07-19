import SwiftUI

struct CreateView: View {
    @Environment(QRDesign.self) private var design
    @State private var showECC = false

    var body: some View {
        @Bindable var design = design
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PreviewCard()

                    // Content type selector
                    Picker("Content type", selection: $design.contentType) {
                        ForEach(ContentType.allCases) { t in
                            Label(t.label, systemImage: t.symbol).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    contentForm(design)

                    Button {
                        showECC = true
                    } label: {
                        HStack {
                            Label("Error correction", systemImage: "checkmark.shield")
                            Spacer()
                            Text(design.ecc).foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                }
                .padding()
            }
            .navigationTitle("Create")
            .background(BackdropGradient())
            .sheet(isPresented: $showECC) {
                ECCSheet(ecc: $design.ecc)
                    .presentationDetents([.medium])
            }
        }
    }

    @ViewBuilder
    private func contentForm(_ design: QRDesign) -> some View {
        @Bindable var design = design
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
