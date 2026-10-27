// The line's geometry and drawing (DESIGN.md S1 V2 B4). Core Text shapes it and Core Graphics draws it into a bitmap,
// so the tests render exactly what the app's Metal strip shows.
import CoreGraphics
import CoreText
import Foundation

/// A shaped glyph: its font (a fallback one for characters Menlo lacks), id, x in the line, advance, whether it
/// belongs to a paragraph end, and whether it stands after the caret.
public struct Glyph {
    public let font: CTFont, id: CGGlyph, x: CGFloat, advance: CGFloat, muted: Bool, after: Bool
}

/// The line laid out around the caret: `caret` is the caret's x in it, where the text before it ends and the text
/// after it begins. It rests with that x at the caret.
public struct Shaped {
    public var glyphs: [Glyph] = [], width: CGFloat = 0, caret: CGFloat = 0
    public init() {}
}

public struct Style {
    public var font: CTFont
    public var background = rgb(0x0e1013), text = rgb(0xd8dce3), muted = rgb(0x5c646f), caret = rgb(0x7aa7f0)
    public init(font: CTFont) { self.font = font }
    public var size: CGFloat { CTFontGetSize(font) }
}

/// An sRGB colour from 0xRRGGBB.
public func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 255) / 255, green: CGFloat(hex >> 8 & 255) / 255, blue: CGFloat(hex & 255) / 255,
            alpha: 1)
}

public enum Line {
    public static let glideDuration = 0.140
    /// The caret's x, and where the fade of the text before it (V2) reaches full strength and nothing, as fractions
    /// of the width.
    public static let caret: CGFloat = 0.6, opaqueFrom = 0.45, clearAt = 0.25
    /// The text after the caret (B4): full strength up to 80 % of the width, nothing from 95 % on.
    public static let afterOpaqueTo: CGFloat = 0.8, afterClearAt: CGFloat = 0.95
    public static let paragraphEnd = " ¶ "
    /// Characters shaped on each side of the caret per edit: 200 Menlo cells at 28 pt span about 3,400 pt, the
    /// visible 35 % of a window over 9,000 pt wide (before the caret 25 % to 60 %, after it 60 % to 95 %).
    public static let tail = 200
    /// About one word, in cells: an English word averages about five letters, plus its space. Holding ← leaves the
    /// text at most this far behind the caret.
    public static let wordCells = 6
    static let mutedKey = NSAttributedString.Key("FlowMuted")

    /// Ease-out cubic, 1 − (1 − u)³, with u clamped to 0…1.
    public static func ease(_ u: Double) -> Double {
        let v = 1 - min(max(u, 0), 1)
        return 1 - v * v * v
    }

    /// A glyph's opacity by its x in a band `w` wide: 1 right of 45 %, 0 at 25 % and left of it, linear between.
    public static func fade(x: Double, width w: Double) -> Double {
        min(max((x - clearAt * w) / ((opaqueFrom - clearAt) * w), 0), 1)
    }

    /// The same for the text after the caret: 1 left of 80 %, 0 at 95 % and right of it, linear between.
    public static func fadeAfter(x: Double, width w: Double) -> Double {
        min(max((afterClearAt * w - x) / ((afterClearAt - afterOpaqueTo) * w), 0), 1)
    }

    /// The width of `s` alone as the line shows it (a paragraph end as ` ¶ `): how far an edit that adds or removes
    /// `s` at the caret, or a caret move over it, moves the text. Measured on its own, not as the difference of two
    /// shaped lines, because their start moves with every key.
    public static func width(_ s: String, font: CTFont) -> CGFloat {
        let shown = s.replacingOccurrences(of: "\n", with: paragraphEnd)
        return shown.isEmpty ? 0 : CTLineGetTypographicBounds(
            CTLineCreateWithAttributedString(attributed(shown, font, muted: false)), nil, nil, nil)
    }

    /// Shapes the line around the caret: the text before it with its paragraph ends, then the marked text (a pending
    /// dead key, at the caret, in the text colour), then the text after it; once per edit, as one line, so the two
    /// parts meet where Core Text puts the caret.
    public static func shape(_ text: Text, marked: String, font: CTFont) -> Shaped {
        let (before, after) = text.line(around: tail)
        let s = NSMutableAttributedString()
        for part in before + [(text: marked, muted: false)] where !part.text.isEmpty {
            s.append(attributed(part.text, font, muted: part.muted))
        }
        let split = s.length  // the caret, in the line's UTF-16 units
        for part in after { s.append(attributed(part.text, font, muted: part.muted)) }
        let line = CTLineCreateWithAttributedString(s)
        var out = Shaped()
        out.width = CTLineGetTypographicBounds(line, nil, nil, nil)
        out.caret = CTLineGetOffsetForStringIndex(line, split, nil)
        for run in CTLineGetGlyphRuns(line) as! [CTRun] {
            let attributes = CTRunGetAttributes(run) as NSDictionary, n = CTRunGetGlyphCount(run)
            let runFont = attributes[kCTFontAttributeName as String] as! CTFont, muted = attributes[mutedKey.rawValue] != nil
            var ids = [CGGlyph](repeating: 0, count: n), pos = [CGPoint](repeating: .zero, count: n)
            var adv = [CGSize](repeating: .zero, count: n), at = [CFIndex](repeating: 0, count: n)
            CTRunGetGlyphs(run, CFRange(), &ids)
            CTRunGetPositions(run, CFRange(), &pos)
            CTRunGetAdvances(run, CFRange(), &adv)
            CTRunGetStringIndices(run, CFRange(), &at)
            for i in 0..<n {
                out.glyphs.append(Glyph(font: runFont, id: ids[i], x: pos[i].x, advance: adv[i].width, muted: muted,
                                        after: at[i] >= split))
            }
        }
        return out
    }

