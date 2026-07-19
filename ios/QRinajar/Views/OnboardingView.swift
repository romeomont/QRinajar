import SwiftUI

// First-launch wizard: pick what kind of data to encode, then a starting
// style, then apply both to the shared design and hand off to the app.
struct OnboardingView: View {
    @Environment(QRDesign.self) private var design
    @Binding var isPresented: Bool

    @State private var step = 0
    @State private var selectedType: ContentType = .website
    @State private var selectedStyle: StylePreset.Kind = .rounded

    private let steps = ["What are you sharing?", "Pick a starting style"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProgressView(value: Double(step + 1), total: Double(steps.count))
                    .tint(brandBlue)

                if step == 0 {
                    contentTypeStep
                } else {
                    styleStep
                }

                Spacer()

                Button {
                    if step == 0 {
                        design.contentType = selectedType
                        withAnimation { step = 1 }
                    } else {
                        design.applyStyle(selectedStyle == .square ? .square : .rounded)
                        isPresented = false
                    }
                } label: {
                    Text(step == 0 ? "Next" : "Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(brandBlue)
            }
            .padding()
            .navigationTitle(steps[step])
            .navigationBarTitleDisplayMode(.inline)
            .background(BackdropGradient())
        }
        .interactiveDismissDisabled()
    }

    private var contentTypeStep: some View {
        VStack(spacing: 12) {
            ForEach(ContentType.allCases) { t in
                Button {
                    selectedType = t
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: t.symbol)
                            .font(.title3)
                            .foregroundStyle(brandBlue)
                            .frame(width: 28)
                        Text(t.id == "text" ? "Custom text" : t.label)
                            .font(.body.weight(.medium))
                        Spacer()
                        if selectedType == t {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(brandBlue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedType == t ? brandBlue.opacity(0.15) : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selectedType == t ? brandBlue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var styleStep: some View {
        HStack(spacing: 12) {
            ForEach(StylePreset.Kind.allCases.filter { $0 != .custom }) { kind in
                StylePresetCard(kind: kind, active: selectedStyle == kind) {
                    selectedStyle = kind
                }
            }
        }
    }
}
