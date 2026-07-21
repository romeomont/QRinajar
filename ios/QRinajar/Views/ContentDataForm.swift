import SwiftUI

// Data-entry step: type-specific fields + error correction, extracted so the
// create flow's "Enter details" step can embed it directly.
struct ContentDataForm: View {
    @Environment(QRDesign.self) private var design

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

        }
    }
}

// A 4-stop thermometer (L/M/Q/H) that lives right under the QR preview so
// the effect of raising error correction is visible immediately, instead
// of behind a sheet.
struct ECCThermometer: View {
    @Binding var ecc: String
    @State private var showInfo = false

    private let levels: [(String, String)] = [
        ("L", "7% recovery — max capacity"),
        ("M", "15% recovery — recommended default"),
        ("Q", "25% recovery — good with a logo"),
        ("H", "30% recovery — best with a logo"),
    ]

    // The percent each level actually recovers, used to size the covered
    // corner in the visual below.
    private let percents: [Double] = [0.07, 0.15, 0.25, 0.30]

    private var selectedIndex: Int {
        levels.firstIndex { $0.0 == ecc } ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Error correction", systemImage: "checkmark.shield")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(levels[selectedIndex].1)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                InfoTip(
                    title: "Error correction",
                    text: "How much of the code can be missing, dirty, or obscured by a logo and still scan. Higher levels tolerate more missing area but pack the code with denser modules. M is a good default; use Q or H if you're adding a center logo."
                )
            }

            HStack(spacing: 6) {
                ForEach(levels.indices, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            ecc = levels[i].0
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Capsule()
                                .fill(i <= selectedIndex ? brandBlue : Color.secondary.opacity(0.2))
                                .frame(height: 10)
                            Text(levels[i].0)
                                .font(.caption2.weight(i == selectedIndex ? .bold : .regular))
                                .foregroundStyle(i == selectedIndex ? brandBlue : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            RecoveryVisual(percent: percents[selectedIndex])
                .padding(.top, 4)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
    }
}

// Shows, at a glance, how much of the code the current level can lose to
// dirt/damage/a logo and still scan: a mock module grid with a chunk
// covered, sized to the selected level's actual recovery percentage.
struct RecoveryVisual: View {
    var percent: Double

    private let gridSize = 7

    // A fixed, hand-picked module pattern — just needs to read as
    // "QR-ish," not encode anything real.
    private let pattern: Set<Int> = [
        0, 2, 3, 5, 8, 10, 13, 14, 16, 18, 19, 21, 23, 24, 27, 29,
        30, 32, 35, 36, 38, 41, 43, 44, 46, 47,
    ]

    // The real percentages (7–30%) barely register visually at true scale,
    // so the covered corner is exaggerated (roughly doubled) purely to make
    // the L → H difference legible at a glance — the number alongside it
    // is still the real figure.
    private var coverFraction: Double {
        min(percent * 2.2, 0.62)
    }

    // A gentle continuous breathing pulse on the patch, plus a quick bump
    // whenever the level changes — just enough motion to draw the eye to
    // what the patch means without being distracting.
    @State private var pulse = false
    @State private var bump = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geo in
                    let cell = geo.size.width / CGFloat(gridSize)
                    Canvas { ctx, size in
                        for row in 0..<gridSize {
                            for col in 0..<gridSize {
                                guard pattern.contains(row * gridSize + col) else { continue }
                                let rect = CGRect(
                                    x: CGFloat(col) * cell + 1, y: CGFloat(row) * cell + 1,
                                    width: cell - 2, height: cell - 2
                                )
                                ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(.black.opacity(0.85)))
                            }
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // The "damaged" patch — proportionally sized to what this
                // level can tolerate — with a checkmark to show it still scans.
                GeometryReader { geo in
                    let side = geo.size.width * CGFloat(coverFraction)
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(brandBlue)
                        Image(systemName: "checkmark")
                            .font(.system(size: max(side * 0.45, 8), weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: side, height: side)
                    .position(x: geo.size.width - side / 2, y: geo.size.height - side / 2)
                    .scaleEffect(pulse ? 1.08 : 1, anchor: .bottomTrailing)
                }
            }
            .frame(width: 64, height: 64)
            .background(RoundedRectangle(cornerRadius: 8).fill(.white))
            .scaleEffect(bump ? 1.06 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .onChange(of: percent) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                    bump = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        bump = false
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Still scans even with part missing or obscured")
                    .font(.caption2.weight(.semibold))
                Text("Blue patch shows roughly how much of the code can be missing, dirty, or covered by a logo at this level and still scan.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

