// The box (DESIGN.md W2, F1, A1): a small floating panel over whatever the user is doing, with the rest of every screen
// dimmed. It takes the keys without activating Lemna, so the app behind stays the active one (and is where Paste goes,
// O3). The line moves into it from the window and back (one LineView). Its effects (F1) run on layers of its own
// through Core Animation, off the main thread: the open and the close (P1, the dim with them, D1), the accent border
// (B1) and its warmth (B2), the word sheen (K3), and the hand-off's motion (H1, C1: the line's glyphs as layers of
// their own, the box's collapse, carried on in the ghost once the box has gone). The ambience (A1) plays on the dims, on a
// Metal layer over each shade (Ambient.swift). Nothing runs at rest or while it is hidden.
import AppKit
import LemnaCore
import QuartzCore

/// A non-activating panel that can be key although it is borderless (AppKit's `canBecomeKey` is true only for titled
/// windows).
final class BoxPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    // Paste's wait for Return to come up watches the key-ups with a local monitor (`afterReturnIsUp`), not here: AppKit
    // gives a key-up with ⌘ down to no window.
    override func sendEvent(_ e: NSEvent) {
        // Lemna is not the active app while the box has the keys. Should AppKit then leave out the main menu's key
        // equivalents (Done ⌘⏎, Copy ⌘⇧⏎, Save… ⌘S, Open Window ⌃⌘F, Sound ⌘K, Quit ⌘Q), the menu gets them here; only
        // a key no menu item took reaches this, so nothing runs twice.
        if e.type == .keyDown, e.modifierFlags.contains(.command), NSApp.mainMenu?.performKeyEquivalent(with: e) == true {
            return
        }
        super.sendEvent(e)
    }
}

/// Omarchy's one curve (F1: P1, G1), as Core Animation and AppKit take it.
let quint = CAMediaTimingFunction(controlPoints: Float(Curve.controlPoints.x1), Float(Curve.controlPoints.y1),
                                  Float(Curve.controlPoints.x2), Float(Curve.controlPoints.y2))

/// The box's face (F1), over the line: a hand-off's glyphs (H1, C1), over them the accent border (B1, its warmth B2)
/// and above it the sheen (K3), so the word sheen lights the border itself. A layer tree of Lemna's own (a layer-hosting
/// view, which AppKit leaves alone) that lets the mouse through. The box's last look as it goes has one too, with the
/// line's last frame under it (Esc) or the hand-off's glyphs going on.
final class Face: NSView {
    /// B1: 1 pt, the siblings' 1 px line, on the box's whole points, so it is sharp at 1× and 2×.
    static let borderWidth: CGFloat = 1, cornerRadius: CGFloat = 10
    private let shot = CALayer(), pieces = CALayer(), border = CALayer(), sheen = CALayer(), band = CAGradientLayer(),
                ring = CAShapeLayer()

