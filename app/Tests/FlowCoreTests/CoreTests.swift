import CoreGraphics
import CoreText
import Testing
@testable import FlowCore

let menlo = CTFontCreateWithName("Menlo" as CFString, 28, nil)
let advance = Line.width("M", font: menlo)  // monospaced: every Menlo glyph

/// The line's characters, and the runs drawn muted.
func shown(_ t: Text, last n: Int = 999) -> (line: String, muted: [String]) {
    let parts = t.line(last: n)
    return (parts.map(\.text).joined(), parts.filter(\.muted).map(\.text))
}

@Test func paragraphsAndPlainText() {
    var t = Text()
    #expect(t.paragraphs == [""] && t.plainText == "")
    t.type("Hello")
    t.endParagraph()
    t.type("World")
    #expect(t.paragraphs == ["Hello", "World"])
    #expect(t.plainText == "Hello\nWorld")
    t.endParagraph()
    t.endParagraph()  // two Returns: a blank line
    t.type("again")
    #expect(t.paragraphs == ["Hello", "World", "", "again"])
    #expect(t.plainText == "Hello\nWorld\n\nagain")
    #expect(t.utf16Count == t.plainText.utf16.count)
    var u = Text()
    #expect(u.type("one\ntwo") == (removed: "", added: "one ¶ two"))  // a newline from the input system ends a paragraph
    #expect(u.paragraphs == ["one", "two"])
}

@Test func backspaceWithinWordOnly() {
    var t = Text(["the cat"])
    #expect(t.backspace() == "t" && t.plainText == "the ca")
    t = Text(["the c"])
    #expect(t.backspace() == "c")
    #expect(t.backspace() == nil && t.plainText == "the ")  // not across the space that ended the last word
    t = Text(["café"])
    #expect(t.backspace() == "é" && t.plainText == "caf")
    t = Text(["end", ""])
    #expect(t.backspace() == nil && t.paragraphs == ["end", ""])  // at a paragraph's start: nothing
    t = Text(["end", "x"])
    #expect(t.backspace() == "x")
    #expect(t.backspace() == nil && t.paragraphs == ["end", ""])  // never across the paragraph end
    t = Text()
    #expect(t.backspace() == nil)
    t = Text(["a\u{A0}"])  // ⌥Space's no-break space ends a word too
    #expect(t.backspace() == nil)
}

@Test func pressAndHoldReplacesTheLastLetter() {
    var t = Text(["one", "cafe"])
    #expect(t.type("é", replacing: 1) == (removed: "e", added: "é"))
    #expect(t.paragraphs == ["one", "café"])
    #expect(t.type("x", replacing: 9) == (removed: "café", added: "x"))  // never past the paragraph's start
    #expect(t.paragraphs == ["one", "x"])
}

@Test func paragraphEndsShowAsMutedPilcrow() {
    #expect(shown(Text(["Hello", "World"])) == (line: "Hello ¶ World", muted: [" ¶ "]))
    #expect(shown(Text(["a", "", ""])) == (line: "a ¶  ¶ ", muted: [" ¶ ", " ¶ "]))  // Return twice
    #expect(shown(Text(["abc", "defgh"]), last: 6).line == " ¶ defgh")  // only the tail
    #expect(shown(Text(["abcdefgh"]), last: 3).line == "fgh")
    var t = Text(["x"])
    #expect(t.endParagraph() == Line.paragraphEnd)
}

@Test func shapedLineCarriesMutedGlyphsAndMarkedText() {
    let s = Line.shape(Text(["ab", "c"]), marked: "´", font: menlo)
    #expect(s.glyphs.map(\.muted) == [false, false, true, true, true, false, false])  // "ab ¶ c´"
    #expect(abs(s.width - 7 * advance) < 1e-9)
    #expect(s.glyphs.allSatisfy { abs($0.advance - advance) < 1e-9 })
}

@Test func editsMoveTheLineEndByTheirWidth() {
    #expect(abs(Line.width("t", font: menlo) - advance) < 1e-9)  // +advance per key
    #expect(abs(Line.width(Line.paragraphEnd, font: menlo) - 3 * advance) < 1e-9)  // Return
    #expect(Line.width("", font: menlo) == 0)
}

