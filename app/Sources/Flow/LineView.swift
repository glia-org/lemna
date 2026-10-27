// The writing surface (DESIGN.md S1 V2 B4 P0): the view fills its container (the box, or the window: one view moved
// between them, W2), its layer paints the background, and the line is drawn into the strip across its middle on each
// key and, while a glide runs, on each display refresh. The caret moves through the text and edits anywhere (B4);
// every change to the text leaves as a journal edit (E2) and, ahead of the drawing, as a click (K1).
import AppKit
import FlowClicks
import FlowCore
import FlowJournal
import QuartzCore

final class LineView: NSView, NSTextInputClient {
    let style: Style
    private let strip = Strip()
    private(set) var text = Text()
    private var marked = ""
    /// Each change to the text, as the journal records it; called on the key event.
    var onEdit: (Edit) -> Void = { _ in }
    /// Clicks on the keys that change the text, played before the edit is laid out and drawn so the sound leaves
    /// first; nil when the player could not start.
    var clicks: ClickPlayer?
    /// Esc while writing: the box hides (the app decides; in the window Esc does nothing).
    var onEscape: () -> Void = {}
    /// False from Done until Back: keys do nothing and the line keeps its last frame.
    private(set) var accepting = true
    /// `glide` moves the text before the caret (an edit there), `slide` the whole text (a caret move): S1, B4.
    private var shaped = Shaped(), glide = Glide(), slide = Glide()
    /// About one word: the most a held ← leaves the text behind the caret.
    private lazy var word = Line.width(String(repeating: "n", count: Line.wordCells), font: style.font)
    private var link: CADisplayLink?
    private var keyFrame = 0.0  // when a key last drew a frame

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        wantsLayer = true
        addSubview(strip)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() { layer?.backgroundColor = style.background }
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        if link == nil {  // made once; it follows the view to the display it is on
            let l = displayLink(target: self, selector: #selector(tick(_:)))
            l.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)  // ProMotion holds 120
            l.isPaused = true  // runs only while a glide does
            l.add(to: .main, forMode: .common)
            link = l
        }
        relayout()  // each move into the box or the window: its size, its scale, a fresh frame
    }
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        relayout()
    }
    override func setFrameSize(_ size: NSSize) {
        super.setFrameSize(size)
        relayout()
    }
    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        strip.synced = true
    }
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        strip.synced = false
    }

    /// Puts the strip across the middle and draws the line again; the caret stays at 60 % of the new width.
    private func relayout() {
        guard window != nil else { return }  // nowhere to present yet; viewDidMoveToWindow comes
        strip.frame = Line.band(in: bounds.size, style: style)
        strip.resize(scale: window?.backingScaleFactor ?? 2)
        render(at: CACurrentMediaTime())
    }

    /// Draws again as the view now stands: its container came on screen, or the line came back from under the review.
    func redraw() { relayout() }

    // MARK: Frames

    /// Presents a frame only while the view is on screen: a drawable presented to a hidden window or view may not come
    /// back to the layer's pool of two, and the next `nextDrawable` would wait up to a second on the main thread. The
    /// box hides often (Esc, the hotkey, a paste) and the session can end while it is hidden; `redraw` catches up.
    private func render(at t: Double) {
        guard window?.isVisible == true, !isHiddenOrHasHiddenAncestor else { return }
        let band = CGRect(origin: .zero, size: strip.bounds.size), moved = CGFloat(slide.offset(at: t))
        let edit = CGFloat(glide.offset(at: t))
        strip.present { Line.draw(shaped, before: edit + moved, after: moved, in: $0, band: band, style: style) }
    }

    @objc private func tick(_ l: CADisplayLink) {
        if keyFrame <= l.timestamp { render(at: l.targetTimestamp) }  // else a key already drew this refresh's frame
        if !gliding(at: l.targetTimestamp) { l.isPaused = true }
    }

    private func gliding(at t: Double) -> Bool { glide.active(at: t) || slide.active(at: t) }

    /// Shows a change at once, on the key event itself: the text before the caret moved left by `dw` points (an edit
    /// there), the whole text by `ds` (a caret move; capped at a word behind, and starting at most a band's width
    /// away), or neither (a deletion after the caret closes up at once).
    private func edited(before dw: CGFloat = 0, moved ds: CGFloat = 0) {
        let now = CACurrentMediaTime(), still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        shaped = Line.shape(text, marked: marked, font: style.font)
        glide.add(Double(dw), at: now, reduceMotion: still)
        slide.add(Double(ds), at: now, reduceMotion: still, cap: max(abs(Double(ds)), Double(word)),
                  limit: Double(bounds.width))
        // Drawn as the glides will stand when the frame is on screen (the display link's next target while that lies
        // ahead, else about one refresh on): at the key's own time the new glyph is still wholly under the caret, and the
        // frame would show nothing new.
        let target = link?.targetTimestamp ?? 0, refresh = 1 / Double(window?.screen?.maximumFramesPerSecond ?? 60)
        let shown = target > now ? target : now + refresh
        keyFrame = now
        render(at: shown)
        if gliding(at: shown) { link?.isPaused = false }
    }

    private func width(_ s: String) -> CGFloat { Line.width(s, font: style.font) }

    /// A key's change: its edits to the journal, then on screen as its motion says.
    private func take(_ change: Change) {
        for e in change.edits { onEdit(e) }
        switch change.motion {
        case .none: break
        case .before(let added, let removed): edited(before: width(added) - width(removed))
        case .after: edited()
        case .caret(let passed, let leftward): edited(moved: leftward ? -width(passed) : width(passed))
        }
    }

    /// A delete key: the backspace click when it took something, before the line is laid out; at the start (⌫) or
    /// the end (⌦) it does nothing, silently.
    private func delete(_ change: Change) {
        guard !change.edits.isEmpty else { return }
        clicks?.play(.backspace)
        take(change)
    }

    // MARK: Session

    /// Shows `t` at rest and takes keys: the restore at launch, and the clear after a session ends.
    func load(_ t: Text) {
        (text, marked, glide, slide, accepting) = (t, "", Glide(), Glide(), true)
        inputContext?.discardMarkedText()  // after `marked` is empty, so an unmarkText it may send adds nothing
        shaped = Line.shape(text, marked: "", font: style.font)
        if window != nil { render(at: CACurrentMediaTime()) }
    }

    /// Done: keys stop. Pending input (a dead key) joins the text, as the line already shows it, so the review and the
    /// journal hold what was on screen.
    func stop() {
        accepting = false
        if !marked.isEmpty {
            for e in text.insert(marked).edits { onEdit(e) }
            marked = ""
            shaped = Line.shape(text, marked: "", font: style.font)
        }
        inputContext?.discardMarkedText()
    }

    /// Back: keys again.
    func resume() { accepting = true }

    // MARK: Input

    override func keyDown(with event: NSEvent) {
        guard accepting else { return }
        // ⌘ chords are the menu's, or nothing; but ⌘← and ⌘→ move the caret to the paragraph's ends (B4).
        if event.modifierFlags.contains(.command), event.specialKey != .leftArrow, event.specialKey != .rightArrow {
            return
        }
        interpretKeyEvents([event])
    }

    /// The keys of B4, by the commands AppKit's key bindings (StandardKeyBinding.dict) send for them: Return; ⌫, ⌥⌫,
    /// ⌦, ⌥⌦; ←, →, ⌥←, ⌥→; ⌘← and ⌘→, which send moveToLeftEndOfLine: and moveToRightEndOfLine: and go to the
    /// paragraph's ends (on one line, a paragraph is the only line there is); and Esc (its cancelOperation:, after the
    /// input method had its say, so an input method's own Esc still cancels its pending text). The other commands
    /// that mean the same move come along at no cost (⌃B ⌃F, ⌃⌥B ⌃⌥F, ⌃A ⌃E and ⌥↑ ⌥↓; ⌃H and ⌃D already send
    /// deleteBackward: and deleteForward:). Every other command (↑, ↓, Tab, a selection) does nothing.
    override func doCommand(by selector: Selector) {
        guard accepting else { return }
        typealias K = NSStandardKeyBindingResponding
        switch selector {
        case #selector(K.insertNewline(_:)):
            clicks?.play(.paragraph)
            take(text.insert("\n"))
        case #selector(K.deleteBackward(_:)): delete(text.deleteBackward())
        case #selector(K.deleteWordBackward(_:)): delete(text.deleteWordBackward())
        case #selector(K.deleteForward(_:)): delete(text.deleteForward())
        case #selector(K.deleteWordForward(_:)): delete(text.deleteWordForward())
        case #selector(K.moveLeft(_:)), #selector(K.moveBackward(_:)): take(text.moveLeft())
        case #selector(K.moveRight(_:)), #selector(K.moveForward(_:)): take(text.moveRight())
        case #selector(K.moveWordLeft(_:)), #selector(K.moveWordBackward(_:)): take(text.moveWordLeft())
        case #selector(K.moveWordRight(_:)), #selector(K.moveWordForward(_:)): take(text.moveWordRight())
        case #selector(K.moveToLeftEndOfLine(_:)), #selector(K.moveToBeginningOfLine(_:)),
             #selector(K.moveToBeginningOfParagraph(_:)):
            take(text.moveToParagraphStart())
        case #selector(K.moveToRightEndOfLine(_:)), #selector(K.moveToEndOfLine(_:)),
             #selector(K.moveToEndOfParagraph(_:)):
            take(text.moveToParagraphEnd())
        case #selector(NSResponder.cancelOperation(_:)):
            onEscape()
        default:
            break
        }
    }

    func insertText(_ string: Any, replacementRange r: NSRange) {
        guard accepting else { return }
        let s = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        if !s.isEmpty { clicks?.play(s.allSatisfy(\.isWhitespace) ? .space : .letter) }
        // The press-and-hold accent menu replaces the letter just typed: a range that ends at the caret.
        let pressAndHold = marked.isEmpty && r.location != NSNotFound && NSMaxRange(r) == text.utf16Caret
        let change = text.insert(s, replacing: pressAndHold ? r.length : 0), old = marked
        marked = ""
        for e in change.edits { onEdit(e) }
        var dw = -width(old)  // the pending text it takes the place of
        if case .before(let added, let removed) = change.motion { dw += width(added) - width(removed) }
        edited(before: dw)
    }
    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        guard accepting else { return }
        let old = marked
        marked = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        if !marked.isEmpty && marked != old { clicks?.play(.letter) }  // a dead key: a key pressed, and the line shows it
        edited(before: width(marked) - width(old))
    }
    func unmarkText() {  // the pending text stays as it is shown, so the line does not move
        if !marked.isEmpty { for e in text.insert(marked).edits { onEdit(e) } }
        marked = ""
    }
    func hasMarkedText() -> Bool { !marked.isEmpty }
    func markedRange() -> NSRange {
        marked.isEmpty ? NSRange(location: NSNotFound, length: 0)
            : NSRange(location: text.utf16Caret, length: marked.utf16.count)
    }
    func selectedRange() -> NSRange { NSRange(location: text.utf16Caret + marked.utf16.count, length: 0) }
    /// The document as the input system sees it: the text with the pending text at the caret.
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        let all = NSMutableString(string: text.plainText)
        all.insert(marked, at: text.utf16Caret)
        let r = NSIntersectionRange(range, NSRange(location: 0, length: all.length))
        actualRange?.pointee = r
        return NSAttributedString(string: all.substring(with: r), attributes: [.font: style.font])
    }
    func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }
    /// The caret, so the accent menu and input method windows open there.
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        let caret = Line.caretRect(in: Line.band(in: bounds.size, style: style), style: style)
        return window?.convertToScreen(convert(caret, to: nil)) ?? .zero
    }
    func characterIndex(for point: NSPoint) -> Int { NSNotFound }
}