    init() {
        super.init(frame: .zero)
        let root = CALayer()
        layer = root  // before wantsLayer: layer-hosting
        wantsLayer = true
        autoresizingMask = [.width, .height]
        border.borderWidth = Self.borderWidth
        border.cornerRadius = Self.cornerRadius
        border.borderColor = Style.accent
        sheen.cornerRadius = Self.cornerRadius
        sheen.masksToBounds = true
        band.startPoint = CGPoint(x: 0, y: 0.5)
        band.endPoint = CGPoint(x: 1, y: 0.5)
        band.isHidden = true
        var lean = CATransform3DIdentity
        lean.m21 = 1  // x moves by y about its middle: the band leans right at 45°
        band.transform = lean
        sheen.addSublayer(band)
        ring.fillColor = nil
        ring.strokeColor = CGColor(gray: 0, alpha: 1)
        ring.lineWidth = Self.borderWidth
        for l in [shot, pieces, border, sheen] { root.addSublayer(l) }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func setFrameSize(_ size: NSSize) {
        super.setFrameSize(size)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for l in [pieces, border, sheen, ring] { l.frame = bounds }
        let half = Self.borderWidth / 2, r = Self.cornerRadius - half  // the border's own band
        ring.path = CGPath(roundedRect: bounds.insetBy(dx: half, dy: half), cornerWidth: r, cornerHeight: r, transform: nil)
        CATransaction.commit()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        let s = window?.backingScaleFactor ?? 2
        for l in [layer, shot, pieces, border, sheen, band, ring].compactMap({ $0 }) { l.contentsScale = s }
    }

    /// The border's colour as it shows now, also mid-change.
    var shownBorder: CGColor? { border.presentation()?.borderColor ?? border.borderColor }

    /// The border's colour, from wherever it stands, over `d` on `curve` (0: at once).
    func borderColor(_ color: CGColor, over d: Double, curve: CAMediaTimingFunction = quint) {
        let from = shownBorder
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        border.borderColor = color
        border.removeAnimation(forKey: "warmth")
        if d > 0, let from {
            let a = CABasicAnimation(keyPath: "borderColor")
            (a.fromValue, a.toValue, a.duration, a.timingFunction) = (from, color, d, curve)
            border.add(a, forKey: "warmth")
        }
        CATransaction.commit()
    }

    /// One band of light across the box, left to right at 45°, at an even pace over `d` (as Omarchy's sheen moves): a
    /// gradient from clear to white at `peak` and back, as wide as the box is tall; over the whole box, or only on its
    /// border (K3, `borderOnly`; E1's band across the box, until pass 17b). It rests past the right edge, out of sight.
    func sweep(peak: CGFloat, borderOnly: Bool, over d: Double) {
        guard d > 0 else { return }
        let b = bounds, w = b.height, reach = (w + b.height) / 2  // half the leaning band's width
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        band.colors = [CGColor(gray: 1, alpha: 0), CGColor(gray: 1, alpha: peak), CGColor(gray: 1, alpha: 0)]
        band.bounds = CGRect(x: 0, y: 0, width: w, height: b.height)
        band.position = CGPoint(x: b.maxX + reach, y: b.midY)
        band.isHidden = false
        sheen.mask = borderOnly ? ring : nil
        let move = CABasicAnimation(keyPath: "position.x")
        (move.fromValue, move.toValue, move.duration) = (b.minX - reach, b.maxX + reach, d)
        band.add(move, forKey: "sweep")
        CATransaction.commit()
    }

    /// The line's last frame where the line was: the box's last look. The box itself shows none (the line is live).
    func show(_ image: CGImage, in frame: CGRect, scale: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        (shot.contents, shot.frame, shot.contentsScale) = (image, frame, scale)
        CATransaction.commit()
    }

    /// H1 and C1: each glyph of `cut` as a layer of its own where the line showed it, under the border and clipped by
    /// the box's rounded edge, leaving along `way` by `reach` on the curve over `Tuning.exit` from `t0` plus its start
    /// (`Handoff.Piece.start`). Core Animation keeps the times, so nothing on the main thread holds the motion up, and a
    /// piece whose start is past goes on from where it stands: the ghost takes the motion over from the box this way.
    func send(_ cut: LineView.Cut, _ way: Handoff.Way, reach: CGFloat, from t0: Double) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shot.contents = nil  // the pieces are the line's look
        pieces.sublayers = nil
        let key = way == .send ? "position.x" : "position.y"
        for p in cut.pieces {
            guard let image = cut.image.cropping(to: p.pixels(bandHeight: cut.band.height, scale: cut.scale)) else {
                continue
            }
            let l = CALayer()
            (l.contents, l.contentsScale) = (image, cut.scale)
            l.frame = p.rect.offsetBy(dx: cut.band.minX, dy: cut.band.minY)
            pieces.addSublayer(l)
            let rest = way == .send ? l.position.x : l.position.y
            if way == .send { l.position.x = rest + reach } else { l.position.y = rest + reach }  // where it ends
            let a = CABasicAnimation(keyPath: key)
            (a.fromValue, a.toValue, a.duration, a.timingFunction) = (rest, rest + reach, Effects.Tuning.exit, quint)
            a.beginTime = l.convertTime(t0 + p.start(way), from: nil)
            a.fillMode = .backwards  // at rest until it sets off
            l.add(a, forKey: "leave")
        }
        CATransaction.commit()
    }

