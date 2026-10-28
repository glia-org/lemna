import CoreGraphics
import CoreText
import LemnaJournal
import Testing
@testable import LemnaCore

let menlo = CTFontCreateWithName("Menlo" as CFString, 28, nil)
let advance = Line.width("M", font: menlo)  // monospaced: every Menlo glyph

/// The line's characters before and after the caret, and the runs drawn muted.
func shown(_ t: Text, around n: Int = 999) -> (before: String, after: String, muted: [String]) {
    let (b, a) = t.line(around: n)
    return (b.map(\.text).joined(), a.map(\.text).joined(), (b + a).filter(\.muted).map(\.text))
}

@Test func paragraphsAndPlainText() {
    var t = Text()
    #expect(t.paragraphs == [""] && t.plainText == "")
    t.insert("Hello")
    t.insert("\n")  // Return
    t.insert("World")
    #expect(t.paragraphs == ["Hello", "World"])
    #expect(t.plainText == "Hello\nWorld" && t.caret == 11 && t.count == 11)
    t.insert("\n")
    t.insert("\n")  // two Returns: a blank line
    t.insert("again")
    #expect(t.paragraphs == ["Hello", "World", "", "again"])
    #expect(t.plainText == "Hello\nWorld\n\nagain")
    #expect(t.utf16Caret == t.plainText.utf16.count)
    var u = Text()
    #expect(u.insert("one\r\ntwo\u{2028}") == Change(edits: [.insert(at: 0, "one\ntwo\n")],
                                                      motion: .before(added: "one\ntwo\n", removed: "")))
    #expect(u.paragraphs == ["one", "two", ""])  // a newline of any kind from the input system ends a paragraph
    #expect(u.insert("") == Change())
}

@Test func pressAndHoldReplacesTheLetterBeforeTheCaret() {
    var t = Text("one cafe!", caret: 8)
    #expect(t.insert("é", replacing: 1) == Change(edits: [.delete(at: 7, count: 1), .insert(at: 7, "é")],
                                                motion: .before(added: "é", removed: "e")))
    #expect(t.plainText == "one café!" && t.caret == 8)
    t = Text("a🙂")
    #expect(t.insert("x", replacing: 2).edits == [.delete(at: 1, count: 1), .insert(at: 1, "x")])  // 🙂: two units
    #expect(t.plainText == "ax")
    t = Text("x")
    #expect(t.insert("y", replacing: 9).edits == [.delete(at: 0, count: 1), .insert(at: 0, "y")])  // never past the start
}

@Test func paragraphEndsShowAsMutedPilcrow() {
    #expect(shown(Text("Hello\nWorld")) == (before: "Hello ¶ World", after: "", muted: [" ¶ "]))
    #expect(shown(Text("a\n\n")) == (before: "a ¶  ¶ ", after: "", muted: [" ¶ ", " ¶ "]))  // Return twice
    #expect(shown(Text("abc\ndefgh"), around: 6).before == " ¶ defgh")  // only what can be on screen
    #expect(shown(Text("abcdefgh"), around: 3).before == "fgh")
    #expect(shown(Text("one\ntwo", caret: 3)) == (before: "one", after: " ¶ two", muted: [" ¶ "]))  // before the ¶
    #expect(shown(Text("one\ntwo", caret: 4)) == (before: "one ¶ ", after: "two", muted: [" ¶ "]))  // after it
    #expect(shown(Text("abcdefgh", caret: 4), around: 2) == (before: "cd", after: "ef", muted: []))
}

@Test func shapedLineCarriesMutedGlyphsAndMarkedText() {
    let s = Line.shape(Text("ab\nc"), marked: "´", font: menlo)
    #expect(s.glyphs.map(\.muted) == [false, false, true, true, true, false, false])  // "ab ¶ c´"
    #expect(abs(s.width - 7 * advance) < 1e-9 && abs(s.caret - 7 * advance) < 1e-9)
    #expect(s.glyphs.allSatisfy { abs($0.advance - advance) < 1e-9 && !$0.after })
    // The caret mid-text: the marked text at it, before it; the rest after it.
    let m = Line.shape(Text("ab\ncd", caret: 2), marked: "´", font: menlo)  // "ab´ ¶ cd"
    #expect(m.glyphs.map(\.after) == [false, false, false, true, true, true, true, true])
    #expect(m.glyphs.map(\.muted) == [false, false, false, true, true, true, false, false])
    #expect(abs(m.caret - 3 * advance) < 1e-9 && abs(m.width - 8 * advance) < 1e-9)
}

