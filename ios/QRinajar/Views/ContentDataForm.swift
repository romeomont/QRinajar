import SwiftUI

// Data-entry step: type-specific fields + error correction, extracted so the
// create flow's "Enter details" step can embed it directly.
struct ContentDataForm: View {
    @Environment(QRDesign.self) private var design

    // A dimmer prompt than the system default so the demo text (e.g.
    // "https://example.com") reads clearly as an example to fill in, not as
    // already-entered content.
    private func hint(_ text: String) -> Text {
        Text(text).foregroundStyle(.secondary.opacity(0.55))
    }

    var body: some View {
        @Bindable var design = design
        VStack(spacing: 20) {
            GroupCard {
                switch design.contentType {
                case .website:
                    LabeledField("Website URL") {
                        TextField("", text: $design.websiteURL, prompt: hint("https://example.com"))
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                case .text:
                    LabeledField("Text") {
                        TextField("", text: $design.textBody, prompt: hint("Hello, world!"), axis: .vertical)
                            .lineLimit(3...8)
                    }
                case .social:
                    LabeledField("Profile URL") {
                        TextField("", text: $design.socialURL, prompt: hint("https://instagram.com/yourhandle"))
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                case .wifi:
                    LabeledField("Network name (SSID)") {
                        TextField("", text: $design.wifiSSID, prompt: hint("MyWiFiNetwork")).autocorrectionDisabled()
                    }
                    LabeledField("Password") {
                        TextField("", text: $design.wifiPassword, prompt: hint("password")).autocorrectionDisabled()
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
                        LabeledField("First") { TextField("", text: $design.contactFirst, prompt: hint("Jane")) }
                        LabeledField("Last") { TextField("", text: $design.contactLast, prompt: hint("Doe")) }
                    }
                    LabeledField("Organization") { TextField("", text: $design.contactOrg, prompt: hint("Example Org")) }
                    LabeledField("Title") { TextField("", text: $design.contactTitle, prompt: hint("Field Technician")) }
                    LabeledField("Phone") {
                        TextField("", text: $design.contactPhone, prompt: hint("+1 555 0100")).keyboardType(.phonePad)
                    }
                    LabeledField("Email") {
                        TextField("", text: $design.contactEmail, prompt: hint("jane@example.com"))
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.emailAddress)
                    }
                    LabeledField("URL") {
                        TextField("", text: $design.contactURL, prompt: hint("https://example.com"))
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    }
                }
            }

        }
    }
}

// An under-bracket ("⊔") connecting the two ECC options recommended for a
// logo, drawn beneath the Q and H columns of the thermometer.
struct LogoBracketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
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

    // A slow, subtle breathing highlight near the end of each unselected
    // bar — just enough to read as "there's more here" without competing
    // for attention with the selected level.
    @State private var inactivePulse = false

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
                                .overlay {
                                    if i > selectedIndex {
                                        // A full-bar gradient (not just a
                                        // sliver) so the pulse reads as the
                                        // bar actually filling in toward the
                                        // end, rather than an empty capsule
                                        // with a faint dot on it.
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.clear, brandBlue.opacity(inactivePulse ? 0.55 : 0.15)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(height: 10)
                                    }
                                }
                            Text(levels[i].0)
                                .font(.caption2.weight(i == selectedIndex ? .bold : .regular))
                                .foregroundStyle(i == selectedIndex ? brandBlue : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    inactivePulse = true
                }
            }

            // Q and H are the two levels worth choosing for a logo — a
            // bracket spanning just those two columns makes that pairing
            // legible at a glance rather than buried in the info tip text.
            GeometryReader { geo in
                let spacing: CGFloat = 6
                let count = CGFloat(levels.count)
                let segmentWidth = (geo.size.width - spacing * (count - 1)) / count
                let bracketWidth = segmentWidth * 2 + spacing
                let bracketX = (segmentWidth + spacing) * 2

                VStack(spacing: 2) {
                    LogoBracketShape()
                        .stroke(brandBlue, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .frame(width: bracketWidth, height: 6)
                    Text("Best for logos")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(brandBlue)
                }
                .frame(width: bracketWidth)
                .position(x: bracketX + bracketWidth / 2, y: geo.size.height / 2)
            }
            .frame(height: 26)

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

