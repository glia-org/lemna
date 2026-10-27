// The review (DESIGN.md O1 O2 O3 R1 R2 M1): the session's intent, if one was set, the whole text, the mechanical pass
// already applied (one toggle back to the raw text), Harper's suggestions beside the text or under it, each accepted
// or skipped, the duration and word count, and the hand-off: Paste (in the box), Copy, Save…, Back, and Discard set
// apart. One content view, two hosts: the box grown in place (W2), or a sheet on the window. The app owns what the
// buttons do and how the text is linted; this only shows and reports.
import AppKit
import FlowCore

/// The window's host: a sheet the review's content fills, as wide as the review asks within the window.
final class ReviewPanel: NSPanel {
    let review: Review

    /// `room`: the window's content size, which the sheet fits in.
    init(review: Review, room: NSSize) {
        self.review = review
        let width = min(review.width, room.width - 40)
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
    /// The selected suggestion: its row, and its range in the text (the panel's selection colour).
    static let selection = color(0x283457)
    /// Around the text column, inside either host.
    static let margin: CGFloat = 20
    /// How long the list waits for Harper before it says it is unavailable; the review works without it.
    static let patience = 2.0
    /// The content: what a host shows, filling it.
    var view: NSView { content }
    var onCopy: () -> Void = {}, onPaste: () -> Void = {}, onSave: () -> Void = {}, onBack: () -> Void = {}
    var onDiscard: () -> Void = {}, onUndoHandoff: () -> Void = {}
    /// The text changed (a suggestion accepted, R1 undone or redone): what was handed off is not what shows now.
    var onTextChange: () -> Void = {}
    /// The text column's width: 72 characters, the text view's insets and padding, the scroller. It stays this wide
    /// where the host has room, beside Harper's list or above it (`ReviewLayout`); a narrow sheet narrows it.
    let columnWidth: CGFloat
    /// What the review asks of a host: the column, the list at its widest beside it, the margins.
    var width: CGFloat { columnWidth + ReviewLayout.gap + ReviewLayout.listWidest + 2 * Self.margin }
    /// Where the keys go when a host shows the review: the text, so arrows and Page Down scroll it.
    var focus: NSView { textView }

    private let raw: String, fixed: Mechanical.Result
    private(set) var showsRaw = false
    /// The text shown, Harper's suggestions for it, what was accepted (R2).
    private var list: SuggestionList
    /// What Copy, Paste and Save hand off: the text as shown, with the suggestions accepted so far.
    var text: String { list.text }
    /// Lints a text off the main thread and answers on it (the app's Harper).
    private let lint: (String, @escaping ([Suggestion]) -> Void) -> Void
    private enum Check { case checking, ready, unavailable }
    private var check = Check.checking
    /// Each lint's number: an answer to an earlier one (R1 toggled meanwhile, or too late) is dropped.
    private var generation = 0

    private let content = Content()
    private let textView: NSTextView
    private let font = NSFont.systemFont(ofSize: 15)
    private let fixToggle = NSButton(title: "Undo", target: nil, action: nil)
    private let accepted = Review.label("")
    private let handoff = Review.label(""), handoffUndo = NSButton(title: "Undo (10 s)", target: nil, action: nil)
    private let copyButton = NSButton(title: "Copy", target: nil, action: nil)
    /// Only in the box, where there is an app to paste into; ⌘⏎ presses it there, Copy in the window.
    private let pasteButton: NSButton?

    // Harper's column: its heading, one line while there is no list (checking…, unavailable, none), the rows, and the
    // buttons under them.
    private let column = NSStackView()
    private let heading = Review.label(""), status = Review.label("")
    private let listScroll = NSScrollView(), rows = NSStackView()
    private var rowViews: [Row] = []
    private let actions = NSStackView()
    private var acceptButton: NSButton!, acceptAllButton: NSButton!
    // Where the columns go for the content's width (`arrange`), and the constraints that differ between beside and
    // below.
    private var textX: NSLayoutConstraint!, textWidth: NSLayoutConstraint!
    private var listX: NSLayoutConstraint!, listWidth: NSLayoutConstraint!
    private var besideOnly: [NSLayoutConstraint] = [], belowOnly: [NSLayoutConstraint] = []
    private var placed: ReviewLayout.Columns?

    /// `raw`: the text as typed; `stats`: "12 min · 834 words"; `note`: why the session is not kept, if it is not;
    /// `intent`: the session's intent line, if one was set; `paste`: offer Paste (the box's review); `lint`: Harper,
    /// asked about the shown text at once and again after R1's Undo or Redo.
    init(raw: String, stats: String, note: String?, intent: String?, paste: Bool,
         lint: @escaping (String, @escaping ([Suggestion]) -> Void) -> Void) {
        self.raw = raw
        fixed = Mechanical.apply(raw)
        list = SuggestionList(text: fixed.text)
        self.lint = lint
        let scroll = NSTextView.scrollableTextView()
        textView = scroll.documentView as! NSTextView

        // At most 72 characters a line: the measure of a pangram in the text's font.
        let sample = "the quick brown fox jumps over the lazy dog" as NSString
        let column72 = 72 * sample.size(withAttributes: [.font: font]).width / CGFloat(sample.length)
        let inset: CGFloat = 16, margin = Self.margin
        let scroller = NSScroller.scrollerWidth(for: .regular, scrollerStyle: NSScroller.preferredScrollerStyle)
        let padding = 2 * (textView.textContainer?.lineFragmentPadding ?? 0)
        columnWidth = (column72 + padding + 2 * inset + scroller).rounded(.up)
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

        // The footer: the pass and its toggle (then what Harper changed), duration and words, the hand-off and its
        // undo, the journal's note.
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
        var lines: [NSView] = [row(fixes, fixToggle, accepted), Self.label(stats), row(handoff, handoffUndo)]
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

        makeColumn()

        content.wantsLayer = true
        content.layer?.backgroundColor = Self.background.cgColor  // the same in the box as on the sheet
        for v in [scroll, column, footer, buttons] as [NSView] {
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
        // Across: the text column and Harper's where `arrange` puts them for the content's width. Down: the text,
        // Harper's column beside it (its top on the text's, never past its bottom) or under it, the footer, then the
        // buttons, across both columns.
        textX = scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor)
        textWidth = scroll.widthAnchor.constraint(equalToConstant: columnWidth)
        listX = column.leadingAnchor.constraint(equalTo: content.leadingAnchor)
        listWidth = column.widthAnchor.constraint(equalToConstant: 0)
        let someText = scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        someText.priority = NSLayoutConstraint.Priority(760)  // over the list's height (740): below, the list gives way
        NSLayoutConstraint.activate([
            textX, textWidth, listX, listWidth, someText,
            scroll.topAnchor.constraint(equalTo: top, constant: gap),
            footer.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: inset),
            footer.trailingAnchor.constraint(lessThanOrEqualTo: column.trailingAnchor),
            buttons.topAnchor.constraint(equalTo: footer.bottomAnchor, constant: 16),
            buttons.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            buttons.trailingAnchor.constraint(equalTo: column.trailingAnchor),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -margin),
        ])
        besideOnly = [
            column.topAnchor.constraint(equalTo: scroll.topAnchor),
            column.bottomAnchor.constraint(lessThanOrEqualTo: scroll.bottomAnchor),
            footer.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 12),
        ]
        belowOnly = [
            column.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 12),
            footer.topAnchor.constraint(equalTo: column.bottomAnchor, constant: 12),
            listScroll.heightAnchor.constraint(lessThanOrEqualToConstant: 132),  // about seven rows; the rest is text's
        ]
        NSLayoutConstraint.activate(belowOnly)
        content.arrange = { [weak self] in self?.arrange(width: $0) }  // the view may outlive the review in its host

        recheck()
    }

    /// The review's keys wherever the focus is in it (`ReviewKey`): ⌘⏎ presses Paste where there is one, else Copy; Esc
    /// is Back; with a suggestion selected ↑ and ↓ move through the list, Return accepts, ⌫ skips; else plain Return is
    /// swallowed (the read-only text would take it and do nothing). Each host calls this from `performKeyEquivalent`,
    /// which AppKit tries before the main menu, whose Done (off in the review) has the same chord, and from
    /// `sendEvent`, for the keys that are not key equivalents. True: handled.
    func handles(_ e: NSEvent) -> Bool {
        guard e.type == .keyDown else { return false }
        let flags = e.modifierFlags
        switch ReviewKey.route(keyCode: e.keyCode, command: flags.contains(.command),
                               others: !flags.intersection([.option, .control, .shift]).isEmpty, isRepeat: e.isARepeat,
                               listed: check == .ready && list.current != nil) {
        case .copy: (pasteButton ?? copyButton).performClick(nil)
        case .back: onBack()
        case .accept: accept()
        case .skip: skip()
        case .up: move(-1)
        case .down: move(1)
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

    /// The text as it stands, the selected suggestion's range lit.
    private func show() {
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: Self.foreground]))
        light()
    }

    /// The selected suggestion's range on the selection colour, scrolled into view; nothing lit without one.
    private func light() {
        guard let storage = textView.textStorage else { return }
        storage.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: storage.length))
        guard check == .ready, let s = list.current, s.end <= storage.length else { return }
        let r = NSRange(location: s.start, length: s.length)
        storage.addAttribute(.backgroundColor, value: Self.selection, range: r)
        textView.scrollRangeToVisible(r)
    }

    @objc private func toggleFixes() {
        showsRaw.toggle()
        fixToggle.title = showsRaw ? "Redo" : "Undo"
        // Harper's suggestions and what was accepted belong to the other text: this one is linted afresh.
        list = SuggestionList(text: showsRaw ? raw : fixed.text)
        show()
        recheck()
        onTextChange()
    }

    // MARK: Harper (R2)

    /// Asks Harper about the text as shown. Until it answers the column says `checking…`; after `patience` without an
    /// answer, `Harper unavailable` (that lint's answer is then dropped, and the review goes on without it).
    private func recheck() {
        generation += 1
        let mine = generation, asked = list.text
        check = .checking
        for r in rowViews { r.removeFromSuperview() }
        rowViews = []
        refreshColumn()
        lint(asked) { [weak self] found in
            guard let self, self.generation == mine, self.check == .checking else { return }
            self.list = SuggestionList(text: asked, items: found)
            self.check = .ready
            self.fillRows()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.patience) { [weak self] in
            guard let self, self.generation == mine, self.check == .checking else { return }
            self.check = .unavailable
            self.refreshColumn()
        }
    }

    private func accept() {
        guard let i = list.selected, let s = list.current, let replacement = s.replacement, list.accept()
        else { return }
        rowViews.remove(at: i).removeFromSuperview()
        // Only the changed range, as the list changed its text: the text view keeps its scroll (a whole new string
        // could jump back to the top), and the next suggestion's range is lit where it now is.
        textView.textStorage?.replaceCharacters(in: NSRange(location: s.start, length: s.length), with: replacement)
        refreshColumn()
        light()
        onTextChange()
    }

    private func skip() {
        guard let i = list.selected, list.skip() else { return }
        rowViews.remove(at: i).removeFromSuperview()
        refreshColumn()
        light()
    }

    private func acceptAll() {
        guard list.acceptAll() > 0 else { return }
        fillRows()
        onTextChange()
    }

    private func move(_ by: Int) {
        list.move(by)
        refreshColumn()
        light()
    }

    /// The rows anew for the list (Harper's answer, accept all), then the text and the column.
    private func fillRows() {
        for r in rowViews { r.removeFromSuperview() }
        rowViews = list.items.map { _ in
            let r = Row()
            r.onClick = { [unowned self, unowned r] in
                guard let i = self.rowViews.firstIndex(where: { $0 === r }) else { return }
                self.list.select(i)
                self.refreshColumn()
                self.light()
            }
            return r
        }
        for r in rowViews {
            rows.addArrangedSubview(r)
            r.widthAnchor.constraint(equalTo: rows.widthAnchor).isActive = true
        }
        show()
        refreshColumn()
    }

    /// The column for the state: `checking…` or `Harper unavailable` under the heading; the rows and their buttons;
    /// or, with nothing (left) to suggest, no column but one muted line. Its place stays either way, so the text does
    /// not move when Harper answers. Also the footer's count of accepted suggestions.
    private func refreshColumn() {
        let rowsShown = check == .ready && !list.items.isEmpty
        heading.isHidden = check == .ready && list.items.isEmpty
        status.isHidden = rowsShown
        switch check {
        case .checking: status.attributedStringValue = Self.muted("checking…")
        case .unavailable: status.attributedStringValue = Self.muted("Harper unavailable")
        case .ready: status.attributedStringValue = Self.muted("Harper · no suggestions")
        }
        listScroll.isHidden = !rowsShown
        actions.isHidden = !rowsShown
        acceptButton.isHidden = list.current?.replacement == nil  // Harper only points at it: skip only
        acceptAllButton.isHidden = !list.items.contains { $0.replacement != nil }
        // Numbered by place, 1 to N, so an accept or a skip renumbers the rows after it.
        for (i, r) in rowViews.enumerated() { r.show(list.items[i], number: i + 1, selected: i == list.selected) }
        if rowsShown, let i = list.selected { rowViews[i].scrollToVisible(rowViews[i].bounds) }
        accepted.stringValue = list.note ?? ""
        accepted.isHidden = list.note == nil
    }

    private func makeColumn() {
        heading.attributedStringValue = Self.muted("HARPER · ENGLISH · OFFLINE", kern: 0.6)

        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = 0
        rows.setHuggingPriority(.defaultHigh, for: .vertical)  // as tall as its rows: the list's height follows them
        rows.translatesAutoresizingMaskIntoConstraints = false
        let document = Flipped()  // the rows start at the top
        document.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(rows)
        listScroll.documentView = document
        listScroll.drawsBackground = false
        listScroll.borderType = .noBorder
        listScroll.hasVerticalScroller = true
        listScroll.autohidesScrollers = true
        let clip = listScroll.contentView
        let fit = listScroll.heightAnchor.constraint(equalTo: document.heightAnchor)
        fit.priority = NSLayoutConstraint.Priority(740)  // as tall as the rows, where there is room
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            rows.topAnchor.constraint(equalTo: document.topAnchor),
            rows.bottomAnchor.constraint(equalTo: document.bottomAnchor),
            document.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            document.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            document.topAnchor.constraint(equalTo: clip.topAnchor),
            fit,
        ])

        acceptButton = small("accept", #selector(pressAccept))
        acceptAllButton = small("accept all", #selector(pressAcceptAll))
        actions.setViews([acceptButton, small("skip", #selector(pressSkip)), acceptAllButton], in: .leading)
        actions.spacing = 6
        actions.edgeInsets = NSEdgeInsets(top: 0, left: Row.inset, bottom: 0, right: 0)

        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 6
        column.detachesHiddenViews = true  // the hidden parts take no room
        column.setHuggingPriority(.defaultHigh, for: .vertical)  // as tall as what shows, not as the text
        column.setViews([heading, status, listScroll, actions], in: .top)
        // The heading and the lines as wide as the column (cut at its end), not as their text measures.
        for v in [heading, status, listScroll] { v.widthAnchor.constraint(equalTo: column.widthAnchor).isActive = true }
    }

    /// The columns for the content's width, beside or below (`ReviewLayout`): at each host's size and each resize.
    private func arrange(width: CGFloat) {
        let c = ReviewLayout.columns(width: width, column: columnWidth, margin: Self.margin)
        guard c != placed else { return }
        let flips = placed?.beside != c.beside
        placed = c
        (textX.constant, textWidth.constant) = (c.textX, c.textWidth)
        (listX.constant, listWidth.constant) = (c.listX, c.listWidth)
        guard flips else { return }
        NSLayoutConstraint.deactivate(c.beside ? belowOnly : besideOnly)
        NSLayoutConstraint.activate(c.beside ? besideOnly : belowOnly)
    }

    @objc private func pressCopy() { onCopy() }
    @objc private func pressPaste() { onPaste() }
    @objc private func pressSave() { onSave() }
    @objc private func pressBack() { onBack() }
    @objc private func pressDiscard() { onDiscard() }
    @objc private func undoHandoff() { onUndoHandoff() }
    @objc private func pressAccept() { accept() }
    @objc private func pressSkip() { skip() }
    @objc private func pressAcceptAll() { acceptAll() }

    private func button(_ title: String, _ action: Selector) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.bezelStyle = .push
        return b
    }

    /// The list's buttons: small, under the rows.
    private func small(_ title: String, _ action: Selector) -> NSButton {
        let b = button(title, action)
        b.controlSize = .small
        b.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small))
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

    /// A line of Harper's column in the muted colour, indented as the rows' text is, so it stands over it.
    private static func muted(_ s: String, kern: CGFloat = 0) -> NSAttributedString {
        let p = NSMutableParagraphStyle()
        (p.firstLineHeadIndent, p.lineBreakMode) = (Row.inset, .byTruncatingTail)
        return NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: 12),
                                                          .foregroundColor: color(0x5c646f), .kern: kern,
                                                          .paragraphStyle: p])
    }
}

