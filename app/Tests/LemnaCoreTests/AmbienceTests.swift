// The ambience (DESIGN.md A1): the Ambience submenu's choice (S1), the tuning (I1, raised in pass 16), the run of a
// scene and its close (R1), Rain's coupling to typing and, since pass 16, to where the key is on the keyboard, Still
// water's drops at rest that no key feeds (pass 24), the cap, and the Metal pipeline drawing offscreen. No Foundation
// here (see RenderTests.swift).
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
/// The scenes' colours: Lemna's ink (C1, TH1).
private let ink = stage.ink

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
    #expect(Mode.allCases.map(\.title) == ["Rain", "Still water"])  // pass 18 and pass 24 (RM1) removed six
    for mode in Mode.allCases {
        #expect(Ambience(kept: Ambience(mode).kept) == Ambience(mode) && Ambience(mode).kept == mode.rawValue)
    }
    #expect(Ambience(kept: nil) == Ambience() && Ambience(kept: "off") == Ambience() && Ambience(.water).kept == "water")
    // M8, never built, or a mode removed in pass 18 or in pass 24: Off.
    for gone in ["burn", "beams", "fireworks", "swarm", "drift", "rings", "grid"] {
        #expect(Ambience(kept: gone) == Ambience() && Ambience(kept: gone).playing(reduceMotion: false) == nil)
    }
    var a = Ambience()
    a.choose(.rain)
    #expect(a.mode == .rain && a.playing(reduceMotion: false) == .rain)
    a.choose(nil)
    #expect(a == Ambience())
    #expect(Mode.allCases.filter(\.everyScreen) == [.rain])  // Still water stays on the box's screen
    #expect(Mode.allCases.filter(\.ambient) == [.rain, .water])  // from the show to the close (pass 19b, I1; pass 24)
}

@Test func reduceMotionForcesOffAndKeepsThePick() {
    let a = Ambience(.water)
    #expect(a.playing(reduceMotion: true) == nil && a.playing(reduceMotion: false) == .water)
    #expect(!Ambience.available(reduceMotion: true) && Ambience.available(reduceMotion: false))
    #expect(a.mode == .water && a.kept == "water")  // kept: Reduce Motion off again, it plays again
}

@Test func theAmbienceTuningIsPlainToSee() {
    // Pass 16 (the user: "The ambience effects are way too subtle"); pass 15's, the panel's, in the comments.
    #expect(T.cap == 2000 && T.frameRate == 60 && T.linger == 4 && T.fadeOut == 1)
    // Rain since pass 19b (matrix §6.2), each pair (idle, typing); pass 16's head 0.8, trail from 0.55, 3 s, 1.0.
    #expect(T.rainScale == 0.5 && T.rainPitch == 1 && T.rainActive == (0.3, 0.7) && T.rainGap == (3, 2))
    #expect(T.rainSpeed == (5...10, 15...30) && T.rainTrail == (6...18, 10...30))
    #expect(T.rainHead == (0.35, 0.85) && T.rainTrailTop == (0.2, 0.5) && T.rainChange == (0.3, 1.5))
    #expect(T.rainKeyHead == 0.95 && T.rainKeyTrailTop == 0.55 && T.rainKeyTrail == 8...20)
    #expect(T.rainFast == 6 && T.rainRise == 0.25 && T.rainSettle == 1.2 && T.rainHold == 0.8 && T.rainIdleRate == 30)
    // Still water (pass 24), look §5.3's Ripples: 0.12 drops a second a screen, 48 pt clear of the box, one at the
    // show; 3 crests from 36 pt/s, the calm centre at 0.7 of it; 1.2–2 pt, ±40 ms; troughs 3 pt in at 0.4; up over
    // 180 ms, e^(−t/1.4 s) · √(12 pt / r), under 0.01 not drawn, 4.5 s a drop; 24 drops; 30 Hz.
    #expect(T.waterRate == 0.12 && T.waterClear == 48 && T.waterSummon == 48 && T.waterDrops == 24)
    #expect(T.waterCrests == 3 && T.waterSpeed == 36 && T.waterSpread == 0.15 && T.waterJitter == 0.15)
    #expect(T.waterWidth == 1.2...2 && T.waterStart == 0.04 && T.waterTrough == 3 && T.waterTroughShare == 0.4)
    #expect(T.waterOnset == 0.18 && T.waterDecay == 1.4 && T.waterNear == 12 && T.waterShown == 0.01)
    #expect(T.waterPeak == (0.27, 0.14))  // times Still's ink alphas 0.6 and 0.5: look §5.3's 0.16 and 0.07 on screen
    #expect(T.waterLife == 4.5 && T.waterFrameRate == 30 && near(1 - T.waterSpread * 2, 0.7, 1e-12))
    // C1: Lemna's ink is the box's text and accent, added (Rain's C2 the same two, the other way round); every stage
    // carries its theme's (TH1).
    let lemna = Theme.lemna.night
    #expect(ink == Theme.Ink(text: lemna.text, accent: lemna.accent, blend: .add, alpha: 1) && elsewhere.ink == ink)
}

@Test func aSpriteIsThe32BytesTheShaderReads() {
    #expect(MemoryLayout<Sprite>.size == 32 && MemoryLayout<Sprite>.stride == 32)
    #expect(Sprite.packed(0x7aa7f0) == 0xfff0_a77a)  // red in the low byte, as unpack_unorm4x8 reads it
    let s = Sprite(x: 1, y: 2, w: 3, h: 4, alpha: 1.5, colour: 0xffffff, kind: .ring, parameter: 64)
    #expect(s.kind == .ring && s.parameter == 64 && s.alpha == 1 && s.shape == 1 | 64 << 8)  // alpha clamped
    let b = Sprite.ring(radius: 1234.5, width: 2)  // half points and sixteenths
    #expect(b & 0x3fff == 2469 && b >> 14 == 32 && Sprite.ring(radius: 99_999, width: 99) == 0x3fff | 1023 << 14)
    let ring = Sprite.ring(x: 10, y: 20, radius: 30, width: 1.5, alpha: 0.2, colour: 0xc9d3c4)  // its square
    #expect(ring.w == 66 && ring.h == 66 && ring.kind == .ring && ring.parameter == Sprite.ring(radius: 30, width: 1.5))
}

