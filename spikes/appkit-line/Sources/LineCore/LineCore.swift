// The sliding line's rules, free of AppKit so `swift test` can check them without a window.
import CoreGraphics
import CoreText

/// A shaped glyph: its font, id, x in the line and advance.
public struct Glyph {
    public let font: CTFont, id: CGGlyph, x: CGFloat, advance: CGFloat
    public init(font: CTFont, id: CGGlyph, x: CGFloat, advance: CGFloat) {
        (self.font, self.id, self.x, self.advance) = (font, id, x, advance)
    }
}

public enum Line {
    public static let glideDuration = 0.140

    /// Ease-out cubic, 1 − (1 − u)³, with u clamped to 0…1.
    public static func ease(_ u: Double) -> Double {
        let v = 1 - min(max(u, 0), 1)
        return 1 - v * v * v
    }

    /// A glyph's opacity by its x in a window `w` wide: 1 right of 45 %, 0 at 25 % and left of it, linear between.
    public static func fade(x: Double, width w: Double) -> Double {
        min(max((x - 0.25 * w) / (0.20 * w), 0), 1)
    }

    /// Backspace within the current word only: the text without its last character, or nil when there is
    /// nothing to delete (empty, or the text ends in the space that starts the current word).
    public static func backspace(_ s: String) -> String? {
        guard let last = s.last, last != " " else { return nil }
        return String(s.dropLast())
    }

    /// Return: a space followed by ¶, so paragraphs stay visible in the one line.
    public static func newline(_ s: String) -> String { s + " ¶" }

    /// Draws the glyphs in the context's fill colour, the line starting at `x0`, each faded by its centre x in a
    /// strip `w` wide, clipped at `caretX`: nothing is drawn right of the caret (DESIGN.md S1), so a new glyph
    /// emerges from under the caret as the line glides.
    public static func draw(_ glyphs: [Glyph], in c: CGContext, x0: CGFloat, baseline: CGFloat, caretX: CGFloat,
                            width w: CGFloat) {
        c.saveGState()
        let all = c.boundingBoxOfClipPath
        c.clip(to: CGRect(x: all.minX, y: all.minY, width: caretX - all.minX, height: all.height))
        for g in glyphs {
            let x = x0 + g.x, a = fade(x: Double(x + g.advance / 2), width: Double(w))
            guard a > 0, x < w else { continue }  // nothing left of 25 %
            c.setAlpha(CGFloat(a))
            var id = g.id, p = CGPoint(x: x, y: baseline)
            CTFontDrawGlyphs(g.font, &id, &p, 1, c)
        }
        c.restoreGState()
    }

    /// Nearest-rank percentile (p in 0…1); NaN for an empty sample.
    public static func percentile(_ xs: [Double], _ p: Double) -> Double {
        guard !xs.isEmpty else { return .nan }
        let s = xs.sorted()
        return s[min(max(Int((p * Double(s.count)).rounded(.up)) - 1, 0), s.count - 1)]
    }
}

/// The line's x offset from its resting place (end at the caret): starts at +advance and eases to 0 in 140 ms.
public struct Glide {
    public var from = 0.0, start = 0.0
    public init() {}

    public func offset(at t: Double) -> Double { from * (1 - Line.ease((t - start) / Line.glideDuration)) }
    public func active(at t: Double) -> Bool { from != 0 && t < start + Line.glideDuration }

    /// The line's end moved left by `dw` (an append; negative for a deletion). The glide restarts from the
    /// offset still remaining plus `dw`, so nothing on screen jumps; a remainder in the same direction is capped
    /// at one such step, so the line never trails more than one keystroke. Reduce Motion jumps.
    public mutating func add(_ dw: Double, at t: Double, reduceMotion: Bool) {
        guard dw != 0 else { return }
        if reduceMotion { from = 0; return }
        var r = offset(at: t)
        if r * dw > 0 { r = dw > 0 ? min(r, dw) : max(r, dw) }
        from = r + dw
        start = t
    }
}