    /// A hand-off's glyphs gone.
    func unsend() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pieces.sublayers = nil
        CATransaction.commit()
    }

    /// Back at rest: no sheen, no hand-off's glyphs, the border's colour where its change was heading.
    func stop() {
        border.removeAllAnimations()
        band.removeAllAnimations()
        band.isHidden = true
        unsend()
    }
}

final class Box {
    let panel: BoxPanel
    /// The box's background with its rounded corners, holding the line and, over it, the face.
    private let content = NSView()
    private let face = Face()
    /// The box's last look after it went (P1; H1 and C1 carried on): a window that takes no keys and no clicks, so the
    /// box itself goes at once and the keys (and a paste's ⌘V) reach the app behind from the first instant.
    private let ghost: NSPanel
    private let card = NSView(), ghostFace = Face()
    /// One overlay per screen, under the box: the box's background at 0.5 (D1), the opacity on a layer of Lemna's own,
    /// and over it, once a mode has played there, the ambience's layer (A1).
    private final class Dim {
        let window: NSWindow, shade: CALayer
        var ambient: Ambient?
        init(window: NSWindow, shade: CALayer) { (self.window, self.shade) = (window, shade) }
    }
    private var dims: [Dim] = []
    private let lineHeight: CGFloat, style: Style
    private weak var line: LineView?
    /// The Effects submenu (F1), set by the app; Reduce Motion is read with it at each show, hide and key.
    var effects = Effects() { didSet { effectsChanged() } }
    /// The Ambience submenu (A1), set by the app; Reduce Motion is read with it at each show and change.
    var ambience = Ambience() { didSet { if panel.isVisible { stageAmbience(on: panel.screen) } } }
    /// The dims' ambiences that play in this show: the ones the line's keys go to.
    private var ambients: [Ambient] = []
    /// Moved on at each show and hide: a fade's end or the border's cooling that finds a later one does nothing.
    private var turn = 0
    /// B2: when the line last took a key, whether the border has the accent, and the one timer that cools it.
    private var lastKey = 0.0, warm = true, cooling: Timer?
    /// A hand-off's motion under way while the box is up (H1, C1): its way, when it began, the line's cut and how far
    /// each glyph travels; the ghost takes it over when the box goes (`hide`).
    private struct Sending {
        let way: Handoff.Way, t0: Double, cut: LineView.Cut, reach: CGFloat
    }
    private var sending: Sending?

    /// Every magnitude (the open and close, the dim, the border's warmth, the sheen, the hand-off) is `Effects.Tuning`'s.
    private typealias T = Effects.Tuning

    /// `lineHeight`: the box's height while it holds the line (`BoxFrame.height`).
    init(lineHeight: CGFloat, style: Style) {
        (self.lineHeight, self.style) = (lineHeight, style)
        panel = BoxPanel(contentRect: .zero, styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                         backing: .buffered, defer: true)
        panel.level = .floating
        // On every Space and over a full-screen app (as an auxiliary of its Space), left out of Mission Control.
        panel.collectionBehavior = Self.behavior
        panel.hidesOnDeactivate = false  // NSPanel's default; the box stays until Esc, the hotkey or a paste
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none  // AppKit's own open and close off: P1 is Lemna's
        panel.appearance = NSAppearance(named: .darkAqua)  // its sheets' buttons, drawn for the dark background
        // Clear around the rounded content so the corners show what is behind, with the system's shadow along them.
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.alphaValue = 1  // opaque (Q1); P1's open fades it in from 0
        content.wantsLayer = true
        content.layer?.backgroundColor = style.background
        content.layer?.cornerRadius = Face.cornerRadius
        content.layer?.masksToBounds = true  // the line's square layers end at the rounded edge
        content.addSubview(face)  // the line goes in under it (`hold`)
        panel.contentView = content
        ghost = NSPanel(contentRect: .zero, styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: true)
        ghost.level = .floating
        ghost.collectionBehavior = Self.behavior
        ghost.ignoresMouseEvents = true  // and a borderless panel never becomes key
        ghost.isReleasedWhenClosed = false
        ghost.animationBehavior = .none
        ghost.canHide = false  // Lemna hidden after a question or the save panel (`handBack`): the motion plays on
        ghost.isOpaque = false
        ghost.backgroundColor = .clear
        ghost.hasShadow = true
        card.wantsLayer = true
        card.layer?.backgroundColor = style.background
        card.layer?.cornerRadius = Face.cornerRadius
        card.layer?.masksToBounds = true
        card.addSubview(ghostFace)
        ghost.contentView = card
    }

