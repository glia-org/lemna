import Foundation

/// Why a pack would not load or the player would not start.
public struct ClickError: Error, CustomStringConvertible {
    public let description: String

    init(_ description: String) { self.description = description }
}

/// What a key-down sounds like. `paragraph` is Return.
public enum KeyKind: Int, CaseIterable, Sendable {
    case letter, space, paragraph, backspace
}

/// A folder of WAV or CAF clicks with a `pack.json`:
///
///     {"name": "…", "licence": "CC0-1.0", "source": "https://…",
///      "files": {"letter": ["a.wav", …], "space": […], "paragraph": […], "backspace": […]}}
///
/// Every kind needs at least one file; two or more let the player avoid repeating itself.
public struct SoundPack: Sendable {
    public let name: String
    public let licence: String
    public let source: String
    public let folder: URL
    /// The files of each kind, in `pack.json` order.
    public let files: [KeyKind: [URL]]

    private struct Manifest: Decodable {
        let name: String
        let licence: String
        let source: String
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
        self.folder = folder
        self.files = files
    }

    /// The pack shipped inside this library (see THIRD_PARTY.md for its source and licence).
    public static func bundled() throws -> SoundPack {
        // SwiftPM's Bundle.module looks for FlowClicks_FlowClicks.bundle at the app bundle's root,
        // where codesign refuses it, then at the absolute build path. An app assembled by a script
        // copies it into Contents/Resources, so look there first.
        let inApp = Bundle.main.resourceURL?.appendingPathComponent("FlowClicks_FlowClicks.bundle")
        let bundle = inApp.flatMap { Bundle(url: $0) } ?? Bundle.module
        guard let folder = bundle.url(forResource: "DefaultPack", withExtension: nil) else {
            throw ClickError("the default pack is missing from the resource bundle")
        }
        return try SoundPack(folder: folder)
    }
}
