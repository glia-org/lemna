// The review (DESIGN.md O1 O2 O3 R1 M1): the session's intent, if one was set, the whole text, the mechanical pass
// already applied (one toggle back to the raw text), the duration and word count, and the hand-off: Paste (in the box),
// Copy, Save…, Back, and Discard set apart. One content view, two hosts: the box grown in place (W2), or a sheet on the
// window. The app owns what the buttons do; this only shows and reports.
import AppKit
import FlowCore

/// The window's host: a sheet the review's content fills, sized as v1's was.
final class ReviewPanel: NSPanel {
    let review: Review

    /// `room`: the window's content size, which the sheet fits in.
    init(review: Review, room: NSSize) {
        self.review = review
        let width = min(review.columnWidth + 2 * Review.margin, room.width - 40)
        let height = max(min(room.height - 60, 720), 240)
        super.init(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.titled],
                   backing: .buffered, defer: true)
        appearance = NSAppearance(named: .darkAqua)
        backgroundColor = Review.background
        hidesOnDeactivate = false  // NSPanel's default would take the sheet off the window on a switch of app
        contentView = review.view
        initialFirstResponder = review.focus  // arrows and Page Down scroll the text
    }

    override func performKeyEquivalent(with e: NSEvent) -> Bool { review.handles(e) || super.performKeyEquivalent(with: e) }
    override func sendEvent(_ e: NSEvent) { if !review.handles(e) { super.sendEvent(e) } }
}

final class Review: NSObject {
    static let background = color(0x14171b), foreground = color(0xd9dde3)
    /// Around the text column, inside either host.
    static let margin: CGFloat = 20
    /// The content: what a host shows, filling it.
    let view = NSView()
    var onCopy: () -> Void = {}, onPaste: () -> Void = {}, onSave: () -> Void = {}, onBack: () -> Void = {}
    var onDiscard: () -> Void = {}, onUndoHandoff: () -> Void = {}
    /// The text changed (R1 undone or redone): what was handed off is not what shows now.
    var onTextChange: () -> Void = {}
    /// The text column's width: 72 characters, the text view's insets and padding, the scroller. The box is wider than
    /// that, so the column stays this wide and centred in it; a narrow sheet narrows it.
    let columnWidth: CGFloat
    /// Where the keys go when a host shows the review: the text, so arrows and Page Down scroll it.
    var focus: NSView { textView }

    private let raw: String, fixed: Mechanical.Result
    private(set) var showsRaw = false
    /// What Copy, Paste and Save hand off: what the review shows.
    var text: String { showsRaw ? raw : fixed.text }

    private let textView: NSTextView
    private let font = NSFont.systemFont(ofSize: 15)
    private let fixToggle = NSButton(title: "Undo", target: nil, action: nil)
    private let handoff = Review.label(""), handoffUndo = NSButton(title: "Undo (10 s)", target: nil, action: nil)
    private let copyButton = NSButton(title: "Copy", target: nil, action: nil)
    /// Only in the box, where there is an app to paste into; ⌘⏎ presses it there, Copy in the window.
    private let pasteButton: NSButton?

    /// `raw`: the text as typed; `stats`: "12 min · 834 words"; `note`: why the session is not kept, if it is not;
    /// `intent`: the session's intent line, if one was set; `paste`: offer Paste (the box's review).
    init(raw: String, stats: String, note: String?, intent: String?, paste: Bool) {
        self.raw = raw
        fixed = Mechanical.apply(raw)
        let scroll = NSTextView.scrollableTextView()
        textView = scroll.documentView as! NSTextView

        // At most 72 characters a line: the measure of a pangram in the text's font.
        let sample = "the quick brown fox jumps over the lazy dog" as NSString
        let column = 72 * sample.size(withAttributes: [.font: font]).width / CGFloat(sample.length)
        let inset: CGFloat = 16, margin = Self.margin
        let scroller = NSScroller.scrollerWidth(for: .regular, scrollerStyle: NSScroller.preferredScrollerStyle)
        let padding = 2 * (textView.textContainer?.lineFragmentPadding ?? 0)
        columnWidth = (column + padding + 2 * inset + scroller).rounded(.up)
        pasteButton = paste ? NSButton(title: "Paste", target: nil, action: nil) : nil
        super.init()

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
        copyButton.bezelStyle = .push  // not the default button: Return does not copy; the host sends ⌘⏎ (`handles`)
        pasteButton?.target = self
        pasteButton?.action = #selector(pressPaste)
        pasteButton?.bezelStyle = .push  // nor this one, for the same reason
        back.keyEquivalent = "\u{1b}"
        save.keyEquivalent = "s"
        save.keyEquivalentModifierMask = .command
        discard.hasDestructiveAction = true
        let buttons = NSStackView()
        buttons.setViews([discard], in: .leading)
        buttons.setViews([back, save, copyButton] + (pasteButton.map { [$0] } ?? []), in: .trailing)

        let content = view
        content.wantsLayer = true
        content.layer?.backgroundColor = Self.background.cgColor  // the same in the box as on the sheet
        for v in [scroll, footer, buttons] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(v)
        }
        // The header: the intent, one line in the muted colour above the text's left edge; nothing without one.
        var top = content.topAnchor, gap = margin
        if let intent {
            let header = Self.label(intent)
            header.font = .systemFont(ofSize: 13)
            header.textColor = color(0x5c646f)
            header.toolTip = intent
            header.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(header)
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: content.topAnchor, constant: margin),
                header.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: inset),
                header.trailingAnchor.constraint(lessThanOrEqualTo: scroll.trailingAnchor, constant: -inset),
            ])
            (top, gap) = (header.bottomAnchor, 8)
        }
        // The column: its own width where the host has room (the box), the host's width less the margins where not.
        let measure = scroll.widthAnchor.constraint(equalToConstant: columnWidth)
        measure.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: top, constant: gap),
            scroll.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            scroll.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -2 * margin),
            measure,
            footer.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 12),
            footer.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: inset),
            footer.trailingAnchor.constraint(lessThanOrEqualTo: scroll.trailingAnchor),
            buttons.topAnchor.constraint(equalTo: footer.bottomAnchor, constant: 16),
            buttons.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            buttons.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -margin),
        ])
    }

    /// The review's keys wherever the focus is in it (`ReviewKey`): ⌘⏎ presses Paste where there is one, else Copy; Esc
    /// is Back; plain Return is swallowed (the read-only text would take it and do nothing). Each host calls this from
    /// `performKeyEquivalent`, which AppKit tries before the main menu, whose Done (off in the review) has the same
    /// chord, and from `sendEvent`, for the keys that are not key equivalents. True: handled.
    func handles(_ e: NSEvent) -> Bool {
        guard e.type == .keyDown else { return false }
        let flags = e.modifierFlags
        switch ReviewKey.route(keyCode: e.keyCode, command: flags.contains(.command),
                               others: !flags.intersection([.option, .control, .shift]).isEmpty, isRepeat: e.isARepeat) {
        case .copy: (pasteButton ?? copyButton).performClick(nil)
        case .back: onBack()
        case .nothing: break
        case .pass: return false
        }
        return true
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
        onTextChange()
    }

    @objc private func pressCopy() { onCopy() }
    @objc private func pressPaste() { onPaste() }
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
