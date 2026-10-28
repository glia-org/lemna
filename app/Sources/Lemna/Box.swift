// The box (DESIGN.md W2, F1): a small floating panel over whatever the user is doing, with the rest of every screen
// dimmed. It takes the keys without activating Lemna, so the app behind stays the active one (and is where Paste goes,
// O3). The line moves into it from the window and back (one LineView). Its effects (F1) run on layers of its own
// through Core Animation, off the main thread: the open and the close (P1, the dim with them, D1), the accent border
// (B1) and its warmth (B2), the sheens (E1, K3). Nothing runs at rest or while it is hidden.
import AppKit
import LemnaCore
import QuartzCore

/// A non-activating panel that can be key although it is borderless (AppKit's `canBecomeKey` is true only for titled
/// windows).
final class BoxPanel: NSPanel {
    /// Each key that comes up while the box has the keys: Paste waits for Return's.
    var onKeyUp: (UInt16) -> Void = { _ in }

    override var canBecomeKey: Bool { true }

    override func sendEvent(_ e: NSEvent) {
        if e.type == .keyUp { onKeyUp(e.keyCode) }
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

/// The box's face (F1), over the line: the accent border (B1, its warmth B2) and above it the sheen (E1, K3), so the
/// word sheen lights the border itself. A layer tree of Lemna's own (a layer-hosting view, which AppKit leaves alone)
/// that lets the mouse through. The box's last look as it fades has one too, with the line's last frame under it.
final class Face: NSView {
    /// B1: 1 pt, the siblings' 1 px line, on the box's whole points, so it is sharp at 1× and 2×.
    static let borderWidth: CGFloat = 1, cornerRadius: CGFloat = 10
    private let shot = CALayer(), border = CALayer(), sheen = CALayer(), band = CAGradientLayer(), ring = CAShapeLayer()

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
        for l in [shot, border, sheen] { root.addSublayer(l) }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func setFrameSize(_ size: NSSize) {
        super.setFrameSize(size)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for l in [border, sheen, ring] { l.frame = bounds }
        let half = Self.borderWidth / 2, r = Self.cornerRadius - half  // the border's own band
        ring.path = CGPath(roundedRect: bounds.insetBy(dx: half, dy: half), cornerWidth: r, cornerHeight: r, transform: nil)
        CATransaction.commit()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        let s = window?.backingScaleFactor ?? 2
        for l in [layer, shot, border, sheen, band, ring].compactMap({ $0 }) { l.contentsScale = s }
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
    /// gradient from clear to white at `peak` and back, as wide as the box is tall; over the whole box (E1) or only on its
    /// border (K3, `borderOnly`). It rests past the right edge, out of sight.
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

    /// Back at rest: no sheen, the border's colour where its change was heading.
    func stop() {
        border.removeAllAnimations()
        band.removeAllAnimations()
        band.isHidden = true
    }
}

final class Box {
    let panel: BoxPanel
    /// The box's background with its rounded corners, holding the line and, over it, the face.
    private let content = NSView()
    private let face = Face()
    /// The box's last look after it went (P1, E1): a window that takes no keys and no clicks, so the box itself goes at
    /// once and the keys (and a paste's ⌘V) reach the app behind from the first instant.
    private let ghost: NSPanel
    private let ghostFace = Face()
    /// One overlay per screen, under the box: the box's background at 0.5 (D1), the opacity on a layer of Lemna's own.
    private var dims: [(window: NSWindow, shade: CALayer)] = []
    private let lineHeight: CGFloat, style: Style
    private weak var line: LineView?
    /// The Effects submenu (F1), set by the app; Reduce Motion is read with it at each show, hide and key.
    var effects = Effects() { didSet { effectsChanged() } }
    /// Moved on at each show and hide: a fade's end or the border's cooling that finds a later one does nothing.
    private var turn = 0
    /// B2: when the line last took a key, whether the border has the accent, and the one timer that cools it.
    private var lastKey = 0.0, warm = true, cooling: Timer?

    /// Every magnitude (the open and close, the dim, the border's warmth, the sheens) is `Effects.Tuning`'s.
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
        ghost.isOpaque = false
        ghost.backgroundColor = .clear
        ghost.hasShadow = true
        let card = NSView()
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
            panel.setFrame(BoxFrame.line(in: screen.visibleFrame, height: lineHeight), display: false)
            face.stop()
            face.borderColor(T.warm, over: 0)
            warm = true
            if effects.plays(.borderWarms, reduceMotion: still) {  // as if a key came: it cools if none does
                lastKey = CACurrentMediaTime()
                coolLater(T.coolAfter)
            }
            dim(over: open)
            panel.alphaValue = open > 0 ? 0 : 1
            panel.orderFrontRegardless()  // Lemna is not active: plain orderFront may leave it behind the active app's
            hold(line)  // once the panel is on screen, so the strip's first frames reach a shown layer
            if open > 0 { pop(over: open) }
        }
        panel.makeKey()  // the line takes keys from the first instant, the open under way or not
    }

    /// How the box goes: at once (the line moves to the window), with P1's fade (Esc, the hotkey, a click outside), or
    /// as a hand-off (a paste, Copy, Save…), with E1's sheen across it as it fades.
    enum Leaving { case atOnce, fade, handOff }

    /// Off screen at once; what fades is the box's last look (`ghost`), and at a hand-off E1's sheen crosses it, the
    /// fade waiting so that both end together (sheen 0–350 ms, fade 150–350 ms). The dim fades with it.
    func hide(_ leaving: Leaving = .fade) {
        let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let fade = leaving == .atOnce ? 0 : effects.duration(.pop, T.close, reduceMotion: still)
        let sweep = leaving == .handOff ? effects.duration(.handOffSheen, T.handOffSheen, reduceMotion: still) : 0
        let wait = max(sweep - fade, 0)
        turn += 1
        cooling?.invalidate()
        cooling = nil
        if panel.isVisible, fade + sweep > 0 { leaveLook(waiting: wait, fading: fade, sweep: sweep) }
        panel.orderOut(nil)
        content.layer?.removeAnimation(forKey: "pop")
        face.stop()
        NSAnimationContext.runAnimationGroup { $0.duration = 0; panel.animator().alphaValue = 1 }  // ends an open's fade
        undim(waiting: wait, fading: fade)
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

    /// E1 on a box that stays: ⌘⏎ copied instead of pasting and says why at its bottom edge.
    func sweep() {
        let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        face.sweep(peak: CGFloat(T.handOffPeak), borderOnly: false,
                   over: effects.duration(.handOffSheen, T.handOffSheen, reduceMotion: still))
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
    /// window; after `waiting` it fades out over `fading` on the curve, with E1's sheen across it over `sweep`.
    private func leaveLook(waiting: Double, fading: Double, sweep: Double) {
        guard let shot = line?.snapshot() else { return }  // nothing drawn yet: it goes at once
        ghost.setFrame(panel.frame, display: false)
        ghostFace.show(shot.image, in: shot.frame, scale: panel.backingScaleFactor)
        ghostFace.borderColor(face.shownBorder ?? T.warm, over: 0)
        ghost.alphaValue = panel.alphaValue  // a close during the open goes on from where the open was
        ghost.orderFrontRegardless()
        CATransaction.flush()  // its layers committed before the box goes, so no frame shows neither
        ghost.invalidateShadow()
        ghostFace.sweep(peak: CGFloat(T.handOffPeak), borderOnly: false, over: sweep)
        let mine = turn
        DispatchQueue.main.asyncAfter(deadline: .now() + waiting) { [weak self] in
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
            let shade = CALayer(), v = NSView()
            shade.backgroundColor = style.background
            shade.opacity = 0
            v.layer = shade  // layer-hosting: AppKit leaves its opacity alone
            v.wantsLayer = true
            w.contentView = v
            dims.append((w, shade))
        }
        for (dim, s) in zip(dims, screens) {
            dim.window.setFrame(s.frame, display: false)
            fade(dim.shade, from: dim.window.isVisible ? nil : 0, to: T.dim, over: d)  // off screen: from nothing
            dim.window.orderFrontRegardless()
        }
        for dim in dims.dropFirst(screens.count) { dim.window.orderOut(nil) }
    }

    /// The dim goes with the box: after `waiting`, fading over `fading`; at once without a fade.
    private func undim(waiting: Double, fading: Double) {
        guard fading > 0 else {
            for dim in dims { dim.window.orderOut(nil) }
            return
        }
        for dim in dims where dim.window.isVisible { fade(dim.shade, to: 0, after: waiting, over: fading) }
        let mine = turn
        DispatchQueue.main.asyncAfter(deadline: .now() + waiting + fading) { [weak self] in
            guard let self, self.turn == mine else { return }
            for dim in self.dims { dim.window.orderOut(nil) }
        }
    }

    /// A layer's opacity to `value` from `start` (nil: wherever it stands), after `delay`, over `d` on the curve (0: at
    /// once).
    private func fade(_ l: CALayer, from start: Float? = nil, to value: Float, after delay: Double = 0, over d: Double) {
        let from = start ?? l.presentation()?.opacity ?? l.opacity
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        l.opacity = value
        l.removeAnimation(forKey: "fade")
        if d > 0 {
            let a = CABasicAnimation(keyPath: "opacity")
            (a.fromValue, a.toValue, a.duration, a.timingFunction) = (from, value, d, quint)
            if delay > 0 {
                a.beginTime = l.convertTime(CACurrentMediaTime(), from: nil) + delay
                a.fillMode = .backwards
            }
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
