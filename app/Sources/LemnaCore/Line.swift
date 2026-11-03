// The line's geometry and drawing (DESIGN.md S1 V2 B4). Core Text shapes it and Core Graphics draws it into a bitmap,
// so the tests render exactly what the app's Metal strip shows.
import CoreGraphics
import CoreText
import Foundation

/// A shaped glyph: its font (a fallback one for characters Menlo lacks), id, x in the line, advance, whether it
/// belongs to a paragraph end or a line break (muted), whether it stands after the caret, and where it starts in the
/// line's string (UTF-16).
public struct Glyph {
    public let font: CTFont, id: CGGlyph, x: CGFloat, advance: CGFloat, muted: Bool, after: Bool, index: Int
}

/// The line laid out around the caret: `caret` is the caret's x in it, where the text before it ends and the text
/// after it begins, `split` the same place in the line's UTF-16 units. It rests with that x at the caret. `selected`:
/// the selection's part of it in the same units, ending or starting at `split` (empty: nothing selected).
public struct Shaped {
    public var glyphs: [Glyph] = [], width: CGFloat = 0, caret: CGFloat = 0, split = 0, selected = 0..<0
    public init() {}
}

/// The newest glyphs as the band draws them (F1: K1, E2; `Entrance` says when): the last `units` of the line's UTF-16
/// units before the caret, at `alpha` (times their V2 fade). The default draws them as the rest.
public struct Newest: Equatable {
    public var units = 0, alpha = 1.0
    public init(units: Int = 0, alpha: Double = 1) { (self.units, self.alpha) = (units, alpha) }
}

/// The colours and the font, in the box and in the window: a theme as it shows now (DESIGN.md TH1), its night palette
/// when `dark` (LK1: the system's appearance, unless the theme keeps one), with the muted grey and the accent of
/// Increase Contrast or not. `Style(font:)` is Lemna's, today's look (F1 T2). The app takes a new one as a container
/// comes on screen.
public struct Style {
    public var font: CTFont
    /// The box's surface, the text, the muted grey (the ` ¶ `, the ` ↵ `, the bottom edge) and the caret (the accent).
    public var background: CGColor, text: CGColor, muted: CGColor, caret: CGColor
    /// The box's edge: the accent (B1) or the theme's hairline.
    public var border: CGColor
    public let theme: Theme, dark: Bool, increasedContrast: Bool

    public init(_ theme: Theme = .lemna, dark: Bool = true, increasedContrast: Bool = false, font: CTFont) {
        (self.theme, self.dark, self.increasedContrast, self.font) = (theme, dark, increasedContrast, font)
        let p = dark ? theme.night : theme.day
        (background, text, muted, caret) = (rgb(p.surface), rgb(p.text), p.muted(increasedContrast: increasedContrast),
                                            p.accent(increasedContrast: increasedContrast))
        border = theme.box.border == .accent ? caret : rgb(p.line)
    }

    /// The palette that shows: the dim, its opacity, the ambience's ink.
    public var palette: Theme.Palette { dark ? theme.night : theme.day }
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
    /// A line break (⇧⏎, pass 29b; `Text.lineBreak`) as the line shows it: a muted return arrow, U+21B5, drawn as the
    /// ` ¶ ` is, its arrow in `markFont` and its two spaces in the line's face, so it takes a paragraph end's room.
    public static let lineBreak = " \u{21B5} "
    /// The selection's band (B4, pass 29): the accent at this alpha behind the selected glyphs. 0.3 reads on each
    /// theme's surface with the text over it: on Lemna's box #0e1013 the band is #2e3d55, 1.74:1 to the box and the
    /// text 8.0:1 on it; on Still's paper #c4cbb7, 1.47:1 (macOS's own light selection on white, 1.5:1) and the text
    /// 5.9:1; on Still's night #444a3b, 1.88:1 and the text 6.6:1.
    public static let selectionAlpha: CGFloat = 0.3
    /// Characters shaped on each side of the caret per edit, enough for the visible 35 % of a window 10,000 pt wide
    /// (before the caret 25 % to 60 %, after it 60 % to 95 %): 300 Menlo cells at 28 pt span about 5,100 pt; under a
    /// proportional face prose takes about 13 pt a character at 30 pt (Literata, Charter 31), so 300 span at least
    /// 3,900 pt where 200 spanned 2,600 (a window up to 7,500 pt).
    public static let tail = 300
    /// About one word, in cells: an English word averages about five letters, plus its space. Holding ← leaves the
    /// text at most this far behind the caret.
    public static let wordCells = 6
    static let mutedKey = NSAttributedString.Key("LemnaMuted"), afterKey = NSAttributedString.Key("LemnaAfter")

