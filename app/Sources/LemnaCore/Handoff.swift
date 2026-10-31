// The hand-off's motion (DESIGN.md F1's H1 and C1, pass 17b; the user, 2026-10-29: "Right now the animation that is
// used is really lackluster and not well done. This can be improved a lot."; the picks H1 A0 T1 C1 of
// docs/design-panel-lemna-handoff.html, H1 on easeOutQuint): from the key-down on, the line's glyphs leave the box one
// after another from the caret outwards, off its right edge at a paste or up off its top edge at a copy or a save; the
// dim lifts from the first frame and the emptied box collapses, 260 ms in all. Since pass 24, under a theme whose
// hand-off is the box's fade (Still, MO1 of docs/design-panel-lemna-themes.html), a paste sends one ring of two crests
// from the box's outline out across the wash instead, while the box fades and the wash lifts with the ring. Where each
// glyph and each line of the ring is and when, as pure functions: the app's Core Animation layers and the tests'
// renders take their places and times from here. Free of AppKit.
import CoreGraphics
import CoreText

public enum Handoff {
    private typealias T = Effects.Tuning

    /// Where the text goes: off the box's right edge into the app behind (a paste, H1), or up off its top edge (C1: a
    /// copy or a save, and a ⌘⏎ that copied instead, whose box stays).
    public enum Way: Equatable { case send, rise }

    /// One glyph of the band's last frame, cut out to leave on its own: `rect` its cell in the band's points (origin at
    /// the bottom left), on whole pixels at the scale it was cut at, as wide as the glyph's advance where the band showed
    /// it (clipped at the caret, at the band's edge, at 95 % after the caret) and as tall as the font's ascent and
    /// descent and a little; `rank` how many glyphs stand between it and the caret on its side; `after` whether it
    /// stands after the caret (B4).
    public struct Piece: Equatable {
        public var rect: CGRect, rank: Int, after: Bool
        public init(rect: CGRect, rank: Int, after: Bool) { (self.rect, self.rank, self.after) = (rect, rank, after) }

        /// Its cell in the band's bitmap at `scale`: pixels, origin at the top left (CGImage's `cropping(to:)`).
        public func pixels(bandHeight: CGFloat, scale: CGFloat) -> CGRect {
            CGRect(x: (rect.minX * scale).rounded(), y: ((bandHeight - rect.maxY) * scale).rounded(),
                   width: (rect.width * scale).rounded(), height: (rect.height * scale).rounded())
        }

        /// When it sets off, in seconds after the key: the glyph at the caret at once, each further one
        /// `Tuning.exitStagger` after its neighbour nearer the caret, and those past `exitStaggerCap` all with the last
        /// (the faded rest goes with it, so a line of any length has left by the same time). Sent right, the text after
        /// the caret sets off at once, with the glyph at the caret: it is ahead of it, and a later start would let the
        /// glyphs behind run into it. Rising, both sides go from the caret outwards.
        public func start(_ way: Way) -> Double {
            way == .send && after ? 0 : min(Double(rank) * T.exitStagger, T.exitStaggerCap)
        }
    }

    /// The glyphs as `Line.draw` showed them (`before` and `after` its offsets), one piece each that the band drew with
    /// some alpha: what lies in its fades' clear ends is left out, as nothing of it shows.
    public static func pieces(_ line: Shaped, before: CGFloat, after: CGFloat, band: CGRect, style: Style,
                              scale: CGFloat) -> [Piece] {
        let bar = Line.caretRect(in: band, style: style), w = Double(band.width)
        let ascent = CTFontGetAscent(style.font), descent = CTFontGetDescent(style.font), pad = 0.1 * style.size
        let baseline = band.midY - (ascent - descent) / 2  // as `Line.draw` centres the glyphs
        func snap(_ v: CGFloat) -> CGFloat { (v * scale).rounded() / scale }
        let bottom = snap(max(baseline - descent - pad, band.minY)), top = snap(min(baseline + ascent + pad, band.maxY))
        var out: [Piece] = []
        for isAfter in [false, true] {
            let x0 = isAfter ? bar.maxX - line.caret + after : bar.minX - line.caret + before
            let clip = isAfter ? (lo: bar.maxX, hi: band.minX + Line.afterClearAt * band.width) : (lo: band.minX, hi: bar.minX)
            let glyphs = line.glyphs.filter { $0.after == isAfter }  // left to right
            for (i, g) in glyphs.enumerated() {
                let x = x0 + g.x, mid = Double(x + g.advance / 2 - band.minX)
                let a = isAfter ? Line.fadeAfter(x: mid, width: w) : Line.fade(x: mid, width: w)
                guard a > 0, x < clip.hi, x + g.advance > clip.lo else { continue }
                let l = snap(max(x, clip.lo)), r = snap(min(x + g.advance, clip.hi))
                guard r > l else { continue }  // a mark of no width: its ink is in its base's cell
                out.append(Piece(rect: CGRect(x: l, y: bottom, width: r - l, height: top - bottom),
                                 rank: isAfter ? i : glyphs.count - 1 - i, after: isAfter))
            }
        }
        return out
    }

    /// How far every piece travels, the same for all so none runs into another: `Tuning.sendReach` of the box's width
    /// to the right, `riseReach` of its height upward. Aimed well past the edge: a glyph crosses it at speed and slows
    /// only once it is clipped.
    public static func reach(_ way: Way, box: CGSize) -> CGFloat {
        way == .send ? T.sendReach * box.width : T.riseReach * box.height
    }

