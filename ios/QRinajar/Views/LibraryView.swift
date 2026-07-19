import SwiftUI

struct LibraryView: View {
    @Environment(QRDesign.self) private var design
    @Environment(PresetStore.self) private var store
    @State private var showSave = false
    @State private var newName = ""
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                if store.presets.isEmpty {
                    ContentUnavailableView("No saved presets", systemImage: "tray",
                        description: Text("Save your current design to reuse it later."))
                } else {
                    Section("Saved presets") {
                        ForEach(store.presets) { preset in
                            Button {
                                design.apply(preset.design)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name).font(.headline).foregroundStyle(.primary)
                                    Text(preset.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { store.delete(at: $0) }
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
            .toolbar { EditButton() }
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
        }
    }

    private func defaultName() -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, HH:mm"
        return "Design " + f.string(from: Date())
    }
}
