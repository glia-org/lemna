// The effects (DESIGN.md F1): the Effects submenu's choice (S1), the newest glyphs' entrance (K1, E2), a fade, and how
// the band draws it. No Foundation here (see RenderTests.swift).
import CoreGraphics
import Testing
@testable import LemnaCore

private typealias Item = Effects.Item

@Test func effectsStartWithThePicksOn() {
    let e = Effects()
    #expect(e.on && Item.allCases.allSatisfy { e.plays($0, reduceMotion: false) })  // every one ticked
    // Pass 17b: "Hand-off" (the motion, H1 and C1) where "Hand-off sheen" was (E1); pass 18: "Glyph fade" where
    // "Glyph pop-in" was (K1), Border warms (B2) and Word sheen (K3) removed.
    #expect(Item.allCases.map(\.title) == ["Pop", "Glyph fade", "Hand-off", "Paragraph fade"])
    #expect(e.duration(.pop, 0.25, reduceMotion: false) == 0.25)
}

@Test func offStopsEveryEffectAndKeepsTheTicks() {
    var e = Effects()
    e.choose(.paragraphFade)  // on: unticks it
    #expect(!e.plays(.paragraphFade, reduceMotion: false))
    e.toggle()  // Off
    #expect(!e.on && Item.allCases.allSatisfy { !e.plays($0, reduceMotion: false) })
    #expect(e.duration(.pop, 0.25, reduceMotion: false) == 0)
    #expect(e.ticked == [.pop, .glyphFade, .handOff])  // kept
    e.toggle()  // back, with the ticks
    #expect(e.plays(.glyphFade, reduceMotion: false) && !e.plays(.paragraphFade, reduceMotion: false))
    e.choose(.pop)  // while on: unticks
    #expect(!e.plays(.pop, reduceMotion: false))
    e.toggle()
    e.choose(.glyphFade)  // while off, a ticked item: on again, and it stays ticked
    #expect(e.on && e.plays(.glyphFade, reduceMotion: false) && e.plays(.handOff, reduceMotion: false))
    #expect(!e.plays(.pop, reduceMotion: false))
    e.toggle()
    e.choose(.paragraphFade)  // while off, an unticked one: on, with it ticked
    #expect(e.on && e.plays(.paragraphFade, reduceMotion: false))
}

@Test func reduceMotionStopsWhatMovesAndGreysIt() {
    let e = Effects()
    #expect(Item.allCases.filter(\.moves) == [.pop, .handOff])  // the two fades are opacity alone
    for item in Item.allCases {
        #expect(e.plays(item, reduceMotion: true) == !item.moves)  // the glyph fade and the paragraph fade stay
        #expect(Effects.available(item, reduceMotion: true) == !item.moves && Effects.available(item, reduceMotion: false))
    }
    #expect(e.duration(.pop, 0.25, reduceMotion: true) == 0)  // the box comes and goes at once
    #expect(e.duration(.glyphFade, 0.08, reduceMotion: true) == 0.08)
    #expect(e.duration(.paragraphFade, 0.2, reduceMotion: true) == 0.2)
    #expect(e.ticked.count == 4)  // Reduce Motion takes no tick away: off again, they play again
}

@Test func effectsRoundTripThroughADictionary() {
    var e = Effects()
    e.choose(.pop)
    e.choose(.glyphFade)
    e.toggle()
    #expect(e.kept == ["on": false, "pop": false, "glyphFade": false, "handOff": true, "paragraphFade": true])
    #expect(Effects(kept: e.kept) == e)
    #expect(Effects(kept: nil) == Effects() && Effects(kept: [:]) == Effects())  // a first launch
    var unticked = Effects()
    unticked.choose(.paragraphFade)
    #expect(Effects(kept: ["paragraphFade": false, "gone": false]) == unticked)  // missing keys tick, unknown ones go
    #expect(Effects(kept: ["handOffSheen": false]) == Effects())  // E1's old tick: the motion starts ticked
    // Pass 18: B2's and K3's ticks are ignored, the pop-in's carries over to the glyph fade (its own key first).
    #expect(Effects(kept: ["borderWarms": true, "wordSheen": true]) == Effects())
    var noFade = Effects()
    noFade.choose(.glyphFade)
    #expect(Effects(kept: ["glyphPopIn": false]) == noFade)
    #expect(Effects(kept: ["glyphPopIn": false, "glyphFade": true]) == Effects())
}

@Test func theTuningIsPlainToSee() {
    // Pass 14b (the user: "Where are the new animations, I can barely see anything."); pass 14's subtle values beside.
    typealias T = Effects.Tuning
    #expect(T.open == 0.300 && T.openScale == 0.87 && T.close == 0.200)  // subtle: 0.250, 0.95, 0.160
    #expect(T.glyphFade == 0.080)  // pass 18, opacity alone; the pop-in's 0.160 from 70 %, 3 pt low (subtle: 0.120)
    #expect(T.paragraphFade == 0.200 && T.dim == 0.5)  // subtle: 0.120; the dim unchanged
    // Pass 17b, the hand-off (H1 on easeOutQuint, C1), in E1's place (a sheen, peak 0.35 over 0.350 s).
    #expect(T.exit == 0.200 && T.exitStagger == 0.007 && T.exitStaggerCap == 0.120)
    #expect(T.sendReach == 1.0 && T.riseReach == 1.25)
    #expect(T.lift == 0.140 && T.collapseAt == 0.120 && T.collapse == 0.140 && T.collapseScale == 0.9)  // 0.160 before
    // Pass 18: every duration on one scale, 80, 140, 200, 300 ms.
    for d in [T.glyphFade, Line.glideDuration, T.lift, T.collapse, T.close, T.paragraphFade, T.exit, T.open] {
        #expect([0.080, 0.140, 0.200, 0.300].contains(d), "\(d)")
    }
}

@Test func anEntranceFadesInOnTheCurve() {
    let e = Entrance.glyph(units: 1, at: 1)  // K1: opacity alone, over 80 ms
    #expect(e.newest(at: 1) == Newest(units: 1, alpha: 0))  // the key's own instant
    #expect(abs(e.newest(at: 1 + 1.0 / 120).alpha - 0.413) < 0.002)  // the first 120 Hz frame
    #expect(e.newest(at: 1.029).alpha > 0.9 && e.newest(at: 1.028).alpha < 0.9)  // 90 % in at 29 ms
    #expect(e.active(at: 1.079) && !e.active(at: 1.080))
    #expect(e.newest(at: 1.080) == Newest())  // done: drawn as the rest of the line
    let paragraph = Entrance.paragraph(units: 3, at: 0)  // E2: the ` ¶ `, opacity alone, over 200 ms
    #expect(abs(paragraph.newest(at: 0.025).alpha - 0.48) < 0.01 && paragraph.active(at: 0.199) && !paragraph.active(at: 0.2))
    #expect(Entrance().newest(at: 0) == Newest() && !Entrance().active(at: 0))
}

@Test func theNewestGlyphFadesInWhereItStands() {
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
    #expect(abs(Int(faded.peak) - Int(whole.peak) / 2) <= 2)  // the newest at half its alpha
    // Opacity alone (pass 18): its ink where the whole glyph's is, no smaller, no lower.
    #expect(faded.top == whole.top && faded.bottom == whole.bottom)
    #expect(faded.left == whole.left && faded.right == whole.right)
    #expect(ink(Newest(units: 1, alpha: 0.5), m).peak == ink(Newest(), m).peak)  // the M as it was
    #expect(ink(Newest(units: 2, alpha: 0.5), m).peak < ink(Newest(), m).peak)  // two units: the M too
}
