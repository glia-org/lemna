// The ambience (DESIGN.md A1): the Ambience submenu's choice (S1), the tuning (I1, raised in pass 16), the run of a
// scene from the first key to its end (R1), every mode's coupling to typing and, since pass 16, to where the key is on
// the keyboard, the cap, and the Metal pipeline drawing offscreen. No Foundation here (see RenderTests.swift).
import CoreGraphics
import CoreText
import Darwin
import Testing
@testable import LemnaCore

private typealias Mode = Ambience.Mode
private typealias T = Ambience.Tuning
private typealias Event = Ambience.Event

/// A laptop's screen, 1512 × 982 pt, with the box where `BoxFrame` puts it (907 × 112 pt in the lower third).
private let screen = CGSize(width: 1512, height: 982)
private let box = BoxFrame.line(in: CGRect(x: 0, y: 80, width: 1512, height: 868), height: 112)
private let style = Style(font: menlo)
private let stage = Ambience.Stage(size: screen, box: box, style: style)
/// Another screen's dim: no box on it.
private let elsewhere = Ambience.Stage(size: screen, style: style)
private let glyphs = Ambience.Glyphs(font: menlo)
private let m = glyphs.slot("m")!

/// A key of a US keyboard by what it types (its kVK code), for the renders.
private let us: [Character: UInt16] = {
    var t: [Character: UInt16] = [" ": 0x31, "\n": 0x24, ",": 0x2B, ".": 0x2F]
    for (c, k) in zip("asdfhgzxcvbqweryt", [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0B, 0x0C, 0x0D,
                                            0x0E, 0x0F, 0x10, 0x11] as [UInt16]) { t[c] = k }
    for (c, k) in zip("oupilj'k;nm", [0x1F, 0x20, 0x23, 0x22, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2D, 0x2E] as [UInt16]) { t[c] = k }
    return t
}()
private func key(_ c: Character) -> Keyboard.Position? { us[c].flatMap { Keyboard.position(of: $0) } }
/// A position anywhere along the block (for the extremes).
private func column(_ x: Double, row: Double = 1) -> Keyboard.Position { Keyboard.Position(row: row, column: x) }

/// `scene` stepped at 60 Hz for `seconds`, `events` in the first step; the last step's sprites.
private func play(_ scene: inout any Ambience.Scene, _ events: [Event] = [], for seconds: Double,
                  rate: Double = 5) -> [Sprite] {
    var out: [Sprite] = []
    let frames = max(Int((seconds * 60).rounded()), 1)
    for f in 0..<frames {
        out.removeAll()
        scene.step(dt: 1.0 / 60, events: f == 0 ? events : [], rate: rate, into: &out)
    }
    return out
}

private func scene(_ mode: Mode, on s: Ambience.Stage = stage, seed: UInt64 = 7) -> any Ambience.Scene {
    Ambience.scene(mode, stage: s, glyphs: glyphs, seed: seed)
}

private func near(_ a: Double, _ b: Double, _ tolerance: Double) -> Bool { abs(a - b) <= tolerance }

// MARK: The choice (S1) and the tuning (I1)

@Test func ambienceStartsOffAndKeepsAModeAcrossLaunches() {
    #expect(Ambience().mode == nil && Ambience().kept == "off")  // D0
    #expect(Mode.allCases.map(\.title) == ["Drift", "Rain", "Rings", "Beams", "Grid", "Fireworks", "Swarm"])
    for mode in Mode.allCases {
        #expect(Ambience(kept: Ambience(mode).kept) == Ambience(mode) && Ambience(mode).kept == mode.rawValue)
    }
    #expect(Ambience(kept: nil) == Ambience() && Ambience(kept: "off") == Ambience())
    #expect(Ambience(kept: "burn") == Ambience())  // M8, never built, or a mode since removed: Off
    var a = Ambience()
    a.choose(.rain)
    #expect(a.mode == .rain && a.playing(reduceMotion: false) == .rain)
    a.choose(nil)
    #expect(a == Ambience())
    #expect(Mode.allCases.filter(\.everyScreen) == [.rain, .beams])  // the rest stay on the box's screen
}

@Test func reduceMotionForcesOffAndKeepsThePick() {
    let a = Ambience(.drift)
    #expect(a.playing(reduceMotion: true) == nil && a.playing(reduceMotion: false) == .drift)
    #expect(!Ambience.available(reduceMotion: true) && Ambience.available(reduceMotion: false))
    #expect(a.mode == .drift && a.kept == "drift")  // kept: Reduce Motion off again, it plays again
}

