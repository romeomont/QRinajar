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
    @State private var showStartAnotherAlert = false
    @State private var showSaveAlert = false
    @State private var saveName = ""
    @State private var showSavedToastFlag = false
    @State private var savedToastMessage = "Added to Library"
    @State private var savedToastWorkItem: DispatchWorkItem?
    @State private var showFlyToLibrary = false
    @State private var flyToLibraryAtTarget = false

    // A periodic "New" crossfade over the start-over button, drawing
    // attention to it without being constant — repeats every 30s rather
    // than looping continuously.
    @State private var showStartOverNewLabel = false
    @State private var startOverBounceScheduled = false

    // A gentle, continuous twinkle on the start-over circle — three tiny
    // sparkles fading in and out on their own staggered, slow cycles so it
    // never reads as one uniform blink.
    @State private var sparkle1 = false
    @State private var sparkle2 = false
    @State private var sparkle3 = false

    private var sparkles: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 7))
                .foregroundStyle(brandBlue.opacity(sparkle1 ? 0.9 : 0.15))
                .scaleEffect(sparkle1 ? 1 : 0.6)
                .offset(x: 18, y: -20)
            Image(systemName: "sparkle")
                .font(.system(size: 6))
                .foregroundStyle(brandBlue.opacity(sparkle2 ? 0.85 : 0.1))
                .scaleEffect(sparkle2 ? 1 : 0.6)
                .offset(x: -20, y: 12)
            Image(systemName: "sparkle")
                .font(.system(size: 5))
                .foregroundStyle(brandBlue.opacity(sparkle3 ? 0.9 : 0.1))
                .scaleEffect(sparkle3 ? 1 : 0.6)
                .offset(x: 15, y: 18)
        }
    }

    // Tracks the exact design last written to the Library so a repeat
    // Save with nothing changed can say so instead of writing a duplicate.
    @State private var lastSavedSnapshot: DesignSnapshot?

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
                        // Scrolls with the rest of the form instead of being
                        // pinned up top with the preview — it doesn't need
                        // to stay visible the way the live QR preview does.
                        @Bindable var design = design
                        ECCThermometer(ecc: $design.ecc)
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
        .overlay(alignment: .top) {
            // A small icon that flings itself up toward the Library's
            // toolbar button when a save lands, so the badge's new count
            // feels connected to the action that caused it (approximate
            // target — toolbar items aren't reachable for an exact
            // matchedGeometryEffect across the nav bar boundary).
            if showFlyToLibrary {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(brandBlue))
                    .scaleEffect(flyToLibraryAtTarget ? 0.35 : 1)
                    .opacity(flyToLibraryAtTarget ? 0 : 1)
                    .offset(
                        x: flyToLibraryAtTarget ? 150 : 0,
                        y: flyToLibraryAtTarget ? 8 : 240
                    )
            }
        }
        .overlay(alignment: .bottom) {
            if showSavedToastFlag {
                Label(savedToastMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.85), in: Capsule())
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityShareSheet(activityItems: [item.image])
        }
        .navigationTitle(step.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(BackdropGradient())
        .toolbar {
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
                    // Extra trailing/top space inside the button's own frame
                    // (rather than an .offset overlay past its edge) so the
                    // badge doesn't get clipped by the toolbar's glass pill,
                    // which masks anything overhanging its rounded bounds.
                    Image(systemName: "books.vertical")
                        .padding(.top, 6)
                        .padding(.trailing, 6)
                        .overlay(alignment: .topTrailing) {
                            if store.newCount > 0 {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 9, height: 9)
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showLibrary) {
            // Interactive dismiss disabled — its own downward-drag gesture
            // otherwise fights with row swipe-to-delete, closing the whole
            // sheet on an imprecise or diagonal swipe.
            LibraryView()
                .interactiveDismissDisabled()
        }
        .onChange(of: showLibrary) { _, isShowing in
            // Marks viewed on dismiss, not open — so rows can still show a
            // "New" tag while the Library is open, then both the row tags
            // and the toolbar badge clear together once it's closed.
            if !isShowing { store.markLibraryViewed() }
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
                GeometryReader { geo in
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        // Start-over sits to the left of SAVE — same
                        // destructive confirm, smaller footprint than its
                        // old standalone card.
                        Button {
                            // If this exact design is already saved and
                            // untouched since, starting another doesn't
                            // discard anything unsaved — just do it, no
                            // confirmation needed.
                            if let last = lastSavedSnapshot, last == design.snapshot {
                                design.apply(.factory)
                                path = []
                            } else {
                                showStartAnotherAlert = true
                            }
                        } label: {
                            ZStack {
                                sparkles

                                Image(systemName: "plus")
                                    .font(.headline.weight(.bold))
                                    .opacity(showStartOverNewLabel ? 0 : 1)
                                Text("New")
                                    .font(.caption.weight(.bold))
                                    .opacity(showStartOverNewLabel ? 1 : 0)
                            }
                            .foregroundStyle(brandBlue)
                            .frame(width: 60, height: 60)
                        }
                        .background(Circle().fill(.ultraThinMaterial))
                        .buttonStyle(.plain)
                        .onAppear {
                            guard !startOverBounceScheduled else { return }
                            startOverBounceScheduled = true
                            scheduleStartOverBounce()
                            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                                sparkle1 = true
                            }
                            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true).delay(0.5)) {
                                sparkle2 = true
                            }
                            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true).delay(0.9)) {
                                sparkle3 = true
                            }
                        }

                        Button {
                            // Save goes straight to the Library — no dialog
                            // gating it. If nothing's changed since the last
                            // save, say so instead of writing a duplicate.
                            if let last = lastSavedSnapshot, last == design.snapshot {
                                showSavedToast(message: "Already in Library")
                            } else {
                                saveName = defaultName()
                                showSaveAlert = true
                            }
                        } label: {
                            Text("SAVE")
                                .font(.headline.weight(.bold))
                        }
                        .buttonStyle(FloatingPillButtonStyle())
                        .frame(width: geo.size.width / 2)

                        // Share is a secondary option to the right of Save,
                        // not a gate in front of it — the native share sheet
                        // already offers Save Image, Copy, AirDrop, etc.
                        Button {
                            if let ui = QRCardRenderer.composeImage(design.snapshot, opaque: false) {
                                shareItem = ShareItem(image: ui)
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(brandBlue)
                                .frame(width: 60, height: 60)
                        }
                        .background(Circle().fill(.ultraThinMaterial))
                        .buttonStyle(.plain)
                        Spacer(minLength: 0)
                    }
                }
                .frame(height: 60)
                .alert("Discard this design?", isPresented: $showStartAnotherAlert) {
                    Button("Discard", role: .destructive) {
                        design.apply(.factory)
                        path = []
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Starting another QR code will clear what you have now. Save it first if you want to keep it.")
                }
            } else {
                GeometryReader { geo in
                    HStack {
                        Spacer(minLength: 0)
                        Button {
                            if let next = FlowStep(rawValue: step.rawValue + 1) {
                                path.append(next)
                            }
                        } label: {
                            Text("NEXT")
                                .font(.headline.weight(.bold))
                        }
                        .buttonStyle(FloatingPillButtonStyle())
                        .frame(width: geo.size.width / 2)
                        Spacer(minLength: 0)
                    }
                }
                .frame(height: 60)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
        .alert("Save to Library", isPresented: $showSaveAlert) {
            TextField("Name", text: $saveName)
            Button("Save") {
                let name = saveName.trimmingCharacters(in: .whitespaces)
                store.save(name: name.isEmpty ? defaultName() : name, design: design.snapshot)
                lastSavedSnapshot = design.snapshot
                showSavedToast(message: "Added to Library")
                animateSaveToLibrary()
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

    private func scheduleStartOverBounce() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            // A slow crossfade to "New" directly over the plus icon, then
            // back — no bounce, just a quiet, unhurried call-out.
            withAnimation(.easeInOut(duration: 0.8)) {
                showStartOverNewLabel = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showStartOverNewLabel = false
                }
            }
            scheduleStartOverBounce()
        }
    }

    private func animateSaveToLibrary() {
        flyToLibraryAtTarget = false
        showFlyToLibrary = true
        withAnimation(.easeIn(duration: 0.5)) {
            flyToLibraryAtTarget = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            showFlyToLibrary = false
        }
    }

    private func showSavedToast(message: String) {
        savedToastWorkItem?.cancel()
        savedToastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showSavedToastFlag = true
        }
        let work = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.25)) {
                showSavedToastFlag = false
            }
        }
        savedToastWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
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