@Test func theStageIsTheLinesGeometryInTheBox() {
    let line = box.insetBy(dx: 1, dy: 1)  // inside the border
    #expect(stage.band == Line.band(in: line.size, style: style).offsetBy(dx: line.minX, dy: line.minY))
    #expect(stage.caret == stage.band.minX + 0.6 * stage.band.width)
    #expect(stage.band.minY > box.minY && stage.band.maxY < box.maxY)
    #expect(elsewhere.box == nil && stage.keyboard == .ansi)
    #expect(glyphs.ids.count > 150 && glyphs.slot("é") != nil && glyphs.slot("„") != nil && glyphs.letters.count == 26)
    #expect(glyphs.rainSet == Array("012345789Zz:.\"=*+-<>|_").map { glyphs.slot($0)! })  // K1, pass 19b
    #expect(glyphs.cell.width >= Line.width("M", font: menlo) && glyphs.cell.height >= 28)
    // Where a key is: across the screen from a tenth to nine tenths.
    #expect(near(stage.screenX(column(0))!, 151.2, 1e-6) && near(stage.screenX(column(15))!, 1360.8, 1e-6))
    #expect(stage.screenX(nil) == nil)
}

// MARK: The run

@Test func typingRateCountsTheLastTwoSeconds() {
    var typing = Ambience.Typing()
    for i in 0..<15 { typing.key(at: Double(i) * 0.2) }  // 5 keys a second for 3 s
    #expect(near(typing.rate(at: 2.85), 5, 0.01))
    #expect(typing.rate(at: 6) == 0)
}

@Test func aRunFadesOutOverItsCloseOnTheCurve() {
    // Every mode left plays from the show (pass 24 removed the ones that lingered 4 s after the last key): the close
    // fades it with the dim, on its curve (pass 18; evenly before), or ends it at once.
    var closed = Ambience.Run(mode: .water, stage: stage, glyphs: glyphs, seed: 1)
    var out: [Sprite] = []
    #expect(closed.frame(at: 0, dt: 1.0 / 30, into: &out) == 1 && !out.isEmpty && out.allSatisfy { $0.kind == .ring })
    closed.close(at: 1, over: 0.2)
    #expect(near(closed.alpha(at: 1.1), 1 - Curve.easeOutQuint(0.5), 1e-9) && closed.alpha(at: 1.1) < 0.04)
    #expect(closed.alpha(at: 1 + 1.0 / 60) > 0.6 && closed.frame(at: 1.21, dt: 0.1, into: &out) == nil)
    var atOnce = Ambience.Run(mode: .water, stage: stage, glyphs: glyphs, seed: 1)
    atOnce.close(at: 1, over: 0)
    #expect(atOnce.alpha(at: 1) == 0)
}

