// The surface's bottom edge, in the box or the window (it is the line's subview and moves with it): the Bluetooth
// notice (K1) and the note of a hand-off that copied instead of pasting, or did not happen (O1 O2 O3).
import AppKit
import FlowCore

/// The bottom edge of the surface: one line of small grey text, the Bluetooth notice or a hand-off's note. It stays off
/// the line's glyphs: in the window (at least 300 pt tall) the line's band starts 122 pt up; in the box (110 pt inside
/// its border) 27 pt up, where the text's top meets the band's lower quarter, which holds no ink (the band is twice the
/// font's size, the glyphs centred). This view is above the strip, so the text shows either way. Clicks go through to
/// the surface.
final class EdgeView: NSView {
    static let height: CGFloat = 40
    private let notice = NSTextField(labelWithString: BluetoothNotice.text)
    private var shown = 0  // the latest text; an earlier notice's fade finds it moved on
    /// A hand-off's note is up: it stays until `clearNote`.
    private var noting = false

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: Self.height))
        autoresizingMask = [.width, .maxYMargin]  // across the bottom as the window resizes
        notice.font = .systemFont(ofSize: 12)
        notice.textColor = color(0x5c646f)
        notice.alignment = .center
        notice.lineBreakMode = .byTruncatingTail
        notice.isHidden = true
        notice.frame = NSRect(x: 0, y: 12, width: 0, height: notice.fittingSize.height)
        notice.autoresizingMask = [.width]
        addSubview(notice)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    /// The Bluetooth notice: at once, then after 5 s it fades out over a second.
    func showNotice() { show(BluetoothNotice.text, fades: true) }

    /// Why ⌘⏎ copied instead of pasting, or why a hand-off did not happen: in the notice's place, until the next key,
    /// Esc or the container going (`clearNote`).
    func showNote(_ text: String) { show(text, fades: false) }

    /// The note goes; a Bluetooth notice is left to its fade.
    func clearNote() {
        guard noting else { return }
        noting = false
        shown += 1
        notice.isHidden = true
    }

    private func show(_ text: String, fades: Bool) {
        shown += 1
        let mine = shown
        noting = !fades
        notice.stringValue = text
        NSAnimationContext.runAnimationGroup { $0.duration = 0; notice.animator().alphaValue = 1 }  // ends a fade
        notice.isHidden = false
        guard fades else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, self.shown == mine else { return }
            NSAnimationContext.runAnimationGroup { $0.duration = 1; self.notice.animator().alphaValue = 0 }
        }
    }
}

/// An sRGB colour from 0xRRGGBB.
func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 255) / 255, green: CGFloat(hex >> 8 & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}