    static let behavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

    var isVisible: Bool { panel.isVisible }

    /// On screen with the keys and the dim. From off screen: on the screen with the pointer, centred in its lower third
    /// (`BoxFrame`), with the line, popping open (P1). On screen already (clicked away from): only the keys back.
    func show(_ line: LineView) {
        if !panel.isVisible, let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
            ?? NSScreen.main {
            let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            let open = effects.duration(.pop, T.open, reduceMotion: still)
            turn += 1
            ghost.orderOut(nil)  // the last look of a close still under way goes at once
            ghostFace.stop()
            if let l = card.layer { uncollapse(l) }
            sending = nil
            panel.hasShadow = true  // a hand-off took it away
            panel.setFrame(BoxFrame.line(in: screen.visibleFrame, height: lineHeight), display: false)
            face.stop()
            face.borderColor(T.warm, over: 0)
            warm = true
            if effects.plays(.borderWarms, reduceMotion: still) {  // as if a key came: it cools if none does
                lastKey = CACurrentMediaTime()
                coolLater(T.coolAfter)
            }
            dim(over: open)
            stageAmbience(on: screen)
            panel.alphaValue = open > 0 ? 0 : 1
            panel.orderFrontRegardless()  // Lemna is not active: plain orderFront may leave it behind the active app's
            hold(line)  // once the panel is on screen, so the strip's first frames reach a shown layer
            if open > 0 { pop(over: open) }
        }
        panel.makeKey()  // the line takes keys from the first instant, the open under way or not
    }

    /// How the box goes: at once (the line moves to the window), with P1's fade (Esc, the hotkey, a click outside), or
    /// as a hand-off (a paste, Copy, Save…): its motion (`handOff`) carried on in the ghost, or P1's fade when that did
    /// not play (`Handoff.leaving`).
    enum Leaving { case atOnce, fade, handOff }

    /// Off screen at once. A hand-off's motion under way goes on in the ghost where it stands, the dim lifting as it
    /// was (H1, C1); any other way out but `atOnce` fades the box's last look (`ghost`) and the dim with it (P1).
    func hide(_ leaving: Leaving = .fade) {
        let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let fade = leaving == .atOnce ? 0 : effects.duration(.pop, T.close, reduceMotion: still)
        let moving = leaving == .atOnce ? nil : sending
        sending = nil
        turn += 1
        cooling?.invalidate()
        cooling = nil
        if let moving {
            let left = moving.t0 + Handoff.end - CACurrentMediaTime()
            if panel.isVisible, left > 0 { carryOn(moving, for: left) }
        } else {
            for a in ambients { a.close(over: fade) }  // the scene fades with the dim
            if panel.isVisible, fade > 0 { leaveLook(fading: fade) }
        }
        panel.orderOut(nil)
        if let l = content.layer {
            l.removeAnimation(forKey: "pop")
            uncollapse(l)
        }
        face.stop()
        NSAnimationContext.runAnimationGroup { $0.duration = 0; panel.animator().alphaValue = 1 }  // ends an open's fade
        if let moving { afterLift(from: moving.t0) } else { undim(over: fade) }
    }

