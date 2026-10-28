// The Sound submenu (DESIGN.md K1): which click pack plays, or none, and what ⌘K does. Free of AppKit, so the tests
// check it.

/// The pack chosen and whether the sound is on. Off keeps the pack, so ⌘K brings back the one that played last.
public struct SoundChoice: Equatable {
    /// The submenu's packs in its order: the item's title and the pack's folder in the app's Contents/Resources. The
    /// first is the default.
    public static let packs: [(title: String, folder: String)] = [
        ("Keychron", "DefaultPack"), ("Typewriter", "TypewriterPack"), ("Soft", "SoftPack"), ("Electric", "ElectricPack"),
    ]

    /// The chosen pack's folder.
    public private(set) var pack: String
    public private(set) var on: Bool

    /// As kept across launches; a pack nobody kept, or one no longer in the list, is the default.
    public init(pack: String?, on: Bool) {
        self.pack = Self.packs.contains { $0.folder == pack } ? pack! : Self.packs[0].folder
        self.on = on
    }

    /// The chosen pack's place in `packs`.
    public var index: Int { Self.packs.firstIndex { $0.folder == pack } ?? 0 }

    /// A pack from the submenu: it plays from now on, and the sound is on. An unknown folder changes nothing.
    public mutating func choose(_ folder: String) {
        guard Self.packs.contains(where: { $0.folder == folder }) else { return }
        pack = folder
        on = true
    }

    /// Off (⌘K): the sound goes off, or, when it is off, comes back with the last pack.
    public mutating func toggle() { on.toggle() }
}