@Test func theAmbienceTuningIsPlainToSee() {
    // Pass 16 (the user: "The ambience effects are way too subtle"); pass 15's, the panel's, in the comments.
    #expect(T.cap == 2000 && T.frameRate == 60 && T.linger == 4 && T.fadeOut == 1)
    #expect(T.driftPeak == 0.7 && T.driftHold == 1.5 && T.driftLife == 4 && T.driftCurrent == 8...40)  // 0.35, no hold
    #expect(T.rainHead == 0.8 && T.rainTrailStart == 0.55 && T.rainLife == 3 && T.rainScale == 1)  // 0.3, 0.18, 2.5, 0.8
    #expect(T.ringPeak == 0.6 && T.ringWidth == 2 && T.ringLife == 2 && T.ringInward == 240)  // 0.25, 1, 1.5, 160
    #expect(T.beamPeak == 0.45 && T.beamHead == 0.95)  // 0.18, 0.55
    #expect(T.gridCell == 32 && T.gridLines == 0.12 && T.gridLit == 0.6 && T.gridLife == 0.9)  // 24, 0.06, 0.2, 0.6
    #expect(T.firePeak == 0.9 && T.fireSparks == 48 && T.fireLife == 2)  // 0.42, 24, 1.6
    #expect(T.swarmPeak == 0.6 && T.swarmStroke == 2)  // 0.3, 1.2
    // C1: the box's text and accent.
    func hex(_ c: CGColor) -> UInt32 {
        c.components!.prefix(3).reduce(0) { $0 << 8 | UInt32(($1 * 255).rounded()) }
    }
    #expect(T.text == hex(style.text) && T.accent == hex(Style.accent))
}

@Test func aSpriteIsThe32BytesTheShaderReads() {
    #expect(MemoryLayout<Sprite>.size == 32 && MemoryLayout<Sprite>.stride == 32)
    #expect(Sprite.packed(0x7aa7f0) == 0xfff0_a77a)  // red in the low byte, as unpack_unorm4x8 reads it
    let s = Sprite(x: 1, y: 2, w: 3, h: 4, alpha: 1.5, colour: 0xffffff, kind: .ring, parameter: Sprite.stroke(1))
    #expect(s.kind == .ring && s.parameter == 64 && s.alpha == 1)  // alpha clamped
    let b = Sprite.bend(radius: 1234.5, width: 2)  // half points and sixteenths
    #expect(b & 0x3fff == 2469 && b >> 14 == 32 && Sprite.bend(radius: 99_999, width: 99) == 0x3fff | 1023 << 14)
}

@Test func theStageIsTheLinesGeometryInTheBox() {
    let line = box.insetBy(dx: 1, dy: 1)  // inside the border
    #expect(stage.band == Line.band(in: line.size, style: style).offsetBy(dx: line.minX, dy: line.minY))
    #expect(stage.caret == stage.band.minX + 0.6 * stage.band.width)
    #expect(stage.band.minY > box.minY && stage.band.maxY < box.maxY && stage.baseline > stage.band.minY)
    #expect(elsewhere.box == nil && stage.keyboard == .ansi)
    #expect(glyphs.ids.count > 150 && glyphs.slot("é") != nil && glyphs.slot("„") != nil && glyphs.letters.count == 26)
    #expect(glyphs.cell.width >= Line.width("M", font: menlo) && glyphs.cell.height >= 28)
    // Where a key is: across the screen from a tenth to nine tenths, along the box from 5 % to 95 %.
    #expect(near(stage.screenX(column(0))!, 151.2, 1e-6) && near(stage.screenX(column(15))!, 1360.8, 1e-6))
    #expect(near(stage.boxX(column(0))!, Double(box.minX) + 0.05 * Double(box.width), 1e-6))
    #expect(stage.boxX(nil) == Double(stage.caret) && elsewhere.boxX(column(3)) == nil && stage.screenX(nil) == nil)
}

// MARK: The run

@Test func typingRateCountsTheLastTwoSeconds() {
    var typing = Ambience.Typing()
    for i in 0..<15 { typing.key(at: Double(i) * 0.2) }  // 5 keys a second for 3 s
    #expect(near(typing.rate(at: 2.85), 5, 0.01))
    #expect(typing.rate(at: 6) == 0)
}

@Test func aRunLastsFourSecondsAfterTheLastKeyTheLastOneFading() {
    var run = Ambience.Run(mode: .rings, stage: stage, glyphs: glyphs, seed: 1)
    var out: [Sprite] = []
    #expect(run.frame(at: 0, dt: 1.0 / 60, into: &out) == nil)  // no key yet: nothing plays
    run.take([Ambience.Key(t: 10, kind: .glyph("a"))])
    #expect(run.frame(at: 10, dt: 1.0 / 60, into: &out) == 1 && !out.isEmpty && out.allSatisfy { $0.kind == .bend })
    #expect(run.alpha(at: 12.9) == 1 && near(run.alpha(at: 13.5), 0.5, 1e-9) && run.alpha(at: 14) == 0)
    run.take([Ambience.Key(t: 11, kind: .space)])  // a later key moves the end on
    #expect(run.alpha(at: 14) == 1 && run.alpha(at: 15) == 0)
    #expect(run.frame(at: 15, dt: 1.0 / 60, into: &out) == nil && out.isEmpty)
    var closed = Ambience.Run(mode: .rings, stage: stage, glyphs: glyphs, seed: 1)
    closed.take([Ambience.Key(t: 0, kind: .glyph("a"))])
    closed.close(at: 1, over: 0.2)  // the box went: fading with the dim
    #expect(near(closed.alpha(at: 1.1), 0.5, 1e-9) && closed.frame(at: 1.21, dt: 0.1, into: &out) == nil)
    var atOnce = Ambience.Run(mode: .rings, stage: stage, glyphs: glyphs, seed: 1)
    atOnce.take([Ambience.Key(t: 0, kind: .glyph("a"))])
    atOnce.close(at: 1, over: 0)
    #expect(atOnce.alpha(at: 1) == 0)
}

