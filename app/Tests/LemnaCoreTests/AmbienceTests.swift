// The ambience (DESIGN.md A1): the Ambience submenu's choice (S1), the tuning (I1), the run of a scene from the first
// key to its end (R1), every mode's coupling to typing and the cap, and the Metal pipeline drawing offscreen. No
// Foundation here (see RenderTests.swift).
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

@Test func theTuningIsThePanels() {
    // docs/design-panel-lemna-ambience.html, I1's table and the cards.
    #expect(T.cap == 2000 && T.frameRate == 60 && T.linger == 4 && T.fadeOut == 1)
    #expect(T.driftPeak == 0.35 && T.driftLife == 4 && T.driftIn == 0.3 && T.driftCurrent == 8...40)
    #expect(T.rainHead == 0.3 && T.rainLife == 2.5 && T.rainFall == 150...300 && T.rainTrail == 4...8)
    #expect(T.ringPeak == 0.25 && T.ringWidth == 1 && T.ringLife == 1.5 && T.ringReach == 400)
    #expect(T.beamPeak == 0.18 && T.beamHead == 0.55)
    #expect(T.gridCell == 24 && T.gridLines == 0.06 && T.gridLit == 0.2 && T.gridLife == 0.6 && T.gridReach == 3)
    // C1: the box's text and accent.
    func hex(_ c: CGColor) -> UInt32 {
        c.components!.prefix(3).reduce(0) { $0 << 8 | UInt32(($1 * 255).rounded()) }
    }
    #expect(T.text == hex(style.text) && T.accent == hex(Style.accent))
}

@Test func aSpriteIsThe32BytesTheShaderReads() {
    #expect(MemoryLayout<Sprite>.size == 32 && MemoryLayout<Sprite>.stride == 32)
    #expect(Sprite.packed(0x7aa7f0) == 0xfff0_a77a)  // red in the low byte, as unpack_unorm4x8 reads it
    let s = Sprite(x: 1, y: 2, w: 3, h: 4, alpha: 1.5, colour: 0xffffff, kind: .arc, parameter: Sprite.stroke(1))
    #expect(s.kind == .arc && s.parameter == 64 && s.alpha == 1)  // alpha clamped
}

