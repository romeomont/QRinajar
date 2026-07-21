import SwiftUI

struct LibraryView: View {
    @Environment(QRDesign.self) private var design
    @Environment(PresetStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var popupPreset: SavedPreset?

    // Only the first row demos its swipe (delete, then rename) — guaranteed
    // the very first time the Library is ever opened, then only as an
    // occasional reminder rather than every visit, so it doesn't pester
    // returning users.
    @AppStorage("librarySwipeDemoLastShown") private var lastDemoShown: Double = 0
    private let demoReminderInterval: TimeInterval = 14 * 24 * 60 * 60

    private var shouldPlayDemo: Bool {
        lastDemoShown == 0 || Date().timeIntervalSince1970 - lastDemoShown > demoReminderInterval
    }

    // Swipe-to-delete removes immediately (no confirmation prompt) — the
    // safety net is shaking the device to undo, matching Mail/Notes.
    @State private var lastDeleted: (preset: SavedPreset, index: Int)?
    @State private var undoWorkItem: DispatchWorkItem?

    // The sheet itself has interactiveDismissDisabled() (see
    // CreateFlowView) so row swipes can't accidentally close it — this
    // handle is the deliberate replacement for that gesture.
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Sits above the nav bar entirely, same position/shape as
            // QRPopupCard's handle, rather than tucked under the "Library"
            // title.
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard value.translation.height > 0 else { return }
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            // 20% less than QRPopupCard's handle (60/140) —
                            // the Library sheet closes with a lighter touch.
                            let flungDown = value.predictedEndTranslation.height > 112
                            if value.translation.height > 48 || flungDown {
                                dismiss()
                            } else {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )

            NavigationStack {
            ZStack(alignment: .bottom) {
            List {
                if store.presets.isEmpty {
                    ContentUnavailableView("No saved presets", systemImage: "tray",
                        description: Text("Save your current design to reuse it later."))
                } else {
                    Section {
                        ForEach(Array(store.presets.enumerated()), id: \.element.id) { index, preset in
                            LibraryRow(
                                preset: preset,
                                playDemo: index == 0 && shouldPlayDemo,
                                onOpen: {
                                    design.apply(preset.design)
                                    dismiss()
                                },
                                onShowQR: {
                                    withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                                        popupPreset = preset
                                    }
                                },
                                onDelete: { performDelete(preset, at: index) },
                                onDemoFinished: {
                                    lastDemoShown = Date().timeIntervalSince1970
                                },
                                onRename: { newName in store.rename(preset, to: newName) }
                            )
                        }
                    } header: {
                        Text("Saved presets")
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // No GlassButtonStyle here — toolbar items already get
                    // Liquid Glass automatically; adding it again stacked a
                    // second glass shape behind the icon.
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onShake { undoLastDelete() }

            if let preset = popupPreset {
                QRPopupCard(preset: preset) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                        popupPreset = nil
                    }
                }
                .zIndex(1)
            }
            }
        }
        }
        // Applied to the whole card (handle + nav bar + content) so it all
        // moves down together with the drag, same as QRPopupCard.
        .offset(y: dragOffset)
    }

    private func performDelete(_ preset: SavedPreset, at index: Int) {
        lastDeleted = (preset, index)
        store.delete(preset)

        undoWorkItem?.cancel()
        let work = DispatchWorkItem { lastDeleted = nil }
        undoWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: work)
    }

    private func undoLastDelete() {
        guard let (preset, index) = lastDeleted else { return }
        undoWorkItem?.cancel()
        lastDeleted = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            store.restore(preset, at: index)
        }
    }
}

// A self-drawn swipe-to-delete row (rather than List's built-in
// .swipeActions) so the first row can be driven programmatically for the
// one-time reveal demo — native swipeActions has no API for that.
private struct LibraryRow: View {
    let preset: SavedPreset
    let playDemo: Bool
    let onOpen: () -> Void
    let onShowQR: () -> Void
    let onDelete: () -> Void
    let onDemoFinished: () -> Void
    let onRename: (String) -> Void