@Test func aKeysCodeBecomesItsPlaceOnTheKeyboardOfTheStage() {
    var run = Ambience.Run(mode: .rain, stage: stage, glyphs: glyphs, seed: 1)
    run.take([Ambience.Key(t: 0, kind: .glyph("a"), code: 0x00), Ambience.Key(t: 0, kind: .space, code: 0x31),
              Ambience.Key(t: 0, kind: .paragraph, code: 0x24), Ambience.Key(t: 0, kind: .backspace, code: 0x33),
              Ambience.Key(t: 0, kind: .glyph("é"))])  // the accent menu's pick: no code
    #expect(run.events == [.typed(slot: glyphs.slot("a"), at: Keyboard.position(of: 0x00)),
                           .space(Keyboard.position(of: 0x31)), .paragraph(Keyboard.position(of: 0x24)),
                           .backspace(Keyboard.position(of: 0x33)), .typed(slot: glyphs.slot("é"), at: nil)])
    var iso = Ambience.Run(mode: .rain, stage: Ambience.Stage(size: screen, box: box, keyboard: .iso, style: style),
                           glyphs: glyphs, seed: 1)
    iso.take([Ambience.Key(t: 0, kind: .glyph("<"), code: 0x32), Ambience.Key(t: 0, kind: .paragraph, code: 0x24)])
    #expect(iso.events.map(\.key) == [Keyboard.position(of: 0x32, on: .iso), Keyboard.position(of: 0x24, on: .iso)])
    #expect(iso.events[0].key?.row == 3)  // the key left of Z, not ANSI's ` left of 1
}

@Test func aGlyphPushedPastTheBoxsLeftEdgeLeaves() {
    // 60 letters, the caret at their end: about 32 fit between the caret and the band's left edge.
    let letters = String(repeating: "abcdefghijklmnopqrstuvwxyz", count: 3).prefix(60)
    let line = Line.shape(Text(String(letters)), marked: "", font: menlo), a = Double(advance)
    var run = Ambience.Run(mode: .drift, stage: stage, glyphs: glyphs, seed: 1)
    run.take([Ambience.Key(t: 0, kind: .glyph("h"), line: line, pushed: a)])
    let leaving = run.events.compactMap { e -> (Int, CGPoint)? in if case .leaving(let s, let p) = e { (s, p) } else { nil } }
    #expect(leaving.count == 1 && run.events.last == .typed(slot: glyphs.slot("h"), at: nil))
    if let (slot, p) = leaving.first {
        let edge = Double(stage.band.minX), middle = Double(p.x) + a / 2
        #expect(middle < edge && middle >= edge - a && p.y == stage.baseline)
        let x0 = Double(stage.caret - line.caret), i = Int(((Double(p.x) - x0) / a).rounded())
        #expect(slot == glyphs.slot(Array(letters)[i]))  // the line's own glyph at that place
    }
    var deleting = Ambience.Run(mode: .drift, stage: stage, glyphs: glyphs, seed: 1)
    deleting.take([Ambience.Key(t: 0, kind: .backspace, line: line, pushed: -a)])
    var other = Ambience.Run(mode: .drift, stage: elsewhere, glyphs: glyphs, seed: 1)
    other.take([Ambience.Key(t: 0, kind: .glyph("h"), line: line, pushed: a)])
    #expect(deleting.events == [.backspace(nil)] && other.events == [.typed(slot: glyphs.slot("h"), at: nil)])
    var short = Ambience.Run(mode: .drift, stage: stage, glyphs: glyphs, seed: 1)
    short.take([Ambience.Key(t: 0, kind: .glyph("c"), line: Line.shape(Text("abc"), marked: "", font: menlo), pushed: a)])
    #expect(short.events.count == 1)  // a short line: nothing reaches the edge
}

// MARK: The modes

