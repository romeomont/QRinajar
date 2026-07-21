import SwiftUI

// Small shared building blocks used across the tabs.

struct GroupCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial))
    }
}

struct LabeledField<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content
                .textFieldStyle(.plain)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.5)))
        }
    }
}

struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 1
    var format: (Double) -> String = { String(Int($0)) }
    var tip: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                if let tip { InfoTip(title: title, text: tip) }
                Spacer()
                Text(format(value)).font(.caption.monospacedDigit()).foregroundStyle(brandBlue)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// Bridges an Int model field to a Double-based slider.
struct IntSlider: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Double>
    var suffix: String = ""
    var tip: String? = nil

    var body: some View {
        LabeledSlider(
            title: title,
            value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }),
            range: range,
            format: { "\(Int($0))\(suffix)" },
            tip: tip
        )
    }
}

// Section header used inside the Style sub-panels.
struct PanelHeader: View {
    let title: String
    let systemImage: String
    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}

// A small "i" button that pops over a plain-language explanation of a
// control — tap target for anything whose effect isn't obvious from its
// label alone (error correction, gradients, quiet zone, etc).
struct InfoTip: View {
    let title: String
    let text: String
    @State private var showing = false

    var body: some View {
        Button {
            showing = true
        } label: {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(width: 280, alignment: .leading)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// Attaches a title + InfoTip as a row header, so callers don't have to
// hand-build the HStack each time.
struct TipLabel: View {
    let title: String
    let tip: String
    var body: some View {
        HStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            InfoTip(title: title, text: tip)
        }
    }
}

// Standalone controls that float over content (a sheet's close button, the
// flow's bottom Back/Next bar) don't automatically pick up Liquid Glass the
// way toolbar items do — apply these explicitly, with a plain fallback for
// pre-iOS 26.
struct GlassButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

// The create flow's floating Next/Save bar — a pill-shaped, elevated CTA
// that hovers above the safe area instead of a full-bleed bottom bar.
struct FloatingPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(brandBlue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: brandBlue.opacity(0.45), radius: 16, x: 0, y: 8)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GlassProminentButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent).tint(brandBlue)
        } else {
            content.buttonStyle(.borderedProminent).tint(brandBlue)
        }
    }
}

// A soft brand-tinted backdrop behind scroll content.
struct BackdropGradient: View {
    var body: some View {
        LinearGradient(
            colors: [brandBlue.opacity(0.12), .clear],
            startPoint: .top, endPoint: .center
        )
        .ignoresSafeArea()
    }
}
