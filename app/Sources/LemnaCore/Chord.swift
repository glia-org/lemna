// The summon chord (DESIGN.md SP2, the picks SR1 SC2 SD2 of `docs/design-panel-lemna-settings.html`): the key and the
// modifiers of the global hotkey as Carbon takes them and UserDefaults keeps them, how menus and the field write it,
// which chords may summon, and what holds one already. Free of AppKit and Carbon, so the tests check it; the field, the
// registration and the lists a chord is checked against are the app's (Settings.swift, Summon.swift).

/// A virtual key code (Events.h's kVK_…, the physical key whatever the layout) and Carbon's modifier mask, as
/// RegisterEventHotKey takes them and CopySymbolicHotKeys reports them, so nothing converts on the way.
public struct Chord: Hashable {
    /// Carbon's modifier bits (Events.h: controlKey, optionKey, shiftKey, cmdKey).
    public static let control: UInt32 = 1 << 12, option: UInt32 = 1 << 11, shift: UInt32 = 1 << 9, command: UInt32 = 1 << 8
    public static let allModifiers = control | option | shift | command

    public let key: UInt32
    /// The four above only: Fn (0x20000, on 104 of the system's 161 enabled chords, survey §6), Caps Lock and the
    /// right-hand bits are dropped, so a chord compares with the system's as a press would.
    public let modifiers: UInt32

    public init(key: UInt32, modifiers: UInt32) { (self.key, self.modifiers) = (key, modifiers & Self.allModifiers) }

    /// ⌃⌥Space (DESIGN.md Open 7), the default.
    public static let summon = Chord(key: 0x31, modifiers: control | option)

    // MARK: Kept (SD2)

    /// As `hotkey` keeps it: `{key: 49, modifiers: 6144}` for ⌃⌥Space. `[:]` is no chord.
    public var stored: [String: Int] { ["key": Int(key), "modifiers": Int(modifiers)] }

    /// What `hotkey` holds: nil for none (the empty dictionary); the default for a value that is missing, does not
    /// decode, or that the rules or Lemna's own keys refuse (checked again at each launch).
    public static func kept(_ stored: [String: Any]?, lemna: [MenuKey] = [], letter: (UInt32) -> String? = usLetter)
        -> Chord? {
        guard let stored else { return summon }
        if stored.isEmpty { return nil }
        guard let k = stored["key"] as? Int, let m = stored["modifiers"] as? Int, (0..<128).contains(k),
              (0...Int(UInt32.max)).contains(m)
        else { return summon }
        let c = Chord(key: UInt32(k), modifiers: UInt32(m))
        return c.refusal(lemna: lemna, letter: letter) == nil ? c : summon
    }

    // MARK: Written (SR1)

    /// The keys with a name of their own, whatever the layout: as menus draw them, and the character a menu item's key
    /// equivalent takes (NSText.h's control characters, NSEvent.h's function-key characters).
    static let named: [UInt32: (glyph: String, equivalent: String)] = [
        0x31: ("Space", " "), 0x24: ("↩", "\r"), 0x4C: ("⌤", "\u{3}"), 0x30: ("⇥", "\t"), 0x35: ("⎋", "\u{1b}"),
        0x33: ("⌫", "\u{8}"), 0x75: ("⌦", "\u{f728}"), 0x7B: ("←", "\u{f702}"), 0x7C: ("→", "\u{f703}"),
        0x7D: ("↓", "\u{f701}"), 0x7E: ("↑", "\u{f700}"), 0x73: ("↖", "\u{f729}"), 0x77: ("↘", "\u{f72b}"),
        0x74: ("⇞", "\u{f72c}"), 0x79: ("⇟", "\u{f72d}"), 0x47: ("⌧", "\u{f739}"), 0x72: ("Help", "\u{f746}"),
    ]
    /// kVK_F1 … kVK_F20, in order.
    static let functionKeys: [UInt32] = [0x7A, 0x78, 0x63, 0x76, 0x60, 0x61, 0x62, 0x64, 0x65, 0x6D, 0x67, 0x6F, 0x69,
                                         0x6B, 0x71, 0x6A, 0x40, 0x4F, 0x50, 0x5A]