    /// The hand-off's motion (F1's H1 and C1, pass 17b), from the key-down's own turn, before anything waits: the line
    /// cut into one layer per glyph in place of its band (`LineView.cut`), sent off the right edge (`.send`, a paste) or
    /// up off the top edge (`.rise`, a copy or a save) on Core Animation; the dim lifting at once, the shadow gone with
    /// it (under the dim it barely shows; the ghost has none either), and from 120 ms the emptied box collapsing.
    /// `stays`: the box stays (⌘⏎ copied instead and says why), and only the glyphs rise. Nothing in it waits for the
    /// paste and the paste waits for none of it (T1): at Return's key-up the box goes and the ghost carries on (`hide`).
    /// False when it does not play: Effects ▸ Hand-off unticked, Off, Reduce Motion, the box off screen, nothing drawn.
    @discardableResult func handOff(_ way: Handoff.Way, stays: Bool = false) -> Bool {
        let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        guard panel.isVisible, Handoff.leaving(effects, reduceMotion: still) == .motion, let line else { return false }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        guard let cut = line.cut() else {
            CATransaction.commit()
            return false
        }
        let t0 = CACurrentMediaTime(), reach = Handoff.reach(way, box: content.bounds.size)
        face.send(cut, way, reach: reach, from: t0)
        if stays {
            let mine = turn
            DispatchQueue.main.asyncAfter(deadline: .now() + Effects.Tuning.exitStaggerCap + Effects.Tuning.exit) {
                [weak self] in
                guard let self, self.turn == mine else { return }
                self.face.unsend()  // risen out of sight
            }
        } else {
            sending = Sending(way: way, t0: t0, cut: cut, reach: reach)
            panel.hasShadow = false
            if let l = content.layer { collapse(l, from: t0) }
            for dim in dims where dim.window.isVisible {
                fade(dim.shade, to: 0, over: T.lift)
                if let a = dim.ambient { fade(a.layer, to: 0, over: T.lift) }
            }
            for a in ambients { a.close(over: T.lift) }  // the scene fades with the dim
        }
        CATransaction.commit()
        CATransaction.flush()  // frame 1 now, whatever else the key's turn does
        return true
    }

    /// The hand-off did not happen after its motion began (the pasteboard refused, ⌘V could not be made): the box as it
    /// was, its dim and shadow back at once; the line comes back with `LineView.resume`.
    func unsend() {
        face.unsend()
        guard sending != nil else { return }
        sending = nil
        if let l = content.layer { uncollapse(l) }
        panel.hasShadow = true
        panel.invalidateShadow()
        for dim in dims where dim.window.isVisible { fade(dim.shade, to: T.dim, over: 0) }
        stageAmbience(on: panel.screen)
    }

    /// A key's frame is on screen (`LineView.onShown`, after the frame): B2 keeps the border warm while keys come, K3
    /// sweeps along it on Space. Steady typing touches no layer: only the first key after a pause animates (the accent
    /// back in `warmIn`), and one timer per pause cools it.
    func keyShown(_ typed: String) {
        guard panel.isVisible else { return }
        let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if effects.plays(.borderWarms, reduceMotion: still) {
            lastKey = CACurrentMediaTime()
            if !warm {
                face.borderColor(T.warm, over: T.warmIn)
                warm = true
            }
            if cooling == nil { coolLater(T.coolAfter) }
        }
        if let last = typed.last, last.isWhitespace, !last.isNewline, effects.plays(.wordSheen, reduceMotion: still) {
            face.sweep(peak: CGFloat(T.wordPeak), borderOnly: true, over: T.wordSheen)
        }
    }

    /// A key the line took, after its frame (A1): to the ambience of each screen where a mode plays, as a value.
    func ambientKey(_ k: Ambience.Key) {
        guard panel.isVisible else { return }  // window mode has no dim and no ambience
        for a in ambients { a.key(k) }
    }

    // MARK: Inside

