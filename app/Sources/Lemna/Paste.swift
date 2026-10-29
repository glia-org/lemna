// The pasteboard and the keys for Copy (O1) and Paste (O3): Lemna's item, and ⌘V as the keyboard would send it. Lemna
// writes the pasteboard and never reads it: after a paste its text stays on the clipboard. Since pass 17a also the
// hand-off's timing log.
import AppKit
import Carbon.HIToolbox
import QuartzCore

enum Clipboard {
    /// Copy's item: plain text, marked for clipboard managers as concealed and transient (nspasteboard.org), kept off
    /// other devices. `prepareForNewContents(with:)` clears the pasteboard itself; `declareTypes` would clear it again
    /// and drop the host-only option (NSPasteboard.h), so the types go in as one item. False when the write failed.
    static func write(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        _ = pasteboard.prepareForNewContents(with: .currentHostOnly)
        let item = NSPasteboardItem()
        item.setString(text, forType: .string)
        for marker in ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType"] {
            item.setData(Data(), forType: NSPasteboard.PasteboardType(marker))
        }
        return pasteboard.writeObjects([item])
    }
}

/// ⌘V as two key events, down and up, with the Command flag, posted at the HID tap so they reach whatever has the keys
/// as typed ones do. Their own event source: the flags are only the ones set here, whatever keys are held (⇧ would make
/// it Paste and Match Style). Needs the PostEvent permission, shown as Accessibility; without it macOS drops them.
struct CommandV {
    private let down: CGEvent, up: CGEvent

    init?() {
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        else { return nil }
        down.flags = .maskCommand
        up.flags = .maskCommand
        (self.down, self.up) = (down, up)
    }

    func post() {
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

/// The hand-off's timing log (pass 17a), off unless `defaults write dev.lemna.app LemnaTiming -bool true` (read at each
/// Done and Copy): one line in the system log per step, `Lemna timing: <step> at <ms> ms`, counted from the key-down
/// (or the click) that began the hand-off, on the clock NSEvent's timestamps use.
struct Timing {
    private var start: Double?

    static let off = Timing()

    /// From `event`'s time (nil: now) while the default is on, else off.
    static func from(_ event: NSEvent?) -> Timing {
        var t = Timing()
        if UserDefaults.standard.bool(forKey: "LemnaTiming") { t.start = event?.timestamp ?? CACurrentMediaTime() }
        return t
    }

    var on: Bool { start != nil }

    func mark(_ step: String) {
        guard let start else { return }
        NSLog("Lemna timing: %@ at %.1f ms", step, (CACurrentMediaTime() - start) * 1000)
    }
}