    /// A piece's offset along its way `t` seconds after the key: none until it sets off, then `reach` on the curve
    /// over `Tuning.exit`. easeOutQuint, not ease-in: an exit starts fast, where the eye is (the panel's "H1 on quint").
    public static func offset(_ piece: Piece, _ way: Way, reach: CGFloat, at t: Double) -> CGFloat {
        reach * CGFloat(Curve.easeOutQuint((t - piece.start(way)) / T.exit))
    }

    /// The box `t` seconds after the key: from `Tuning.collapseAt` it shrinks about its middle to `collapseScale` and
    /// fades out over `collapse`, on the curve.
    public static func box(at t: Double) -> (scale: Double, alpha: Double) {
        let e = Curve.easeOutQuint((t - T.collapseAt) / T.collapse)
        return (1 - (1 - T.collapseScale) * e, 1 - e)
    }

    /// The dim's share of its strength `t` seconds after the key: it lifts from the key on, over `Tuning.lift`.
    public static func dim(at t: Double) -> Double { 1 - Curve.easeOutQuint(t / T.lift) }

    /// Seconds from the key to the motion's end, the box gone: 260 ms (280 until pass 18).
    public static var end: Double { T.collapseAt + T.collapse }

    /// How a box goes at a hand-off.
    public enum Leaving: Equatable {
        /// This motion (Effects ▸ Hand-off).
        case motion
        /// P1's close, as Esc's, over the duration given (Hand-off unticked, Pop ticked; or Hand-off ticked under a
        /// theme whose hand-off is the box's fade, Still's MO1).
        case fade(Double)
        /// At once: Reduce Motion (it stops both), Effects ▸ Off, or neither ticked.
        case atOnce
    }

    /// `handOff`: the theme's (`Theme.Motion`); a fade there plays as P1's close, on Effects ▸ Hand-off's tick.
    public static func leaving(_ effects: Effects, reduceMotion: Bool,
                               handOff: Theme.Motion.HandOff = .stream) -> Leaving {
        if effects.plays(.handOff, reduceMotion: reduceMotion) { return handOff == .stream ? .motion : .fade(T.close) }
        let close = effects.duration(.pop, T.close, reduceMotion: reduceMotion)
        return close > 0 ? .fade(close) : .atOnce
    }

    // MARK: MO1's ring (pass 24)

    /// Whether a hand-off sends MO1's ring across the wash, beside the box's fade: a paste, under a theme whose hand-off
    /// is the box's fade, on Effects ▸ Hand-off's tick. Copy and Save… keep the plain fade (`.rise`); Reduce Motion stops
    /// the hand-off, ring and all (the box then goes as `leaving` says: at once), and so does Effects ▸ Off.
    public static func rings(_ way: Way, _ effects: Effects, reduceMotion: Bool,
                             handOff: Theme.Motion.HandOff) -> Bool {
        way == .send && handOff == .fade && effects.plays(.handOff, reduceMotion: reduceMotion)
    }

    /// One line of the ring, a crest or the trough inside it: it leaves the box's outline `start` seconds after the key
    /// and runs out at `Tuning.ringSpeed`; `share`, its alpha's share of the ring's.
    public struct RingLine: Equatable {
        public let start: Double, share: Double

        /// How far outside the box's outline it is `t` seconds after the key (not yet out: 0 or less).
        public func offset(at t: Double) -> CGFloat { T.ringSpeed * CGFloat(t - start) }
    }

    /// The ring's lines, the first crest first: each crest `Tuning.ringSpacing` behind the one before, each trough
    /// `ringTrough` inside its crest at `ringTroughShare` of the alpha.
    public static let ring: [RingLine] = (0..<T.ringCrests).flatMap { k -> [RingLine] in
        let start = Double(CGFloat(k) * T.ringSpacing / T.ringSpeed)
        return [RingLine(start: start, share: 1),
                RingLine(start: start + Double(T.ringTrough / T.ringSpeed), share: T.ringTroughShare)]
    }

    /// The ring's alpha `t` seconds after the key, by night or by day (`Tuning.ringPeak`): up over `ringOnset` on the
    /// curve, down as (1 − t / `ringLife`)^1.5, nothing from `ringLife` on.
    public static func ringAlpha(at t: Double, dark: Bool) -> Double {
        guard t < T.ringLife else { return 0 }
        let peak = dark ? T.ringPeak.night : T.ringPeak.day
        return peak * Curve.easeOutQuint(t / T.ringOnset) * pow(1 - max(t, 0) / T.ringLife, 1.5)
    }

    /// A line `d` points out from the box's outline (`box`, its corners `corner`), as a stroke `width` wide centred on
    /// it: the rectangle the stroke's outer edge follows and its corners (a layer's bounds and radius for its border).
    public static func ringOutline(_ box: CGRect, corner: CGFloat, offset d: CGFloat,
                                   width: CGFloat) -> (rect: CGRect, corner: CGFloat) {
        let grow = d + width / 2
        return (box.insetBy(dx: -grow, dy: -grow), corner + grow)
    }

    /// The dim's share of its strength `t` seconds after the key under the ring: it lifts evenly over `ringLife`.
    public static func washUnderRing(at t: Double) -> Double { min(max(1 - t / T.ringLife, 0), 1) }
}