@Test func driftCarriesTheLeavingGlyphsLeftOnTheRatesCurrentAndFadesThem() {
    let p = CGPoint(x: 200, y: 300), leaf = [Event.leaving(slot: m, at: p)]
    var s = scene(.drift)
    var out = play(&s, leaf + leaf + leaf + [.typed(slot: m, at: key("m")), .space(nil)], for: 1.0 / 60)
    #expect(s.count == 3)
    #expect(out.allSatisfy { $0.kind == .glyph && $0.parameter == UInt32(m) && $0.colour == Sprite.packed(T.text) })
    #expect(out[0].alpha < 0.05)  // fading in
    out = play(&s, for: 0.3 - 1.0 / 60)
    #expect(near(Double(out[0].alpha), 0.7, 0.01))  // its peak at 0.3 s
    out = play(&s, for: 1.5)
    #expect(near(Double(out[0].alpha), 0.7, 0.01))  // held until 1.8 s
    out = play(&s, for: 1.1)
    #expect(near(Double(out[0].alpha), 0.35, 0.01))  // halfway down at 2.9 s
    out = play(&s, for: 1.2)
    #expect(s.count == 0 && out.isEmpty)  // gone by 4 s
    // At rest the current's 8 pt/s; typing, a glyph leaves at the line's speed (an advance a key) and slows onto a
    // current easing toward 40 pt/s at 10 keys a second.
    func carried(rate: Double, for seconds: Double = 2) -> Double {
        var d = scene(.drift)
        let first = play(&d, leaf, for: 1.0 / 60, rate: rate)[0].x
        return Double(first - play(&d, for: seconds, rate: rate)[0].x)
    }
    #expect(near(carried(rate: 0), 16, 0.5) && carried(rate: 10) > 150)
    #expect(near(carried(rate: 6, for: 1.0 / 6), Double(advance) * 6 / 6, 1.5))  // a key's time: about an advance on
    var none = scene(.drift)
    #expect(play(&none, [.typed(slot: m, at: nil), .space(nil), .paragraph(nil), .backspace(nil)], for: 0.5).isEmpty)
}

@Test func rainDropsOneColumnWhereTheKeyIsItsHeadTheTypedGlyph() {
    var s = scene(.rain)
    var out = play(&s, [.typed(slot: m, at: key("m")), .space(nil), .paragraph(nil), .backspace(nil)], for: 1.0 / 60)
    #expect((5...9).contains(s.count) && out.count == 1)  // one drop; its trail grows as it falls
    out = play(&s, for: 0.5)
    let head = out[0]
    #expect(head.kind == .glyph && head.parameter == UInt32(m) && head.colour == Sprite.packed(T.accent))
    #expect(near(Double(head.alpha), 0.8, 0.001) && out.count > 1 && out.count <= s.count)  // the trail as far as it fell
    let trail = Array(out.dropFirst())
    #expect(trail.allSatisfy { $0.colour == Sprite.packed(T.text) && $0.x == head.x && $0.y > head.y })
    #expect(near(Double(trail[0].alpha), 0.55, 0.001))
    #expect(zip(trail, trail.dropFirst()).allSatisfy { near(Double($1.alpha / $0.alpha), 0.75, 0.001) })  // fainter upward
    #expect(near(Double(head.h), Double(glyphs.cell.height), 1e-3))  // the line's size
    out = play(&s, for: 2.6)
    #expect(s.count == 0 && out.isEmpty)  // 3 s a drop
    // Where the key is: the left end of the keyboard a tenth across the screen, the right end nine tenths; the number
    // row starts higher than the bottom letter row.
    func drop(_ k: Keyboard.Position?, on st: Ambience.Stage = stage) -> Sprite {
        var r = scene(.rain, on: st)
        return play(&r, [.typed(slot: m, at: k)], for: 1.0 / 60)[0]
    }
    let cellW = Double(glyphs.cell.width), within = 0.4 * 1512 * 0.8 / 15 + cellW  // anywhere on the key, on a column
    #expect(abs(Double(drop(column(0.5)).x) - 1512 * (0.1 + 0.8 * 0.5 / 15)) <= within)
    #expect(abs(Double(drop(column(14.5)).x) - 1512 * (0.1 + 0.8 * 14.5 / 15)) <= within)
    var again = scene(.rain), xs = Set<Float>()  // one key typed again and again: its drops spread over the key
    for _ in 0..<20 { xs.insert(play(&again, [.typed(slot: m, at: column(7.5))], for: 1.0 / 60).last!.x) }  // the newest
    #expect(xs.count >= 3 && xs.allSatisfy { abs(Double($0) - 1512 * 0.5) <= within })
    #expect(drop(column(5, row: 0)).y > drop(column(5, row: 3)).y + 150)
    #expect(abs(Double(drop(nil).x) - Double(stage.caret)) <= cellW)  // no position: at the caret
    #expect(abs(Double(drop(column(14.5), on: elsewhere).x) - 1512 * (0.1 + 0.8 * 14.5 / 15)) <= within)  // every screen
    var many = scene(.rain)
    _ = play(&many, Array(repeating: .typed(slot: m, at: key("m")), count: 50), for: 1.0 / 60)
    #expect(many.count >= 250)  // the density is the keys'
}

/// A circle's centre and radius from one of its arcs: the arc's middle is on it, its turn points away from the centre.
private func circleOf(_ out: [Sprite]) -> (x: Double, y: Double, r: Double) {
    let s = out[0], r = Double(s.parameter & 0x3fff) / 2, a = Double(s.rotation) + .pi / 2
    return (Double(s.x) - r * cos(a), Double(s.y) - r * sin(a), r)
}