@Test func easeOutCubic() {
    #expect(Line.ease(0) == 0)
    #expect(Line.ease(1) == 1)
    #expect(Line.ease(0.5) == 0.875)
    #expect(Line.ease(-1) == 0 && Line.ease(2) == 1)
    #expect(Line.ease(0.2) < Line.ease(0.3))
}

@Test func glideStartsAtAdvanceAndEasesToZeroIn140ms() {
    var g = Glide()
    g.add(10, at: 1, reduceMotion: false)
    #expect(g.offset(at: 1) == 10)
    #expect(abs(g.offset(at: 1.07) - 1.25) < 1e-9)  // (1 − 0.5)³ of it left at half time
    #expect(g.active(at: 1.1))
    #expect(g.offset(at: 1.141) == 0 && !g.active(at: 1.141))
}

@Test func keystrokeDuringGlideAddsToRemainderCappedAtOneAdvance() {
    var g = Glide()
    g.add(10, at: 0, reduceMotion: false)
    let before = g.offset(at: 0.05)
    g.add(10, at: 0.05, reduceMotion: false)
    #expect(abs(g.offset(at: 0.05) - (before + 10)) < 1e-9)  // nothing jumps
    g.add(10, at: 0.05, reduceMotion: false)
    #expect(g.offset(at: 0.05) == 20)  // capped: never more than one keystroke behind
    g.add(-10, at: 0.05, reduceMotion: false)
    #expect(g.offset(at: 0.05) == 10)  // a deletion moves the target back, no jump
}

@Test func backspaceGlidesBack() {
    var g = Glide()
    g.add(-10, at: 0, reduceMotion: false)
    #expect(g.offset(at: 0) == -10)  // the line starts left of its rest and glides right
    #expect(g.offset(at: 0.07) > -10 && g.offset(at: 0.07) < 0)
    #expect(g.offset(at: 0.14) == 0)
}

@Test func reduceMotionJumps() {
    var g = Glide()
    g.add(10, at: 0, reduceMotion: true)
    #expect(g.offset(at: 0) == 0 && !g.active(at: 0))
}

@Test func fadeByX() {
    let w = 1200.0
    #expect(Line.fade(x: 0.25 * w, width: w) == 0)
    #expect(Line.fade(x: 0.10 * w, width: w) == 0)
    #expect(abs(Line.fade(x: 0.35 * w, width: w) - 0.5) < 1e-12)
    #expect(Line.fade(x: 0.45 * w, width: w) == 1)
    #expect(Line.fade(x: 0.60 * w, width: w) == 1)
}

@Test func nothingDrawnRightOfCaret() {
    // "MW" with its end at the caret, x 120 of a band 200 wide; a glide offset puts W partly past it. Background and
    // caret are clear here, so every inked pixel is text.
    var style = Style(font: menlo)
    (style.background, style.caret) = (CGColor(gray: 0, alpha: 0), CGColor(gray: 0, alpha: 0))
    let line = Line.shape(Text(["MW"]), marked: "", font: menlo), a = advance
    let (w, h) = (200, 56), caretX = 120
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 1, data: nil)
    /// The pixel columns holding ink after drawing the line at a glide offset.
    func inked(offset: CGFloat) -> Set<Int> {
        c.clear(CGRect(x: 0, y: 0, width: w, height: h))
        Line.draw(line, offset: offset, in: c, band: CGRect(x: 0, y: 0, width: w, height: h), style: style)
        let px = c.data!.assumingMemoryBound(to: UInt8.self)
        return Set((0..<w * h).filter { px[4 * $0 + 3] > 0 }.map { $0 % w })
    }
    var id = line.glyphs[1].id, ink = CGRect.zero
    CTFontGetBoundingRectsForGlyphs(menlo, .horizontal, &id, &ink, 1)
    #expect(CGFloat(caretX) - a / 2 + ink.maxX > CGFloat(caretX))  // unclipped, W would cross the caret
    #expect(inked(offset: a / 2).max() == caretX - 1)  // mid-glide: W half out from under the caret, ending at it
    #expect(inked(offset: a).max()! < caretX)  // the key's own frame: W wholly under the caret
    #expect(inked(offset: -a / 2).max()! < caretX)  // backspace's glide back
}
