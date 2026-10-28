// The glide (DESIGN.md S1 B4): an offset for a part of the line (the text before the caret, or the whole text on a
// caret move), so nothing on screen jumps when a key lands mid-glide.

/// A part's x offset from its resting place: starts at the step's width and eases to 0.
public struct Glide {
    public var from = 0.0, start = 0.0
    public init() {}

    public func offset(at t: Double) -> Double { from * (1 - Line.ease((t - start) / Line.glideDuration)) }
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
