// Settings… (DESIGN.md SP2, the picks SP2 SK1 SR1 SC2 SW3 SD2 of `docs/design-panel-lemna-settings.html`): one plain
// window holding the summon chord, the one setting a menu cannot hold, and the field that records it; since pass 37 also
// the sound as Session › Sound ▸ has it and the box's fixed chords. The chord's model, its rules, what the window says
// and the chords' list are LemnaCore's (`Chord`, `Shortcuts`); the app keeps and registers the chord and keeps the
// sound (main.swift, Summon.swift).
import AppKit
import Carbon.HIToolbox
import LemnaCore

/// The summon chord's field (SR1), Lemna's own control, behaving as the recorder libraries' do (survey §4). A click, or
/// Space or Return while it has the focus, starts listening: the app pauses the global hotkey (so Lemna's own chord
/// reaches the field), a local monitor takes each key-down before the menus and the window do (⌘S does not save, Tab
/// does not move on), and the modifiers show as they go down. The next key with its modifiers goes to `recorded`, which
/// keeps it, or says why not and the field listens on; ⌫ alone clears; Esc alone, a click elsewhere, the window losing
/// the keys or the focus moving cancel, the old chord kept. The × clears too. Drawn as a text field, in system colours.
final class Recorder: NSView {
    var chord: Chord? { didSet { needsDisplay = true } }
    var letter: (UInt32) -> String? = layoutLetter
    var onListening: (Bool) -> Void = { _ in }
    /// A key-down while listening: the chord and what the key typed; true when kept (listening ends).
    var recorded: (Chord, String?) -> Bool = { _, _ in true }
    var onClear: () -> Void = {}
    private(set) var listening = false
    private var held: UInt32 = 0, monitor: Any?

    override var intrinsicContentSize: NSSize { NSSize(width: 150, height: 24) }
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }  // reachable with Tab without Full Keyboard Access, as a text field is
    override var focusRingMaskBounds: NSRect { bounds }
    override func drawFocusRingMask() { NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill() }

    /// Where the × sits, while a chord is kept and the field is not listening.
    private var clearRect: NSRect { NSRect(x: bounds.maxX - 22, y: bounds.midY - 8, width: 16, height: 16) }

    override func draw(_ dirty: NSRect) {
        let edge = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        NSColor.textBackgroundColor.setFill()
        edge.fill()
        (listening ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        edge.stroke()
        let (text, colour): (String, NSColor) = listening
            ? (held == 0 ? "…" : Chord.glyphs(held) + " …", .secondaryLabelColor)
            : chord.map { ($0.glyphs(letter: letter), .labelColor) } ?? ("None", .secondaryLabelColor)
        let s = NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                                                             .foregroundColor: colour])
        let size = s.size()
        s.draw(at: NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2))
        if !listening, chord != nil,
           let x = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear") {
            let tinted = NSImage(size: clearRect.size, flipped: false) { r in
                x.draw(in: r)
                NSColor.tertiaryLabelColor.set()
                r.fill(using: .sourceAtop)
                return true
            }
            tinted.draw(in: clearRect)
        }
    }

    override func mouseDown(with e: NSEvent) {
        if !listening, chord != nil, clearRect.contains(convert(e.locationInWindow, from: nil)) { return onClear() }
        listen()
    }

    override func keyDown(with e: NSEvent) {
        guard carbon(e.modifierFlags) == 0, [kVK_Space, kVK_Return].contains(Int(e.keyCode)) else {
            return super.keyDown(with: e)  // Esc goes on to the window, which closes
        }
        listen()
    }

    override func resignFirstResponder() -> Bool {
        cancel()
        return super.resignFirstResponder()
    }

    override func viewWillMove(toWindow w: NSWindow?) {
        if w == nil { cancel() }
    }

    func listen() {
        guard !listening else { return }
        window?.makeFirstResponder(self)
        (listening, held) = (true, 0)
        onListening(true)
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown]) {
            [weak self] e in self?.take(e) == true ? nil : e
        }
        needsDisplay = true
    }

    /// Ends listening without keeping anything.
    func cancel() {
        guard listening else { return }
        listening = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        onListening(false)
        needsDisplay = true
    }

    /// True when `e` is the field's alone.
    private func take(_ e: NSEvent) -> Bool {
        switch e.type {
        case .flagsChanged:  // shown, and passed on so AppKit keeps its own state of the modifiers
            held = carbon(e.modifierFlags)
            needsDisplay = true
            return false
        case .keyDown:
            let mods = carbon(e.modifierFlags), code = Int(e.keyCode)
            if e.isARepeat { return true }
            if mods == 0, code == kVK_Escape { cancel() }
            else if mods == 0, code == kVK_Delete || code == kVK_ForwardDelete {
                cancel()
                onClear()
            } else if recorded(Chord(key: UInt32(e.keyCode), modifiers: mods), e.characters) { cancel() }
            else { NSSound.beep() }
            return true
        default:  // a click: on the field it listens on; elsewhere listening ends and the click goes on
            if e.window !== window || !bounds.contains(convert(e.locationInWindow, from: nil)) { cancel() }
            return false
        }
    }

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .button }
    override func accessibilityLabel() -> String? { "Show Lemna shortcut" }
    override func accessibilityValue() -> Any? { listening ? "Listening" : chord?.glyphs(letter: letter) ?? "None" }
    override func accessibilityPerformPress() -> Bool {
        listen()
        return true
    }
}

