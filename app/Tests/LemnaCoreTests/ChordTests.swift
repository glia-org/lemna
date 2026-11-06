// The summon chord (SP2: SR1 SC2 SD2): its glyphs, how `hotkey` keeps it, the rules, Lemna's own keys and the system's,
// and what the menu and the Settings window say; since pass 37 the window's overview of the box's chords.
import Testing
@testable import LemnaCore

private let (ctrl, opt, shift, cmd) = (Chord.control, Chord.option, Chord.shift, Chord.command)

/// Lemna's main menu's key equivalents as `mainMenu()` writes them (the app reads them from the menu itself).
private let lemna = [("Done", "\r", cmd), ("Copy", "\r", cmd | shift), ("Save…", "s", cmd), ("Off", "k", cmd),
                     ("Undo", "z", cmd), ("Redo", "Z", cmd), ("Cut", "x", cmd), ("Copy", "c", cmd),
                     ("Paste", "v", cmd), ("Select All", "a", cmd), ("Emoji & Symbols", " ", ctrl | cmd),
                     ("Open Window", "f", ctrl | cmd),
                     ("Settings…", ",", cmd), ("Close", "w", cmd), ("Quit Lemna", "q", cmd)]
    .map { MenuKey(title: $0.0, equivalent: $0.1, modifiers: $0.2) }

@Test func aChordIsWrittenAsMenusWriteIt() {
    #expect(Chord.summon.glyphs() == "⌃⌥Space")
    #expect(Chord(key: 0x28, modifiers: cmd | shift | opt | ctrl).glyphs() == "⌃⌥⇧⌘K")  // Apple's order, whatever the bits
    #expect(Chord(key: 0x24, modifiers: shift | cmd).glyphs() == "⇧⌘↩")
    #expect(Chord(key: 0x60, modifiers: 0).glyphs() == "F5" && Chord(key: 0x69, modifiers: ctrl).glyphs() == "⌃F13")
    #expect(Chord(key: 0x7B, modifiers: ctrl | opt).glyphs() == "⌃⌥←")
    #expect(Chord(key: 0x35, modifiers: cmd | opt).glyphs() == "⌥⌘⎋")
    #expect(Chord(key: 0x2B, modifiers: ctrl | opt).glyphs() == "⌃⌥,")
    // The key is the physical one; its letter is the layout's: on a German layout kVK_ANSI_Y is Z.
    let german: (UInt32) -> String? = { $0 == 0x10 ? "z" : $0 == 0x06 ? "y" : Chord.usLetter($0) }
    #expect(Chord(key: 0x10, modifiers: ctrl | opt).glyphs(letter: german) == "⌃⌥Z")
    #expect(Chord(key: 0x10, modifiers: ctrl | opt).glyphs() == "⌃⌥Y")
    #expect(Chord(key: 0x5D, modifiers: ctrl | opt).glyphs() == "⌃⌥Key 93")  // JIS ¥: nothing on the US layout
    // Show Lemna's key equivalent: Space as " ", a letter in lower case, an F-key as its function-key character.
    #expect(Chord.summon.equivalent() == " " && Chord(key: 0x28, modifiers: ctrl | shift).equivalent() == "k")
    #expect(Chord(key: 0x60, modifiers: 0).equivalent() == "\u{f708}")  // NSF5FunctionKey
    #expect(Chord(key: 0x7A, modifiers: 0).equivalent() == "\u{f704}")
}

@Test func hotkeyKeepsKeyCodeAndCarbonModifiers() {
    #expect(Chord.summon.stored == ["key": 49, "modifiers": 6144])  // kVK_Space, controlKey | optionKey
    for c in [Chord.summon, Chord(key: 0x28, modifiers: ctrl | opt | cmd), Chord(key: 0x60, modifiers: 0),
              Chord(key: 0x31, modifiers: cmd)] {
        #expect(Chord.kept(c.stored, lemna: lemna) == c)
    }
    #expect(Chord.kept(nil) == Chord.summon)  // nothing kept, as before this pass
    #expect(Chord.kept([:]) == nil)  // cleared: no chord
    // What does not decode, or what the rules or Lemna's own keys refuse, reads as the default.
    #expect(Chord.kept(["key": "49", "modifiers": 6144]) == Chord.summon)
    #expect(Chord.kept(["key": 49]) == Chord.summon && Chord.kept(["key": 300, "modifiers": 0]) == Chord.summon)
    #expect(Chord.kept(["key": 0x25, "modifiers": Int(cmd)]) == Chord.summon)  // ⌘L
    #expect(Chord.kept(["key": 0x24, "modifiers": Int(cmd | shift)], lemna: lemna) == Chord.summon)  // Copy's ⇧⌘↩
    // Only ⌃⌥⇧⌘ are kept: Fn (the system's function and arrow chords carry it), Caps Lock and the right-hand bits go.
    #expect(Chord(key: 0x7A, modifiers: cmd | 0x20000 | 0x400 | 0x2000) == Chord(key: 0x7A, modifiers: cmd))
    #expect(Chord.kept(["key": 0x7A, "modifiers": Int(cmd | 0x20000)]) == Chord(key: 0x7A, modifiers: cmd))
}