    /// What a key types with no modifier on the US layout: the tests' layout, and the app's when the current one
    /// cannot be read. The app's own (`layoutLetter`) asks the current layout, so a German ⌃⌥Z reads Z.
    public static func usLetter(_ key: UInt32) -> String? {
        let main = Array("asdfhgzxcv§bqweryt123465=97-80]ou[ip\0lj'k;\\,/nm.\0\0`")  // kVK 0x00 … 0x32
        let pad: [UInt32: Character] = [0x41: ".", 0x43: "*", 0x45: "+", 0x4B: "/", 0x4E: "-", 0x51: "=", 0x52: "0",
                                        0x53: "1", 0x54: "2", 0x55: "3", 0x56: "4", 0x57: "5", 0x58: "6", 0x59: "7",
                                        0x5B: "8", 0x5C: "9"]
        let c = key < main.count ? main[Int(key)] : pad[key]
        return c.flatMap { $0 == "\0" ? nil : String($0) }
    }

    /// The modifiers as menus write them, in Apple's order ⌃⌥⇧⌘.
    public static func glyphs(_ modifiers: UInt32) -> String {
        [(control, "⌃"), (option, "⌥"), (shift, "⇧"), (command, "⌘")].filter { modifiers & $0.0 != 0 }.map(\.1).joined()
    }

    /// The chord as menus write it: the modifiers, then the key's name, or what it types on the layout (`letter`) in
    /// capitals, as menus show letters.
    public func glyphs(letter: (UInt32) -> String? = usLetter) -> String {
        let name: String
        if let n = Self.named[key] { name = n.glyph }
        else if let f = Self.functionKeys.firstIndex(of: key) { name = "F\(f + 1)" }
        else if let s = letter(key), !s.isEmpty { name = s.uppercased().count == s.count ? s.uppercased() : s }
        else { name = "Key \(key)" }
        return Self.glyphs(modifiers) + name
    }

    /// The key as a menu item's key equivalent takes it (in lower case: the ⇧ stays in the mask); nil when the layout
    /// types nothing for it.
    public func equivalent(letter: (UInt32) -> String? = usLetter) -> String? {
        if let n = Self.named[key] { return n.equivalent }
        if let f = Self.functionKeys.firstIndex(of: key) { return String(UnicodeScalar(0xF704 + UInt32(f))!) }
        return letter(key)?.lowercased()
    }

    // MARK: Checked (SC2)

    public enum Refusal: Equatable {
        /// No ⌃ or ⌘: the chord types a character (⌥K types ˚), or ⇧, ⌥ or ⌥⇧ alone with an F-key.
        case needsControlOrCommand
        /// ⌃ or ⌘ alone with a key apps use that way (⌘L, ⌃K, ⌘←).
        case needsAnother
        /// One of Lemna's own key equivalents (in the box and the window): the item's title.
        case lemna(String)
    }

    public enum Verdict: Equatable {
        case keep
        /// Kept and registered, with a warning: macOS has it on (its name when known), so it works once that is off.
        case taken(String?)
        case refused(Refusal)
    }

    /// The rules: an F-key alone or with ⌃ or ⌘; Space, Return, Enter and Tab with ⌃ or ⌘; every other key with two
    /// modifiers, one of them ⌃ or ⌘. ⇧, ⌥ and ⌥⇧ alone never: they type characters (⌥Space a no-break space), macOS
    /// 15.0–15.1 refused ⌥ and ⌥⇧ alone, and Secure Input silences them; ⌘ or ⌃ alone with a letter is every app's menu
    /// or text field's chord (survey §5, §8).
    public var rule: Refusal? {
        let primary = modifiers & (Self.control | Self.command) != 0
        if Self.functionKeys.contains(key) { return modifiers == 0 || primary ? nil : .needsControlOrCommand }
        guard primary else { return .needsControlOrCommand }
        if [0x31, 0x24, 0x4C, 0x30].contains(key) { return nil }
        return modifiers.nonzeroBitCount >= 2 ? nil : .needsAnother
    }

    /// The rules, then Lemna's own key equivalents (as the app reads them from its main menu).
    public func refusal(lemna: [MenuKey], letter: (UInt32) -> String? = usLetter) -> Refusal? {
        if let r = rule { return r }
        let e = equivalent(letter: letter)
        return lemna.first { $0.equivalent == e && $0.modifiers == modifiers }.map { .lemna($0.title) }
    }

    /// Whether a recorded chord may be kept: refused by the rules or Lemna's own keys, else kept, with a warning when
    /// it is among `system`, the chords macOS has on (CopySymbolicHotKeys' enabled ones, as the app reads them).
    public func verdict(lemna: [MenuKey], system: [Chord], letter: (UInt32) -> String? = usLetter) -> Verdict {
        if let r = refusal(lemna: lemna, letter: letter) { return .refused(r) }
        return system.contains(self) ? .taken(Self.systemNames[self]) : .keep
    }