    /// The line in the box, inside its border, under the face.
    private func hold(_ line: LineView) {
        self.line = line
        panel.invalidateShadow()  // the shadow follows the outline (the box on another screen has another width)
        let inner = content.bounds.insetBy(dx: 1, dy: 1)  // inside the border, which would cover the bottom edge
        // One frame per show: the strip's pool holds two drawables, and frames presented in the same turn of the run
        // loop come back only after it, so a third would wait. The size is set first, while the line is still where
        // nothing is drawn (off screen); then moving in draws once (`viewDidMoveToWindow`), else `redraw`.
        if line.frame != inner { line.frame = inner }
        if line.superview !== content {
            line.autoresizingMask = [.width, .maxYMargin]  // a fixed height at the bottom
            content.addSubview(line, positioned: .below, relativeTo: nil)
        } else {
            line.redraw()
        }
        panel.makeFirstResponder(line)
    }

    /// P1's open: the window fades in from transparent (its shadow with it; AppKit animates the window's alpha) while the
    /// content grows from `Tuning.openScale` about its middle (Core Animation scales the layer, the line's band with
    /// it, sharp again at rest). The shadow is taken again at full size once it has grown.
    private func pop(over d: Double) {
        guard let layer = content.layer else { return }
        let s = CGFloat(T.openScale), b = content.bounds, a = layer.anchorPoint
        var grown = CATransform3DIdentity  // s·p + (1 − s)·m about the anchor, m the middle: the middle stays put
        (grown.m11, grown.m22) = (s, s)
        (grown.m41, grown.m42) = ((0.5 - a.x) * b.width * (1 - s), (0.5 - a.y) * b.height * (1 - s))
        let grow = CABasicAnimation(keyPath: "transform")
        (grow.fromValue, grow.toValue) = (NSValue(caTransform3D: grown), NSValue(caTransform3D: CATransform3DIdentity))
        (grow.duration, grow.timingFunction) = (d, quint)
        let mine = turn
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let self, self.turn == mine else { return }
            self.panel.invalidateShadow()
        }
        layer.add(grow, forKey: "pop")
        CATransaction.commit()
        NSAnimationContext.runAnimationGroup { ctx in
            (ctx.duration, ctx.timingFunction) = (d, quint)
            panel.animator().alphaValue = 1
        }
    }

    /// The box's last look where it was: the line's last frame under the face, the border as it showed, in the ghost
    /// window; it fades out over `fading` on the curve.
    private func leaveLook(fading: Double) {
        guard let shot = line?.snapshot() else { return }  // nothing drawn yet: it goes at once
        ghost.setFrame(panel.frame, display: false)
        ghost.hasShadow = true
        ghostFace.show(shot.image, in: shot.frame, scale: panel.backingScaleFactor)
        ghostFace.borderColor(face.shownBorder ?? T.warm, over: 0)
        ghost.alphaValue = panel.alphaValue  // a close during the open goes on from where the open was
        ghost.orderFrontRegardless()
        CATransaction.flush()  // its layers committed before the box goes, so no frame shows neither
        ghost.invalidateShadow()
        let mine = turn
        DispatchQueue.main.async { [weak self] in
            guard let self, self.turn == mine else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                (ctx.duration, ctx.timingFunction) = (fading, quint)
                self.ghost.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                guard let self, self.turn == mine else { return }
                self.ghost.orderOut(nil)
                self.ghostFace.stop()
            })
        }
    }

    /// The box goes while its hand-off still moves (Return came up, T1): the ghost takes the motion over where it
    /// stands, the same glyphs at the same times and the same collapse (Core Animation keeps them, so nothing jumps),
    /// shadowless as the box had become, and goes `left` seconds on, at the motion's end.
    private func carryOn(_ s: Sending, for left: Double) {
        ghost.setFrame(panel.frame, display: false)
        ghost.hasShadow = false
        ghostFace.borderColor(face.shownBorder ?? T.warm, over: 0)
        ghostFace.send(s.cut, s.way, reach: s.reach, from: s.t0)
        if let l = card.layer {
            uncollapse(l)
            collapse(l, from: s.t0)
        }
        ghost.alphaValue = panel.alphaValue  // a hand-off during the open goes on from where the open was
        ghost.orderFrontRegardless()
        CATransaction.flush()  // its layers committed before the box goes, so no frame shows neither
        let mine = turn
        DispatchQueue.main.asyncAfter(deadline: .now() + left) { [weak self] in
            guard let self, self.turn == mine else { return }
            self.ghost.orderOut(nil)
            self.ghostFace.stop()
            if let l = self.card.layer { self.uncollapse(l) }
        }
    }

    /// From `t0` + `Tuning.collapseAt`, `l` (the box's content, or the ghost's card) shrinks about its middle to
    /// `collapseScale` and fades out over `collapse` on the curve, and stays so until `uncollapse`. Core Animation keeps
    /// the times, so the ghost's collapse goes on from where the box's was.
    private func collapse(_ l: CALayer, from t0: Double) {
        let s = CGFloat(T.collapseScale), b = l.bounds, a = l.anchorPoint
        var small = CATransform3DIdentity  // s·p + (1 − s)·m about the anchor, m the middle, as P1's open
        (small.m11, small.m22) = (s, s)
        (small.m41, small.m42) = ((0.5 - a.x) * b.width * (1 - s), (0.5 - a.y) * b.height * (1 - s))
        let shrink = CABasicAnimation(keyPath: "transform"), fade = CABasicAnimation(keyPath: "opacity")
        (shrink.fromValue, shrink.toValue) = (NSValue(caTransform3D: CATransform3DIdentity), NSValue(caTransform3D: small))
        (fade.fromValue, fade.toValue) = (1, 0)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (anim, key) in [(shrink, "collapse"), (fade, "collapseFade")] {
            (anim.duration, anim.timingFunction, anim.fillMode, anim.isRemovedOnCompletion) = (T.collapse, quint, .both, false)
            anim.beginTime = l.convertTime(t0 + T.collapseAt, from: nil)
            l.add(anim, forKey: key)
        }
        CATransaction.commit()
    }

    private func uncollapse(_ l: CALayer) {
        l.removeAnimation(forKey: "collapse")
        l.removeAnimation(forKey: "collapseFade")
    }

    /// The dim lifting since the hand-off's first frame (`handOff`): its windows go, and the ambience stops, once it has.
    private func afterLift(from t0: Double) {
        let mine = turn
        DispatchQueue.main.asyncAfter(deadline: .now() + max(t0 + T.lift - CACurrentMediaTime(), 0)) { [weak self] in
            guard let self, self.turn == mine else { return }
            for dim in self.dims { dim.window.orderOut(nil) }
            self.stopAmbience()
        }
    }

    /// The dim over every screen, one level under the box, transparent to the mouse, fading in over `d` (P1, D1).
    /// Overlays are made anew for screens that came since the last time and fitted to each screen's frame on each show.
    private func dim(over d: Double) {
        let screens = NSScreen.screens
        while dims.count < screens.count {
            let w = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true)
            w.backgroundColor = .clear
            w.isOpaque = false
            w.hasShadow = false
            w.ignoresMouseEvents = true
            w.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
            w.collectionBehavior = Self.behavior
            w.isReleasedWhenClosed = false
            w.animationBehavior = .none
            w.canHide = false  // as the ghost: it fades out or lifts even when Lemna is hidden (`handBack`)
            let root = CALayer(), shade = CALayer(), v = NSView()
            shade.backgroundColor = style.background
            shade.opacity = 0
            root.addSublayer(shade)  // the ambience's layer goes over it (A1)
            v.layer = root  // layer-hosting: AppKit leaves the shade's opacity alone
            v.wantsLayer = true
            w.contentView = v
            dims.append(Dim(window: w, shade: shade))
        }
        for (dim, s) in zip(dims, screens) {
            dim.window.setFrame(s.frame, display: false)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            dim.shade.frame = CGRect(origin: .zero, size: s.frame.size)
            CATransaction.commit()
            fade(dim.shade, from: dim.window.isVisible ? nil : 0, to: T.dim, over: d)  // off screen: from nothing
            dim.window.orderFrontRegardless()
        }
        for dim in dims.dropFirst(screens.count) { dim.window.orderOut(nil) }
    }

    /// The dim goes with the box, fading over `fading`; at once without a fade. The ambience's layers fade with the
    /// shades and stay hidden until a show's scene has a cleared frame out (`Ambient.show`); the scenes stop once the dim
    /// is gone.
    private func undim(over fading: Double) {
        guard fading > 0 else {
            for dim in dims {
                if let a = dim.ambient { fade(a.layer, to: 0, over: 0) }
                dim.window.orderOut(nil)
            }
            return stopAmbience()
        }
        for dim in dims where dim.window.isVisible {
            fade(dim.shade, to: 0, over: fading)
            if let a = dim.ambient { fade(a.layer, to: 0, over: fading) }
        }
        let mine = turn
        DispatchQueue.main.asyncAfter(deadline: .now() + fading) { [weak self] in
            guard let self, self.turn == mine else { return }
            for dim in self.dims { dim.window.orderOut(nil) }
            self.stopAmbience()
        }
    }

    /// The ambience on the dims (A1): this show's mode, none under Reduce Motion, on the box's screen, and on the other
    /// screens for the modes that play on every one (Rain, Beams); each dim's layer gets its screen's stage, the box and
    /// its line where they are on it. A dim gets its layer the first time a mode plays on it.
    private func stageAmbience(on boxScreen: NSScreen?) {
        let mode = ambience.playing(reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        let keyboard = Keyboard.kind(layoutType: physicalLayout())  // where a key is (pass 16)
        ambients = []
        for (dim, s) in zip(dims, NSScreen.screens) {
            let here = s == boxScreen, m = here || mode?.everyScreen == true ? mode : nil
            guard m != nil || dim.ambient != nil else { continue }
            let a = dim.ambient ?? Ambient(font: style.font)
            if dim.ambient == nil {
                dim.ambient = a
                dim.window.contentView?.layer?.addSublayer(a.layer)
            }
            let box = here ? panel.frame.offsetBy(dx: -s.frame.minX, dy: -s.frame.minY) : nil
            let stage = Ambience.Stage(size: s.frame.size, box: box, inset: 1, corner: Face.cornerRadius,
                                       keyboard: keyboard, style: style)
            a.begin(m, on: stage, scale: s.backingScaleFactor)
            if m != nil { ambients.append(a) }
        }
    }

    private func stopAmbience() {
        for a in ambients { a.stop() }
        ambients = []
    }

    /// A layer's opacity to `value` from `start` (nil: wherever it stands), over `d` on the curve (0: at once).
    private func fade(_ l: CALayer, from start: Float? = nil, to value: Float, over d: Double) {
        let from = start ?? l.presentation()?.opacity ?? l.opacity
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        l.opacity = value
        l.removeAnimation(forKey: "fade")
        if d > 0 {
            let a = CABasicAnimation(keyPath: "opacity")
            (a.fromValue, a.toValue, a.duration, a.timingFunction) = (from, value, d, quint)
            l.add(a, forKey: "fade")
        }
        CATransaction.commit()
    }

    /// B2: after `after` seconds, the border cools if no key came in the last `coolAfter` (else it looks again then),
    /// evenly over `coolOver`.
    private func coolLater(_ after: Double) {
        let mine = turn
        cooling = Timer.scheduledTimer(withTimeInterval: after, repeats: false) { [weak self] _ in
            guard let self, self.turn == mine else { return }
            self.cooling = nil
            let quiet = CACurrentMediaTime() - self.lastKey
            guard quiet >= T.coolAfter else { return self.coolLater(T.coolAfter - quiet) }
            self.face.borderColor(T.cooled, over: T.coolOver, curve: CAMediaTimingFunction(name: .linear))
            self.warm = false
        }
    }

    /// The submenu changed while the box is up: a border B2 left cool warms at once when B2 goes off; turned on, B2
    /// starts watching for the pause.
    private func effectsChanged() {
        guard panel.isVisible else { return }
        if effects.plays(.borderWarms, reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) {
            if cooling == nil, warm {
                lastKey = CACurrentMediaTime()
                coolLater(T.coolAfter)
            }
        } else {
            cooling?.invalidate()
            cooling = nil
            if !warm { face.borderColor(T.warm, over: 0) }
            warm = true
        }
    }
}