    /// A glyph's opacity by its x in a band `w` wide: 1 right of 45 %, 0 at 25 % and left of it, linear between.
    public static func fade(x: Double, width w: Double) -> Double {
        min(max((x - clearAt * w) / ((opaqueFrom - clearAt) * w), 0), 1)
    }

    /// The same for the text after the caret: 1 left of 80 %, 0 at 95 % and right of it, linear between.
    public static func fadeAfter(x: Double, width w: Double) -> Double {
        min(max((afterClearAt * w - x) / ((afterClearAt - afterOpaqueTo) * w), 0), 1)
    }

    /// `s` as the line shows it: each paragraph end a ` ¶ `, each line break a ` ↵ ` (an entrance's units).
    public static func shown(_ s: String) -> String { Text.runs(Substring(s), selected: false).map(\.text).joined() }

    /// The width of `s` alone as the line shows it (a paragraph end as ` ¶ ` and a line break as ` ↵ `, each mark in
    /// `markFont`): how far an edit that adds or removes `s` at the caret, or a caret move over it, moves the text.
    /// Measured on its own, not as the difference of two shaped lines, because their start moves with every key.
    public static func width(_ s: String, font: CTFont) -> CGFloat {
        guard !s.isEmpty else { return 0 }
        let shown = NSMutableAttributedString()
        let mark = s.contains(where: { $0 == "\n" || $0 == Text.lineBreak }) ? markFont(for: font) : font
        for part in Text.runs(Substring(s), selected: false) {
            shown.append(attributed(part.text, font, muted: part.muted, mark: mark))
        }
        return CTLineGetTypographicBounds(CTLineCreateWithAttributedString(shown), nil, nil, nil)
    }

    /// The face of the ` ¶ `'s pilcrow (pass 29; the user, 2026-11-03: "the newline character, which is rendered,
    /// looks weird when having a serif font. I like the non-serif newline character much better.") and of the ` ↵ `'s
    /// arrow (pass 29b): the line's own when it is monospaced (Lemna's Menlo), else Menlo at its size, as Code's atlas
    /// takes it (`Ambience.Glyphs.atlasFont`). Their two spaces stay in the line's face, so a mark keeps its room.
    public static func markFont(for font: CTFont) -> CTFont { Ambience.Glyphs.atlasFont(for: font) }