    /// macOS's chords most likely met, by name (survey §8); the rest read "macOS uses …" alone. Mission Control's ⌃
    /// and an arrow are not here: the rules refuse them first.
    static let systemNames: [Chord: String] = [
        Chord(key: 0x31, modifiers: command): "Spotlight", Chord(key: 0x31, modifiers: option | command): "Spotlight",
        Chord(key: 0x31, modifiers: control): "input sources",
        Chord(key: 0x31, modifiers: control | option): "input sources",
        Chord(key: 0x31, modifiers: control | command): "Character Viewer",
        Chord(key: 0x14, modifiers: shift | command): "screenshots",
        Chord(key: 0x15, modifiers: shift | command): "screenshots",
        Chord(key: 0x17, modifiers: shift | command): "screenshots",
        Chord(key: 0x14, modifiers: control | shift | command): "screenshots",
        Chord(key: 0x15, modifiers: control | shift | command): "screenshots",
    ]

    // MARK: Said (SD2)

    /// How the kept chord stands at a check (launch, each opening of the menu, the window): none kept, free as far as
    /// can be told, on in macOS (its name when known), or refused by RegisterEventHotKey.
    public enum Standing: Equatable { case none, free, taken(String?), unregistered }

    public static func standing(_ chord: Chord?, registered: Bool, system: [Chord]) -> Standing {
        guard let chord else { return .none }
        guard registered else { return .unregistered }
        return system.contains(chord) ? .taken(systemNames[chord]) : .free
    }

    /// The menu-bar item's grey line under Show Lemna, which then shows no chord; nil while the chord works as far as
    /// can be told, or there is none.
    public static func note(_ chord: Chord?, _ s: Standing, letter: (UInt32) -> String? = usLetter) -> String? {
        guard let g = chord?.glyphs(letter: letter) else { return nil }
        switch s {
        case .taken: return "\(g): taken by macOS"
        case .unregistered: return "\(g): not available"
        case .none, .free: return nil
        }
    }

    /// The Settings window's grey line for the kept chord: empty while there is nothing to say.
    public static func help(_ chord: Chord?, _ s: Standing, letter: (UInt32) -> String? = usLetter) -> String {
        let g = chord?.glyphs(letter: letter) ?? ""
        switch s {
        case .none: return "No shortcut. Show Lemna from its icon in the menu bar."
        case .free: return ""
        case .taken(let name):
            return "macOS uses \(g)\(name.map { " for \($0)" } ?? ""). Turn it off in System Settings › Keyboard, or "
                + "record another."
        case .unregistered: return "\(g) is not available: another app may use it. Record another shortcut."
        }
    }

    /// The grey line while the field listens; `old` is what Esc keeps.
    public static func listening(keeping old: Chord?, letter: (UInt32) -> String? = usLetter) -> String {
        old.map { "Press the new shortcut, or Esc to keep \($0.glyphs(letter: letter))." }
            ?? "Press the new shortcut, or Esc to cancel."
    }

    /// Why a recorded chord was not kept; `typed`: what the key typed with its modifiers, from the key-down.
    public func help(_ r: Refusal, typed: String?, letter: (UInt32) -> String? = usLetter) -> String {
        let g = glyphs(letter: letter)
        switch r {
        case .needsControlOrCommand:
            if Self.functionKeys.contains(key) { return "\(g) needs ⌃ or ⌘, or no modifier." }
            let more = modifiers == 0 && rule(with: Self.control) != nil ? " and another modifier" : ""
            guard let typed, typed.unicodeScalars.allSatisfy({ $0.properties.isGraphemeBase }), !typed.isEmpty,
                  !typed.allSatisfy(\.isWhitespace)
            else { return "\(g) needs ⌃ or ⌘\(more)." }
            return "\(g) types \(typed). Add ⌃ or ⌘\(more)."
        case .needsAnother: return "Apps use \(g) for their own commands. Add another modifier."
        case .lemna(let title): return "Lemna uses \(g) for \(title)."
        }
    }

    /// The rule for this key with `m` instead of its modifiers.
    private func rule(with m: UInt32) -> Refusal? { Chord(key: key, modifiers: m).rule }
}

/// A key equivalent of Lemna's main menu as the app reads it: the item's title, its character and Carbon's mask, an
/// upper-case letter holding the ⇧ as AppKit reads it ("Z" with ⌘ is ⇧⌘Z).
public struct MenuKey: Equatable {
    public let title: String, equivalent: String, modifiers: UInt32

    public init(title: String, equivalent: String, modifiers: UInt32) {
        let lower = equivalent.lowercased()
        self.title = title
        self.equivalent = lower
        self.modifiers = (modifiers | (lower == equivalent ? 0 : Chord.shift)) & Chord.allModifiers
    }
}