@Test func ringsGoOutFromWhereTheKeyIsToTheScreensEdgeAndInOnBackspace() {
    var s = scene(.rings)
    var out = play(&s, [.typed(slot: m, at: nil)], for: 1.0 / 60)
    var c = circleOf(out)
    #expect(out.allSatisfy { $0.kind == .bend && $0.parameter >> 14 == 32 } && near(Double(out[0].alpha), 0.6, 0.01))  // 2 pt
    #expect(near(c.x, Double(stage.caret), 0.5) && near(c.y, Double(box.maxY), 0.5))  // no position: at the caret
    let early = c.r
    out = play(&s, for: 0.5)
    c = circleOf(out)
    let corner = hypot(Double(stage.caret), Double(screen.height) - Double(box.maxY))  // the farthest: top left
    #expect(c.r > early && c.r > 0.75 * corner && out[0].alpha < 0.6)  // out on the curve (79 % at a quarter), fading
    #expect(out.count < T.ringArcs)  // the arcs off the screen left out
    out = play(&s, for: 1.4)
    #expect(circleOf(out).r > 0.99 * corner)  // past the screen's edge
    #expect(play(&s, for: 0.2).isEmpty)  // 2 s a ring
    // Where the key is along the box's top edge.
    for x in [0.5, 7.5, 14.5] {
        var k = scene(.rings)
        let at = circleOf(play(&k, [.typed(slot: m, at: column(x))], for: 1.0 / 60))
        #expect(near(at.x, Double(box.minX) + Double(box.width) * (0.05 + 0.9 * x / 15), 0.5), "\(x)")
    }
    var back = scene(.rings)
    let far = circleOf(play(&back, [.backspace(Keyboard.position(of: 0x33))], for: 1.0 / 60))
    let close = circleOf(play(&back, for: 0.5))
    #expect(far.r > 200 && close.r < far.r && near(far.x, Double(box.minX) + Double(box.width) * (0.05 + 0.9 * 14 / 15), 0.5))
    var two = scene(.rings)
    let both = play(&two, [.typed(slot: m, at: nil), .space(nil)], for: 0.1)
    #expect(Set(both.map { $0.parameter }).count == 1 && both.count >= 16)  // two rings, the same radius
    var other = scene(.rings, on: elsewhere)
    #expect(play(&other, [.typed(slot: m, at: nil)], for: 0.1).isEmpty)
}

@Test func beamsSweepAtTheKeysRowSpaceAlongTheBottomReturnAcross() {
    var s = scene(.beams)
    #expect(play(&s, [.typed(slot: m, at: key("m")), .backspace(nil)], for: 0.2).isEmpty)
    var word = play(&s, [.space(Keyboard.position(of: 0x31))], for: 0.1)
    #expect(word.count == 1 && word[0].kind == .beam && word[0].colour == Sprite.packed(T.accent) && word[0].h == 3)
    #expect(abs(Double(word[0].y) - 0.1 * 982) <= 0.02 * 982 + 1)  // the space bar's row: along the bottom
    #expect(word[0].parameter > 200)  // a bright head
    let x = word[0].x
    word = play(&s, for: 0.3)
    #expect(word[0].x > x)  // sweeping right
    #expect(play(&s, for: 0.7).isEmpty)  // 1 s
    var line = scene(.beams)
    let start = play(&line, [.paragraph(Keyboard.position(of: 0x24))], for: 0.2)[0], later = play(&line, for: 0.4)[0]
    #expect(start.h == 4 && later.x > start.x + 400 && later.w >= start.w)  // across the screen, growing in
    #expect(abs(Double(start.y) - 0.475 * 982) <= 0.02 * 982 + 1)  // Return's row, the home row
    #expect(near(Double(play(&line, for: 1.0 / 60)[0].alpha), 0.45, 0.01))  // the accent at its peak mid-way
    var iso = scene(.beams)
    let tall = play(&iso, [.paragraph(Keyboard.position(of: 0x24, on: .iso))], for: 0.2)[0]
    #expect(abs(Double(tall.y) - (0.85 - 0.75 * 1.5 / 4) * 982) <= 0.02 * 982 + 1)  // ISO's Return, rows 1 and 2
    var other = scene(.beams, on: elsewhere)
    #expect(play(&other, [.space(nil)], for: 0.1).isEmpty && play(&other, [.paragraph(nil)], for: 0.1).count == 1)
}