@Test func theRulesRefuseWhatTypesOrWhatAppsUse() {
    let refused: [(UInt32, UInt32, Chord.Refusal)] = [
        (0x28, 0, .needsControlOrCommand), (0x28, shift, .needsControlOrCommand), (0x28, opt, .needsControlOrCommand),
        (0x28, opt | shift, .needsControlOrCommand), (0x31, opt, .needsControlOrCommand), (0x31, 0, .needsControlOrCommand),
        (0x60, shift, .needsControlOrCommand), (0x60, opt, .needsControlOrCommand),  // ⇧F5, ⌥F5
        (0x25, cmd, .needsAnother), (0x28, ctrl, .needsAnother), (0x7B, cmd, .needsAnother), (0x33, cmd, .needsAnother),
    ]
    for (key, mods, why) in refused { #expect(Chord(key: key, modifiers: mods).rule == why) }
    let kept: [(UInt32, UInt32)] = [(0x31, ctrl | opt), (0x31, ctrl), (0x31, cmd), (0x24, cmd), (0x30, ctrl),
                                    (0x60, 0), (0x5A, 0), (0x60, cmd), (0x28, ctrl | opt), (0x28, cmd | shift),
                                    (0x12, ctrl | opt), (0x7B, ctrl | opt), (0x28, ctrl | opt | shift | cmd)]
    for (key, mods) in kept { #expect(Chord(key: key, modifiers: mods).rule == nil) }
}

@Test func lemnasOwnKeysAreRefusedAndTheSystemsWarned() {
    let none = [Chord]()
    #expect(Chord(key: 0x24, modifiers: cmd | shift).verdict(lemna: lemna, system: none) == .refused(.lemna("Copy")))
    #expect(Chord(key: 0x24, modifiers: cmd).verdict(lemna: lemna, system: none) == .refused(.lemna("Done")))
    #expect(Chord(key: 0x03, modifiers: ctrl | cmd).verdict(lemna: lemna, system: none) == .refused(.lemna("Open Window")))
    #expect(Chord(key: 0x06, modifiers: cmd | shift).verdict(lemna: lemna, system: none) == .refused(.lemna("Redo")))
    #expect(Chord(key: 0x06, modifiers: ctrl | cmd).verdict(lemna: lemna, system: none) == .keep)  // ⌃⌘Z is free
    // Emoji & Symbols (pass 38): Lemna's own before the system's Character Viewer.
    #expect(Chord(key: 0x31, modifiers: ctrl | cmd).verdict(lemna: lemna, system: [Chord(key: 0x31, modifiers: ctrl | cmd)])
        == .refused(.lemna("Emoji & Symbols")))
    // The menu is matched by what the key types: on a layout where kVK_ANSI_F types something else, ⌃⌘F is not it.
    #expect(Chord(key: 0x03, modifiers: ctrl | cmd).verdict(lemna: lemna, system: none, letter: { _ in "q" }) == .keep)
    // The system's enabled chords, as CopySymbolicHotKeys gives them: kept with a warning, named when well known.
    let system = [Chord(key: 0x31, modifiers: cmd), Chord(key: 0x31, modifiers: ctrl),
                  Chord(key: 0x31, modifiers: ctrl | opt), Chord(key: 0x14, modifiers: shift | cmd),
                  Chord(key: 0x25, modifiers: ctrl | opt | cmd), Chord(key: 0x7A, modifiers: shift | cmd | 0x20000)]
    #expect(Chord.summon.verdict(lemna: lemna, system: system) == .taken("input sources"))
    #expect(Chord(key: 0x31, modifiers: cmd).verdict(lemna: lemna, system: system) == .taken("Spotlight"))
    #expect(Chord(key: 0x14, modifiers: shift | cmd).verdict(lemna: lemna, system: system) == .taken("screenshots"))
    #expect(Chord(key: 0x25, modifiers: ctrl | opt | cmd).verdict(lemna: lemna, system: system) == .taken(nil))
    #expect(Chord(key: 0x7A, modifiers: shift | cmd).verdict(lemna: lemna, system: system) == .taken(nil))  // Fn masked
    #expect(Chord(key: 0x28, modifiers: ctrl | opt).verdict(lemna: lemna, system: system) == .keep)
    // The rules come first: ⌘L is refused as every app's, whatever the lists say.
    #expect(Chord(key: 0x25, modifiers: cmd).verdict(lemna: lemna, system: system) == .refused(.needsAnother))
}

@Test func theMenuAndTheWindowSayHowTheChordStands() {
    let system = [Chord.summon]
    let taken = Chord.standing(Chord.summon, registered: true, system: system)
    #expect(taken == .taken("input sources"))
    #expect(Chord.note(Chord.summon, taken) == "⌃⌥Space: taken by macOS")
    #expect(Chord.help(Chord.summon, taken)
        == "macOS uses ⌃⌥Space (input sources). Lemna gets it once that shortcut is off.")
    let other = Chord(key: 0x25, modifiers: ctrl | opt | cmd)
    #expect(Chord.help(other, .taken(nil)) == "macOS uses ⌃⌥⌘L. Lemna gets it once that shortcut is off.")
    #expect(Chord.standing(other, registered: true, system: system) == .free)
    #expect(Chord.note(other, .free) == nil && Chord.help(other, .free) == "")
    #expect(Chord.standing(other, registered: false, system: system) == .unregistered)
    #expect(Chord.note(other, .unregistered) == "⌃⌥⌘L: not available")
    #expect(Chord.standing(nil, registered: true, system: system) == .none && Chord.note(nil, .none) == nil)
    #expect(Chord.help(nil, .none) == "Show Lemna from the menu-bar item.")
    #expect(Chord.listening(keeping: Chord.summon) == "Press the new shortcut. Esc keeps ⌃⌥Space.")
    #expect(Chord.listening(keeping: nil) == "Press the new shortcut. Esc keeps none.")
    // Why a recorded chord was not kept.
    let optionK = Chord(key: 0x28, modifiers: opt)
    #expect(optionK.help(.needsControlOrCommand, typed: "˚") == "⌥K types ˚. Add ⌃ or ⌘.")
    #expect(Chord(key: 0x28, modifiers: 0).help(.needsControlOrCommand, typed: "k")
        == "K types k. Add ⌃ or ⌘ and another modifier.")
    #expect(Chord(key: 0x31, modifiers: opt).help(.needsControlOrCommand, typed: "\u{a0}") == "⌥Space needs ⌃ or ⌘.")
    #expect(Chord(key: 0x60, modifiers: shift).help(.needsControlOrCommand, typed: "\u{f708}")
        == "⇧F5 needs ⌃ or ⌘, or no modifier.")
    #expect(Chord(key: 0x25, modifiers: cmd).help(.needsAnother, typed: "l")
        == "Apps use ⌘L themselves. Add another modifier.")
    #expect(Chord(key: 0x24, modifiers: cmd | shift).help(.lemna("Copy"), typed: "\r") == "Copy uses ⇧⌘↩ in the box.")
}

@Test func theOverviewListsEachChordOnceAsMenusWriteIt() {
    let rows = Shortcuts.overview, chords = rows.flatMap(\.chords)
    #expect(Set(chords).count == chords.count && Set(rows.map(\.label)).count == rows.count)
    for c in chords {
        let g = c.glyphs(letter: Chord.usLetter)
        #expect(!g.isEmpty && !g.contains("Key"))
    }
    #expect(rows.map(Shortcuts.glyphs) == ["⌘↩", "⇧⌘↩", "⌘S", "⎋", "↩", "⇧↩", "⌥← ⌥→", "⌘← ⌘→", "⇧← ⇧→", "⌥⌫ ⌥⌦",
                                           "⌘Z ⇧⌘Z", "⌘A ⌘C ⌘X ⌘V", "⌃⌘Space", "⌘K", "⌃⌘F"])
    // Every ⌘ chord but the caret's moves is a key equivalent of the main menu, so it is what the box does.
    for c in chords where c.modifiers & cmd != 0 && ![0x7B, 0x7C].contains(c.key) {
        #expect(lemna.contains { $0.equivalent == c.equivalent() && $0.modifiers == c.modifiers })
    }
}