@Test func anAmbientRunPlaysWithoutKeysUntilTheClose() {
    // Rain (pass 19b, I1): from its first frame, no key needed, and no end 4 s after the last; the close as any mode's.
    var run = Ambience.Run(mode: .rain, stage: stage, glyphs: glyphs, seed: 1)
    var out: [Sprite] = []
    #expect(run.frame(at: 0, dt: 1.0 / 30, into: &out) == 1 && out.count > 100)
    run.take([Ambience.Key(t: 1, kind: .glyph("a"))])
    #expect(run.alpha(at: 5) == 1 && run.alpha(at: 600) == 1 && run.frame(at: 600, dt: 1.0 / 30, into: &out) == 1)
    run.close(at: 601, over: 0.2)
    #expect(near(run.alpha(at: 601.1), 1 - Curve.easeOutQuint(0.5), 1e-9) && run.frame(at: 601.21, dt: 0.1, into: &out) == nil)
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

// MARK: The modes

/// Rain (pass 19b) stepped `seconds` at `hz`, `events` in the first step, at `rate` keys a second; its last sprites.
private func fall(_ r: inout Rain, _ events: [Event] = [], for seconds: Double, rate: Double = 0,
                  hz: Double = 60) -> [Sprite] {
    var out: [Sprite] = []
    for f in 0..<max(Int((seconds * hz).rounded()), 1) {
        out.removeAll()
        r.step(dt: 1 / hz, events: f == 0 ? events : [], rate: rate, into: &out)
    }
    return out
}

/// A Rain sprite's cell on `r`'s grid, or nil off it: column and row (0 at the top).
private func cell(_ s: Sprite, on r: Rain, _ st: Ambience.Stage = stage) -> (c: Int, r: Int)? {
    let left = (Double(st.size.width) - Double(r.columns) * r.pitch) / 2
    let c = (Double(s.x) - left) / r.pitch - 0.5, row = (Double(st.size.height) - Double(s.y)) / r.pitch - 0.5
    guard near(c, c.rounded(), 1e-3), near(row, row.rounded(), 1e-3) else { return nil }
    return (Int(c.rounded()), Int(row.rounded()))
}

@Test func rainIsAFixedGridOfTheFilmsGlyphsFallingFromItsFirstFrame() {
    var r = Rain(stage: stage, glyphs: glyphs, seed: 7)
    #expect(near(r.pitch, 18.5, 0.01) && r.columns == 81 && r.rows == 54)  // 14 pt glyphs on 18.5 pt, 1512 × 982
    #expect(glyphs.rainSet.count == 22 && glyphs.rainSet.map { glyphs.ids[$0] }.count == 22)
    var out = fall(&r, for: 1.0 / 30, hz: 30)
    // Born mid-rain (stepped ahead at rest): spread over the screen's whole height and width at once.
    let cells = out.compactMap { cell($0, on: r) }
    #expect(out.count > 100 && cells.count == out.count)
    #expect(Set(cells.map(\.c)).count > 15 && cells.contains { $0.r < 10 } && cells.contains { $0.r > 44 })
    #expect(out.allSatisfy { glyphs.rainSet.contains(Int($0.parameter)) && $0.kind == .glyph })  // K1, no key yet
    #expect(out.allSatisfy { near(Double($0.h), 18.5, 0.01) && near(Double($0.w), Double(glyphs.cell.width) / 2, 0.01) })
    let heads = out.filter { $0.colour == Sprite.packed(ink.text) }, trail = out.filter { $0.colour == Sprite.packed(ink.accent) }
    #expect(!heads.isEmpty && heads.allSatisfy { near(Double($0.alpha), 0.35, 1e-3) })  // C2: the head pale, the trail blue
    #expect(heads.count + trail.count == out.count && trail.allSatisfy { $0.alpha <= 0.2 + 1e-4 && $0.alpha > 0.02 })
    // About 30 % of the columns falling at rest (0.3 heads a column on average, about a quarter showing one; about
    // 200 of the 4,374 cells lit).
    let falling = Set(trail.map { cell($0, on: r)!.c }).count
    #expect((12...40).contains(falling) && (100...500).contains(out.count), "\(falling) columns, \(out.count) sprites")
    // The cells never move: a minute of steps, every sprite on the grid.
    for _ in 0..<60 {
        out = fall(&r, for: 0.5)
        #expect(out.allSatisfy { cell($0, on: r) != nil })
    }
    #expect(r.frameRate == 30)  // at rest, 30 Hz
}

@Test func aKeysHeadStepsACellATimeAndItsTrailDimsInPlace() {
    var r = Rain(stage: stage, glyphs: glyphs, seed: 7)
    var out = fall(&r, [.typed(slot: m, at: column(7.5))], for: 1.0 / 60)
    #expect(r.frameRate == 60)  // a key: 60 Hz
    let first = out.first { $0.parameter == UInt32(m) }!, start = cell(first, on: r)!
    #expect(first.colour == Sprite.packed(ink.text) && near(Double(first.alpha), 0.95, 1e-3))  // the typed glyph, pale
    var rows = [start.r], alphas: [Float] = []
    for _ in 0..<90 {  // 1.5 s at 60 Hz
        out = fall(&r, for: 1.0 / 60)
        let head = out.filter { $0.parameter == UInt32(m) }
        #expect(head.count == 1 && cell(head[0], on: r)!.c == start.c)  // its column
        rows.append(cell(head[0], on: r)!.r)
        if let left = out.first(where: { cell($0, on: r)! == start }), rows.last! > start.r {
            #expect(left.colour == Sprite.packed(ink.accent) && glyphs.rainSet.contains(Int(left.parameter)))
            alphas.append(left.alpha)  // the cell it left, where it was
        }
    }
    #expect(zip(rows, rows.dropFirst()).allSatisfy { $1 - $0 == 0 || $1 - $0 == 1 })  // a cell a step, no slide
    #expect((7...16).contains(rows.last! - start.r))  // 5–10 rows a second at rest, for 1.5 s
    // Its trail dims in place, linearly, from the key's 0.55: an equal step a frame until it is gone.
    #expect(alphas.count > 10 && alphas[0] <= 0.55 && alphas[0] > 0.45)
    let steps = zip(alphas, alphas.dropFirst()).map { Double($0 - $1) }
    #expect(steps.allSatisfy { $0 > 0 && near($0, steps[0], 2e-4) }, "\(steps)")
}

@Test func everyLitGlyphChangesInPlaceFasterWhenTyping() {
    /// Changes a lit-cell second, over `seconds`: a cell still dimming from one step to the next with another glyph.
    func changes(_ r: inout Rain, rate: Double, for seconds: Double) -> Double {
        var last: [Int: (slot: UInt32, alpha: Float)] = [:], changed = 0, seen = 0
        for _ in 0..<Int(seconds * 60) {
            var now: [Int: (slot: UInt32, alpha: Float)] = [:]
            for s in fall(&r, for: 1.0 / 60, rate: rate) where s.colour == Sprite.packed(ink.accent) {
                let c = cell(s, on: r)!, key = c.c * 1000 + c.r
                now[key] = (s.parameter, s.alpha)
                if let before = last[key], before.alpha > s.alpha {
                    seen += 1
                    if before.slot != s.parameter { changed += 1 }
                }
            }
            last = now
        }
        return Double(changed) / (Double(seen) / 60)
    }
    var r = Rain(stage: stage, glyphs: glyphs, seed: 5)
    let rest = changes(&r, rate: 0, for: 6)
    _ = fall(&r, for: 2, rate: 6)
    let typing = changes(&r, rate: 6, for: 4)
    // 0.3 and 1.5 a second (a twenty-second of the picks land on the glyph that was there).
    #expect(near(rest, 0.3 * 21 / 22, 0.07) && near(typing, 1.5 * 21 / 22, 0.25), "\(rest) \(typing)")
}

@Test func aKeyStartsAHeadWhereTheKeyIsTheTypedGlyphAtIt() {
    func head(_ k: Keyboard.Position?, on st: Ambience.Stage = stage) -> Sprite {
        var r = Rain(stage: st, glyphs: glyphs, seed: 3)
        return fall(&r, [.typed(slot: m, at: k)], for: 1.0 / 60).first { $0.parameter == UInt32(m) }!
    }
    // The left end of the keyboard a tenth across the screen, the right end nine tenths, anywhere on the key, on a
    // column; the number row starts higher than the bottom letter row.
    let within = 0.4 * 1512 * 0.8 / 15 + 18.5
    #expect(abs(Double(head(column(0.5)).x) - 1512 * (0.1 + 0.8 * 0.5 / 15)) <= within)
    #expect(abs(Double(head(column(14.5)).x) - 1512 * (0.1 + 0.8 * 14.5 / 15)) <= within)
    #expect(head(column(5, row: 0)).y > head(column(5, row: 3)).y + 150)
    #expect(abs(Double(head(nil).x) - Double(stage.caret)) <= 18.5)  // no position: at the caret
    #expect(abs(Double(head(column(14.5), on: elsewhere).x) - 1512 * (0.1 + 0.8 * 14.5 / 15)) <= within)  // every screen
    var again = Rain(stage: stage, glyphs: glyphs, seed: 3), xs = Set<Float>()  // one key typed again and again
    for _ in 0..<20 {
        xs.formUnion(fall(&again, [.typed(slot: m, at: column(7.5))], for: 1.0 / 60).filter { $0.parameter == UInt32(m) }.map(\.x))
    }
    #expect(xs.count >= 3 && xs.allSatisfy { abs(Double($0) - 1512 * 0.5) <= within })  // spread over the key
    // Its trail from 0.55, above the rest's 0.2; Space, Return and ⌫ start none.
    var r = Rain(stage: stage, glyphs: glyphs, seed: 3)
    let trail = fall(&r, [.typed(slot: m, at: column(7.5))], for: 0.5).filter { $0.colour == Sprite.packed(ink.accent) }
    #expect(trail.contains { $0.alpha > 0.4 })
    var quiet = Rain(stage: stage, glyphs: glyphs, seed: 3)
    let none = fall(&quiet, [.space(column(6.75, row: 4)), .paragraph(nil), .backspace(column(14, row: 0))], for: 0.5)
    #expect(none.allSatisfy { $0.alpha <= 0.35 + 1e-3 })  // nothing at a key's 0.95 or 0.55
}

@Test func typingRaisesTheRainAndAPauseSettlesIt() {
    var r = Rain(stage: stage, glyphs: glyphs, seed: 9)
    #expect(r.intensity == 0)
    _ = fall(&r, [.space(nil)], for: 0.25, rate: 6)  // 6 keys a second (I* 1): up with τ 0.25 s
    #expect(near(r.intensity, 1 - exp(-1), 0.005))
    _ = fall(&r, [.space(nil)], for: 1.0 / 60, rate: 0)  // the last key, and the window empty: it holds 0.8 s
    let held = r.intensity
    _ = fall(&r, for: 0.78, rate: 0)
    #expect(r.intensity == held && r.frameRate == 60)
    _ = fall(&r, for: 1.22, rate: 0)  // then down with τ 1.2 s
    #expect(near(r.intensity, held * exp(-1), 0.01))
    _ = fall(&r, for: 3, rate: 0)
    #expect(r.intensity < 0.05 && r.frameRate == 30)  // at rest again: 30 Hz
    // Every magnitude between its rest and its typing value: brighter, faster, denser.
    var calm = Rain(stage: stage, glyphs: glyphs, seed: 9), busy = Rain(stage: stage, glyphs: glyphs, seed: 9)
    let a = fall(&calm, for: 4), b = fall(&busy, for: 4, rate: 6)
    #expect(near(busy.intensity, 1, 0.01) && b.count > 2 * a.count)
    #expect(b.filter { $0.colour == Sprite.packed(ink.text) }.allSatisfy { near(Double($0.alpha), 0.85, 0.01) })
    #expect(b.contains { $0.colour == Sprite.packed(ink.accent) && $0.alpha > 0.45 })
}

/// The most and the mean sprites Rain draws on `size` over 10 s, at rest or typing at `keys` a second on the keys
/// of a sentence (the rate as `Typing` counts it).
private func sprites(on size: CGSize, keys: Double) -> (most: Int, mean: Int) {
    let b = BoxFrame.line(in: CGRect(x: 0, y: 80, width: size.width, height: size.height - 114), height: 112)
    var r = Rain(stage: Ambience.Stage(size: size, box: b, style: style), glyphs: glyphs, seed: 13)
    let line = Array("the boats sat low in the water and the reeds bent over them ")
    var out: [Sprite] = [], most = 0, sum = 0, next = 0.0, typed = 0
    let frames = 600
    for f in 0..<frames {
        let t = Double(f) / 60
        var events: [Event] = []
        while keys > 0, next <= t {
            let c = line[typed % line.count]
            events.append(c == " " ? .space(key(c)) : .typed(slot: glyphs.slot(c), at: key(c)))
            (typed, next) = (typed + 1, next + 1 / keys)
        }
        out.removeAll()
        r.step(dt: 1.0 / 60, events: events, rate: min(Double(typed), keys * 2) / 2, into: &out)
        if f >= 180 { (most, sum) = (max(most, r.shown), sum + r.shown) }  // after 3 s of it
    }
    return (most, sum / (frames - 180))
}

@Test func rainStaysUnderTheCapTypingOnALargeScreen() {
    let laptop = CGSize(width: 1512, height: 982), large = CGSize(width: 2560, height: 1440)
    let counts = [(laptop, 0.0), (laptop, 6), (large, 0), (large, 6), (large, 10)].map { (size, keys) in
        (size, keys, sprites(on: size, keys: keys))
    }
    for (size, keys, n) in counts {
        print("rain sprites \(Int(size.width)) × \(Int(size.height)) at \(keys) keys/s: mean \(n.mean), most \(n.most)")
    }
    #expect(counts[3].2.most < T.cap && counts[1].2.most < T.cap)  // typing at 6 keys a second (I 1), the large screen
    #expect(counts[0].2.mean < counts[1].2.mean / 2 && counts[2].2.mean < counts[3].2.mean / 2)
}

@Test func everyModeStaysUnderTheCap() {
    var flood: [Event] = []
    let keys = [0x00, 0x0C, 0x12, 0x2E, 0x31, 0x24, 0x33].map { Keyboard.position(of: UInt16($0)) }
    for i in 0..<3000 {
        let at = keys[i % keys.count]
        let end: Event = i % 7 == 0 ? .paragraph(at) : .space(at), back: Event = i % 11 == 0 ? .backspace(at) : .space(nil)
        flood += [.typed(slot: m, at: at), end, back]
    }
    for mode in Mode.allCases {
        var s = scene(mode)
        for seconds in [0.2, 0.4, 1] {  // the flood, then the scene carrying it on
            let out = play(&s, seconds == 0.2 ? flood : [], for: seconds)
            #expect(out.count <= T.cap && s.count <= T.cap, "\(mode) \(seconds)")
        }
    }
    var run = Ambience.Run(mode: .rain, stage: stage, glyphs: glyphs, seed: 1), out: [Sprite] = []
    run.take((0..<3000).map { Ambience.Key(t: Double($0) / 1000, kind: .glyph("m"), code: 0x2E) })
    _ = run.frame(at: 3, dt: 1.0 / 60, into: &out)
    #expect(out.count <= T.cap && run.count <= T.cap && out.contains { $0.parameter == UInt32(m) })
}

// MARK: Still water (pass 24)

/// Still water stepped `seconds` at 30 Hz, `events` and `rate` in every step; the most drops and sprites alive at once,
/// every drop that landed (where), and the last step's sprites.
private func pond(_ w: inout Water, for seconds: Double, events: [Event] = [], rate: Double = 0)
    -> (most: Int, sprites: Int, landed: [CGPoint], out: [Sprite]) {
    var out: [Sprite] = [], most = 0, sprites = 0, landed: [CGPoint] = []
    for _ in 0..<Int((seconds * 30).rounded()) {
        let before = w.landed
        out.removeAll()
        w.step(dt: 1.0 / 30, events: events, rate: rate, into: &out)
        if w.landed > before, let d = w.drops.last { landed.append(CGPoint(x: d.x, y: d.y)) }
        (most, sprites) = (max(most, w.drops.count), max(sprites, out.count))
    }
    return (most, sprites, landed, out)
}

@Test func stillWaterDropsAtRestAtItsRateScaledToTheScreen() {
    // Look §5.3: 0.12 a second on a 1512 × 982 pt screen (a mean of 8 s apart), by the area on another; one at the
    // show above the middle of the box's top edge; every one at least 48 pt clear of the box; 30 Hz.
    let large = CGSize(width: 2560, height: 1440)
    for (size, rate) in [(screen, 0.12), (large, 0.12 * 2560 * 1440 / (1512 * 982))] {
        let b = BoxFrame.line(in: CGRect(x: 0, y: 80, width: size.width, height: size.height - 114), height: 112)
        var w = Water(stage: Ambience.Stage(size: size, box: b, style: style), glyphs: glyphs, seed: 21)
        #expect(w.landed == 1 && w.drops[0].x == Double(b.midX) && w.drops[0].y == Double(b.maxY) + 48)  // the show's
        #expect(w.frameRate == 30)
        let seconds = 2000.0, p = pond(&w, for: seconds)
        let clear = b.insetBy(dx: -48, dy: -48)
        print("still water at rest on \(Int(size.width)) × \(Int(size.height)): \(p.landed.count) drops in \(Int(seconds)) s"
              + " (\(rate * seconds) expected), at most \(p.most) at once")
        #expect(abs(Double(p.landed.count) - rate * seconds) < 0.15 * rate * seconds)
        #expect(p.landed.allSatisfy { !clear.contains($0) && $0.x >= 0 && $0.y >= 0 && $0.x <= size.width && $0.y <= size.height })
    }
}

@Test func stillWaterTakesNoKeys() {
    // Rest only (the user's pick): a flood of keys at 12 a second, every kind, changes nothing a frame draws.
    var calm = Water(stage: stage, glyphs: glyphs, seed: 5)
    var typed = calm
    let flood: [Event] = [.typed(slot: m, at: key("m")), .space(key(" ")), .paragraph(key("\n")), .backspace(nil)]
    var same = true, drawn = 0
    for _ in 0..<(30 * 120) {  // two minutes at 30 Hz
        var a: [Sprite] = [], b: [Sprite] = []
        calm.step(dt: 1.0 / 30, events: [], rate: 0, into: &a)
        typed.step(dt: 1.0 / 30, events: flood, rate: 12, into: &b)
        (same, drawn) = (same && a == b, drawn + a.count)
    }
    #expect(same && drawn > 0 && calm.landed == typed.landed && calm.landed > 5)
    // And through a run: keys or none, the same frames, and 30 Hz throughout.
    var quiet = Ambience.Run(mode: .water, stage: stage, glyphs: glyphs, seed: 9), busy = quiet
    var a: [Sprite] = [], b: [Sprite] = []
    for f in 0..<300 {
        let t = Double(f) / 30
        busy.take([Ambience.Key(t: t, kind: .glyph("a"), code: 0x00), Ambience.Key(t: t, kind: .space, code: 0x31)])
        #expect(quiet.frame(at: t, dt: 1.0 / 30, into: &a) == busy.frame(at: t, dt: 1.0 / 30, into: &b))
        same = same && a == b && busy.frameRate == 30
    }
    #expect(same)
}

@Test func aDropsRingsRiseSoftlyThenFadeWithRadiusAndTime() {
    var w = Water(stage: elsewhere, glyphs: glyphs, seed: 3)  // no box: no drop at the show
    #expect(w.drops.isEmpty)
    w.drop(x: 700, y: 500)
    /// The drop's sprites at `t` seconds: (radius, alpha), largest first.
    var t = 0.0
    func at(_ until: Double) -> [(r: Double, a: Double)] {
        var out: [Sprite] = []
        while t < until - 1e-9 {
            out.removeAll()
            w.step(dt: 1.0 / 30, events: [], rate: 0, into: &out)
            t += 1.0 / 30
        }
        return out.filter { $0.x == 700 && $0.y == 500 }.map { (Double($0.parameter & 0x3fff) / 2, Double($0.alpha)) }
            .sorted { $0.r > $1.r }
    }
    let peak = T.waterPeak.add  // Lemna's ink: added
    let first = at(1.0 / 30)
    #expect(!first.isEmpty && first.allSatisfy { $0.a < 0.75 * peak })  // a soft onset, not at its peak
    let onset = at(0.2)
    #expect(onset.contains { $0.a > 0.8 * peak })  // near its peak after 180 ms
    // At 1 s: three crests, the lead 36 pt out, the calm centre about 0.7 of it, each with its trough 3 pt in at 0.4.
    let one = at(1)
    let crests = one.filter { c in one.contains { abs($0.r - (c.r - 3)) < 0.5 && abs($0.a - 0.4 * c.a) < 1e-3 } }
    #expect(crests.count == 3 && one.count == 6, "\(one)")
    #expect(near(crests[0].r, 36, 2) && near(crests[2].r / crests[0].r, 0.7, 0.1))
    // With the radius: the outer crest, at the same age, lower by √(r_inner / r_outer) (their onsets long over).
    #expect(near(crests[0].a / crests[2].a, (crests[2].r / crests[0].r).squareRoot(), 0.02))
    // With time: the lead crest's alpha falls frame on frame, as e^(−t/1.4 s) · √(12 / r).
    var lead: [Double] = [one.first!.a]
    for s in [1.5, 2, 2.5, 3] { lead += at(s).prefix(1).map(\.a) }
    #expect(lead.count >= 4 && zip(lead, lead.dropFirst()).allSatisfy { $0 > $1 }, "\(lead)")
    #expect(near(lead[0], peak * exp(-1 / 1.4) * (12 / one[0].r).squareRoot(), 2e-3))
    // Gone by 4.5 s, its rings under 0.01 long before.
    #expect(at(4.6).isEmpty && !w.drops.contains { $0.x == 700 && $0.y == 500 })
}

@Test func stillWaterStaysUnderTheCapOnALargeScreen() {
    let large = CGSize(width: 2560, height: 1440)
    let b = BoxFrame.line(in: CGRect(x: 0, y: 80, width: 2560, height: 1326), height: 112)
    var w = Water(stage: Ambience.Stage(size: large, box: b, style: style), glyphs: glyphs, seed: 13)
    let rest = pond(&w, for: 600)  // ten minutes at rest
    for i in 0..<100 { w.drop(x: Double(40 + 24 * i), y: 1200) }  // more than it holds
    let full = pond(&w, for: 0.5)  // their crests and troughs all out
    print("still water on 2560 × 1440: at rest at most \(rest.most) drops, \(rest.sprites) sprites; \(w.drops.count) drops"
          + " at its limit, \(full.out.count) sprites")
    #expect(rest.sprites <= T.cap && rest.most < T.waterDrops)
    #expect(w.drops.count == T.waterDrops && full.out.count <= w.count && w.count <= T.cap)
    #expect(full.out.count > 4 * T.waterDrops)
}

// MARK: Metal

@Test(.enabled(if: Ambience.Renderer.available)) func theShaderCompilesAndDrawsOneFrameOffscreen() throws {
    let renderer = try #require(Ambience.Renderer(font: menlo))
    #expect(Ambience.Renderer.compileSeconds > 0)
    print("ambience shader compiled in \(Int(Ambience.Renderer.compileSeconds * 1000)) ms")
    let size = CGSize(width: 400, height: 100)
    let sprites = [
        Sprite.ring(x: 100, y: 50, radius: 29, width: 8, alpha: 1, colour: ink.accent),  // as Still water draws
        glyphs.sprite(glyphs.slot("M")!, centre: CGPoint(x: 250, y: 50), alpha: 1, colour: ink.text),
    ]
    let px = try #require(renderer.offscreen(sprites, size: size, scale: 2))
    func pixel(_ x: Double, _ y: Double, in f: [UInt8]? = nil) -> [UInt8] {  // points, origin at the bottom left
        let i = 4 * (Int((size.height - y) * 2) * 800 + Int(x * 2))
        return Array((f ?? px)[i..<i + 4])
    }
    // On the ring's circle: the accent, opaque (BGRA), within a pixel's sampling; a Gaussian across it, e^(−2) one
    // width out, nothing beyond two; clear around, and in its middle.
    let on = pixel(100, 50 + 29.25)
    #expect(on[3] >= 253 && abs(Int(on[0]) - 0xf0) <= 2 && abs(Int(on[1]) - 0xa7) <= 2 && abs(Int(on[2]) - 0x7a) <= 2)
    let out8 = Int(pixel(100, 50 + 29.25 + 8)[3])  // 8.25 pt out: 255 · e^(−2 · 1.03²)
    #expect(abs(out8 - Int(255 * exp(-2 * 1.03125 * 1.03125))) <= 2)
    #expect(pixel(100, 50 + 29 + 16.5)[3] == 0 && pixel(100, 50 + 29 - 16.5)[3] == 0)
    #expect(pixel(2, 2) == [0, 0, 0, 0] && pixel(100, 50) == [0, 0, 0, 0])
    var inked = 0
    for y in stride(from: 30.0, to: 70, by: 0.5) {
        for x in stride(from: 240.0, to: 260, by: 0.5) where pixel(x, y)[3] > 128 { inked += 1 }
    }
    #expect(inked > 100)  // the M from the atlas
    let half = try #require(renderer.offscreen([sprites[0]], size: size, scale: 2, alpha: 0.5))
    #expect(abs(Int(pixel(100, 50 + 29.25, in: half)[3]) - 128) <= 1)  // the run's alpha multiplies every sprite
}

/// A dark app (or a light one) under the theme's dim, the ambience's frame `px` over it and the box with `text` on top,
/// in `look`: what the box's screen shows, 1512 × 982 pt at 2×, written to app/renders/`name`.
private func compose(_ px: [UInt8], text: Text, name: String, look: Style = style, lightApp: Bool = false) throws {
    let (w, h) = (Int(screen.width) * 2, Int(screen.height) * 2), style = look, shape = look.theme.box
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    c.setFillColor(rgb(lightApp ? 0xffffff : 0x24272e))  // an app, a few lines of its text
    c.fill(CGRect(origin: .zero, size: screen))
    c.setFillColor(rgb(lightApp ? 0xaeb3ba : 0x4a505a))
    for (i, length) in [360, 540, 450, 270, 510, 390, 0, 450, 360, 240, 480, 330, 420].enumerated() where length > 0 {
        c.fill(CGRect(x: 48, y: screen.height - 90 - CGFloat(i) * 36, width: CGFloat(length), height: 9))
    }
    c.setFillColor(rgb(style.palette.dim).copy(alpha: CGFloat(style.palette.dimAlpha))!)  // the dim, D1
    c.fill(CGRect(origin: .zero, size: screen))
    let data = try #require(CFDataCreate(nil, px, px.count))
    let image = try #require(CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * w,
                                     space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                     bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue
                                         | CGBitmapInfo.byteOrder32Little.rawValue),
                                     provider: CGDataProvider(data: data)!, decode: nil, shouldInterpolate: false,
                                     intent: .defaultIntent))
    c.draw(image, in: CGRect(origin: .zero, size: screen))
    let box = BoxFrame.line(in: CGRect(x: 0, y: 80, width: 1512, height: 868), height: BoxFrame.height(fontSize: style.size))
    c.addPath(CGPath(roundedRect: box, cornerWidth: shape.corner, cornerHeight: shape.corner, transform: nil))  // opaque
    c.setFillColor(style.background)
    c.fillPath()
    c.saveGState()
    let line = box.insetBy(dx: shape.borderWidth, dy: shape.borderWidth)
    c.translateBy(x: line.minX, y: line.minY)
    Line.draw(Line.shape(text, marked: "", font: style.font), before: 0, after: 0, in: c,
              band: Line.band(in: line.size, style: style), style: style)
    c.restoreGState()
    let half = shape.borderWidth / 2, r = shape.corner - half
    c.addPath(CGPath(roundedRect: box.insetBy(dx: half, dy: half), cornerWidth: r, cornerHeight: r, transform: nil))
    c.setStrokeColor(style.border)
    c.setLineWidth(shape.borderWidth)
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

