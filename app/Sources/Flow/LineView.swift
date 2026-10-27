// The writing surface (DESIGN.md S1 V2 B1 P0): the view fills the window, its layer paints the background, and the
// line is drawn into the strip across its middle on each key and, while a glide runs, on each display refresh.
import AppKit
import FlowCore
import QuartzCore

final class LineView: NSView, NSTextInputClient {
    let style: Style
    private let strip = Strip()
    private var text = Text(), marked = ""
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
        guard window != nil, link == nil else { return }
        let l = displayLink(target: self, selector: #selector(tick(_:)))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)  // ProMotion holds 120
        l.isPaused = true  // runs only while a glide does
        l.add(to: .main, forMode: .common)
        link = l
        relayout()
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

    // MARK: Frames

    private func render(at t: Double) {
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

    // MARK: Input

    override func keyDown(with event: NSEvent) {
        guard !event.modifierFlags.contains(.command) else { return }  // ⌘ chords: the menu's, or nothing
        interpretKeyEvents([event])
    }

    /// Return and backspace; every other command (Esc's cancelOperation:, arrows, ⌥⌫, Tab) does nothing.
    override func doCommand(by selector: Selector) {
        switch selector {
        case #selector(NSStandardKeyBindingResponding.insertNewline(_:)):
            edited(width(text.endParagraph()))
        case #selector(NSStandardKeyBindingResponding.deleteBackward(_:)):
            guard let c = text.backspace() else { return }
            edited(-width(String(c)))
        default:
            break
        }
    }

    func insertText(_ string: Any, replacementRange r: NSRange) {
        let s = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        let pressAndHold = marked.isEmpty && r.location != NSNotFound && NSMaxRange(r) == text.utf16Count
        let change = text.type(s, replacing: pressAndHold ? r.length : 0), old = marked
        marked = ""
        edited(width(change.added) - width(change.removed) - width(old))
    }
    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        let old = marked
        marked = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        edited(width(marked) - width(old))
    }
    func unmarkText() {  // the pending text stays as it is shown, so the line does not move
        text.type(marked)
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
