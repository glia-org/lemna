// The pasteboard and the keys for Copy (O1) and Paste (O3): Flow's item, the old clipboard kept and put back, and ⌘V
// as the keyboard would send it.
import AppKit
import Carbon.HIToolbox

enum Clipboard {
    /// Copy's item: plain text, marked for clipboard managers as concealed and transient (nspasteboard.org), kept off
    /// other devices. `prepareForNewContents(with:)` clears the pasteboard itself; `declareTypes` would clear it again
    /// and drop the host-only option (NSPasteboard.h), so the types go in as one item. Returns the change count the
    /// write left (Paste's restore compares it), nil when the write failed.
    static func write(_ text: String) -> Int? {
        let pasteboard = NSPasteboard.general
        _ = pasteboard.prepareForNewContents(with: .currentHostOnly)
        let item = NSPasteboardItem()
        item.setString(text, forType: .string)
        for marker in ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType"] {
            item.setData(Data(), forType: NSPasteboard.PasteboardType(marker))
        }
        return pasteboard.writeObjects([item]) ? pasteboard.changeCount : nil
    }

    /// Each item on the general pasteboard as the data of each of its types: what NSPasteboard gives (a copied file is
    /// its URL; the file is not read). Nil when Flow may not read it (macOS 15.4's pasteboard privacy set to deny for
    /// Flow): every read would come back empty, and putting back nothing would empty the clipboard, so then Flow's
    /// text stays on it instead.
    static func save() -> [[(NSPasteboard.PasteboardType, Data)]]? {
        let pasteboard = NSPasteboard.general
        if #available(macOS 15.4, *), pasteboard.accessBehavior == .alwaysDeny { return nil }
        return (pasteboard.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }
    }

    /// Puts saved items back as they were; an empty clipboard stays empty.
    static func restore(_ items: [[(NSPasteboard.PasteboardType, Data)]]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let back = items.map { types -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in types { item.setData(data, forType: type) }
            return item
        }
        if !back.isEmpty { pasteboard.writeObjects(back) }
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
