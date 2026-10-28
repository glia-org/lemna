// Summoning (DESIGN.md W2): a global hotkey that brings the box (or, in window mode, the window) or puts it away, and
// the menu-bar item with Lemna's menu.
import AppKit
import Carbon.HIToolbox
import LemnaCore

/// The global hotkey, ⌃⌥Space: the one place the chord is defined (no setting to change it yet). Carbon's
/// RegisterEventHotKey sees only this chord, so it needs no Accessibility or Input Monitoring permission (an event tap
/// would) and works in an unsigned build.
final class Hotkey {
    static let keyCode = UInt32(kVK_Space), carbonModifiers = UInt32(controlKey | optionKey)
    /// The same chord as a menu shows it.
    static let equivalent = " ", modifiers: NSEvent.ModifierFlags = [.control, .option]

    private let pressed: () -> Void
    private var hotKey: EventHotKeyRef?, handler: EventHandlerRef?

    /// Nil when the chord cannot be registered; the menu-bar item still shows Lemna.
    init?(_ pressed: @escaping () -> Void) {
        self.pressed = pressed
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        // A C callback captures nothing, so the hotkey reaches itself through the handler's user data. Carbon calls it
        // on the main thread, from the application's event target.
        let call: EventHandlerUPP = { _, _, me in
            if let me { Unmanaged<Hotkey>.fromOpaque(me).takeUnretainedValue().pressed() }
            return noErr
        }
        let target = GetApplicationEventTarget()
        guard InstallEventHandler(target, call, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler) == noErr,
              RegisterEventHotKey(Self.keyCode, Self.carbonModifiers, EventHotKeyID(signature: 0x4C6D_6E61, id: 1),  // 'Lmna'
                                  target, 0, &hotKey) == noErr
        else { return nil }  // deinit removes what was installed
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}

/// The menu-bar item: the mark (a template, so the menu bar tints it) and Lemna's menu. As an accessory app Lemna has no
/// menu bar of its own, so this menu carries the main menu's items too: Show Lemna (with the hotkey's chord), Open
/// Window, Done, Copy, Save…, Discard…, Sound ▸ (the packs, Off), Quit. The App validates them: the hand-offs' state,
/// the Sound submenu's check marks, Open Window's title.
func makeStatusItem(target: AnyObject) -> NSStatusItem {
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
    menu.addItem(withTitle: "Show Lemna", action: #selector(App.summon(_:)), keyEquivalent: Hotkey.equivalent)
        .keyEquivalentModifierMask = Hotkey.modifiers
    menu.addItem(withTitle: "Open Window", action: #selector(App.toggleWindow(_:)), keyEquivalent: "f")
        .keyEquivalentModifierMask = [.control, .command]
    menu.addItem(.separator())
    menu.addItem(withTitle: "Done", action: #selector(App.done(_:)), keyEquivalent: "\r")
    menu.addItem(withTitle: "Copy", action: #selector(App.copyText(_:)), keyEquivalent: "\r")
        .keyEquivalentModifierMask = [.command, .shift]
    menu.addItem(withTitle: "Save…", action: #selector(App.saveText(_:)), keyEquivalent: "s")
    menu.addItem(withTitle: "Discard…", action: #selector(App.discard(_:)), keyEquivalent: "")
    menu.addItem(.separator())
    menu.addItem(withTitle: "Sound", action: nil, keyEquivalent: "").submenu = soundMenu(target: target)
    for i in menu.items where i.action != nil { i.target = target }  // the app may not be active: no key window
    menu.addItem(.separator())
    menu.addItem(withTitle: "Quit Lemna", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    item.menu = menu
    return item
}
