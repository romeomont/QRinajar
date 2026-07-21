import Foundation
import Observation

struct SavedPreset: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var createdAt = Date()
    var design: DesignSnapshot
}

// Persists named presets and the "last design" as Codable JSON in Application Support,
// an upgrade over the web app's single localStorage slot.
@Observable
final class PresetStore {
    private(set) var presets: [SavedPreset] = []
    private var lastViewedAt: Date = .distantPast

    // Count of presets saved since the Library was last opened, shown as a
    // red badge on its toolbar icon.
    var newCount: Int {
        presets.filter { $0.createdAt > lastViewedAt }.count
    }

    func isNew(_ preset: SavedPreset) -> Bool {
        preset.createdAt > lastViewedAt
    }

    func markLibraryViewed() {
        lastViewedAt = Date()
        UserDefaults.standard.set(lastViewedAt, forKey: "libraryLastViewedAt")
    }

    private let fm = FileManager.default

    private var supportDir: URL {
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("QRinajar", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    private var presetsURL: URL { supportDir.appendingPathComponent("presets.json") }
    private var lastURL: URL { supportDir.appendingPathComponent("last-design.json") }

    init() {
        load()
        lastViewedAt = (UserDefaults.standard.object(forKey: "libraryLastViewedAt") as? Date) ?? .distantPast
    }

    func load() {
        if let data = try? Data(contentsOf: presetsURL),
           let decoded = try? JSONDecoder().decode([SavedPreset].self, from: data) {
            presets = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(presets) {
            try? data.write(to: presetsURL, options: .atomic)
        }
    }

    func save(name: String, design: DesignSnapshot) {
        presets.insert(SavedPreset(name: name, design: design), at: 0)
        persist()
    }

    func delete(_ preset: SavedPreset) {
        presets.removeAll { $0.id == preset.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        persist()
    }

    // Re-inserts a swiped-away preset, used by shake-to-undo.
    func restore(_ preset: SavedPreset, at index: Int) {
        let clamped = min(max(index, 0), presets.count)
        presets.insert(preset, at: clamped)
        persist()
    }

    func rename(_ preset: SavedPreset, to newName: String) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        presets[index].name = trimmed
        persist()
    }

    // Last-design auto-persist (mirrors the web app localStorage boot behaviour).
    func saveLast(_ design: DesignSnapshot) {
        if let data = try? JSONEncoder().encode(design) {
            try? data.write(to: lastURL, options: .atomic)
        }
    }

    func loadLast() -> DesignSnapshot? {
        guard let data = try? Data(contentsOf: lastURL) else { return nil }
        return try? JSONDecoder().decode(DesignSnapshot.self, from: data)
    }
}
