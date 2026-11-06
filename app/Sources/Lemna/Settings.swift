// Settings… (DESIGN.md SP2, the picks SP2 SK1 SR1 SC2 SW3 SD2 of `docs/design-panel-lemna-settings.html`): one plain
// window holding the summon chord, the one setting a menu cannot hold, and the field that records it. The chord's model,
// its rules and what the window says are LemnaCore's (`Chord`); the app keeps and registers it (main.swift, Summon.swift).
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

/// The Settings window (SW3): "Lemna Settings", a plain titled window at the normal level (under the box's), system
/// controls and the system's appearance whatever Lemna's theme, one row: "Show Lemna:", the field, Reset to ⌃⌥Space
/// (grey while the chord is ⌃⌥Space), and under them a grey line saying how the chord stands, empty while there is
/// nothing to say, or what to do while the field listens. The app supplies the chord and acts on what the row asks.
final class Settings: NSObject, NSWindowDelegate {
    let window: NSWindow = SettingsWindow(contentRect: NSRect(x: 0, y: 0, width: 470, height: 98),
                                          styleMask: [.titled, .closable], backing: .buffered, defer: true)
    let recorder = Recorder()
    private let reset = NSButton(title: "Reset to \(Chord.summon.glyphs())", target: nil, action: nil)
    private let help = NSTextField(wrappingLabelWithString: "")
    /// The chord kept and how it stands now.
    var stand: () -> (chord: Chord?, standing: Chord.Standing) = { (nil, .none) }
    /// Whether a recorded chord may be kept (SC2), read against the menus and the system's list as they are now.
    var check: (Chord) -> Chord.Verdict = { _ in .keep }
    /// Keep a chord (nil clears it) or, for `reset`, the default.
    var keep: (Chord?) -> Void = { _ in }
    var resetChord: () -> Void = {}
    /// The field began or ended listening: the hotkey pauses meanwhile.
    var pause: (Bool) -> Void = { _ in }
    var onClose: () -> Void = {}

    override init() {
        super.init()
        window.title = "Lemna Settings"
        window.isReleasedWhenClosed = false
        window.delegate = self
        let label = NSTextField(labelWithString: "Show Lemna:")
        label.alignment = .right
        help.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        help.textColor = .secondaryLabelColor
        help.maximumNumberOfLines = 2
        reset.bezelStyle = .push
        reset.target = self
        reset.action = #selector(resetPressed)
        let view = NSView()
        for v in [label, recorder, reset, help] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: recorder.centerYAnchor),
            recorder.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            recorder.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            reset.leadingAnchor.constraint(equalTo: recorder.trailingAnchor, constant: 8),
            reset.centerYAnchor.constraint(equalTo: recorder.centerYAnchor),
            reset.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            help.topAnchor.constraint(equalTo: recorder.bottomAnchor, constant: 6),
            help.leadingAnchor.constraint(equalTo: recorder.leadingAnchor),
            help.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        window.contentView = view
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

    /// On screen with the keys, on the field (when the chord is taken that is where to go).
    func show() {
        refresh()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(recorder)
    }

    /// The row as the chord stands now; while the field listens its line is the field's.
    func refresh() {
        let (chord, standing) = stand()
        recorder.chord = chord
        reset.isEnabled = chord != Chord.summon
        if !recorder.listening { help.stringValue = Chord.help(chord, standing, letter: layoutLetter) }
    }

    @objc private func resetPressed() { resetChord() }

    func windowDidResignKey(_ notification: Notification) { recorder.cancel() }

    func windowWillClose(_ notification: Notification) {
        recorder.cancel()
        onClose()
    }
}
