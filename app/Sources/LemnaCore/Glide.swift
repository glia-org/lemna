// The glide (DESIGN.md S1 B4): an offset for a part of the line (the text before the caret, or the whole text on a
// caret move), so nothing on screen jumps when a key lands mid-glide; and the newest glyphs' entrance (F1: K1, E2), a
// fade. Both run on Omarchy's one curve, easeOutQuint (F1: G1).

/// easeOutQuint, cubic-bezier(0.23, 1, 0.32, 1): Omarchy's curve for every animation since 2026-10-28, and Lemna's
/// (F1). Over the glide's 140 ms it covers 25, 46 and 63 % in the first three 120 Hz frames and 90 % at 51 ms (the
/// ease-out cubic before it: 17, 32, 45 % and 75 ms). The box's open and close take the same control points as a
/// CAMediaTimingFunction.
public enum Curve {
    public static let controlPoints: (x1: Double, y1: Double, x2: Double, y2: Double) = (0.23, 1, 0.32, 1)

    /// The progress at `u` of the time, u clamped to 0…1: the bezier's x solved for u (Newton's method, bisection where
    /// it does not settle), its y there. A few multiplications; called once per part per frame.
    public static func easeOutQuint(_ u: Double) -> Double {
        if u <= 0 { return 0 }
        if u >= 1 { return 1 }
        let (x1, y1, x2, y2) = controlPoints
        let cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx
        let cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by
        func x(_ t: Double) -> Double { ((ax * t + bx) * t + cx) * t }
        func y(_ t: Double) -> Double { ((ay * t + by) * t + cy) * t }
        var t = u
        for _ in 0..<8 {
            let e = x(t) - u, slope = (3 * ax * t + 2 * bx) * t + cx
            if abs(e) < 1e-9 { return y(t) }
            if abs(slope) < 1e-6 { break }
            t -= e / slope
        }
        var (lo, hi) = (0.0, 1.0)
        t = u
        for _ in 0..<60 {
            let v = x(t)
            if abs(v - u) < 1e-9 { break }
            if v < u { lo = t } else { hi = t }
            t = (lo + hi) / 2
        }
        return y(t)
    }
}

/// A part's x offset from its resting place: starts at the step's width and eases to 0.
public struct Glide {
    public var from = 0.0, start = 0.0
    public init() {}

    public func offset(at t: Double) -> Double { from * (1 - Curve.easeOutQuint((t - start) / Line.glideDuration)) }
    public func active(at t: Double) -> Bool { from != 0 && t < start + Line.glideDuration }

    /// The text moved left by `dw` (an insertion, a step right; negative for a deletion or a step left, which glide
    /// back). The glide restarts from the offset still remaining plus `dw`, so nothing jumps; a remainder in the same
    /// direction is capped at `cap` (one such step unless given), so the text never trails more than that; and it
    /// never starts further than `limit` from rest (a caret move to a far paragraph end would otherwise start where
    /// nothing is shaped). Reduce Motion jumps.
    public mutating func add(_ dw: Double, at t: Double, reduceMotion: Bool, cap: Double? = nil,
                             limit: Double = .infinity) {
        guard dw != 0 else { return }
        if reduceMotion {
            from = 0
            return
        }
        var r = offset(at: t)
        let c = cap ?? abs(dw)
        if r * dw > 0 { r = dw > 0 ? min(r, c) : max(r, -c) }
        from = min(max(r + dw, -limit), limit)
        start = t
    }
}

/// The newest glyphs' entrance (F1): what a key just added before the caret, the last `units` of the line's UTF-16
/// units before it, fades in from nothing on the curve, opacity alone: a typed glyph over `Tuning.glyphFade` (K1,
/// `glyph`; until pass 18 it also grew and rose), a Return's ` ¶ ` over `Tuning.paragraphFade` (E2, `paragraph`). One at
/// a time: the next key's entrance takes its place and the glyph before it is drawn whole; a delete, a caret move or a
/// dead key's pending mark ends it. It changes how the band draws in frames the glide draws anyway.
public struct Entrance: Equatable {
    public var units = 0, start = 0.0, duration = 0.0
    public init() {}
    init(units: Int, start: Double, duration: Double) {
        (self.units, self.start, self.duration) = (units, start, duration)
    }

    /// K1: a typed glyph, over `Tuning.glyphFade`.
    public static func glyph(units: Int, at t: Double) -> Entrance {
        Entrance(units: units, start: t, duration: Effects.Tuning.glyphFade)
    }

    /// E2: a Return's ` ¶ `, fading in alone over `Tuning.paragraphFade`.
    public static func paragraph(units: Int, at t: Double) -> Entrance {
        Entrance(units: units, start: t, duration: Effects.Tuning.paragraphFade)
    }

    public func active(at t: Double) -> Bool { units > 0 && t < start + duration }

    /// The newest glyphs as the band draws them at `t`; at rest, or once it is over, as the rest of the line.
    public func newest(at t: Double) -> Newest {
        guard active(at: t) else { return Newest() }
        return Newest(units: units, alpha: Curve.easeOutQuint((t - start) / duration))
    }
}
