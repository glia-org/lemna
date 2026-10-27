// The glide (DESIGN.md S1): one offset for the whole line, so nothing on screen jumps when a key lands mid-glide.

/// The line's x offset from its resting place (its end at the caret): starts at the edit's width and eases to 0.
public struct Glide {
    public var from = 0.0, start = 0.0
    public init() {}

    public func offset(at t: Double) -> Double { from * (1 - Line.ease((t - start) / Line.glideDuration)) }
    public func active(at t: Double) -> Bool { from != 0 && t < start + Line.glideDuration }

    /// The line's end moved left by `dw` (an append; negative for a deletion, which glides back). The glide restarts
    /// from the offset still remaining plus `dw`, so nothing jumps; a remainder in the same direction is capped at one
    /// such step, so the line never trails more than one keystroke. Reduce Motion jumps.
    public mutating func add(_ dw: Double, at t: Double, reduceMotion: Bool) {
        guard dw != 0 else { return }
        if reduceMotion {
            from = 0
            return
        }
        var r = offset(at: t)
        if r * dw > 0 { r = dw > 0 ? min(r, dw) : max(r, dw) }
        from = r + dw
        start = t
    }
}