/// Rain after 10 s of typing at 6 keys a second and 0.6 s after a Return, drawn by the Metal pipeline over a dimmed
/// dark app with the box on it, as the box's screen shows it: app/renders/ambience-rain.png (each mode's until pass 24,
/// which removed Drift, Rings and Grid and with them ambience-grid-keyboard.png); Rain at rest 3 s after the summon
/// (ambience-rain-idle.png, pass 19b). Still water's renders are Still's (`stillWaterShowsOnStillsDayAndNightDim`).
@Test(.enabled(if: Ambience.Renderer.available)) func ambienceRenders() throws {
    let renderer = try #require(Ambience.Renderer(font: menlo))
    let words = "the boats sat low in the water and the reeds bent over them"
    let r = typing(Array(words) + ["\n"] + Array("as"), .rain, rate: 6, after: 0.27)
    let typed = try #require(r.alpha)
    #expect(!r.out.isEmpty)
    try compose(try #require(renderer.offscreen(r.out, size: screen, scale: 2, alpha: typed)), text: r.text,
                name: "ambience-rain.png")
    // Rain at rest, as the summon finds it (ambience-rain.png above is the rain while typing).
    var idle = Ambience.Run(mode: .rain, stage: stage, glyphs: glyphs, seed: 11), out: [Sprite] = []
    var a: Double?
    for f in 0..<90 { a = idle.frame(at: Double(f) / 30, dt: 1.0 / 30, into: &out) }  // 3 s at 30 Hz
    let alpha = try #require(a)
    try compose(try #require(renderer.offscreen(out, size: screen, scale: 2, alpha: alpha)), text: Text(String(words)),
                name: "ambience-rain-idle.png")
}

