import SwiftUI

struct LibraryView: View {
    @Environment(QRDesign.self) private var design
    @Environment(PresetStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showSave = false
    @State private var newName = ""
    @State private var showResetConfirm = false
    @State private var pendingDelete: SavedPreset?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            List {
                if store.presets.isEmpty {
                    ContentUnavailableView("No saved presets", systemImage: "tray",
                        description: Text("Save your current design to reuse it later."))
                } else {
                    Section {
                        ForEach(store.presets) { preset in
                            Button {
                                design.apply(preset.design)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.name).font(.headline).foregroundStyle(.primary)
                                        Text(preset.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        requestDelete(preset)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    requestDelete(preset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text("Saved presets")
                    } footer: {
                        Text("Swipe left on a preset, or tap the red ×, to delete it.")
                    }
                }

                Section {
                    Button {
                        newName = defaultName(); showSave = true
                    } label: { Label("Save current design", systemImage: "plus.circle") }

                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: { Label("Reset to factory", systemImage: "arrow.counterclockwise") }
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
            .alert("Save preset", isPresented: $showSave) {
                TextField("Name", text: $newName)
                Button("Save") {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    store.save(name: name.isEmpty ? defaultName() : name, design: design.snapshot)
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Reset to factory?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { design.apply(.factory) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This restores every setting to the original defaults.")
            }
            .alert("Delete preset?", isPresented: $showDeleteConfirm, presenting: pendingDelete) { preset in
                Button("Delete", role: .destructive) { store.delete(preset) }
                Button("Cancel", role: .cancel) {}
            } message: { preset in
                Text("\"\(preset.name)\" will be permanently deleted. This can't be undone.")
            }
        }
    }

    private func requestDelete(_ preset: SavedPreset) {
        pendingDelete = preset
        showDeleteConfirm = true
    }

    private func defaultName() -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, HH:mm"
        return "Design " + f.string(from: Date())
    }
}
