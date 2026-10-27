// The review (DESIGN.md O1 O2 R1): a sheet on the window with the whole text, the mechanical pass already applied (one
// toggle back to the raw text), the duration and word count, and the hand-off: Copy, Save…, Back, and Discard set
// apart. The app owns what the buttons do; this only shows and reports.
import AppKit
import FlowCore

/// Sends Return to Copy and Esc to Back wherever the focus is in the sheet: the read-only text view would otherwise
/// take both keys and do nothing with them.
final class ReviewPanel: NSPanel {
    var onReturn: () -> Void = {}, onEscape: () -> Void = {}

    override func sendEvent(_ e: NSEvent) {
        let plain = e.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty
        if e.type == .keyDown && plain {
            switch e.keyCode {
            case 36, 76: return onReturn()  // Return, Enter
            case 53: return onEscape()  // Esc
            default: break
            }
        }
        super.sendEvent(e)
    }
}

final class ReviewSheet: NSObject {
    static let background = color(0x14171b), foreground = color(0xd9dde3)
    let panel: ReviewPanel
    var onCopy: () -> Void = {}, onSave: () -> Void = {}, onBack: () -> Void = {}, onDiscard: () -> Void = {}
    var onUndoHandoff: () -> Void = {}

    private let raw: String, fixed: Mechanical.Result
    private(set) var showsRaw = false
    /// What Copy and Save hand off: what the sheet shows.
    var text: String { showsRaw ? raw : fixed.text }

    private let textView: NSTextView
    private let font = NSFont.systemFont(ofSize: 15)
    private let fixToggle = NSButton(title: "Undo", target: nil, action: nil)
    private let handoff = ReviewSheet.label(""), handoffUndo = NSButton(title: "Undo (10 s)", target: nil, action: nil)
    private let copyButton = NSButton(title: "Copy", target: nil, action: nil)

    /// `raw`: the text as typed; `stats`: "12 min · 834 words"; `note`: why the session is not kept, if it is not;
    /// `room`: the window's content size, which the sheet fits in.
    init(raw: String, stats: String, note: String?, room: NSSize) {
        self.raw = raw
        fixed = Mechanical.apply(raw)
        let scroll = NSTextView.scrollableTextView()
        textView = scroll.documentView as! NSTextView

        // At most 72 characters a line: the measure of a pangram in the text's font.
        let sample = "the quick brown fox jumps over the lazy dog" as NSString
        let column = 72 * sample.size(withAttributes: [.font: font]).width / CGFloat(sample.length)
        let inset: CGFloat = 16, margin: CGFloat = 20
        let scroller = NSScroller.scrollerWidth(for: .regular, scrollerStyle: NSScroller.preferredScrollerStyle)
        let padding = 2 * (textView.textContainer?.lineFragmentPadding ?? 0)
        let width = min(column + padding + 2 * inset + scroller + 2 * margin, room.width - 40)
        let height = max(min(room.height - 60, 720), 240)
        panel = ReviewPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.titled],
                            backing: .buffered, defer: true)
        super.init()

        panel.appearance = NSAppearance(named: .darkAqua)
        panel.backgroundColor = Self.background
        panel.hidesOnDeactivate = false  // NSPanel's default would take the sheet off the window on a switch of app
        panel.onReturn = { [unowned self] in self.copyButton.performClick(nil) }
        panel.onEscape = { [unowned self] in self.onBack() }

        scroll.borderType = .noBorder
        scroll.drawsBackground = true
        scroll.backgroundColor = Self.background
        scroll.autohidesScrollers = true
        textView.isEditable = false
        textView.isSelectable = true  // a selection can still be dragged out or copied from the context menu
        textView.drawsBackground = true
        textView.backgroundColor = Self.background
        textView.textContainerInset = NSSize(width: inset, height: inset)
        show()

        // The footer: the pass and its toggle, duration and words, the hand-off and its undo, the journal's note.
        let fixes = Self.label(fixed.count == 0 ? "R1 · no fixes"
                               : "R1 · \(fixed.count) \(fixed.count == 1 ? "fix" : "fixes"): \(fixed.summary) ·")
        for b in [fixToggle, handoffUndo] {
            b.isBordered = false
            b.font = .systemFont(ofSize: 12)
            b.contentTintColor = .linkColor
        }
        fixToggle.target = self
        fixToggle.action = #selector(toggleFixes)
        fixToggle.isHidden = fixed.count == 0
        handoffUndo.target = self
        handoffUndo.action = #selector(undoHandoff)
        var lines: [NSView] = [row(fixes, fixToggle), Self.label(stats), row(handoff, handoffUndo)]
        if let note {
            let l = Self.label(note)
            l.toolTip = note
            lines.append(l)
        }
        let footer = NSStackView(views: lines)
        footer.orientation = .vertical
        footer.alignment = .leading
        footer.spacing = 4
        showHandoff(nil, undoable: false)

        let discard = button("Discard…", #selector(pressDiscard)), back = button("Back", #selector(pressBack))
        let save = button("Save…", #selector(pressSave))
        copyButton.target = self
        copyButton.action = #selector(pressCopy)
        copyButton.bezelStyle = .push
        copyButton.keyEquivalent = "\r"  // drawn as the default button; the panel sends it Return
        back.keyEquivalent = "\u{1b}"
        save.keyEquivalent = "s"
        save.keyEquivalentModifierMask = .command
        discard.hasDestructiveAction = true
        let buttons = NSStackView()
        buttons.setViews([discard], in: .leading)
        buttons.setViews([back, save, copyButton], in: .trailing)

        let content = NSView()
        panel.contentView = content
        for v in [scroll, footer, buttons] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(v)
        }
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: content.topAnchor, constant: margin),
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),
            footer.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 12),
            footer.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: inset),
            footer.trailingAnchor.constraint(lessThanOrEqualTo: scroll.trailingAnchor),
            buttons.topAnchor.constraint(equalTo: footer.bottomAnchor, constant: 16),
            buttons.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            buttons.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -margin),
        ])
        panel.initialFirstResponder = textView  // arrows and Page Down scroll the text
    }

    /// The hand-off line: "Copied ·" with Undo (10 s), a save's file name with it, an error without, or nothing.
    func showHandoff(_ text: String?, undoable: Bool) {
        handoff.stringValue = text ?? ""
        handoff.toolTip = text
        handoff.superview?.isHidden = text == nil
        handoffUndo.isHidden = !undoable
    }

    private func show() {
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: Self.foreground]))
    }

    @objc private func toggleFixes() {
        showsRaw.toggle()
        fixToggle.title = showsRaw ? "Redo" : "Undo"
        show()
    }

    @objc private func pressCopy() { onCopy() }
    @objc private func pressSave() { onSave() }
    @objc private func pressBack() { onBack() }
    @objc private func pressDiscard() { onDiscard() }
    @objc private func undoHandoff() { onUndoHandoff() }

    private func button(_ title: String, _ action: Selector) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.bezelStyle = .push
        return b
    }

    private func row(_ views: NSView...) -> NSStackView {
        let s = NSStackView(views: views)
        s.spacing = 4
        return s
    }

    /// A footer line: one line, cut at the end when the sheet is narrow (an error can be long).
    private static func label(_ s: String) -> NSTextField {
        let l = NSTextField(labelWithString: s)
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabelColor
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }
}

/// An sRGB colour from 0xRRGGBB.
func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 255) / 255, green: CGFloat(hex >> 8 & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}