/// The review's content view: it lays the columns out for its own width, whatever size its host gives it (the box sets
/// its frame, the sheet makes it its content view), and again at each resize.
private final class Content: NSView {
    var arrange: (CGFloat) -> Void = { _ in }

    override func setFrameSize(_ size: NSSize) {
        super.setFrameSize(size)
        needsUpdateConstraints = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsUpdateConstraints = true
    }

    override func updateConstraints() {
        arrange(bounds.width)
        super.updateConstraints()
    }
}

/// A document view whose content starts at the top.
private final class Flipped: NSView {
    override var isFlipped: Bool { true }
}

/// One suggestion in Harper's list: its place in the list, its kind, and the change, `wrong → replacement` with the wrong part
/// struck through (struck alone when the change deletes it; not struck when Harper only points at it). Harper's
/// explanation is the tooltip. The selected row stands on the selection colour; a click selects it.
private final class Row: NSView {
    /// The text's inset from the row's edges.
    static let inset: CGFloat = 6
    var onClick: () -> Void = {}
    private let label = NSTextField(labelWithString: "")
    private static let font = NSFont.systemFont(ofSize: 12)
    /// The number's column, then the kind's (Harper's longest kind, "miscellaneous", is 80 pt at 12 pt).
    private static let style: NSParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.tabStops = [NSTextTab(textAlignment: .left, location: 22), NSTextTab(textAlignment: .left, location: 110)]
        p.lineBreakMode = .byTruncatingTail
        return p
    }()

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.inset),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Self.inset),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    /// The whole row takes the click, its label included.
    override func hitTest(_ point: NSPoint) -> NSView? { frame.contains(point) ? self : nil }
    override func mouseDown(with event: NSEvent) { onClick() }

    func show(_ s: Suggestion, number: Int, selected: Bool) {
        let ink: NSColor = selected ? Review.foreground : .secondaryLabelColor
        let base: [NSAttributedString.Key: Any] = [.font: Self.font, .foregroundColor: ink, .paragraphStyle: Self.style]
        let out = NSMutableAttributedString(string: "\(number)\t\(s.label)\t", attributes: base)
        let wrong = s.wrong.replacingOccurrences(of: "\n", with: " ")
        if let replacement = s.replacement {
            var struck = base
            struck[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            struck[.foregroundColor] = selected ? NSColor.secondaryLabelColor : .tertiaryLabelColor
            out.append(NSAttributedString(string: wrong, attributes: struck))
            if !replacement.isEmpty { out.append(NSAttributedString(string: " → " + replacement, attributes: base)) }
        } else {
            out.append(NSAttributedString(string: wrong, attributes: base))
        }
        label.attributedStringValue = out
        layer?.backgroundColor = selected ? Review.selection.cgColor : nil
        toolTip = s.message
    }
}

/// An sRGB colour from 0xRRGGBB.
func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 255) / 255, green: CGFloat(hex >> 8 & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}
