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
        case .export: return "Share"
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
    @Environment(\.colorScheme) private var colorScheme
    @AppColorSchemeStorage private var appearance
    @State private var showLibrary = false
    @State private var shareItem: ShareItem?
    @State private var showFinishOptions = false
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

            if step == .data {
                @Bindable var design = design
                ECCThermometer(ecc: $design.ecc)
                    .padding(.horizontal)
                    .padding(.top, 12)
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
                        EmptyView()
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
        .sheet(item: $shareItem) { item in
            ActivityShareSheet(activityItems: [item.image])
        }
        .navigationTitle(step.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(BackdropGradient())
        .toolbar {
            if step != .type {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Starts a genuinely new code, not just a blank
                        // form pre-loaded with whatever was last edited.
                        design.apply(.factory)
                        path = []
                    } label: {
                        Image(systemName: "plus")
                    }
                    .modifier(GlassButtonStyle())
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    // Tapping switches straight to the opposite of whatever
                    // is currently on screen — no settings detour. "Follow
                    // System" is only reachable by matching the device's
                    // own appearance, not from here.
                    appearance = colorScheme == .dark ? .light : .dark
                } label: {
                    // Shows the mode a tap would take you toward, not the
                    // mode you're in — dark mode shows the sun, light shows
                    // the moon, same convention as most system toggles.
                    Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
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

    // No Back button here — the nav bar's own back chevron (from the real
    // NavigationStack push) already covers that.
    private var footer: some View {
        Group {
            if step == .export {
                Button {
                    showFinishOptions = true
                } label: {
                    Text("FINISH")
                        .font(.headline.weight(.bold))
                }
                .buttonStyle(FloatingPillButtonStyle())
                .confirmationDialog("Finish", isPresented: $showFinishOptions, titleVisibility: .hidden) {
                    Button("Save") {
                        // Auto-named, no prompt — Finish is meant to be a
                        // single tap, and the Library shows the result
                        // immediately after so the user can rename there.
                        store.save(name: defaultName(), design: design.snapshot)
                        showLibrary = true
                    }
                    Button("Share") {
                        // The native share sheet already offers Save Image,
                        // Copy, AirDrop, etc. as built-in actions, so there's
                        // no need for a custom Copy/Save/Share picker here.
                        if let ui = QRCardRenderer.composeImage(design.snapshot, opaque: false) {
                            shareItem = ShareItem(image: ui)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } else {
                Button {
                    if let next = FlowStep(rawValue: step.rawValue + 1) {
                        path.append(next)
                    }
                } label: {
                    Text("NEXT")
                        .font(.headline.weight(.bold))
                }
                .buttonStyle(FloatingPillButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
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

    // design.contentType always has a real value (it defaults to .website
    // so the rest of the model has something to work with), but nothing
    // should read as "selected" here until the user actually taps a card.
    @State private var hasSelected = false

    private var orderedTypes: [ContentType] {
        ContentType.allCases.filter { $0 != .text } + [.text]
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QR codes are everywhere, here are some common ones! If you need something custom hit that custom button.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            typeGrid
        }
    }

    private var typeGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(orderedTypes) { t in
                Button {
                    design.contentType = t
                    hasSelected = true
                    onSelect()
                } label: {
                    let selected = hasSelected && design.contentType == t
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(selected ? brandBlue.opacity(0.28) : brandBlue.opacity(0.12))
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
                            .fill(selected ? brandBlue.opacity(0.15) : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(selected ? brandBlue : Color.clear, lineWidth: 2)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