    /// Shapes the line around the caret: the text before it with its paragraph ends and line breaks, then the marked
    /// text (a pending dead key, at the caret, in the text colour), then the text after it; once per edit, as one line,
    /// so the two parts meet where Core Text puts the caret. The text after it is a run of its own, so no ligature
    /// (Literata's fi, ff, ft, Th) spans the caret, which would draw both letters on one side of it. The selection is
    /// no attribute (which would split a run at the anchor and move the kerning there), only a range of the line's
    /// units.
    public static func shape(_ text: Text, marked: String, font: CTFont) -> Shaped {
        let (before, after) = text.line(around: tail)
        let s = NSMutableAttributedString(), mark = markFont(for: font)
        var selected: Range<Int>?
        func add(_ part: Text.Run) {
            let start = s.length
            s.append(attributed(part.text, font, muted: part.muted, mark: mark))
            if part.selected { selected = (selected?.lowerBound ?? start)..<s.length }
        }
        for part in before + [(text: marked, muted: false, selected: false)] where !part.text.isEmpty { add(part) }
        let split = s.length  // the caret, in the line's UTF-16 units
        for part in after { add(part) }
        s.addAttribute(afterKey, value: true, range: NSRange(location: split, length: s.length - split))
        let line = CTLineCreateWithAttributedString(s)
        var out = Shaped()
        out.width = CTLineGetTypographicBounds(line, nil, nil, nil)
        out.caret = CTLineGetOffsetForStringIndex(line, split, nil)
        out.split = split
        out.selected = selected ?? split..<split
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
                                        after: at[i] >= split, index: at[i]))
            }
        }
        return out
    }

    /// `s` in `font`; a paragraph end's or a line break's (`muted`) with its mark, the one Character in it that is no
    /// space (the pilcrow, the arrow), in `mark` (`markFont`).
    static func attributed(_ s: String, _ font: CTFont, muted: Bool, mark: CTFont) -> NSAttributedString {
        let face = NSAttributedString.Key(kCTFontAttributeName as String)
        var a: [NSAttributedString.Key: Any] = [face: font]
        if muted { a[mutedKey] = true }
        let out = NSMutableAttributedString(string: s, attributes: a)
        let sign = (s as NSString).rangeOfCharacter(from: CharacterSet(charactersIn: " ").inverted)
        if muted, sign.location != NSNotFound { out.addAttribute(face, value: mark, range: sign) }
        return out
    }

    /// The band the line lives in: two em tall (room for descenders and the caret) across the width, on the middle of
    /// `size`, on whole points.
    public static func band(in size: CGSize, style: Style) -> CGRect {
        let h = 2 * style.size
        return CGRect(x: 0, y: ((size.height - h) / 2).rounded(.down), width: size.width, height: h)
    }

    /// The caret: a 2 pt bar 1.2 em tall at 60 % of the band's width, on its middle; its ends rounded by the theme's
    /// `caretEnds` (`draw`).
    public static func caretRect(in band: CGRect, style: Style) -> CGRect {
        CGRect(x: band.minX + caret * band.width, y: band.midY - 0.6 * style.size, width: 2, height: 1.2 * style.size)
    }

    /// Draws the band: its background; the text before the caret, its end at the caret's left edge moved by `before`,
    /// each glyph faded by its centre's x (V2) and clipped at the caret; the text after the caret, its start at the
    /// caret's right edge moved by `after`, faded the other way and clipped at the caret and at 95 % (B4); the caret on
    /// top. So no glyph ever overlaps the caret: nothing before it is drawn right of it (S1; a new glyph emerges from
    /// under it as that part glides, a deleted one is gone at once), nothing after it left of it, and a caret move
    /// passes the text under it. `before` is the edit's glide and the caret move's together, `after` the move's alone.
    /// `newest`: the glyphs a key just added, fading in (F1: K1, E2), in the same pass, one more factor on each glyph's
    /// alpha. The selection (pass 29) is a band behind its glyphs in the caret's colour at `selectionAlpha`, the
    /// caret's height, in its part's clip, fading as that part's glyphs do, so it never crosses the caret either.
    public static func draw(_ line: Shaped, before: CGFloat, after: CGFloat, newest: Newest = Newest(), in c: CGContext,
                            band: CGRect, style: Style) {
        let bar = caretRect(in: band, style: style), w = Double(band.width)
        let baseline = band.midY - (CTFontGetAscent(style.font) - CTFontGetDescent(style.font)) / 2  // centres the glyphs
        c.saveGState()
        if !style.theme.type.smoothed { c.setShouldSmoothFonts(false) }  // Still: the mockup's weight
        c.setFillColor(style.background)
        c.fill(band)
        func part(_ isAfter: Bool, from x0: CGFloat, clip: CGRect, alpha: (Double) -> Double) {
            c.saveGState()
            c.clip(to: clip)
            var (lo, hi) = (CGFloat.infinity, -CGFloat.infinity)  // the selected glyphs' span in this part
            for g in line.glyphs where g.after == isAfter && line.selected.contains(g.index) {
                (lo, hi) = (min(lo, g.x), max(hi, g.x + g.advance))
            }
            if lo < hi {
                c.saveGState()
                c.clip(to: CGRect(x: x0 + lo, y: bar.minY, width: hi - lo, height: bar.height))
                let colours = [style.caret.copy(alpha: selectionAlpha)!, style.caret.copy(alpha: 0)!] as CFArray
                let ramp = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colours,
                                      locations: [0, 1])!
                let (full, clear) = isAfter ? (afterOpaqueTo, afterClearAt) : (opaqueFrom, clearAt)  // V2, B4's fades
                c.drawLinearGradient(ramp, start: CGPoint(x: band.minX + full * band.width, y: 0),
                                     end: CGPoint(x: band.minX + clear * band.width, y: 0),
                                     options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                c.restoreGState()
            }
            let first = isAfter || newest.units == 0 ? Int.max : line.split - newest.units  // the newest glyphs' start
            for g in line.glyphs where g.after == isAfter {
                let x = x0 + g.x, new = g.index >= first
                let a = alpha(Double(x + g.advance / 2 - band.minX)) * (new ? newest.alpha : 1)
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
        let ends = style.theme.box.caretEnds  // Still's rounded ends (look §2.6); Lemna's square
        if ends > 0 {
            c.addPath(CGPath(roundedRect: bar, cornerWidth: ends, cornerHeight: ends, transform: nil))
            c.fillPath()
        } else {
            c.fill(bar)
        }
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
