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

    init() { load() }

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
