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
    @State private var showSettings = false
    @State private var showSaveAlert = false
    @State private var saveName = ""

    // Guards against losing style edits: captured when this step appears,
    // compared against the live design when the user backs out.
    @State private var styleEntrySnapshot: DesignSnapshot?
    @State private var showUnsavedChangesAlert = false
    @State private var pendingPopPath: [FlowStep]?

    // Custom's fine-tune panels only show once the user has actually opted
    // into them, so Square/Rounded stay a simple two-choice pick.
    @State private var showCustomPanels = false

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
                        ContentTypePicker {
                            // Picking a type is the whole decision for this
                            // step, so move on immediately instead of making
                            // the user tap Next too.
                            path.append(.data)
                        }
                    case .data:
                        ContentDataForm()
                    case .style:
                        StylePresetRow { kind in
                            showCustomPanels = (kind == .custom)
                        }
                        if showCustomPanels {
                            StyleCustomPanels()
                        }
                    case .export:
                        ExportPanel()
                    }
                }
                .padding()
                // Extra clearance so the floating scanner button never sits
                // permanently over the last card once scrolled to the bottom.
                .padding(.bottom, 60)
            }

            // Step 1 auto-advances on selection, so there's nothing for a
            // footer to do there.
            if step != .type {
                footer
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Reachable from every step, not just Export — scanning is a
            // separate action from building a code, not tied to one step.
            ScannerButton()
                .padding(.trailing, 16)
                .padding(.bottom, step == .type ? 20 : 88)
        }
        .navigationTitle(step.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(BackdropGradient())
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            if step == .style {
                styleEntrySnapshot = design.snapshot
                showCustomPanels = design.activeStyle == .custom
            }
        }
        .onChange(of: path) { oldPath, newPath in
            // Only care about this step being popped (back button or swipe),
            // not about it being pushed onto or navigated forward from.
            guard step == .style, newPath.count < oldPath.count, oldPath.last == step else { return }
            guard let entry = styleEntrySnapshot, design.snapshot != entry else { return }
            // Cancel the pop so we can ask first; re-applied below if the
            // user chooses to leave anyway.
            pendingPopPath = newPath
            path = oldPath
            showUnsavedChangesAlert = true
        }
        .alert("Unsaved style changes", isPresented: $showUnsavedChangesAlert) {
            Button("Save to Library") {
                saveName = defaultName()
                showSaveAlert = true
            }
            Button("Discard Changes", role: .destructive) {
                if let entry = styleEntrySnapshot { design.apply(entry) }
                if let target = pendingPopPath { path = target }
                pendingPopPath = nil
            }
            Button("Keep Editing", role: .cancel) {
                pendingPopPath = nil
            }
        } message: {
            Text("You changed the style but haven't saved it. Save this design to your library, or discard the changes?")
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            // No Back button here — the nav bar's own back chevron (from the
            // real NavigationStack push) already covers that.
            if step == .export {
                Button {
                    saveName = defaultName()
                    showSaveAlert = true
                } label: {
                    Text("Save to Library").frame(maxWidth: .infinity)
                }
                .modifier(GlassProminentButtonStyle())
            } else {
                Button {
                    if let next = FlowStep(rawValue: step.rawValue + 1) {
                        path.append(next)
                    }
                } label: {
                    Text("Next").frame(maxWidth: .infinity)
                }
                .modifier(GlassProminentButtonStyle())
            }
        }
        .padding()
        .alert("Save to Library", isPresented: $showSaveAlert) {
            TextField("Name", text: $saveName)
            Button("Save") {
                let name = saveName.trimmingCharacters(in: .whitespaces)
                store.save(name: name.isEmpty ? defaultName() : name, design: design.snapshot)
                if let target = pendingPopPath {
                    path = target
                    pendingPopPath = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingPopPath = nil
            }
        }
    }

    private func defaultName() -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, HH:mm"
        return "Design " + f.string(from: Date())
    }
}

// Step 1: pick what kind of data this QR code encodes. "Custom text" is the
// catch-all, so it sits last rather than in its declaration order.
struct ContentTypePicker: View {
    @Environment(QRDesign.self) private var design
    var onSelect: () -> Void = {}

    private var orderedTypes: [ContentType] {
        ContentType.allCases.filter { $0 != .text } + [.text]
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(orderedTypes) { t in
                Button {
                    design.contentType = t
                    onSelect()
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(design.contentType == t ? brandBlue.opacity(0.28) : brandBlue.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: t.symbol)
                                .font(.title2)
                                .foregroundStyle(brandBlue)
                        }
                        Text(t.id == "text" ? "Custom text" : t.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(design.contentType == t ? brandBlue.opacity(0.15) : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(design.contentType == t ? brandBlue : Color.clear, lineWidth: 2)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
