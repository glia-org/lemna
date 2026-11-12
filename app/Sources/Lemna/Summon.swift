// Summoning (DESIGN.md W2): a global hotkey that brings the box (or, in window mode, the window) or puts it away, and
// the menu-bar item with Lemna's menu.
import AppKit
import Carbon.HIToolbox
import LemnaCore

/// The global hotkey: the kept chord (SD2 of `docs/design-panel-lemna-settings.html`), ⌃⌥Space unless Settings changed
/// it. Carbon's RegisterEventHotKey sees only this chord, so it needs no Accessibility or Input Monitoring permission (an
/// event tap would) and works in an unsigned build. Registration is shared and says almost nothing: on macOS 26.5 it
/// refused no chord tried, Spotlight's ⌘Space included (survey §6); a refusal is kept for the menu's note.
final class Hotkey {
    private let pressed: () -> Void
    private var hotKey: EventHotKeyRef?, handler: EventHandlerRef?
    /// What is registered while not paused; nil: none.
    var chord: Chord? { didSet { register() } }
    /// While Settings' field listens (SR1): unregistered, so the field gets Lemna's own chord too.
    var paused = false { didSet { if paused != oldValue { register() } } }
    /// RegisterEventHotKey (or the handler before it) refused `chord` at its last registration.
    private(set) var refused = false

    init(_ pressed: @escaping () -> Void) {
        self.pressed = pressed
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        // A C callback captures nothing, so the hotkey reaches itself through the handler's user data. Carbon calls it
        // on the main thread, from the application's event target.
        let call: EventHandlerUPP = { _, _, me in
            if let me { Unmanaged<Hotkey>.fromOpaque(me).takeUnretainedValue().pressed() }
            return noErr
        }
        if InstallEventHandler(GetApplicationEventTarget(), call, 1, &spec, Unmanaged.passUnretained(self).toOpaque(),
                               &handler) != noErr { handler = nil }
    }

    private func register() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = nil
        guard !paused else { return }  // `refused` stays what the last registration said
        guard let chord else { return refused = false }
        refused = handler == nil
            || RegisterEventHotKey(chord.key, chord.modifiers, EventHotKeyID(signature: 0x4C6D_6E61, id: 1),  // 'Lmna'
                                   GetApplicationEventTarget(), 0, &hotKey) != noErr
        if refused { NSLog("Lemna: the hotkey %@ could not be registered; the menu-bar item shows Lemna", chord.glyphs()) }
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}

/// macOS's own chords that are on (SC2): CopySymbolicHotKeys' entries with their enabled flag, as key code and Carbon
/// modifiers (`Chord` drops the Fn bit). Public Carbon, no permission; about 4 ms a call (survey §6), so read at launch,
/// at a menu's opening and for a recorded chord, never per key.
func systemChords() -> [Chord] {
    var list: Unmanaged<CFArray>?
    guard CopySymbolicHotKeys(&list) == noErr, let entries = list?.takeRetainedValue() as? [[String: Any]] else {
        return []
    }
    return entries.compactMap { e in
        guard e[kHISymbolicHotKeyEnabled] as? Bool == true, let k = e[kHISymbolicHotKeyCode] as? Int,
              let m = e[kHISymbolicHotKeyModifiers] as? Int, (0..<128).contains(k), m >= 0 else { return nil }
        return Chord(key: UInt32(k), modifiers: UInt32(truncatingIfNeeded: m))
    }
}

/// Lemna's own key equivalents (SC2): every item of the main menu that has one, as the box hands ⌘ chords to it.
func menuKeys(_ menu: NSMenu? = NSApp.mainMenu) -> [MenuKey] {
    (menu?.items ?? []).flatMap { i in
        (i.keyEquivalent.isEmpty ? [] : [MenuKey(title: i.title, equivalent: i.keyEquivalent,
                                                 modifiers: carbon(i.keyEquivalentModifierMask))]) + menuKeys(i.submenu)
    }
}