@Test func theStageIsTheLinesGeometryInTheBox() {
    let line = box.insetBy(dx: 1, dy: 1)  // inside the border
    #expect(stage.band == Line.band(in: line.size, style: style).offsetBy(dx: line.minX, dy: line.minY))
    #expect(stage.caret == stage.band.minX + 0.6 * stage.band.width)
    #expect(stage.band.minY > box.minY && stage.band.maxY < box.maxY && stage.baseline > stage.band.minY)
    #expect(elsewhere.box == nil)
    #expect(glyphs.ids.count > 150 && glyphs.slot("é") != nil && glyphs.slot("„") != nil && glyphs.letters.count == 26)
    #expect(glyphs.cell.width >= Line.width("M", font: menlo) && glyphs.cell.height >= 28)
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
    #expect(run.frame(at: 10, dt: 1.0 / 60, into: &out) == 1 && out.count == 8)  // one ring
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

@Test func aGlyphPushedPastTheBoxsLeftEdgeLeaves() {
    // 60 letters, the caret at their end: about 32 fit between the caret and the band's left edge.
    let letters = String(repeating: "abcdefghijklmnopqrstuvwxyz", count: 3).prefix(60)
    let line = Line.shape(Text(String(letters)), marked: "", font: menlo), a = Double(advance)
    var run = Ambience.Run(mode: .drift, stage: stage, glyphs: glyphs, seed: 1)
    run.take([Ambience.Key(t: 0, kind: .glyph("h"), line: line, pushed: a)])
    let leaving = run.events.compactMap { e -> (Int, CGPoint)? in if case .leaving(let s, let p) = e { (s, p) } else { nil } }
    #expect(leaving.count == 1 && run.events.last == .typed(slot: glyphs.slot("h")))
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
    #expect(deleting.events == [.backspace] && other.events == [.typed(slot: glyphs.slot("h"))])  // none leaves
    var short = Ambience.Run(mode: .drift, stage: stage, glyphs: glyphs, seed: 1)
    short.take([Ambience.Key(t: 0, kind: .glyph("c"), line: Line.shape(Text("abc"), marked: "", font: menlo), pushed: a)])
    #expect(short.events.count == 1)  // a short line: nothing reaches the edge
}

// MARK: The modes

@Test func driftCarriesTheLeavingGlyphsLeftOnTheRatesCurrentAndFadesThem() {
    let p = CGPoint(x: 200, y: 300), leaf = [Event.leaving(slot: m, at: p)]
    var s = scene(.drift)
    var out = play(&s, leaf + leaf + leaf + [.typed(slot: m), .space], for: 1.0 / 60)
    #expect(s.count == 3)
    #expect(out.allSatisfy { $0.kind == .glyph && $0.parameter == UInt32(m) && $0.colour == Sprite.packed(T.text) })
    #expect(out[0].alpha < 0.05)  // fading in
    out = play(&s, for: 0.3 - 1.0 / 60)
    #expect(near(Double(out[0].alpha), 0.35, 0.01))  // its peak at 0.3 s
    out = play(&s, for: 1.85)
    #expect(near(Double(out[0].alpha), 0.175, 0.01))  // halfway down at 2.15 s
    out = play(&s, for: 1.9)
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
    #expect(play(&none, [.typed(slot: m), .space, .paragraph, .backspace], for: 0.5).isEmpty)  // only what leaves
}

@Test func rainDropsOneColumnPerGlyphKeyItsHeadTheTypedGlyph() {
    var s = scene(.rain)
    var out = play(&s, [.typed(slot: m), .space, .paragraph, .backspace], for: 1.0 / 60)
    #expect((5...9).contains(s.count) && out.count == 1)  // one drop; its trail grows as it falls
    out = play(&s, for: 0.5)
    let head = out[0]
    #expect(head.kind == .glyph && head.parameter == UInt32(m) && head.colour == Sprite.packed(T.accent))
    #expect(near(Double(head.alpha), 0.3, 0.001) && out.count > 1 && out.count <= s.count)  // the trail as far as it fell
    let trail = out.dropFirst()
    #expect(trail.allSatisfy { $0.colour == Sprite.packed(T.text) && $0.x == head.x && $0.y > head.y })
    #expect(zip(trail, trail.dropFirst()).allSatisfy { near(Double($1.alpha / $0.alpha), 0.6, 0.001) })  // fainter upward
    out = play(&s, for: 2)
    #expect(s.count == 0 && out.isEmpty)  // 2.5 s a drop
    var other = scene(.rain, on: elsewhere)
    #expect(!play(&other, [.typed(slot: nil)], for: 0.3).isEmpty)  // every screen; an unknown glyph rains a letter
    var many = scene(.rain)
    _ = play(&many, Array(repeating: .typed(slot: m), count: 50), for: 1.0 / 60)
    #expect(many.count >= 250)  // the density is the keys'
}

@Test func ringsGoOutFromTheBoxOnEachKeyAndInOnBackspace() {
    /// How far a ring's top side stands above the box.
    func grown(_ out: [Sprite]) -> Double { Double(out[1].y) - Double(box.maxY) }
    var s = scene(.rings)
    var out = play(&s, [.typed(slot: m)], for: 1.0 / 60)
    #expect(out.count == 8 && out.filter { $0.kind == .arc }.count == 4 && near(Double(out[0].alpha), 0.25, 0.01))
    let early = grown(out)
    out = play(&s, for: 0.5)
    #expect(grown(out) > early && grown(out) > 300 && out[0].alpha < 0.25)  // out on the curve, fading
    #expect(out.filter { $0.kind == .arc }.allSatisfy { $0.parameter == 64 })  // 1 pt
    out = play(&s, for: 1)
    #expect(out.isEmpty)
    var back = scene(.rings)
    let far = grown(play(&back, [.backspace], for: 1.0 / 60)), close = grown(play(&back, for: 0.5))
    #expect(far > 140 && close < far)  // inward, onto the box
    var two = scene(.rings)
    #expect(play(&two, [.typed(slot: m), .space], for: 0.1).count == 16)
    var other = scene(.rings, on: elsewhere)
    #expect(play(&other, [.typed(slot: m)], for: 0.1).isEmpty)
}

@Test func beamsSweepBesideTheBoxOnSpaceAndAcrossOnReturn() {
    var s = scene(.beams)
    #expect(play(&s, [.typed(slot: m), .backspace], for: 0.2).isEmpty)
    var word = play(&s, [.space], for: 0.1)
    #expect(word.count == 1 && word[0].kind == .beam && word[0].colour == Sprite.packed(T.accent))
    let y = Double(word[0].y), gap = min(abs(y - Double(box.maxY)), abs(y - Double(box.minY)))
    #expect(gap >= 10 && gap <= 70 && word[0].h == 2)
    let x = word[0].x
    word = play(&s, for: 0.2)
    #expect(word[0].x > x)  // sweeping right
    #expect(play(&s, for: 0.3).isEmpty)
    var line = scene(.beams)
    let start = play(&line, [.paragraph], for: 0.2)[0], later = play(&line, for: 0.4)[0]
    #expect(start.h == 3 && later.x > start.x + 500 && later.w > start.w)  // across the screen, growing in
    #expect(near(Double(play(&line, for: 1.0 / 60)[0].alpha), 0.18, 0.01))  // the accent at its peak mid-way
    var other = scene(.beams, on: elsewhere)
    #expect(play(&other, [.space], for: 0.1).isEmpty && play(&other, [.paragraph], for: 0.1).count == 1)
}

@Test func gridShowsWhileTypingAndLightsCellsNearTheCaretMoreOften() {
    var s = scene(.grid)
    #expect(play(&s, for: 0.5).isEmpty)  // no key yet: no grid
    var out = play(&s, [.typed(slot: m)], for: 0.3)
    let lines = out.filter { $0.colour == Sprite.packed(T.text) }, lit = out.filter { $0.colour == Sprite.packed(T.accent) }
    let across = Int(screen.width / 24)...Int(screen.width / 24) + 1
    let up = Int(screen.height / 24)...Int(screen.height / 24) + 1
    #expect(across.contains(lines.filter { $0.h > 100 }.count) && up.contains(lines.filter { $0.w > 100 }.count))
    #expect(lines.allSatisfy { near(Double($0.alpha), 0.06, 0.001) } && lit.count == 1)
    /// How many cells from the box a cell's centre is.
    func reach(_ c: Sprite) -> Double {
        let dx = max(Double(box.minX) - Double(c.x), Double(c.x) - Double(box.maxX), 0)
        let dy = max(Double(box.minY) - Double(c.y), Double(c.y) - Double(box.maxY), 0)
        return max(dx, dy) / 24
    }
    #expect(reach(lit[0]) > 0 && reach(lit[0]) < 3)  // outside the box, within three cells of it
    out = play(&s, for: 0.31)
    #expect(out.filter { $0.colour == Sprite.packed(T.accent) }.isEmpty)  // 0.6 s a cell
    // Over many keys the lit cells sit nearer the caret than the cells around the box on average.
    var picks = scene(.grid, seed: 3), distances: [Double] = []
    let caret = stage.caretPoint
    for _ in 0..<200 {
        let shown = play(&picks, [.typed(slot: m)], for: 1.0 / 60).filter { $0.colour == Sprite.packed(T.accent) }
        distances += shown.map { hypot(Double($0.x) - caret.x, Double($0.y) - caret.y) }
        _ = play(&picks, for: 0.6)
    }
    let mean = distances.reduce(0, +) / Double(distances.count)
    #expect(distances.count == 200 && mean < 250)  // the box is 907 pt wide: cells all round it average far more
    var other = scene(.grid, on: elsewhere)
    #expect(play(&other, [.typed(slot: m)], for: 0.3).isEmpty)
}

@Test func fireworksBurstAboveTheCaretOnReturn() {
    var s = scene(.fireworks)
    #expect(play(&s, [.typed(slot: m), .typed(slot: glyphs.slot("e")), .space], for: 0.2).isEmpty)
    var out = play(&s, [.paragraph], for: 0.1)
    #expect(out.count == 2)
    #expect(out.allSatisfy { near(Double($0.x), Double(stage.caret), 0.01) && Double($0.y) >= Double(box.maxY) })
    out = play(&s, for: 0.4)
    #expect(out.count == 3 * T.fireSparks)  // burst
    let sparks = out.filter { $0.kind == .glyph }
    let recent = [UInt32(m), UInt32(glyphs.slot("e")!)]
    #expect(sparks.count == T.fireSparks / 2 && sparks.allSatisfy { recent.contains($0.parameter) })  // the last typed
    #expect(out.allSatisfy { Double($0.y) > Double(box.maxY) + 60 })  // above the box
    out = play(&s, for: 1.6)
    #expect(out.isEmpty)
    var other = scene(.fireworks, on: elsewhere)
    #expect(play(&other, [.paragraph], for: 0.6).isEmpty)
}

@Test func swarmBubblesRiseFromTheBoxWithTheRhythmAndPop() {
    var s = scene(.swarm)
    var out = play(&s, [.typed(slot: m)], for: 1.0 / 60)
    #expect(out.count == 1 && out[0].kind == .ring && Double(out[0].y) > Double(box.maxY))
    let y = out[0].y
    out = play(&s, for: 0.5)
    #expect(out[0].y > y + 10)  // rising
    _ = play(&s, [.paragraph, .space, .backspace], for: 1.0 / 60)
    #expect(s.count == 4 * 7)  // Return lets five go, Space one, ⌫ none
    var popped = false
    for _ in 0..<258 {
        let ticks = play(&s, for: 1.0 / 60).contains { $0.kind == .rect }
        popped = popped || ticks
    }
    #expect(popped && s.count == 0)  // each popped into its ticks within 4.2 s, then gone
    func risen(rate: Double) -> Float {
        var b = scene(.swarm)
        let start = play(&b, [.space], for: 1.0 / 60, rate: rate)[0].y
        return play(&b, for: 0.5, rate: rate)[0].y - start
    }
    #expect(risen(rate: 10) > risen(rate: 0) + 20)  // faster as you type faster
    var other = scene(.swarm, on: elsewhere)
    #expect(play(&other, [.typed(slot: m)], for: 0.2).isEmpty)
}

@Test func everyModeStaysUnderTheCap() {
    var flood: [Event] = []
    for i in 0..<3000 {
        let leaving = Event.leaving(slot: m, at: CGPoint(x: Double(100 + i % 50), y: 300))
        let end: Event = i % 7 == 0 ? .paragraph : .space, back: Event = i % 11 == 0 ? .backspace : .space
        flood += [.typed(slot: m), leaving, end, back]
    }
    for mode in Mode.allCases {
        var s = scene(mode)
        for seconds in [0.2, 0.4, 1] {  // Fireworks' bursts come 0.45 s after their Return
            let out = play(&s, seconds == 0.2 ? flood : [], for: seconds)
            #expect(out.count <= T.cap && s.count <= T.cap, "\(mode) \(seconds)")
        }
    }
    var run = Ambience.Run(mode: .rain, stage: stage, glyphs: glyphs, seed: 1), out: [Sprite] = []
    run.take((0..<3000).map { Ambience.Key(t: Double($0) / 1000, kind: .glyph("m")) })
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

/// Each mode after 10 s of typing at 6 keys a second and 0.6 s after a Return (Fireworks 1 s), drawn by the Metal
/// pipeline over a dimmed dark app with the box on it, as the box's screen shows it: app/renders/ambience-<mode>.png,
/// 1512 × 982 pt at 2×, for a look by eye.
@Test(.enabled(if: Ambience.Renderer.available)) func ambienceRenders() throws {
    let renderer = try #require(Ambience.Renderer(font: menlo))
    let words = "the boats sat low in the water and the reeds bent over them"
    let typed = Array(words) + ["\n"] + Array("as")
    for mode in Mode.allCases {
        var run = Ambience.Run(mode: mode, stage: stage, glyphs: glyphs, seed: 11)
        var text = Text(), out: [Sprite] = [], t = 0.0, alpha: Double?
        for (i, c) in typed.enumerated() {
            let key = Double(i) / 6
            while t < key {  // the frames between the keys
                t += 1.0 / 60
                alpha = run.frame(at: t, dt: 1.0 / 60, into: &out)
            }
            text.insert(String(c))
            let kind: Ambience.Key.Kind = c == "\n" ? .paragraph : c == " " ? .space : .glyph(c)
            run.take([Ambience.Key(t: key, kind: kind, line: Line.shape(text, marked: "", font: menlo),
                                   pushed: Double(Line.width(String(c), font: menlo)))])
        }
        let end = Double(words.count) / 6 + (mode == .fireworks ? 1.0 : 0.6)  // after the Return
        while t < end {
            t += 1.0 / 60
            alpha = run.frame(at: t, dt: 1.0 / 60, into: &out)
        }
        let a = try #require(alpha, "\(mode)")
        #expect(!out.isEmpty, "\(mode)")
        let px = try #require(renderer.offscreen(out, size: screen, scale: 2, alpha: a))
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
        let outline = CGPath(roundedRect: box, cornerWidth: 10, cornerHeight: 10, transform: nil)
        c.addPath(outline)  // the box: opaque, the line in it, its accent border
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
        savePNG(c, "ambience-\(mode.rawValue).png", dpi: 144)
    }
}
