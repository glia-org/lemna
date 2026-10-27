import CoreGraphics
import CoreText
import Testing
@testable import LineCore

@Test func easeOutCubic() {
    #expect(Line.ease(0) == 0)
    #expect(Line.ease(1) == 1)
    #expect(Line.ease(0.5) == 0.875)
    #expect(Line.ease(-1) == 0 && Line.ease(2) == 1)
    #expect(Line.ease(0.2) < Line.ease(0.3))
}

@Test func fadeByX() {
    let w = 1200.0
    #expect(Line.fade(x: 0.25 * w, width: w) == 0)
    #expect(Line.fade(x: 0.10 * w, width: w) == 0)
    #expect(abs(Line.fade(x: 0.35 * w, width: w) - 0.5) < 1e-12)
    #expect(Line.fade(x: 0.45 * w, width: w) == 1)
    #expect(Line.fade(x: 0.60 * w, width: w) == 1)
}

@Test func backspaceWithinWord() {
    #expect(Line.backspace("the cat") == "the ca")
    #expect(Line.backspace("the c") == "the ")
    #expect(Line.backspace("the ") == nil)
    #expect(Line.backspace("") == nil)
    #expect(Line.backspace("café") == "caf")
    #expect(Line.backspace(Line.newline("end")) == "end ")
}

@Test func returnInsertsPilcrow() {
    #expect(Line.newline("end") == "end ¶")
    #expect(Line.newline("") == " ¶")
}

@Test func glideStartsAtAdvanceAndEasesToZero() {
    var g = Glide()
    g.add(10, at: 1, reduceMotion: false)
    #expect(g.offset(at: 1) == 10)
    #expect(abs(g.offset(at: 1.07) - 1.25) < 1e-9)
    #expect(g.offset(at: 1.141) == 0 && !g.active(at: 1.141))
    #expect(g.active(at: 1.1))
}

@Test func keystrokeDuringGlideAddsToRemainder() {
    var g = Glide()
    g.add(10, at: 0, reduceMotion: false)
    let before = g.offset(at: 0.05)
    g.add(10, at: 0.05, reduceMotion: false)
    #expect(abs(g.offset(at: 0.05) - (before + 10)) < 1e-9)  // nothing jumps
    g.add(10, at: 0.05, reduceMotion: false)
    #expect(g.offset(at: 0.05) == 20)  // capped: never more than one keystroke behind
    g.add(-10, at: 0.05, reduceMotion: false)
    #expect(g.offset(at: 0.05) == 10)  // a deletion moves the target back, no jump
    var d = Glide()
    d.add(-10, at: 0, reduceMotion: false)
    #expect(d.offset(at: 0) == -10)  // from idle, a deletion glides right
}

@Test func reduceMotionJumps() {
    var g = Glide()
    g.add(10, at: 0, reduceMotion: true)
    #expect(g.offset(at: 0) == 0 && !g.active(at: 0))
}

@Test func nothingDrawnRightOfCaret() {
    // "MW" in Menlo 28 with its end at the caret, x 100 of a strip 200 wide; a glide offset puts W partly past it.
    let font = CTFontCreateWithName("Menlo" as CFString, 28, nil)
    var ids = [CGGlyph](repeating: 0, count: 2)
    #expect(CTFontGetGlyphsForCharacters(font, Array("MW".utf16), &ids, 2))
    let a = CGFloat(CTFontGetAdvancesForGlyphs(font, .horizontal, ids, nil, 2) / 2)  // monospaced
    let glyphs = ids.indices.map { Glyph(font: font, id: ids[$0], x: CGFloat($0) * a, advance: a) }
    let (w, h) = (200, 56)
    let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 4 * w,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    /// The pixel columns holding ink after drawing the line at a glide offset, clipped at `caretX`.
    func inked(offset: CGFloat, caretX: CGFloat = 100) -> Set<Int> {
        c.clear(CGRect(x: 0, y: 0, width: w, height: h))
        c.setFillColor(CGColor(gray: 1, alpha: 1))
        Line.draw(glyphs, in: c, x0: 100 - 2 * a + offset, baseline: 20, caretX: caretX, width: CGFloat(w))
        let px = c.data!.assumingMemoryBound(to: UInt8.self)
        return Set((0..<w * h).filter { px[4 * $0 + 3] > 0 }.map { $0 % w })
    }
    #expect(inked(offset: a / 2, caretX: CGFloat(w)).contains { $0 >= 100 })  // unclipped, W would cross the caret
    #expect(inked(offset: a / 2).max() == 99)  // mid-glide: W half out from under the caret, ending at it
    #expect(inked(offset: a).max()! < 100)  // the key's own frame: W wholly under the caret
    #expect(inked(offset: -a / 2).max()! < 100)  // backspace's glide back
}

@Test func percentileNearestRank() {
    let xs = (1...100).map(Double.init).reversed().map { $0 }
    #expect(Line.percentile(xs, 0.5) == 50)
    #expect(Line.percentile(xs, 0.95) == 95)
    #expect(Line.percentile(xs, 1) == 100)
    #expect(Line.percentile([], 0.5).isNaN)
}
