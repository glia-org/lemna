// The Sound submenu (DESIGN.md K1): which click pack plays, or none, and what ⌘K does; since pass 23 the bed under the
// clicks (BD1) and when it plays. Free of AppKit, so the tests check it.

/// The pack chosen and whether the sound is on. Off keeps the pack, so ⌘K brings back the one that played last.
public struct SoundChoice: Equatable {
    /// The submenu's packs in its order: the item's title and the pack's folder in the app's Contents/Resources. The
    /// first is the default.
    public static let packs: [(title: String, folder: String)] = [
        ("Keychron", "DefaultPack"), ("Typewriter", "TypewriterPack"), ("Soft", "SoftPack"), ("Electric", "ElectricPack"),
        ("Stone", "StonePack"),
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

    /// A theme's pack (TH1, the preset): it plays from now on, and the sound stays on or off as it was (⌘K's is the
    /// user's). An unknown folder changes nothing.
    public mutating func preset(_ folder: String) {
        guard Self.packs.contains(where: { $0.folder == folder }) else { return }
        pack = folder
    }

    /// Off (⌘K): the sound goes off, or, when it is off, comes back with the last pack.
    public mutating func toggle() { on.toggle() }
}

/// The bed chosen in Session › Sound (BD1): a loop of steady sound under the clicks, or none, the default. Kept apart
/// from the pack, so a theme's preset and the submenu set each alone; ⌘K silences both.
public struct BedChoice: Equatable {
    /// The submenu's beds in its order: the item's title and the bed's folder in the app's Contents/Resources/Beds.
    public static let beds: [(title: String, folder: String)] = [("Rain bed", "Rain")]

    /// The chosen bed's folder; nil: none.
    public private(set) var folder: String?

    /// As kept across launches (`bed`, which a theme's preset writes too); none, or one no longer listed, is none.
    public init(kept: String?) { folder = Self.beds.contains { $0.folder == kept } ? kept : nil }

    /// The chosen bed's place in `beds`; nil for none.
    public var index: Int? { Self.beds.firstIndex { $0.folder == folder } }

    /// A bed from the submenu or a theme's preset, or none (nil). An unknown folder changes nothing.
    public mutating func choose(_ folder: String?) {
        guard folder == nil || Self.beds.contains(where: { $0.folder == folder }) else { return }
        self.folder = folder
    }

    /// Whether the bed plays now (sound.md §2.4): a bed is chosen, the sound is on, a container is on screen (the box,
    /// or the window: writing there too) and writing goes on. So it fades in at the summon and out whenever the
    /// container goes, at a hand-off's start (⌘⏎'s send, Copy, Save…'s panel) and at ⌘K; back in when writing goes on
    /// in a container still up (a ⌘⏎ that copied with a note, Save… cancelled) or the sound comes back.
    public func plays(onScreen: Bool, writing: Bool, sound: Bool) -> Bool {
        folder != nil && sound && onScreen && writing
    }
}

extension Theme {
    /// The theme's item in Session › Theme ▸: its title, and the bed its preset turns on, so a bed never comes unasked
    /// (TH1; sound.md §5): "Still (rain bed)".
    public var menuTitle: String {
        guard let bed = BedChoice.beds.first(where: { $0.folder == defaults.bed }) else { return title }
        return "\(title) (\(bed.title.lowercased()))"
    }
}
