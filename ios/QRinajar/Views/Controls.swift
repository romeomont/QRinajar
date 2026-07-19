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

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.caption).foregroundStyle(.secondary)
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

    var body: some View {
        LabeledSlider(
            title: title,
            value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }),
            range: range,
            format: { "\(Int($0))\(suffix)" }
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
