// The pasteboard and the keys for Copy (O1) and Paste (O3): Lemna's item, and ⌘V as the keyboard would send it. Lemna
// writes the pasteboard and never reads it: after a paste its text stays on the clipboard.
import AppKit
import Carbon.HIToolbox

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
