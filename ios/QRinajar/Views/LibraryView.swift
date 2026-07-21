import SwiftUI

struct LibraryView: View {
    @Environment(QRDesign.self) private var design
    @Environment(PresetStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var popupPreset: SavedPreset?
    @AppStorage("hasSeenLibrarySwipeDemo") private var hasSeenSwipeDemo = false

    // Swipe-to-delete removes immediately (no confirmation prompt) — the
    // safety net is shaking the device to undo, matching Mail/Notes.
    @State private var lastDeleted: (preset: SavedPreset, index: Int)?
    @State private var undoWorkItem: DispatchWorkItem?

    var body: some View {
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
                                playDemo: index == 0 && !hasSeenSwipeDemo,
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
                                onDemoFinished: { hasSeenSwipeDemo = true }
                            )
                        }
                    } header: {
                        Text("Saved presets")
                    } footer: {
                        Text("Swipe a preset to delete it — shake to undo.")
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .modifier(GlassButtonStyle())
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

    @State private var offset: CGFloat = 0
    @State private var rowWidth: CGFloat = 360
    private let deleteWidth: CGFloat = 84
    private let rowHeight: CGFloat = 76

    // Only visible once the row has actually started sliding — at rest
    // there's no red anywhere, revealed only as the user (or the demo)
    // drags the content away from it.
    private var revealAmount: CGFloat {
        min(-offset / deleteWidth, 1)
    }

    // Dragging past half the row's own width — not just past the delete
    // button — commits to a full swipe-through delete, Mail-style.
    private var deleteThroughThreshold: CGFloat { rowWidth * 0.5 }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Grows to fill exactly the gap the content has slid open, so a
            // full swipe-through reads as one continuous red sheet rather
            // than a fixed-width button trailing off into empty space.
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

            Button(action: onOpen) {
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
                        guard value.translation.width < 0 else { offset = 0; return }
                        offset = max(value.translation.width, -rowWidth)
                    }
                    .onEnded { value in
                        let translation = value.translation.width
                        // A fast leftward fling commits even if it hasn't
                        // physically crossed the halfway point yet — the
                        // predicted end point stands in for velocity.
                        let flungPast = value.predictedEndTranslation.width < -deleteThroughThreshold
                        if translation < -deleteThroughThreshold || flungPast {
                            withAnimation(.easeIn(duration: 0.22)) {
                                offset = -rowWidth - 60
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onDelete()
                            }
                        } else {
                            let shouldReveal = translation < -deleteWidth / 2
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
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .onAppear {
            guard playDemo else { return }
            // A short peek-and-return so a first-time user discovers the
            // swipe-to-delete gesture without having to be told.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    offset = -deleteWidth
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

// A bottom-anchored card over a dimmed scrim — same shape language as
// iOS's own "AirPods connected" popup — so a saved code can be glanced at
// without leaving the library. Tapping anywhere outside dismisses it.
struct QRPopupCard: View {
    let preset: SavedPreset
    let onDismiss: () -> Void

    @State private var shareImage: ShareableImage?

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
