import Foundation

/// Why a pack would not load or the player would not start.
public struct ClickError: Error, CustomStringConvertible {
    public let description: String

    init(_ description: String) { self.description = description }
}

/// What a key-down sounds like. `paragraph` is Return; `send` is ⌘⏎ when it pastes the text into the app behind (the
/// hand-off, played once at its key-down): longer than a click, a key's release or a carriage's stop in it.
public enum KeyKind: Int, CaseIterable, Sendable {
    case letter, space, paragraph, backspace, send
}

/// A folder of WAV or CAF clicks with a `pack.json`:
///
///     {"name": "…", "licence": "CC0-1.0", "source": "https://…", "attribution": "…",
///      "files": {"letter": ["a.wav", …], "space": […], "paragraph": […], "backspace": […], "send": […]}}
///
/// Every kind needs at least one file; two or more let the player avoid repeating itself. `attribution` is optional:
/// the credit line a licence such as CC BY requires.
public struct SoundPack: Sendable {
    public let name: String
    public let licence: String
    public let source: String
    public let attribution: String?
    public let folder: URL
    /// The files of each kind, in `pack.json` order.
    public let files: [KeyKind: [URL]]

    private struct Manifest: Decodable {
        let name: String
        let licence: String
        let source: String
        let attribution: String?
        let files: [String: [String]]
    }

    public init(folder: URL) throws {
        let data = try Data(contentsOf: folder.appendingPathComponent("pack.json"))
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)
        let kinds = Dictionary(uniqueKeysWithValues: KeyKind.allCases.map { (String(describing: $0), $0) })
        // An unknown key is a typo that would otherwise leave a kind silently empty.
        if let unknown = manifest.files.keys.first(where: { kinds[$0] == nil }) {
            throw ClickError("pack.json: unknown kind \"\(unknown)\"")
        }
        var files: [KeyKind: [URL]] = [:]
        for (key, kind) in kinds {
            let names = manifest.files[key] ?? []
            if names.isEmpty { throw ClickError("pack.json: no files for \"\(key)\"") }
            files[kind] = try names.map { name in
                let url = folder.appendingPathComponent(name)
                if !FileManager.default.fileExists(atPath: url.path) {
                    throw ClickError("pack.json: \(name) not found in the pack")
                }
                return url
            }
        }
        self.name = manifest.name
        self.licence = manifest.licence
        self.source = manifest.source
        self.attribution = manifest.attribution
        self.folder = folder
        self.files = files
    }

    /// A pack an app carries in `Contents/Resources/<folder>`: the default pack (`DefaultPack`), or `TypewriterPack`,
    /// `SoftPack`, `ElectricPack` (see THIRD_PARTY.md for their sources and licences).
    public static func bundled(_ folder: String = "DefaultPack") throws -> SoundPack {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent(folder),
              FileManager.default.fileExists(atPath: url.path) else {
            throw ClickError("the pack \(folder) is missing from the app's Contents/Resources")
        }
        return try SoundPack(folder: url)
    }
}
