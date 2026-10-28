// The effects (DESIGN.md F1): the Effects submenu's choice (S1), the newest glyphs' entrance (K1, E2) and how the band
// draws it. No Foundation here (see RenderTests.swift).
import CoreGraphics
import Testing
@testable import LemnaCore

private typealias Item = Effects.Item

@Test func effectsStartWithThePicksOn() {
    let e = Effects()
    #expect(e.on)
    for item in Item.allCases {
        #expect(e.plays(item, reduceMotion: false) == [.pop, .glyphPopIn, .handOffSheen, .paragraphFade].contains(item))
    }
    #expect(Item.allCases.map(\.title)
        == ["Pop", "Border warms", "Glyph pop-in", "Word sheen", "Hand-off sheen", "Paragraph fade"])
    #expect(e.duration(.pop, 0.25, reduceMotion: false) == 0.25)
    #expect(e.duration(.wordSheen, 0.3, reduceMotion: false) == 0)  // opt-in: at once, which is not at all
}

@Test func offStopsEveryEffectAndKeepsTheTicks() {
    var e = Effects()
    e.choose(.borderWarms)  // on: ticks it
    #expect(e.plays(.borderWarms, reduceMotion: false))
    e.toggle()  // Off
    #expect(!e.on && Item.allCases.allSatisfy { !e.plays($0, reduceMotion: false) })
    #expect(e.duration(.pop, 0.25, reduceMotion: false) == 0)
    #expect(e.ticked == [.pop, .borderWarms, .glyphPopIn, .handOffSheen, .paragraphFade])  // kept
    e.toggle()  // back, with the ticks
    #expect(e.plays(.borderWarms, reduceMotion: false) && e.plays(.pop, reduceMotion: false))
    e.choose(.pop)  // while on: unticks
    #expect(!e.plays(.pop, reduceMotion: false))
    e.toggle()
    e.choose(.glyphPopIn)  // while off, a ticked item: on again, and it stays ticked
    #expect(e.on && e.plays(.glyphPopIn, reduceMotion: false) && e.plays(.borderWarms, reduceMotion: false))
    #expect(!e.plays(.pop, reduceMotion: false))
    e.toggle()
    e.choose(.wordSheen)  // while off, an unticked one: on, with it ticked
    #expect(e.on && e.plays(.wordSheen, reduceMotion: false))
}

@Test func reduceMotionStopsWhatMovesAndGreysIt() {
    var e = Effects()
    e.choose(.borderWarms)
    e.choose(.wordSheen)
    #expect(e.ticked.count == 6)
    #expect(Item.allCases.filter(\.moves) == [.pop, .glyphPopIn, .wordSheen, .handOffSheen])
    for item in Item.allCases {
        #expect(e.plays(item, reduceMotion: true) == !item.moves)  // the paragraph fade and the border's warmth stay
        #expect(Effects.available(item, reduceMotion: true) == !item.moves && Effects.available(item, reduceMotion: false))
    }
    #expect(e.duration(.pop, 0.25, reduceMotion: true) == 0)  // the box comes and goes at once
    #expect(e.duration(.paragraphFade, 0.12, reduceMotion: true) == 0.12)
    #expect(e.ticked.count == 6)  // Reduce Motion takes no tick away: off again, they play again
}

@Test func effectsRoundTripThroughADictionary() {
    var e = Effects()
    e.choose(.pop)
    e.choose(.wordSheen)
    e.toggle()
    #expect(e.kept == ["on": false, "pop": false, "borderWarms": false, "glyphPopIn": true, "wordSheen": true,
                       "handOffSheen": true, "paragraphFade": true])
    #expect(Effects(kept: e.kept) == e)
    #expect(Effects(kept: nil) == Effects() && Effects(kept: [:]) == Effects())  // a first launch
    var sheen = Effects()
    sheen.choose(.wordSheen)
    #expect(Effects(kept: ["wordSheen": true, "gone": false]) == sheen)  // missing keys default, unknown ones are ignored
}