@Test func editsMoveTheTextByTheirWidth() {
    #expect(abs(Line.width("t", font: menlo) - advance) < 1e-9)  // +advance per key
    #expect(abs(Line.width("\n", font: menlo) - 3 * advance) < 1e-9)  // Return, shown as ` ¶ `
    #expect(abs(Line.width("a\nb", font: menlo) - 5 * advance) < 1e-9)
    #expect(Line.width("", font: menlo) == 0)
}

@Test func easeOutQuint() {
    let q = Curve.easeOutQuint
    #expect(q(0) == 0 && q(1) == 1)
    #expect(q(-1) == 0 && q(2) == 1)
    // cubic-bezier(0.23, 1, 0.32, 1) over the glide's 140 ms: the first three 120 Hz frames (the panel's 25, 46, 63 %;
    // the ease-out cubic before it gave 17, 32, 45 %), then 90 % at about 51 ms.
    let frames = [1.0, 2, 3].map { q($0 / 120 / Line.glideDuration) }
    #expect(zip(frames, [0.248, 0.462, 0.632]).allSatisfy { abs($0 - $1) < 0.002 }, "\(frames)")
    #expect(q(0.050 / Line.glideDuration) > 0.89 && q(0.050 / Line.glideDuration) < 0.9)
    #expect(q(0.052 / Line.glideDuration) > 0.9)
    // Its x solved for the time: the curve's own points, and steadily rising, never past 1.
    let us = stride(from: 0.0, through: 1, by: 0.01).map(q)
    #expect(zip(us, us.dropFirst()).allSatisfy { $0 < $1 || $1 == 1 } && us.allSatisfy { $0 <= 1 })
    let (x1, x2) = (Curve.controlPoints.x1, Curve.controlPoints.x2)
    for t in [0.1, 0.3, 0.5, 0.8] {  // at the bezier's own parameter t: x(t) in, 1 − (1 − t)³ out (y1 = y2 = 1)
        let x = 3 * (1 - t) * (1 - t) * t * x1 + 3 * (1 - t) * t * t * x2 + t * t * t
        #expect(abs(q(x) - (1 - (1 - t) * (1 - t) * (1 - t))) < 1e-7)
    }
}