    @State private var offset: CGFloat = 0
    // Where the row sat when the current drag began — lets a second drag on
    // an already-open row (e.g. reaching for full-swipe-delete, then
    // changing your mind) continue from there instead of being computed
    // from zero, which could snap the row shut even though nothing was
    // actually undone.
    @State private var dragStartOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var rowWidth: CGFloat = 360
    private let deleteWidth: CGFloat = 84
    private let editWidth: CGFloat = 84
    private let rowHeight: CGFloat = 76

    @State private var showRenameAlert = false
    @State private var renameText = ""

    // Only visible once the row has actually started sliding — at rest
    // there's no red anywhere, revealed only as the user (or the demo)
    // drags the content away from it.
    private var revealAmount: CGFloat {
        max(min(-offset / deleteWidth, 1), 0)
    }

    // Same idea for the leading-edge rename reveal, swiped the other way.
    private var editRevealAmount: CGFloat {
        max(min(offset / editWidth, 1), 0)
    }

    // Dragging past half the row's own width — not just past the reveal
    // button — commits to a full swipe-through action, Mail-style, on
    // either side.
    private var deleteThroughThreshold: CGFloat { rowWidth * 0.5 }
    private var editThroughThreshold: CGFloat { rowWidth * 0.5 }

    var body: some View {
        ZStack {
            HStack {
                // Grows to fill exactly the gap the content has slid open,
                // same as the delete side, so a full swipe-through reads as
                // one continuous blue sheet.
                ZStack(alignment: .leading) {
                    brandBlue
                        .frame(width: max(offset, 0), height: rowHeight)
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Rename").font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .frame(width: editWidth, height: rowHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
                        renameText = preset.name
                        showRenameAlert = true
                    }
                    .opacity(editRevealAmount)
                }
                Spacer()
            }

            HStack {
                Spacer()
                // Grows to fill exactly the gap the content has slid open, so a
                // full swipe-through reads as one continuous red sheet rather
                // than a fixed-width button trailing off into empty space.
                ZStack(alignment: .trailing) {
                    Color.red
                        .frame(width: max(-offset, 0), height: rowHeight)
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                        Text("Delete").font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .frame(width: deleteWidth, height: rowHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
                        onDelete()
                    }
                    .opacity(revealAmount)
                }
            }

            Button(action: handleContentTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(preset.name).font(.title3.weight(.semibold)).foregroundStyle(.primary)
                        Text(preset.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: onShowQR) {
                        Image(systemName: "qrcode")
                            .font(.title2)
                            .foregroundStyle(brandBlue)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .frame(height: rowHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.clear)
            .offset(x: offset)
            // simultaneousGesture (not .gesture) so the Button's own tap
            // recognizer never gets first refusal on the touch — the row
            // needs to start following the finger immediately, not after
            // the button decides it isn't a tap.
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartOffset = offset
                        }
                        let proposed = dragStartOffset + value.translation.width
                        offset = min(max(proposed, -rowWidth), rowWidth)
                    }
                    .onEnded { value in
                        let proposed = dragStartOffset + value.translation.width
                        isDragging = false

                        if proposed >= 0 {
                            // A fast rightward fling commits to rename
                            // immediately, even short of the halfway point —
                            // same full-swipe-through affordance as delete.
                            let predictedEndRight = dragStartOffset + value.predictedEndTranslation.width
                            let flungPastRight = predictedEndRight > editThroughThreshold
                            if proposed > editThroughThreshold || flungPastRight {
                                withAnimation(.easeIn(duration: 0.22)) {
                                    offset = rowWidth + 60
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    renameText = preset.name
                                    showRenameAlert = true
                                    offset = 0
                                }
                                return
                            }
                            // Otherwise a deliberate rightward swipe reveals
                            // and stays open; it only closes again if the
                            // user taps the row or swipes it back — never on
                            // its own.
                            let shouldReveal = proposed > editWidth / 2
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                offset = shouldReveal ? editWidth : 0
                            }
                            return
                        }
                        // Deletion only commits on a genuinely completed
                        // swipe — dragged (or carried by inertia) almost the
                        // entire width of the row. predictedEndTranslation
                        // folds in velocity, so a fast flick that hasn't
                        // physically reached the edge yet still counts, but
                        // a slow drag that merely crosses the reveal
                        // threshold and stops does not.
                        let fullSwipeThreshold = rowWidth * 0.85
                        let predictedEnd = dragStartOffset + value.predictedEndTranslation.width
                        if predictedEnd < -fullSwipeThreshold {
                            withAnimation(.easeIn(duration: 0.22)) {
                                offset = -rowWidth - 60
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onDelete()
                            }
                        } else {
                            // Was it dragged closer to open, or closer to
                            // closed? Whichever it ends nearer to is where
                            // it lands — a small further tug on an
                            // already-open row shouldn't dismiss it.
                            let shouldReveal = proposed < -deleteWidth / 2
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                offset = shouldReveal ? -deleteWidth : 0
                            }
                        }
                    }
            )
        }
        .frame(height: rowHeight)
        .background {
            GeometryReader { geo in
                Color.clear.onAppear { rowWidth = geo.size.width }
            }
        }
        .clipped()
        // No horizontal inset — the delete/rename color reaches the true
        // edges of the row (Mail-style); the row's own text content gets
        // its margin from padding inside the row instead.
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .onAppear {
            guard playDemo else { return }
            // A short peek-and-return on each side so a first-time user
            // discovers both swipe-to-delete and swipe-to-rename without
            // having to be told — delete first, then rename.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    offset = -deleteWidth
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        offset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            offset = editWidth
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                offset = 0
                            }
                            onDemoFinished()
                        }
                    }
                }
            }
        }
        .alert("Rename preset", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Save") { onRename(renameText) }
            Button("Cancel", role: .cancel) {}
        }
    }

    // While a reveal is open, tapping the row content is "tapping off" it —
    // it closes the reveal rather than opening the preset.
    private func handleContentTap() {
        guard offset == 0 else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { offset = 0 }
            return
        }
        onOpen()
    }
}