    static func attributed(_ s: String, _ font: CTFont, muted: Bool) -> NSAttributedString {
        var a: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): font]
        if muted { a[mutedKey] = true }
        return NSAttributedString(string: s, attributes: a)
    }

    /// The band the line lives in: two em tall (room for descenders and the caret) across the width, on the middle of
    /// `size`, on whole points.
    public static func band(in size: CGSize, style: Style) -> CGRect {
        let h = 2 * style.size
        return CGRect(x: 0, y: ((size.height - h) / 2).rounded(.down), width: size.width, height: h)
    }

    /// The caret: a 2 pt bar 1.2 em tall at 60 % of the band's width, on its middle.
    public static func caretRect(in band: CGRect, style: Style) -> CGRect {
        CGRect(x: band.minX + caret * band.width, y: band.midY - 0.6 * style.size, width: 2, height: 1.2 * style.size)
    }

    /// Draws the band: its background; the text before the caret, its end at the caret's left edge moved by `before`,
    /// each glyph faded by its centre's x (V2) and clipped at the caret; the text after the caret, its start at the
    /// caret's right edge moved by `after`, faded the other way and clipped at the caret and at 95 % (B4); the caret on
    /// top. So no glyph ever overlaps the caret: nothing before it is drawn right of it (S1; a new glyph emerges from
    /// under it as that part glides, a deleted one is gone at once), nothing after it left of it, and a caret move
    /// passes the text under it. `before` is the edit's glide and the caret move's together, `after` the move's alone.
    public static func draw(_ line: Shaped, before: CGFloat, after: CGFloat, in c: CGContext, band: CGRect,
                            style: Style) {
        let bar = caretRect(in: band, style: style), w = Double(band.width)
        let baseline = band.midY - (CTFontGetAscent(style.font) - CTFontGetDescent(style.font)) / 2  // centres the glyphs
        c.saveGState()
        c.setFillColor(style.background)
        c.fill(band)
        func part(_ isAfter: Bool, from x0: CGFloat, clip: CGRect, alpha: (Double) -> Double) {
            c.saveGState()
            c.clip(to: clip)
            for g in line.glyphs where g.after == isAfter {
                let x = x0 + g.x, a = alpha(Double(x + g.advance / 2 - band.minX))
                guard a > 0, x < clip.maxX, x + g.advance > clip.minX else { continue }
                c.setAlpha(CGFloat(a))
                c.setFillColor(g.muted ? style.muted : style.text)
                var id = g.id, p = CGPoint(x: x, y: baseline)
                CTFontDrawGlyphs(g.font, &id, &p, 1, c)
            }
            c.restoreGState()
        }
        part(false, from: bar.minX - line.caret + before,
             clip: CGRect(x: band.minX, y: band.minY, width: bar.minX - band.minX, height: band.height)) {
            fade(x: $0, width: w)
        }
        part(true, from: bar.maxX - line.caret + after,
             clip: CGRect(x: bar.maxX, y: band.minY, width: band.minX + afterClearAt * band.width - bar.maxX,
                          height: band.height)) {
            fadeAfter(x: $0, width: w)
        }
        c.restoreGState()
        c.setFillColor(style.caret)
        c.fill(bar)
    }

    /// A bitmap context laid out as Metal's `.bgra8Unorm` (BGRA in memory, premultiplied, sRGB), in points scaled by
    /// `scale`, with glyphs on subpixel positions so the glide moves them smoothly. `data` nil: Core Graphics owns it.
    public static func context(width: Int, height: Int, rowBytes: Int, scale: CGFloat,
                               data: UnsafeMutableRawPointer?) -> CGContext {
        let c = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: rowBytes,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                          bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
        c.scaleBy(x: scale, y: scale)
        c.setAllowsFontSubpixelPositioning(true)
        c.setShouldSubpixelPositionFonts(true)
        c.setAllowsFontSubpixelQuantization(false)
        c.setShouldSubpixelQuantizeFonts(false)
        return c
    }
}