@Test func anEntranceFadesInOver120msOnTheCurve() {
    let e = Entrance(units: 1, at: 1, grows: true)
    #expect(e.newest(at: 1) == Newest(units: 1, alpha: 0, scale: 0.95))  // the key's own instant: nothing yet, at 95 %
    let first = e.newest(at: 1 + 1.0 / 120)  // the first 120 Hz frame: the panel's α .29
    #expect(abs(first.alpha - 0.29) < 0.01 && abs(first.scale - (0.95 + 0.05 * first.alpha)) < 1e-12)
    #expect(e.newest(at: 1.043).alpha > 0.89)  // 90 % in at 43 ms
    #expect(e.active(at: 1.119) && !e.active(at: 1.120))
    #expect(e.newest(at: 1.120) == Newest())  // done: drawn as the rest of the line
    let paragraph = Entrance(units: 3, at: 0, grows: false)  // E2: the ` ¶ `, opacity only
    #expect(paragraph.newest(at: 0.06).scale == 1 && paragraph.newest(at: 0.06).alpha > 0.9)
    #expect(Entrance().newest(at: 0) == Newest() && !Entrance().active(at: 0))
}

@Test func theNewestGlyphFadesAndGrowsAboutItsBaselineLeft() {
    // "MW" ending at the caret, x 120 of a band 200 wide, at 2×; background and caret clear: every inked pixel is text.
    var style = Style(font: menlo)
    (style.background, style.caret) = (CGColor(gray: 0, alpha: 0), CGColor(gray: 0, alpha: 0))
    let line = Line.shape(Text("MW"), marked: "", font: menlo)
    #expect(line.split == 2 && line.glyphs.map(\.index) == [0, 1])
    let (w, h) = (400, 112)
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    /// The ink of the columns `cols` (2× pixels): the topmost and bottommost rows, the leftmost and rightmost columns
    /// and the strongest alpha.
    func ink(_ newest: Newest, _ cols: Range<Int>) -> (top: Int, bottom: Int, left: Int, right: Int, peak: UInt8) {
        c.clear(CGRect(x: 0, y: 0, width: 200, height: 56))
        Line.draw(line, before: 0, after: 0, newest: newest, in: c, band: CGRect(x: 0, y: 0, width: 200, height: 56),
                  style: style)
        let px = c.data!.assumingMemoryBound(to: UInt8.self)
        var r = (top: Int.max, bottom: Int.min, left: Int.max, right: Int.min, peak: UInt8(0))
        for y in 0..<h { for x in cols where px[4 * (y * w + x) + 3] > 0 {
            let a = px[4 * (y * w + x) + 3]
            r = (min(r.top, y), max(r.bottom, y), min(r.left, x), max(r.right, x), max(r.peak, a))
        } }
        return r
    }
    let a = Int(2 * advance), caret = 240
    let m = (caret - 2 * a)..<(caret - a), wGlyph = (caret - a)..<caret
    let whole = ink(Newest(), wGlyph), faded = ink(Newest(units: 1, alpha: 0.5), wGlyph)
    let grown = ink(Newest(units: 1, alpha: 1, scale: 0.95), wGlyph)
    #expect(abs(Int(faded.peak) - Int(whole.peak) / 2) <= 2)  // the newest at half its alpha
    #expect(ink(Newest(units: 1, alpha: 0.5, scale: 0.95), m).peak == ink(Newest(), m).peak)  // the M as it was
    #expect(ink(Newest(units: 2, alpha: 0.5), m).peak < ink(Newest(), m).peak)  // two units: the M too
    // At 95 %: its top lower and its right edge further left; its baseline and its left edge where they were.
    #expect(grown.top > whole.top && grown.right < whole.right)
    #expect(abs(grown.bottom - whole.bottom) <= 1 && abs(grown.left - whole.left) <= 1)
}