/// What `key` types with no modifier on the current ASCII-capable layout, as menus read key equivalents (UCKeyTranslate,
/// as the recorder libraries do), so a German ⌃⌥Z reads Z; the US layout's when it cannot be read.
func layoutLetter(_ key: UInt32) -> String? {
    guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
          let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else { return Chord.usLetter(key) }
    let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue()
    var dead: UInt32 = 0, length = 0, chars = [UniChar](repeating: 0, count: 4)
    let status = CFDataGetBytePtr(data).withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) {
        UCKeyTranslate($0, UInt16(key), UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                       OptionBits(kUCKeyTranslateNoDeadKeysMask), &dead, chars.count, &length, &chars)
    }
    let s = String(utf16CodeUnits: chars, count: length)
    guard status == noErr, !s.isEmpty, s.unicodeScalars.allSatisfy({ $0.properties.isGraphemeBase }) else {
        return Chord.usLetter(key)
    }
    return s
}

/// AppKit's modifier flags and Carbon's mask: ⌃⌥⇧⌘ only.
private let modifierPairs: [(NSEvent.ModifierFlags, UInt32)] =
    [(.control, Chord.control), (.option, Chord.option), (.shift, Chord.shift), (.command, Chord.command)]

func carbon(_ f: NSEvent.ModifierFlags) -> UInt32 { modifierPairs.reduce(0) { f.contains($1.0) ? $0 | $1.1 : $0 } }

func flags(_ m: UInt32) -> NSEvent.ModifierFlags { modifierPairs.reduce([]) { m & $1.1 != 0 ? $0.union($1.0) : $0 } }

/// The menu-bar item: the mark (a template, so the menu bar tints it) and Lemna's menu. As an accessory app Lemna has no
/// menu bar of its own, so this menu carries the main menu's items too: Show Lemna (with the hotkey's chord, and under it
/// a grey line when the chord is taken: SD2), Open Window, Done, Copy, Save…, Discard…, Theme ▸ (each theme), Sound ▸
/// (the packs, the beds, Off, Mute Clicks), Effects ▸ (each effect, Off), Settings… (SP2; the ambience's mode is chosen
/// there since pass 39), Start at Login, Quit. The App validates them: the hand-offs' state, the submenus' check marks,
/// Open Window's title, Start at Login's tick and title; as the menu's delegate it sets Show Lemna's chord and the grey
/// line each time it opens.
func makeStatusItem(target: App) -> NSStatusItem {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)  // retained by the caller
    let mark = NSImage(size: StatusMark.size, flipped: false) { _ in
        guard let c = NSGraphicsContext.current?.cgContext else { return false }
        StatusMark.draw(in: c)
        return true
    }
    mark.isTemplate = true
    mark.accessibilityDescription = "Lemna"
    item.button?.image = mark
    let menu = NSMenu()
    menu.addItem(withTitle: "Show Lemna", action: #selector(App.summon(_:)), keyEquivalent: "")
    let note = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")  // no action: grey
    note.tag = App.chordNote
    note.isHidden = true
    menu.addItem(withTitle: "Open Window", action: #selector(App.toggleWindow(_:)), keyEquivalent: "f")
        .keyEquivalentModifierMask = [.control, .command]
    menu.addItem(.separator())
    menu.addItem(withTitle: "Paste into App", action: #selector(App.done(_:)), keyEquivalent: "\r")
    menu.addItem(withTitle: "Copy", action: #selector(App.copyText(_:)), keyEquivalent: "\r")
        .keyEquivalentModifierMask = [.command, .shift]
    menu.addItem(withTitle: "Save…", action: #selector(App.saveText(_:)), keyEquivalent: "s")
    menu.addItem(withTitle: "Discard…", action: #selector(App.discard(_:)), keyEquivalent: "")
    menu.addItem(.separator())
    menu.addItem(withTitle: "Theme", action: nil, keyEquivalent: "").submenu = themeMenu(target: target)
    menu.addItem(withTitle: "Sound", action: nil, keyEquivalent: "").submenu = soundMenu(target: target)
    menu.addItem(withTitle: "Effects", action: nil, keyEquivalent: "").submenu = effectsMenu(target: target)
    for i in menu.items where i.action != nil { i.target = target }  // the app may not be active: no key window
    menu.addItem(.separator())
    menu.addItem(withTitle: "Settings…", action: #selector(App.openSettings(_:)), keyEquivalent: ",").target = target
    menu.addItem(withTitle: "Open at Login", action: #selector(App.toggleLogin(_:)), keyEquivalent: "").target = target
    menu.addItem(withTitle: "Quit Lemna", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    menu.delegate = target
    item.menu = menu
    return item
}