/// Rain at rest on Still's day dim (TH1, architecture §7): its ink laid over shows, where light added (Lemna's text
/// colour in both of Rain's roles) would not. Rain's frame 3 s after the summon, in Menlo at Still's size (the atlas's face under a proportional line), laid
/// over the wash over a white app as Core Animation lays the ambience's layer over the shade; counted are the pixels
/// that differ from the wash alone by 8 or more of 255 in a channel. Written as app/renders/ambience-rain-still-day.png,
/// beside the box at rest by day and by night (idle-still-day.png over a light app, idle-still-night.png over a dark
/// one) and Rain at rest on Still's night (ambience-rain-still-night.png, its ink added).
@Test(.enabled(if: Ambience.Renderer.available)) func rainShowsOnStillsDayDim() throws {
    let font = try #require(stillFont)  // Literata from app/Fonts, registered once for every test (ThemeTests)
    let renderer = try #require(Ambience.Renderer(font: Ambience.Glyphs.atlasFont(for: font)))
    let day = Style(.still, dark: false, font: font), night = Style(.still, dark: true, font: font)
    func rain(_ stage: Ambience.Stage, scale: CGFloat) throws -> [UInt8] {
        var run = Ambience.Run(mode: .rain, stage: stage, glyphs: renderer.glyphs, seed: 11), out: [Sprite] = []
        var a: Double?
        for f in 0..<90 { a = run.frame(at: Double(f) / 30, dt: 1.0 / 30, into: &out) }  // 3 s at 30 Hz
        let alpha = try #require(a)
        return try #require(renderer.offscreen(out, size: screen, scale: scale, alpha: alpha, blend: stage.ink.blend))
    }
    func shown(_ px: [UInt8]) -> Int {
        let p = day.palette, k = Double(p.dimAlpha)
        let channels: [UInt32] = [p.dim & 255, p.dim >> 8 & 255, p.dim >> 16 & 255]  // B G R
        let wash = channels.map { (c: UInt32) -> Double in k * Double(c) + (1 - k) * 255 }  // over a white app
        var n = 0
        for i in stride(from: 0, to: px.count, by: 4) {  // BGRA; laid over, px + wash · (1 − a), so the step is px − wash · a
            let a = Double(px[i + 3]) / 255
            var step = 0.0
            for j in 0..<3 { step = max(step, abs(Double(px[i + j]) - wash[j] * a)) }
            if step >= 8 { n += 1 }
        }
        return n
    }
    let stillInk = Ambience.Stage(size: screen, box: box, style: day)
    var added = stillInk, lemna = Theme.lemna.night.ink
    added.ink = Theme.Ink(text: lemna.text, accent: lemna.text, blend: .add, alpha: 1)
    let (ours, light) = (shown(try rain(stillInk, scale: 1)), shown(try rain(added, scale: 1)))
    print("rain on Still's day dim: \(ours) pixels show in its ink, \(light) in light added")
    #expect(ours > 1500 && light * 10 < ours)
    let words = Text("the boats sat low in the water and the reeds bent over them")
    try compose(try rain(stillInk, scale: 2), text: words, name: "ambience-rain-still-day.png", look: day, lightApp: true)
    try compose(try rain(Ambience.Stage(size: screen, box: box, style: night), scale: 2), text: words,
                name: "ambience-rain-still-night.png", look: night)
    let clear = [UInt8](repeating: 0, count: 4 * Int(screen.width) * 2 * Int(screen.height) * 2)
    try compose(clear, text: words, name: "idle-still-day.png", look: day, lightApp: true)
    try compose(clear, text: words, name: "idle-still-night.png", look: night)
}