@Test func glideStartsAtAdvanceAndEasesToZeroIn140ms() {
    var g = Glide()
    g.add(10, at: 1, reduceMotion: false)
    #expect(g.offset(at: 1) == 10)
    #expect(g.offset(at: 1.050) > 1 && g.offset(at: 1.050) < 1.1)  // 90 % of the way at about 50 ms (the cubic: 75)
    #expect(g.offset(at: 1.07) < 0.4)  // under 4 % left at half time (the cubic left 12.5 %)
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

@Test func caretMoveGlideIsCappedAtAWordAndStartsWithinTheBand() {
    var g = Glide()
    for _ in 0 ..< 30 { g.add(-10, at: 0, reduceMotion: false, cap: 60) }  // ← faster than the glide
    #expect(g.offset(at: 0) == -70)  // never more than a word (60) behind, plus the step
    g = Glide()
    g.add(5_000, at: 0, reduceMotion: false, cap: 5_000, limit: 900)  // ⌘→ to a far paragraph end
    #expect(g.offset(at: 0) == 900)
    g.add(-10, at: 0, reduceMotion: false, cap: 60)  // ← right after: the remainder in the other direction stays
    #expect(g.offset(at: 0) == 890)
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
    // After the caret (B4): full strength to 80 %, nothing from 95 %.
    #expect(Line.fadeAfter(x: 0.60 * w, width: w) == 1 && Line.fadeAfter(x: 0.80 * w, width: w) == 1)
    #expect(abs(Line.fadeAfter(x: 0.875 * w, width: w) - 0.5) < 1e-12)
    #expect(Line.fadeAfter(x: 0.95 * w, width: w) == 0 && Line.fadeAfter(x: 1.2 * w, width: w) == 0)
}

@Test func nothingBeforeTheCaretDrawnRightOfIt() {
    // "MW" with its end at the caret, x 120 of a band 200 wide; a glide offset puts W partly past it. Background and
    // caret are clear here, so every inked pixel is text.
    var style = Style(font: menlo)
    (style.background, style.caret) = (CGColor(gray: 0, alpha: 0), CGColor(gray: 0, alpha: 0))
    let line = Line.shape(Text("MW"), marked: "", font: menlo), a = advance
    let (w, h) = (200, 56), caretX = 120
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 1, data: nil)
    /// The pixel columns holding ink after drawing the line at a glide offset.
    func inked(offset: CGFloat) -> Set<Int> {
        c.clear(CGRect(x: 0, y: 0, width: w, height: h))
        Line.draw(line, before: offset, after: 0, in: c, band: CGRect(x: 0, y: 0, width: w, height: h), style: style)
        return columns(c, w, h)
    }
    var id = line.glyphs[1].id, ink = CGRect.zero
    CTFontGetBoundingRectsForGlyphs(menlo, .horizontal, &id, &ink, 1)
    #expect(CGFloat(caretX) - a / 2 + ink.maxX > CGFloat(caretX))  // unclipped, W would cross the caret
    #expect(inked(offset: a / 2).max() == caretX - 1)  // mid-glide: W half out from under the caret, ending at it
    #expect(inked(offset: a).max()! < caretX)  // the key's own frame: W wholly under the caret
    #expect(inked(offset: -a / 2).max()! < caretX)  // backspace's glide back
}

@Test func theTextAfterTheCaretStartsAtItAndEndsBy95Percent() {
    // A band 1000 wide, the caret at 600 to 602: the text before the caret left of 600, the text after it from 602
    // on and gone at 950, also while a caret move glides both. Background and caret clear: every inked pixel is text.
    var style = Style(font: menlo)
    (style.background, style.caret) = (CGColor(gray: 0, alpha: 0), CGColor(gray: 0, alpha: 0))
    let words = String(repeating: "MW ", count: 60)
    let line = Line.shape(Text(words + words, caret: words.count), marked: "", font: menlo), a = advance
    let (w, h) = (1000, 56)
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 1, data: nil)
    for (before, after) in [(0, 0), (a, 0), (-a / 2, -a / 2), (a / 2, a / 2)] as [(CGFloat, CGFloat)] {
        c.clear(CGRect(x: 0, y: 0, width: w, height: h))
        Line.draw(line, before: before, after: after, in: c, band: CGRect(x: 0, y: 0, width: w, height: h), style: style)
        let ink = columns(c, w, h)
        #expect(ink.allSatisfy { $0 < 600 || $0 >= 602 }, "\(before) \(after)")  // nothing on the caret
        #expect(ink.max()! < 950 && ink.max()! > 900)  // faded out by 95 %
        #expect(ink.contains { $0 >= 602 && $0 < 640 } && ink.contains { $0 > 560 && $0 < 600 })  // both parts shown
    }
    // At full strength up to 80 %: a pixel of the after part there is as dark as one just right of the caret.
    c.clear(CGRect(x: 0, y: 0, width: w, height: h))
    Line.draw(line, before: 0, after: 0, in: c, band: CGRect(x: 0, y: 0, width: w, height: h), style: style)
    let px = c.data!.assumingMemoryBound(to: UInt8.self)
    let peak = { (lo: Int, hi: Int) in (0..<w * h).filter { $0 % w >= lo && $0 % w < hi }.map { px[4 * $0 + 3] }.max()! }
    #expect(peak(602, 700) == peak(700, 800) && peak(860, 900) < peak(700, 800))
}

/// The pixel columns of `c` that hold ink.
func columns(_ c: CGContext, _ w: Int, _ h: Int) -> Set<Int> {
    let px = c.data!.assumingMemoryBound(to: UInt8.self)
    return Set((0..<w * h).filter { px[4 * $0 + 3] > 0 }.map { $0 % w })
}