// A bottom-anchored card over a dimmed scrim — same shape language as
// iOS's own "AirPods connected" popup — so a saved code can be glanced at
// without leaving the library. Tapping anywhere outside dismisses it.
struct QRPopupCard: View {
    let preset: SavedPreset
    let onDismiss: () -> Void

    @State private var shareImage: ShareableImage?
    // Follows the finger while dragging the handle down; committing to
    // dismiss (past a threshold, or a fast downward flick) hands off to
    // onDismiss, otherwise the card springs back up.
    @State private var dragOffset: CGFloat = 0

    private var image: UIImage? {
        QRCardRenderer.composeImage(preset.design, opaque: false)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .transition(.opacity)

            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard value.translation.height > 0 else { return }
                                dragOffset = value.translation.height
                            }
                            .onEnded { value in
                                let flungDown = value.predictedEndTranslation.height > 140
                                if value.translation.height > 60 || flungDown {
                                    onDismiss()
                                } else {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )

                if let ui = image {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .padding(18)
                        .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                        .padding(.horizontal, 28)
                }

                Text(preset.name)
                    .font(.headline)

                Button {
                    if let ui = image { shareImage = ShareableImage(image: ui) }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(brandBlue)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
            .offset(y: dragOffset)
            // Flush against the bottom edge, like the AirPods card — no
            // side margins, no rounded bottom corners.
            .ignoresSafeArea(edges: .bottom)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .sheet(item: $shareImage) { item in
            ActivityShareSheet(activityItems: [item.image])
        }
    }
}

private struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