@Test(.enabled(if: Ambience.Renderer.available)) func ringsThatCrossAdd() throws {
    // Two of Still water's rings crossing, each alone and both, added (a dark wash) and laid over (a light one): where
    // they cross the frame is stronger than either alone, as the blend combines them; elsewhere each is as it was.
    let renderer = try #require(Ambience.Renderer(font: menlo))
    let size = CGSize(width: 300, height: 200)
    let a = Sprite.ring(x: 120, y: 100, radius: 50, width: 2, alpha: 0.3, colour: 0xc9d3c4)
    let b = Sprite.ring(x: 180, y: 100, radius: 50, width: 2, alpha: 0.3, colour: 0x3f4a3c)
    func pixel(_ f: [UInt8], _ x: Double, _ y: Double) -> [Int] {  // points, origin at the bottom left; BGRA
        let i = 4 * (Int((size.height - y) * 2) * 600 + Int(x * 2))
        return f[i..<i + 4].map { Int($0) }
    }
    let crossing = (x: 150.0, y: 100 + 40.0)  // 30 pt from each centre across, 40 up: 50 from both
    for blend in [Theme.Ink.Blend.add, .over] {
        let one = try #require(renderer.offscreen([a], size: size, scale: 2, blend: blend))
        let other = try #require(renderer.offscreen([b], size: size, scale: 2, blend: blend))
        let both = try #require(renderer.offscreen([a, b], size: size, scale: 2, blend: blend))
        let (p, q, r) = (pixel(one, crossing.x, crossing.y), pixel(other, crossing.x, crossing.y),
                         pixel(both, crossing.x, crossing.y))
        #expect(r[3] > p[3] + 40 && r[3] > q[3] + 40, "\(blend): \(p) \(q) \(r)")  // about 1 − 0.7², not 0.3
        let added = (0..<3).map { p[$0] + q[$0] }, laid = (0..<3).map { q[$0] + p[$0] * (255 - q[3]) / 255 }
        #expect((0..<3).allSatisfy { abs(r[$0] - (blend == .add ? added : laid)[$0]) <= 2 }, "\(blend): \(r)")
        #expect(pixel(both, 70, 100) == pixel(one, 70, 100) && pixel(both, 230, 100) == pixel(other, 230, 100))
    }
}