@Test func gridLightsTheKeysCellsInAKeyboardUnderTheBox() {
    var s = scene(.grid)
    #expect(play(&s, for: 0.5).isEmpty)  // no key yet: no grid
    var out = play(&s, [.typed(slot: m, at: Keyboard.position(of: 0x0C))], for: 0.3)  // Q
    let lines = out.filter { $0.colour == Sprite.packed(T.text) }, lit = out.filter { $0.colour == Sprite.packed(T.accent) }
    let across = Int(screen.width / 32)...Int(screen.width / 32) + 1
    let up = Int(screen.height / 32)...Int(screen.height / 32) + 1
    #expect(across.contains(lines.filter { $0.h > 100 }.count) && up.contains(lines.filter { $0.w > 100 }.count))
    #expect(lines.allSatisfy { near(Double($0.alpha), 0.12, 0.001) } && lit.count == 1)
    var g = Grid(stage: stage, glyphs: glyphs, seed: 1)
    let q = g.centre(row: 1, column: 1)!, space = (4...8).map { g.centre(row: 4, column: $0)! }
    #expect(lit[0].x == Float(q.x) && lit[0].y == Float(q.y) && Double(lit[0].w) == 31)
    #expect(q.y < box.minY - 32 && abs(Double(g.centre(row: 0, column: 7)!.x) - Double(box.midX)) <= 32)  // under the box
    var bar: [Sprite] = []
    g.step(dt: 0.06, events: [.space(Keyboard.position(of: 0x31))], rate: 5, into: &bar)
    let barCells = bar.filter { $0.colour == Sprite.packed(T.accent) }.map { CGPoint(x: Double($0.x), y: Double($0.y)) }
    #expect(barCells == space && near(Double(bar.last!.alpha), 0.6 * (1 - 0.06 / 0.9), 0.01))  // the space bar, lit
    out = play(&s, for: 0.61)
    #expect(out.filter { $0.colour == Sprite.packed(T.accent) }.isEmpty)  // 0.9 s a cell
    var iso = Grid(stage: Ambience.Stage(size: screen, box: box, keyboard: .iso, style: style), glyphs: glyphs, seed: 1)
    var tall: [Sprite] = []
    iso.step(dt: 0.06, events: [.paragraph(Keyboard.position(of: 0x24, on: .iso))], rate: 5, into: &tall)
    #expect(tall.filter { $0.colour == Sprite.packed(T.accent) }.map { CGPoint(x: Double($0.x), y: Double($0.y)) }
        == [iso.centre(row: 1, column: 14)!, iso.centre(row: 2, column: 14)!])
    // A key with no position: a cell near the caret more often, within three cells of the box.
    var picks = scene(.grid, seed: 3), distances: [Double] = []
    let caret = stage.caretPoint
    for _ in 0..<200 {
        let shown = play(&picks, [.typed(slot: m, at: nil)], for: 1.0 / 60).filter { $0.colour == Sprite.packed(T.accent) }
        distances += shown.map { hypot(Double($0.x) - caret.x, Double($0.y) - caret.y) }
        _ = play(&picks, for: 0.9)
    }
    let mean = distances.reduce(0, +) / Double(distances.count)
    #expect(distances.count == 200 && mean < 300)  // the box is 907 pt wide: cells all round it average far more
    var other = scene(.grid, on: elsewhere)
    #expect(play(&other, [.typed(slot: m, at: nil)], for: 0.3).isEmpty)
}

@Test func fireworksBurstAboveTheBoxWhereReturnIs() {
    var s = scene(.fireworks)
    #expect(play(&s, [.typed(slot: m, at: nil), .typed(slot: glyphs.slot("e"), at: nil), .space(nil)], for: 0.2).isEmpty)
    let enter = Keyboard.position(of: 0x24)!, x = Double(box.minX) + Double(box.width) * (0.05 + 0.9 * enter.across)
    var out = play(&s, [.paragraph(enter)], for: 0.1)
    #expect(out.count == 2)
    #expect(out.allSatisfy { near(Double($0.x), x, 0.01) && Double($0.y) >= Double(box.maxY) })  // Return's x
    out = play(&s, for: 0.4)
    #expect(out.count == 3 * T.fireSparks)  // burst: 48 sparks, each with two trailing dots
    let sparks = out.filter { $0.kind == .glyph }
    let recent = [UInt32(m), UInt32(glyphs.slot("e")!)]
    #expect(sparks.count == T.fireSparks / 2 && sparks.allSatisfy { recent.contains($0.parameter) })  // the last typed
    #expect(out.allSatisfy { Double($0.y) > Double(box.maxY) + 80 } && near(Double(sparks[0].alpha), 0.9, 0.05))
    out = play(&s, for: 2)
    #expect(out.isEmpty)
    var caret = scene(.fireworks)
    #expect(near(Double(play(&caret, [.paragraph(nil)], for: 0.1)[0].x), Double(stage.caret), 0.01))  // no position
    var other = scene(.fireworks, on: elsewhere)
    #expect(play(&other, [.paragraph(nil)], for: 0.6).isEmpty)
}

