import SwiftUI

// The whole app is one guided flow: pick what you're sharing, enter the
// details, style it, then save/export. Library is reachable at any step via
// the toolbar button.
enum FlowStep: Int, CaseIterable, Hashable {
    case type, data, style, export

    var title: String {
        switch self {
        case .type: return "What are you sharing?"
        case .data: return "Enter the details"
        case .style: return "Style it"
        case .export: return "Save & export"
        }
    }
}

struct CreateFlowView: View {
    // Real pushes onto a NavigationStack, one per step, so the system's
    // edge-swipe-to-go-back gesture works the same as any other iOS app —
    // swapping a single view's content in place (the old approach) doesn't
    // give you that gesture for free.
    @State private var path: [FlowStep] = []

    init() {
        // Lets the screenshot/self-test tooling jump straight to a step
        // (see capture_screenshots.sh), same trick the old tab bar used.
        let raw = Int(ProcessInfo.processInfo.environment["QRINAJAR_TAB"] ?? "0") ?? 0
        if let target = FlowStep(rawValue: raw), target != .type {
            _path = State(initialValue: Array(FlowStep.allCases[1...target.rawValue]))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            FlowStepView(step: .type, path: $path)
                .navigationDestination(for: FlowStep.self) { step in
                    FlowStepView(step: step, path: $path)
                }
        }
    }
}

private struct FlowStepView: View {
    let step: FlowStep
    @Binding var path: [FlowStep]

    @Environment(QRDesign.self) private var design
    @Environment(PresetStore.self) private var store
    @State private var showLibrary = false
    @State private var showSaveAlert = false
    @State private var saveName = ""

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step.rawValue + 1), total: Double(FlowStep.allCases.count))
                .tint(brandBlue)
                .padding(.horizontal)
                .padding(.top, 8)

            if step != .type {
                // Pinned so the live effect of every control stays visible.
                PreviewCard(maxHeight: step == .export ? 320 : 200, bare: step == .data)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            ScrollView {
                VStack(spacing: 20) {
                    switch step {
                    case .type:
                        ContentTypePicker()
                    case .data:
                        ContentDataForm()
                    case .style:
                        StylePresetRow()
                        StyleCustomPanels()
                    case .export:
                        ExportPanel()
                    }
                }
                .padding()
            }

            footer
        }
        .navigationTitle(step.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(BackdropGradient())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLibrary = true
                } label: {
                    Image(systemName: "tray.full")
                }
            }
        }
        .sheet(isPresented: $showLibrary) {
            LibraryView()
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step != .type {
                Button("Back") {
                    path.removeLast()
                }
                .buttonStyle(.bordered)
            }

            if step == .export {
                Button {
                    saveName = defaultName()
                    showSaveAlert = true
                } label: {
                    Text("Save to Library").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(brandBlue)
            } else {
                Button {
                    if let next = FlowStep(rawValue: step.rawValue + 1) {
                        path.append(next)
                    }
                } label: {
                    Text("Next").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(brandBlue)
            }
        }
        .padding()
        .alert("Save to Library", isPresented: $showSaveAlert) {
            TextField("Name", text: $saveName)
            Button("Save") {
                let name = saveName.trimmingCharacters(in: .whitespaces)
                store.save(name: name.isEmpty ? defaultName() : name, design: design.snapshot)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func defaultName() -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, HH:mm"
        return "Design " + f.string(from: Date())
    }
}

// Step 1: pick what kind of data this QR code encodes.
struct ContentTypePicker: View {
    @Environment(QRDesign.self) private var design

    var body: some View {
        @Bindable var design = design
        VStack(spacing: 12) {
            ForEach(ContentType.allCases) { t in
                Button {
                    design.contentType = t
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: t.symbol)
                            .font(.title3)
                            .foregroundStyle(brandBlue)
                            .frame(width: 28)
                        Text(t.id == "text" ? "Custom text" : t.label)
                            .font(.body.weight(.medium))
                        Spacer()
                        if design.contentType == t {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(brandBlue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(design.contentType == t ? brandBlue.opacity(0.15) : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(design.contentType == t ? brandBlue : Color.clear, lineWidth: 2)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