/// Still water (pass 24) on Still's day and night washes, as Core Animation lays the ambience's layer over the shade:
/// the drop at the show 1.2 s on, two drops whose rings cross to its left (0.9 and 0.6 s old) and one more to its right
/// (1.0 s). Counted, as `rainShowsOnStillsDayDim` counts them, are the pixels that differ from the wash alone by 8
/// or more of 255 in a channel by day (laid over, over a white app) and by 4 or more by night (added, over a dark one).
/// Written as app/renders/ambience-water-day.png and ambience-water-night.png.
@Test(.enabled(if: Ambience.Renderer.available)) func stillWaterShowsOnStillsDayAndNightDim() throws {
    #expect(Theme.still.defaults.ambience == .water && Theme.lemna.defaults.ambience == nil)  // the presets (TH1)
    let font = try #require(Theme.still.type.font)
    let renderer = try #require(Ambience.Renderer(font: Ambience.Glyphs.atlasFont(for: font)))
    let day = Style(.still, dark: false, font: font), night = Style(.still, dark: true, font: font)
    let shown = BoxFrame.line(in: CGRect(x: 0, y: 80, width: 1512, height: 868), height: BoxFrame.height(fontSize: day.size))
    func water(_ look: Style, scale: CGFloat) throws -> [UInt8] {
        let stage = Ambience.Stage(size: screen, box: shown, inset: 1, corner: 16, style: look)
        var w = Water(stage: stage, glyphs: renderer.glyphs, seed: 4), out: [Sprite] = []
        for f in 0..<36 {  // 1.2 s at 30 Hz
            if f == 9 { w.drop(x: 470, y: 760) }
            if f == 18 { w.drop(x: 500, y: 748) }
            if f == 6 { w.drop(x: 1130, y: 610) }
            out.removeAll()
            w.step(dt: 1.0 / 30, events: [], rate: 0, into: &out)
        }
        return try #require(renderer.offscreen(out, size: screen, scale: scale, alpha: stage.ink.alpha,
                                               blend: stage.ink.blend))
    }
    /// Pixels that differ from the wash by `step` of 255 or more, the wash over `app` (BGR).
    func count(_ px: [UInt8], _ look: Style, over app: [Double], step limit: Double) -> Int {
        let p = look.palette, k = Double(p.dimAlpha)
        let channels: [UInt32] = [p.dim & 255, p.dim >> 8 & 255, p.dim >> 16 & 255]  // B G R
        let wash = (0..<3).map { k * Double(channels[$0]) + (1 - k) * app[$0] }
        var n = 0
        for i in stride(from: 0, to: px.count, by: 4) {  // premultiplied over the wash: px + wash · (1 − a)
            let a = Double(px[i + 3]) / 255
            var step = 0.0
            for j in 0..<3 { step = max(step, abs(Double(px[i + j]) - wash[j] * a)) }
            if step >= limit { n += 1 }
        }
        return n
    }
    let ofDay = count(try water(day, scale: 1), day, over: [255, 255, 255], step: 8)
    let ofNight = count(try water(night, scale: 1), night, over: [0x2e, 0x27, 0x24], step: 4)
    print("still water on Still's washes at 1×: \(ofDay) pixels show by day, \(ofNight) by night")
    #expect(ofDay > 1000 && ofNight > 1000)
    let words = Text("the boats sat low in the water and the reeds bent over them")
    try compose(try water(day, scale: 2), text: words, name: "ambience-water-day.png", look: day, lightApp: true)
    try compose(try water(night, scale: 2), text: words, name: "ambience-water-night.png", look: night)
}