@Test func swarmBubblesRiseFromWhereTheKeyIsWithTheRhythmAndPop() {
    var s = scene(.swarm)
    var out = play(&s, [.typed(slot: m, at: nil)], for: 1.0 / 60)
    #expect(out.count == 1 && out[0].kind == .ring && Double(out[0].y) > Double(box.maxY) && out[0].parameter == 128)
    #expect(abs(Double(out[0].x) - Double(stage.caret)) <= 7)  // no position: at the caret
    let y = out[0].y
    out = play(&s, for: 0.5)
    #expect(out[0].y > y + 10)  // rising
    _ = play(&s, [.paragraph(nil), .space(nil), .backspace(nil)], for: 1.0 / 60)
    #expect(s.count == 4 * 7)  // Return lets five go, Space one, ⌫ none
    var popped = false
    for _ in 0..<258 {
        let ticks = play(&s, for: 1.0 / 60).contains { $0.kind == .rect }
        popped = popped || ticks
    }
    #expect(popped && s.count == 0)  // each popped into its ticks within 4.2 s, then gone
    for x in [0.5, 14.5] {
        var k = scene(.swarm)
        let at = play(&k, [.typed(slot: m, at: column(x))], for: 1.0 / 60)[0].x
        let edge = Double(box.minX) + Double(box.width) * (0.05 + 0.9 * x / 15)
        #expect(abs(Double(at) - min(max(edge, Double(box.minX) + 10), Double(box.maxX) - 10)) <= 7, "\(x)")
    }
    func risen(rate: Double) -> Float {
        var b = scene(.swarm)
        let start = play(&b, [.space(nil)], for: 1.0 / 60, rate: rate)[0].y
        return play(&b, for: 0.5, rate: rate)[0].y - start
    }
    #expect(risen(rate: 10) > risen(rate: 0) + 20)  // faster as you type faster
    var other = scene(.swarm, on: elsewhere)
    #expect(play(&other, [.typed(slot: m, at: nil)], for: 0.2).isEmpty)
}

@Test func everyModeStaysUnderTheCap() {
    var flood: [Event] = []
    let keys = [0x00, 0x0C, 0x12, 0x2E, 0x31, 0x24, 0x33].map { Keyboard.position(of: UInt16($0)) }
    for i in 0..<3000 {
        let leaving = Event.leaving(slot: m, at: CGPoint(x: Double(100 + i % 50), y: 300))
        let at = keys[i % keys.count]
        let end: Event = i % 7 == 0 ? .paragraph(at) : .space(at), back: Event = i % 11 == 0 ? .backspace(at) : .space(nil)
        flood += [.typed(slot: m, at: at), leaving, end, back]
    }
    for mode in Mode.allCases {
        var s = scene(mode)
        for seconds in [0.2, 0.4, 1] {  // Fireworks' bursts come 0.45 s after their Return
            let out = play(&s, seconds == 0.2 ? flood : [], for: seconds)
            #expect(out.count <= T.cap && s.count <= T.cap, "\(mode) \(seconds)")
        }
    }
    var run = Ambience.Run(mode: .rain, stage: stage, glyphs: glyphs, seed: 1), out: [Sprite] = []
    run.take((0..<3000).map { Ambience.Key(t: Double($0) / 1000, kind: .glyph("m"), code: 0x2E) })
    _ = run.frame(at: 3, dt: 1.0 / 60, into: &out)
    #expect(out.count <= T.cap && run.count > T.cap - 10)
}

// MARK: Metal

@Test(.enabled(if: Ambience.Renderer.available)) func theShaderCompilesAndDrawsOneFrameOffscreen() throws {
    let renderer = try #require(Ambience.Renderer(font: menlo))
    #expect(Ambience.Renderer.compileSeconds > 0)
    print("ambience shader compiled in \(Int(Ambience.Renderer.compileSeconds * 1000)) ms")
    let size = CGSize(width: 400, height: 100), accent = T.accent
    let sprites = [
        Sprite(x: 50, y: 50, w: 20, h: 20, alpha: 1, colour: accent, kind: .rect),
        Sprite(x: 150, y: 50, w: 60, h: 60, alpha: 1, colour: T.text, kind: .ring, parameter: Sprite.stroke(2)),
        glyphs.sprite(glyphs.slot("M")!, centre: CGPoint(x: 250, y: 50), alpha: 1, colour: T.text),
        Sprite(x: 350, y: 50, w: 80, h: 4, alpha: 1, colour: accent, kind: .beam, parameter: 255),
    ]
    let px = try #require(renderer.offscreen(sprites, size: size, scale: 2))
    func pixel(_ x: Double, _ y: Double) -> [UInt8] {  // points, origin at the bottom left
        let i = 4 * (Int((size.height - y) * 2) * 800 + Int(x * 2))
        return Array(px[i..<i + 4])
    }
    #expect(pixel(50, 50) == [0xf0, 0xa7, 0x7a, 0xff])  // the accent, opaque, BGRA
    #expect(pixel(2, 2) == [0, 0, 0, 0] && pixel(150, 50) == [0, 0, 0, 0])  // clear around, and inside the ring
    #expect(pixel(179.4, 50)[3] > 200)  // on the ring's 2 pt stroke
    var inked = 0
    for y in stride(from: 30.0, to: 70, by: 0.5) {
        for x in stride(from: 240.0, to: 260, by: 0.5) where pixel(x, y)[3] > 128 { inked += 1 }
    }
    #expect(inked > 100)  // the M from the atlas
    #expect(pixel(389, 50)[3] > pixel(330, 50)[3] && pixel(389, 50)[0] > 0xf0)  // the beam brighter toward its white head
    let half = try #require(renderer.offscreen([sprites[0]], size: size, scale: 2, alpha: 0.5))
    #expect(abs(Int(half[4 * (100 * 800 + 100) + 3]) - 128) <= 1)  // the run's alpha multiplies every sprite
}