/// The window closes on Esc too, as a settings window does; ⌘W is the main menu's Close.
private final class SettingsWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) { performClose(nil) }

    override func keyDown(with e: NSEvent) {
        if carbon(e.modifierFlags) == 0, Int(e.keyCode) == kVK_Escape { return performClose(nil) }
        super.keyDown(with: e)
    }
}

/// The Settings window (SW3; since pass 37 groups on its one page): "Lemna Settings", a plain titled window at
/// the normal level (under the box's), system controls and the system's appearance whatever Lemna's theme. Shortcut:
/// "Show Lemna:", the field, Reset to ⌃⌥Space (grey while the chord is ⌃⌥Space), and under them a grey line saying
/// how the chord stands, empty while there is nothing to say, or what to do while the field listens. Sound: Play sound
/// (⌘K's on or off), the clicks' pack and the bed, as Session › Sound ▸ has them; they call the menu's own actions, and
/// the app refreshes them whenever those keep a change, made here or in a menu. Ambience (pass 39, here alone): the
/// mode on the dim, Code, Still water or Off, by the submenu's action it replaces, refreshed the same way (a theme's
/// preset writes it too). Shortcuts in the box: the fixed chords, read-only (`Shortcuts.overview`). The app supplies the state and acts on what the controls ask.
final class Settings: NSObject, NSWindowDelegate {
    let window: NSWindow = SettingsWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered,
                                          defer: true)
    let recorder = Recorder()
    private let reset = NSButton(title: "Reset to \(Chord.summon.glyphs())", target: nil, action: nil)
    private let help = NSTextField(wrappingLabelWithString: "")
    private let soundBox = NSButton(checkboxWithTitle: "Play sound", target: nil, action: nil)
    private let pack = NSPopUpButton(frame: .zero, pullsDown: false), bed = NSPopUpButton(frame: .zero, pullsDown: false)
    private let mode = NSPopUpButton(frame: .zero, pullsDown: false)
    /// The chord kept and how it stands now.
    var stand: () -> (chord: Chord?, standing: Chord.Standing) = { (nil, .none) }
    /// Whether a recorded chord may be kept (SC2), read against the menus and the system's list as they are now.
    var check: (Chord) -> Chord.Verdict = { _ in .keep }
    /// Keep a chord (nil clears it) or, for `reset`, the default.
    var keep: (Chord?) -> Void = { _ in }
    var resetChord: () -> Void = {}
    /// The field began or ended listening: the hotkey pauses meanwhile.
    var pause: (Bool) -> Void = { _ in }
    /// The sound as Session › Sound ▸ has it: on or off, the pack's place in `SoundChoice.packs`, the bed's in
    /// `BedChoice.beds` (nil: none).
    var sound: () -> (on: Bool, pack: Int, bed: Int?) = { (true, 0, nil) }
    /// The menu's own actions, given the item they would get: Off (⌘K), a pack, a bed (tag −1: No bed).
    var toggleSound: () -> Void = {}
    var choosePack: (NSMenuItem) -> Void = { _ in }
    var chooseBed: (NSMenuItem) -> Void = { _ in }
    /// The ambience shown: the mode's place in `Ambience.Mode.allCases` (nil: Off), and whether the modes are offered
    /// (not under Reduce Motion); and the action the submenu's items had (tag −1: Off).
    var ambience: () -> (mode: Int?, available: Bool) = { (nil, true) }
    var chooseAmbience: (NSMenuItem) -> Void = { _ in }
    var onClose: () -> Void = {}

    override init() {
        super.init()
        window.title = "Lemna Settings"
        window.isReleasedWhenClosed = false
        window.autorecalculatesKeyViewLoop = true
        window.delegate = self
        help.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        help.textColor = .secondaryLabelColor
        help.maximumNumberOfLines = 2
        help.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)  // wraps at the row's width
        reset.bezelStyle = .push
        (reset.target, reset.action) = (self, #selector(resetPressed))
        (soundBox.target, soundBox.action) = (self, #selector(soundToggled))
        for (i, p) in SoundChoice.packs.enumerated() {
            pack.addItem(withTitle: p.title)
            pack.lastItem?.tag = i
        }
        for (i, b) in BedChoice.beds.enumerated() {
            bed.addItem(withTitle: b.title)
            bed.lastItem?.tag = i
        }
        bed.addItem(withTitle: "No bed")
        bed.lastItem?.tag = -1
        for (i, m) in Ambience.Mode.allCases.enumerated() {
            mode.addItem(withTitle: m.title)
            mode.lastItem?.tag = i
        }
        mode.addItem(withTitle: "Off")
        mode.lastItem?.tag = -1
        for p in [pack, bed, mode] {
            p.autoenablesItems = false
            p.target = self
        }
        pack.action = #selector(packChosen)
        bed.action = #selector(bedChosen)
        mode.action = #selector(modeChosen)
        let chord = NSStackView(views: [recorder, reset])
        chord.spacing = 8
        let none = NSGridCell.emptyContentView
        let groups: [[NSView]] = [
            [header("Shortcut"), none], [NSTextField(labelWithString: "Show Lemna:"), chord], [none, help],
            [separator(), none],
            [header("Sound"), none], [none, soundBox], [NSTextField(labelWithString: "Clicks:"), pack],
            [NSTextField(labelWithString: "Bed:"), bed],
            [separator(), none],
            [header("Ambience"), none], [NSTextField(labelWithString: "Mode:"), mode],
            [separator(), none],
            [header("Shortcuts in the box"), none],
        ]
        let small = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let mono = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        let overview: [[NSView]] = Shortcuts.overview.map { row in
            let keys = NSTextField(labelWithString: Shortcuts.glyphs(row)), what = NSTextField(labelWithString: row.label)
            (keys.font, what.font) = (mono, small)
            return [keys, what]
        }
        let grid = NSGridView(views: groups + overview)
        (grid.rowSpacing, grid.columnSpacing, grid.yPlacement) = (3, 8, .center)
        grid.column(at: 0).xPlacement = .trailing
        for i in 1...groups.count { grid.row(at: i).topPadding = i == 2 ? 3 : 5 }  // the list's own rows closer
        for i in groups.indices where groups[i][1] === none {
            grid.row(at: i).mergeCells(in: NSRange(location: 0, length: 2))
            grid.cell(for: groups[i][0])?.xPlacement = groups[i][0] is NSBox ? .fill : .leading
        }
        let view = NSView()
        grid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // Two lines, written or not, so the window keeps its size as the line changes.
            help.widthAnchor.constraint(equalTo: chord.widthAnchor),
            help.heightAnchor.constraint(equalToConstant: 2 * NSLayoutManager().defaultLineHeight(for: help.font!)),
        ])
        window.contentView = view
        window.setContentSize(view.fittingSize)
        window.initialFirstResponder = recorder
        recorder.onClear = { [unowned self] in self.keep(nil) }
        // Refused: not kept, the old chord stays and the field listens on; taken by macOS: kept, the line says so.
        recorder.recorded = { [unowned self] c, typed in
            guard case .refused(let why) = self.check(c) else {
                self.keep(c)
                return true
            }
            self.help.stringValue = c.help(why, typed: typed, letter: layoutLetter)
            return false
        }
        recorder.onListening = { [unowned self] on in
            self.pause(on)
            if on {
                self.help.stringValue = Chord.listening(keeping: self.stand().chord, letter: layoutLetter)
            } else {
                self.refresh()
            }
        }
        window.center()
    }

    private func header(_ title: String) -> NSTextField {
        let l = NSTextField(labelWithString: title)
        l.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        return l
    }

    private func separator() -> NSBox {
        let b = NSBox()
        b.boxType = .separator
        return b
    }

    /// On screen with the keys, on the field (when the chord is taken that is where to go).
    func show() {
        refresh()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(recorder)
    }

    /// The groups as things stand now; while the field listens its line is the field's.
    func refresh() {
        let (chord, standing) = stand()
        recorder.chord = chord
        reset.isEnabled = chord != Chord.summon
        if !recorder.listening { help.stringValue = Chord.help(chord, standing, letter: layoutLetter) }
        refreshSound()
        refreshAmbience()
    }

    /// The sound group as the model has it (the app calls this whenever it keeps a change of the sound or the bed).
    func refreshSound() {
        let s = sound()
        soundBox.state = s.on ? .on : .off
        pack.selectItem(withTag: s.pack)
        bed.selectItem(withTag: s.bed ?? -1)
    }

    @objc private func resetPressed() { resetChord() }
    @objc private func soundToggled() { toggleSound() }
    @objc private func packChosen() { pack.selectedItem.map(choosePack) }
    @objc private func bedChosen() { bed.selectedItem.map(chooseBed) }
    @objc private func modeChosen() { mode.selectedItem.map(chooseAmbience) }

    /// The ambience group as the model has it (the app calls this whenever it keeps a change of the mode).
    func refreshAmbience() {
        let a = ambience()
        for item in mode.itemArray where item.tag >= 0 { item.isEnabled = a.available }
        mode.selectItem(withTag: a.mode ?? -1)
    }

    /// Reduce Motion may have changed while the window was behind.
    func windowDidBecomeKey(_ notification: Notification) { refreshAmbience() }

    func windowDidResignKey(_ notification: Notification) { recorder.cancel() }

    func windowWillClose(_ notification: Notification) {
        recorder.cancel()
        onClose()
    }
}
