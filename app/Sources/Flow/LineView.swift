// The writing surface (DESIGN.md S1 V2 B1 P0): the view fills its container (the box, or the window: one view moved
// between them, W2), its layer paints the background, and the line is drawn into the strip across its middle on each
// key and, while a glide runs, on each display refresh. Every change to the text leaves as a journal edit (E2) and,
// ahead of the drawing, as a click (K1).
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
    private var shaped = Shaped(), glide = Glide()
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
        let band = CGRect(origin: .zero, size: strip.bounds.size), offset = CGFloat(glide.offset(at: t))
        strip.present { Line.draw(shaped, offset: offset, in: $0, band: band, style: style) }
    }

    @objc private func tick(_ l: CADisplayLink) {
        if keyFrame <= l.timestamp { render(at: l.targetTimestamp) }  // else a key already drew this refresh's frame
        if !glide.active(at: l.targetTimestamp) { l.isPaused = true }
    }

    /// Shows an edit that moved the line's end left by `dw` points, at once, on the key event itself.
    private func edited(_ dw: CGFloat) {
        let now = CACurrentMediaTime()
        shaped = Line.shape(text, marked: marked, font: style.font)
        glide.add(Double(dw), at: now, reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        // Drawn as the glide will stand when the frame is on screen (the display link's next target while that lies
        // ahead, else about one refresh on): at the key's own time the new glyph is still wholly under the caret, and the
        // frame would show nothing new.
        let target = link?.targetTimestamp ?? 0, refresh = 1 / Double(window?.screen?.maximumFramesPerSecond ?? 60)
        let shown = target > now ? target : now + refresh
        keyFrame = now
        render(at: shown)
        if glide.active(at: shown) { link?.isPaused = false }
    }

    private func width(_ s: String) -> CGFloat { Line.width(s, font: style.font) }

    /// Applies an edit and hands it to the journal: the one way the text changes, but for backspace.
    @discardableResult
    private func record(_ e: Edit) -> (removed: String, added: String) {
        let change = text.apply(e)
        onEdit(e)
        return change
    }

    // MARK: Session

    /// Shows `t` at rest and takes keys: the restore at launch, and the clear after a session ends.
    func load(_ t: Text) {
        (text, marked, glide, accepting) = (t, "", Glide(), true)
        inputContext?.discardMarkedText()  // after `marked` is empty, so an unmarkText it may send adds nothing
        shaped = Line.shape(text, marked: "", font: style.font)
        if window != nil { render(at: CACurrentMediaTime()) }
    }

    /// Done: keys stop. Pending input (a dead key) joins the text, as the line already shows it, so the review and the
    /// journal hold what was on screen.
    func stop() {
        accepting = false
        if !marked.isEmpty {
            record(.insert(marked))
            marked = ""
            shaped = Line.shape(text, marked: "", font: style.font)
        }
        inputContext?.discardMarkedText()
    }

    /// Back: keys again.
    func resume() { accepting = true }

    // MARK: Input

    override func keyDown(with event: NSEvent) {
        guard accepting, !event.modifierFlags.contains(.command) else { return }  // ⌘ chords: the menu's, or nothing
        interpretKeyEvents([event])
    }

    /// Return, backspace and Esc (its cancelOperation:, after the input method had its say, so an input method's own
    /// Esc still cancels its pending text); every other command (arrows, ⌥⌫, Tab) does nothing.
    override func doCommand(by selector: Selector) {
        guard accepting else { return }
        switch selector {
        case #selector(NSStandardKeyBindingResponding.insertNewline(_:)):
            clicks?.play(.paragraph)
            edited(width(record(.paragraphEnd).added))
        case #selector(NSStandardKeyBindingResponding.deleteBackward(_:)):
            guard let c = text.backspace() else { return }  // B1 decides here, so not through `record`; blocked: silent
            clicks?.play(.backspace)
            onEdit(.deleteBackward(String(c).utf16.count))  // which `Text.apply` replays as the same cut
            edited(-width(String(c)))
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
        let pressAndHold = marked.isEmpty && r.location != NSNotFound && NSMaxRange(r) == text.utf16Count
        let removed = pressAndHold && r.length > 0 ? record(.deleteBackward(r.length)).removed : ""
        let added = s.isEmpty ? "" : record(.insert(s)).added, old = marked
        marked = ""
        edited(width(added) - width(removed) - width(old))
    }
    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        guard accepting else { return }
        let old = marked
        marked = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        if !marked.isEmpty && marked != old { clicks?.play(.letter) }  // a dead key: a key pressed, and the line shows it
        edited(width(marked) - width(old))
    }
    func unmarkText() {  // the pending text stays as it is shown, so the line does not move
        if !marked.isEmpty { record(.insert(marked)) }
        marked = ""
    }
    func hasMarkedText() -> Bool { !marked.isEmpty }
    func markedRange() -> NSRange {
        marked.isEmpty ? NSRange(location: NSNotFound, length: 0)
            : NSRange(location: text.utf16Count, length: marked.utf16.count)
    }
    func selectedRange() -> NSRange { NSRange(location: text.utf16Count + marked.utf16.count, length: 0) }
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        let all = (text.plainText + marked) as NSString, r = NSIntersectionRange(range, NSRange(location: 0, length: all.length))
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