/// A dark app under the dim, the ambience's frame `px` over it and the box with `text` on top: what the box's screen
/// shows, 1512 × 982 pt at 2×, written to app/renders/`name`.
private func compose(_ px: [UInt8], text: Text, name: String) throws {
    let (w, h) = (Int(screen.width) * 2, Int(screen.height) * 2)
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    c.setFillColor(rgb(0x24272e))  // a dark app, a few lines of its text
    c.fill(CGRect(origin: .zero, size: screen))
    c.setFillColor(rgb(0x4a505a))
    for (i, length) in [360, 540, 450, 270, 510, 390, 0, 450, 360, 240, 480, 330, 420].enumerated() where length > 0 {
        c.fill(CGRect(x: 48, y: screen.height - 90 - CGFloat(i) * 36, width: CGFloat(length), height: 9))
    }
    c.setFillColor(style.background.copy(alpha: 0.5)!)  // the dim, D1
    c.fill(CGRect(origin: .zero, size: screen))
    let data = try #require(CFDataCreate(nil, px, px.count))
    let image = try #require(CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * w,
                                     space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                     bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue
                                         | CGBitmapInfo.byteOrder32Little.rawValue),
                                     provider: CGDataProvider(data: data)!, decode: nil, shouldInterpolate: false,
                                     intent: .defaultIntent))
    c.draw(image, in: CGRect(origin: .zero, size: screen))
    c.addPath(CGPath(roundedRect: box, cornerWidth: 10, cornerHeight: 10, transform: nil))  // the box, opaque
    c.setFillColor(style.background)
    c.fillPath()
    c.saveGState()
    let line = box.insetBy(dx: 1, dy: 1)
    c.translateBy(x: line.minX, y: line.minY)
    Line.draw(Line.shape(text, marked: "", font: menlo), before: 0, after: 0, in: c,
              band: Line.band(in: line.size, style: style), style: style)
    c.restoreGState()
    c.addPath(CGPath(roundedRect: box.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 9.5, cornerHeight: 9.5, transform: nil))
    c.setStrokeColor(Style.accent)
    c.setLineWidth(1)
    c.strokePath()
    savePNG(c, name, dpi: 144)
}

/// `typed` at `rate` keys a second through a run of `mode`, each key with its US key code; its last frame `after`
/// seconds past the last key, with the text typed.
private func typing(_ typed: [Character], _ mode: Mode, rate: Double, after: Double) -> (out: [Sprite], alpha: Double?, text: Text) {
    var run = Ambience.Run(mode: mode, stage: stage, glyphs: glyphs, seed: 11)
    var text = Text(), out: [Sprite] = [], t = 0.0, alpha: Double?
    for (i, c) in typed.enumerated() {
        let at = Double(i) / rate
        while t < at {  // the frames between the keys
            t += 1.0 / 60
            alpha = run.frame(at: t, dt: 1.0 / 60, into: &out)
        }
        text.insert(String(c))
        let kind: Ambience.Key.Kind = c == "\n" ? .paragraph : c == " " ? .space : .glyph(c)
        run.take([Ambience.Key(t: at, kind: kind, code: us[c], line: Line.shape(text, marked: "", font: menlo),
                               pushed: Double(Line.width(String(c), font: menlo)))])
    }
    let end = Double(typed.count - 1) / rate + after
    while t < end {
        t += 1.0 / 60
        alpha = run.frame(at: t, dt: 1.0 / 60, into: &out)
    }
    return (out, alpha, text)
}

/// Each mode after 10 s of typing at 6 keys a second and 0.6 s after a Return (Fireworks 1 s), drawn by the Metal
/// pipeline over a dimmed dark app with the box on it, as the box's screen shows it: app/renders/ambience-<mode>.png;
/// and the grid after "the quick brown fox" at 20 keys a second, its keyboard lit (ambience-grid-keyboard.png).
@Test(.enabled(if: Ambience.Renderer.available)) func ambienceRenders() throws {
    let renderer = try #require(Ambience.Renderer(font: menlo))
    let words = "the boats sat low in the water and the reeds bent over them"
    for mode in Mode.allCases {
        let r = typing(Array(words) + ["\n"] + Array("as"), mode, rate: 6, after: mode == .fireworks ? 0.67 : 0.27)
        let a = try #require(r.alpha, "\(mode)")
        #expect(!r.out.isEmpty, "\(mode)")
        try compose(try #require(renderer.offscreen(r.out, size: screen, scale: 2, alpha: a)), text: r.text,
                    name: "ambience-\(mode.rawValue).png")
    }
    let fox = typing(Array("the quick brown fox"), .grid, rate: 20, after: 0.05)
    let lit = fox.out.filter { $0.colour == Sprite.packed(T.accent) }
    #expect(lit.count >= 14)  // every letter's cell and the space bar, still lit
    try compose(try #require(renderer.offscreen(fox.out, size: screen, scale: 2, alpha: fox.alpha ?? 1)), text: fox.text,
                name: "ambience-grid-keyboard.png")
}
