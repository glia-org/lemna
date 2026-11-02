// The ambience (DESIGN.md A1): the Ambience submenu's choice (S1), the tuning (I1, raised in pass 16), the run of a
// scene and its close (R1), Code's coupling to typing and, since pass 16, to where the key is on the keyboard, and
// since pass 27 its curtain, streams, depth and halos, since pass 27b its build-in and its larger lift while typing,
// Still water's drops at rest (pass 24) and per word (pass 25), the cap, and the Metal pipeline drawing offscreen
// (since pass 27 mirrored, softened and in katakana). No Foundation here (see RenderTests.swift).
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
    #expect(Mode.allCases.map(\.title) == ["Code", "Still water"])  // pass 18 and 24 (RM1) removed six; Rain until 25
    for mode in Mode.allCases {
        #expect(Ambience(kept: Ambience(mode).kept) == Ambience(mode) && Ambience(mode).kept == mode.rawValue)
    }
    #expect(Ambience(kept: nil) == Ambience() && Ambience(kept: "off") == Ambience() && Ambience(.water).kept == "water")
    // Code's name until pass 25: still Code, kept from now on under its own.
    #expect(Ambience(kept: "rain") == Ambience(.code) && Ambience(kept: "rain").kept == "code")
    // M8, never built, or a mode removed in pass 18 or in pass 24: Off.
    for gone in ["burn", "beams", "fireworks", "swarm", "drift", "rings", "grid"] {
        #expect(Ambience(kept: gone) == Ambience() && Ambience(kept: gone).playing(reduceMotion: false) == nil)
    }
    var a = Ambience()
    a.choose(.code)
    #expect(a.mode == .code && a.playing(reduceMotion: false) == .code)
    a.choose(nil)
    #expect(a == Ambience())
    #expect(Mode.allCases.filter(\.everyScreen) == [.code])  // Still water stays on the box's screen
    #expect(Mode.allCases.filter(\.ambient) == [.code, .water])  // from the show to the close (pass 19b, I1; pass 24)
}

@Test func reduceMotionForcesOffAndKeepsThePick() {
    let a = Ambience(.water)
    #expect(a.playing(reduceMotion: true) == nil && a.playing(reduceMotion: false) == .water)
    #expect(!Ambience.available(reduceMotion: true) && Ambience.available(reduceMotion: false))
    #expect(a.mode == .water && a.kept == "water")  // kept: Reduce Motion off again, it plays again
}

@Test func theAmbienceTuningIsPlainToSee() {
    // Pass 16 (the user: "The ambience effects are way too subtle"); pass 15's, the panel's, in the comments.
    #expect(T.cap == 20_000 && T.frameRate == 60 && T.linger == 4 && T.fadeOut == 1)  // 2,000, 16,000 in pass 27
    // Code since pass 19b (matrix §6.2), each pair (idle, typing); the speed one range since pass 25 (a column's own,
    // whatever the intensity); the film's frame since pass 27 (pass 25's in the comments): 16.8 pt glyphs (14) on the
    // 18.5 pt grid, heads a column (a share of columns falling, 0.3 / 0.7), 8 / 5 rows apart (a trail and 3 / 2 cells),
    // trails 30–150 / 40–200 cells (6–18 / 10–30), head 0.8 / 1 (0.35 / 0.85), trail from 0.55 / 0.85 (0.2 / 0.5)
    // times a stream's gain and a glyph's level, 0.5 / 2 glyph changes a second (0.3 / 1.5). Pass 27b (the user,
    // 2026-11-02: "it could be just a bit more" reactive; pass 27's in the comments): 1.6 heads a column typing (1.4),
    // the trail from 0.5 / 0.9 (0.55 / 0.85), halos 0.22 / 0.4 (0.22 / 0.35), 3 glyph changes a second typing (2); a
    // key's head 1 (0.95) over a halo of 0.7 (the intensity's), its trail from 1 (0.8) over 20–60 cells (12–40); the
    // intensity up with τ 0.15 s (0.25) and down with τ 1.5 s (1.2); the build-in 4 s (none).
    #expect(T.codeScale == 0.6 && T.codePitch == 0.5 && T.codeActive == (0.8, 1.6) && T.codeGap == (8, 5))
    #expect(T.codeSpeed == 8...16 && T.codeTrail == (30...150, 40...200) && T.codeMost == 3 && T.codeHeight == 1000)
    #expect(T.codeWait == 0.5...1.5)
    #expect(T.codeHigh == 0.3 && T.codeHighRows == 0.05...0.6)
    #expect(T.codeHead == (0.8, 1) && T.codeNeck == 0.7 && T.codeNeckCells == 2)
    #expect(T.codeTrailTop == (0.5, 0.9) && T.codeGain == 0.3...2 && T.codeLevel == 0.3...1 && T.codeLevelSkew == 1.5)
    #expect(T.codeFade == 1 && T.codeHalo == (0.22, 0.4) && T.codeHaloWidth == 0.8 && T.codeChange == (0.5, 3))
    #expect(T.codeNear == 1.6 && T.codeNearActive == (0.06, 0.15) && T.codeNearBright == 1.6 && T.codeNearBlur == 1.5)
    #expect(T.codeKeyHead == 1 && T.codeKeyHalo == 0.7 && T.codeKeyTrailTop == 1 && T.codeKeyTrail == 20...60)
    #expect(T.codeFast == 6 && T.codeRise == 0.15 && T.codeSettle == 1.5 && T.codeHold == 0.8 && T.codeIdleRate == 30)
    #expect(T.codeAhead == 20 && T.codeBuildIn == 4)
    // Still water (pass 24), look §5.3's Ripples raised 2026-11-01 ("it's showing nothing"): 0.5 drops a second a screen, 48 pt clear of the box, one at the
    // show; 3 crests from 36 pt/s, the calm centre at 0.7 of it; 1.2–2 pt, ±40 ms; troughs 3 pt in at 0.4; up over
    // 180 ms, e^(−t/2 s) · √(12 pt / r), under 0.01 not drawn, 6 s a drop; 32 drops; 30 Hz.
    #expect(T.waterRate == 0.5 && T.waterClear == 48 && T.waterSummon == 48 && T.waterDrops == 32)
    #expect(T.waterWordGap == 0.8 && T.waterTop == 40)  // a word's drop (pass 25): 0.8 s apart, 40 pt under the top
    #expect(T.waterCrests == 3 && T.waterSpeed == 36 && T.waterSpread == 0.15 && T.waterJitter == 0.15)
    #expect(T.waterWidth == 2...3.5 && T.waterStart == 0.04 && T.waterTrough == 3 && T.waterTroughShare == 0.4)
    #expect(T.waterOnset == 0.18 && T.waterDecay == 2 && T.waterNear == 12 && T.waterShown == 0.01)
    #expect(T.waterPeak == (0.6, 0.4))  // times Still's ink alphas 0.6 and 0.5: 0.36 and 0.2 on screen (raised 2026-11-01)
    #expect(T.waterLife == 6 && T.waterFrameRate == 30 && near(1 - T.waterSpread * 2, 0.7, 1e-12))
    // C1: Lemna's ink is the box's text and accent, added (Code's C2 the same two, the other way round); every stage
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
    #expect(glyphs.codeSet == (Array("012345789Zz:.\"=*+-<>|_") + Ambience.Glyphs.kana).map { glyphs.slot($0)! })  // K1
    // The katakana (pass 27): 46 from the font Core Text falls back on for Menlo, in its bold, each centred on Menlo's
    // advance and within the cell its own glyphs make, so the cell is as before.
    #expect(Ambience.Glyphs.kana.count == 46 && glyphs.faces.count == 2 && glyphs.ids.count == glyphs.face.count)
    #expect(Ambience.Glyphs.kana.allSatisfy { c in glyphs.slot(c).map { glyphs.face[$0] == 1 && glyphs.shift[$0] > 0 } ?? false })
    #expect(CTFontGetSymbolicTraits(glyphs.faces[1]).contains(.traitBold) && glyphs.face.filter { $0 == 0 }.count > 150)
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
    // Code (pass 19b, I1): from its first frame, no key needed (building in since pass 27b, the whole curtain by
    // `codeBuildIn`), and no end 4 s after the last; the close as any mode's.
    var run = Ambience.Run(mode: .code, stage: stage, glyphs: glyphs, seed: 1)
    var out: [Sprite] = []
    #expect(run.frame(at: 0, dt: 1.0 / 30, into: &out) == 1)
    for f in 1...Int(T.codeBuildIn * 30) { _ = run.frame(at: Double(f) / 30, dt: 1.0 / 30, into: &out) }
    #expect(out.count > 100)
    run.take([Ambience.Key(t: 1, kind: .glyph("a"))])
    #expect(run.alpha(at: 5) == 1 && run.alpha(at: 600) == 1 && run.frame(at: 600, dt: 1.0 / 30, into: &out) == 1)
    run.close(at: 601, over: 0.2)
    #expect(near(run.alpha(at: 601.1), 1 - Curve.easeOutQuint(0.5), 1e-9) && run.frame(at: 601.21, dt: 0.1, into: &out) == nil)
}

@Test func aKeysCodeBecomesItsPlaceOnTheKeyboardOfTheStage() {
    var run = Ambience.Run(mode: .code, stage: stage, glyphs: glyphs, seed: 1)
    run.take([Ambience.Key(t: 0, kind: .glyph("a"), code: 0x00), Ambience.Key(t: 0, kind: .space, code: 0x31),
              Ambience.Key(t: 0, kind: .paragraph, code: 0x24), Ambience.Key(t: 0, kind: .backspace, code: 0x33),
              Ambience.Key(t: 0, kind: .glyph("é"))])  // the accent menu's pick: no code
    #expect(run.events == [.typed(slot: glyphs.slot("a"), at: Keyboard.position(of: 0x00)),
                           .space(Keyboard.position(of: 0x31)), .paragraph(Keyboard.position(of: 0x24)),
                           .backspace(Keyboard.position(of: 0x33)), .typed(slot: glyphs.slot("é"), at: nil)])
    var iso = Ambience.Run(mode: .code, stage: Ambience.Stage(size: screen, box: box, keyboard: .iso, style: style),
                           glyphs: glyphs, seed: 1)
    iso.take([Ambience.Key(t: 0, kind: .glyph("<"), code: 0x32), Ambience.Key(t: 0, kind: .paragraph, code: 0x24)])
    #expect(iso.events.map(\.key) == [Keyboard.position(of: 0x32, on: .iso), Keyboard.position(of: 0x24, on: .iso)])
    #expect(iso.events[0].key?.row == 3)  // the key left of Z, not ANSI's ` left of 1
}

// MARK: The modes

/// Code (pass 19b) stepped `seconds` at `hz`, `events` in the first step, at `rate` keys a second; its last sprites.
private func fall(_ r: inout Code, _ events: [Event] = [], for seconds: Double, rate: Double = 0,
                  hz: Double = 60) -> [Sprite] {
    var out: [Sprite] = []
    for f in 0..<max(Int((seconds * hz).rounded()), 1) {
        out.removeAll()
        r.step(dt: 1 / hz, events: f == 0 ? events : [], rate: rate, into: &out)
    }
    return out
}

/// A Code sprite's cell on `r`'s main grid, or nil off it: column and row (0 at the top).
private func cell(_ s: Sprite, on r: Code, _ st: Ambience.Stage = stage) -> (c: Int, r: Int)? {
    let left = (Double(st.size.width) - Double(r.columns) * r.pitch) / 2
    let c = (Double(s.x) - left) / r.pitch - 0.5, row = (Double(st.size.height) - Double(s.y)) / r.pitch - 0.5
    guard near(c, c.rounded(), 1e-3), near(row, row.rounded(), 1e-3) else { return nil }
    return (Int(c.rounded()), Int(row.rounded()))
}

/// Code's sprites by what they are (pass 27): the main sheet's glyphs, the nearer sheet's (`codeNear` times larger),
/// and the heads' halos (rings of radius 0).
private func sheets(_ out: [Sprite], _ g: Ambience.Glyphs = glyphs) -> (main: [Sprite], near: [Sprite], halos: [Sprite]) {
    let h = Double(g.cell.height) * T.codeScale
    return (out.filter { $0.kind == .glyph && abs(Double($0.h) - h) < 0.01 },
            out.filter { $0.kind == .glyph && abs(Double($0.h) - h * T.codeNear) < 0.01 },
            out.filter { $0.kind == .ring })
}

private func slot(_ s: Sprite) -> Int { Int(s.parameter & 0xfff) }

@Test func codeIsAFixedGridOfTheFilmsGlyphsFallingFromItsFirstFrame() {
    var r = Code(stage: stage, glyphs: glyphs, seed: 7)
    // 18.5 pt cells, 81 × 54 on 1512 × 982 (pass 19b), the glyphs larger in them since pass 27 (16.8 pt, was 14).
    #expect(near(r.pitch, 18.5, 0.01) && r.columns == 81 && r.rows == 54 && near(r.nearPitch, 18.5 * T.codeNear, 0.01))
    #expect(glyphs.codeSet.count == 22 + 46 && Set(glyphs.codeSet).count == 68)
    var out = fall(&r, for: T.codeBuildIn, hz: 30)
    let (main, nearer, halos) = sheets(out)
    #expect(main.count + nearer.count + halos.count == out.count && !nearer.isEmpty && !halos.isEmpty)
    // Born mid-rain (stepped ahead at rest), and built in (pass 27b): over the screen's whole width and height.
    let cells = main.compactMap { cell($0, on: r) }
    #expect(cells.count == main.count && main.count > 2000)
    #expect(Set(cells.map(\.c)).count > 75 && cells.contains { $0.r < 2 } && cells.contains { $0.r > 51 })
    // The films' glyphs, every one mirrored (a negative width) and sharp, at the glyphs' scale; no key yet.
    #expect(main.allSatisfy { glyphs.codeSet.contains(slot($0)) && $0.parameter >> 12 == 0 })
    #expect(main.allSatisfy { near(Double($0.h), Double(glyphs.cell.height) * T.codeScale, 0.01)
        && near(-Double($0.w), Double(glyphs.cell.width) * T.codeScale, 0.01) })
    // The heads and the cells right behind them pale, the trails in the accent (C2).
    let text = main.filter { $0.colour == Sprite.packed(ink.text) }, trail = main.filter { $0.colour == Sprite.packed(ink.accent) }
    #expect(text.count + trail.count == main.count)
    #expect(text.contains { near(Double($0.alpha), T.codeHead.idle, 1e-3) } && text.allSatisfy { $0.alpha <= Float(T.codeHead.idle) + 1e-4 })
    #expect(trail.allSatisfy { Double($0.alpha) > T.codeShown && Double($0.alpha) <= T.codeTrailTop.idle * T.codeGain.upperBound + 1e-4 })
    // The cells never move: a minute of steps, every main sprite on the grid.
    for _ in 0..<60 {
        out = fall(&r, for: 0.5)
        #expect(sheets(out).main.allSatisfy { cell($0, on: r) != nil })
    }
    #expect(r.frameRate == 30)  // at rest, 30 Hz
}

@Test func codeAtRestIsADimCurtainOverTheWholeScreen() {
    // Pass 27 (the user, 2026-11-02, of two frames of the film's titles: "in the movie it looks more like this"):
    // nearly every column holds glyphs from near the top to near the bottom, most of them dim, with brighter streams
    // through them; pass 25 lit about 200 of the 4,374 cells.
    var shares: [Double] = [], held: [Double] = [], dim: [Double] = []
    for seed in UInt64(1)...6 {
        var r = Code(stage: stage, glyphs: glyphs, seed: seed)
        let main = sheets(fall(&r, for: T.codeBuildIn + 3, hz: 30)).main  // 3 s after the build-in (pass 27b)
        var rowsLit = [Int](repeating: 0, count: r.columns)
        for c in main.compactMap({ cell($0, on: r) }) { rowsLit[c.c] += 1 }
        shares.append(Double(main.count) / Double(r.columns * r.rows))
        held.append(Double(rowsLit.filter { Double($0) > 0.3 * Double(r.rows) }.count) / Double(r.columns))
        let trail = main.filter { $0.colour == Sprite.packed(ink.accent) }
        dim.append(Double(trail.filter { Double($0.alpha) < T.codeTrailTop.idle / 2 }.count) / Double(trail.count))
    }
    print("code at rest: \(shares.map { Int($0 * 100) }) % of the cells lit, \(held.map { Int($0 * 100) }) % of the columns over 30 % of their rows, \(dim.map { Int($0 * 100) }) % of the trail cells under half the trail's top")
    #expect(shares.allSatisfy { $0 > 0.55 && $0 < 0.9 })  // a curtain with gaps in it, not a wall
    #expect(held.allSatisfy { $0 > 0.8 })
    #expect(dim.allSatisfy { $0 > 0.5 })  // most of it dim
}

@Test func severalHeadsFallInAColumnStartingAtVariousHeights() {
    // Pass 27: up to `codeMost` heads a column at once at least `codeGap` rows apart, about `codeActive` a column on
    // average, most starting at the top edge and `codeHigh` of them lower down, within `codeHighRows` of the height.
    var r = Code(stage: stage, glyphs: glyphs, seed: 21)
    var last = r.falling, perColumn: [Double] = [], doubled = 0, frames = 0, starts: [Double] = []
    for _ in 0..<(30 * 40) {  // 40 s at 30 Hz, at rest
        _ = fall(&r, for: 1.0 / 30, hz: 30)
        let now = r.falling
        var counts = [Int](repeating: 0, count: r.columns)
        for h in now { counts[h.column] += 1 }
        #expect(counts.allSatisfy { $0 <= T.codeMost })  // 54 rows of 18.5 pt: 999 pt, `codeMost` itself
        for h in now where !last.contains(where: { $0.column == h.column && near($0.row + r.speed[h.column] / 30, h.row, 1e-6) }) {
            starts.append(h.row / Double(r.rows))  // a new one: where it started
        }
        perColumn.append(Double(now.count) / Double(r.columns))
        doubled += counts.filter { $0 >= 2 }.count
        frames += 1
        last = now
    }
    let mean = perColumn.reduce(0, +) / Double(perColumn.count), high = starts.filter { $0 > 0 }
    print("code heads at rest: \(mean) a column, \(Double(doubled) / Double(frames)) columns with two or more, \(starts.count) new, \(high.count) below the top")
    #expect(mean > T.codeActive.idle * 0.8 && mean < T.codeActive.idle * 1.2)
    #expect(Double(doubled) / Double(frames) > 0.04 * Double(r.columns))  // several heads in a column, often
    #expect(near(Double(high.count) / Double(starts.count), T.codeHigh, 0.08) && starts.count > 500)
    #expect(high.allSatisfy { $0 >= T.codeHighRows.lowerBound - 0.02 && $0 <= T.codeHighRows.upperBound })
    // Two heads of a column keep their distance.
    for c in 0..<r.columns {
        let rows = r.falling.filter { $0.column == c }.map(\.row).sorted()
        #expect(zip(rows, rows.dropFirst()).allSatisfy { $1 - $0 >= T.codeGap.idle - 1e-9 })
    }
}

@Test func aStreamsGlyphsEachHaveTheirOwnBrightness() {
    // Pass 27: within a stream each glyph has its own brightness (`codeLevel`, more dim than bright), drawn again
    // with each new glyph, so a bright one sits beside dim ones; a smooth fade alone would make every glyph dimmer
    // than the one below it, younger, in its trail.
    var r = Code(stage: stage, glyphs: glyphs, seed: 4)
    let main = sheets(fall(&r, for: T.codeBuildIn + 3, hz: 30)).main.filter { $0.colour == Sprite.packed(ink.accent) }
    var alpha: [Int: Float] = [:]
    for s in main { if let c = cell(s, on: r) { alpha[c.c * 1000 + c.r] = s.alpha } }
    var pairs = 0, brighterAbove = 0, ratios: [Double] = []
    for (key, a) in alpha {
        guard let below = alpha[key + 1] else { continue }  // the next cell down, younger in the same column
        pairs += 1
        if a > below { brighterAbove += 1 }
        ratios.append(Double(max(a, below) / min(a, below)))
    }
    let share = Double(brighterAbove) / Double(pairs), big = Double(ratios.filter { $0 > 2 }.count) / Double(pairs)
    print("code trails: \(pairs) neighbours, \(Int(share * 100)) % brighter above, \(Int(big * 100)) % more than 2:1")
    #expect(pairs > 1500 && share > 0.3 && big > 0.15)
    #expect(T.codeLevel.upperBound == 1 && T.codeLevel.lowerBound > 0 && T.codeLevelSkew > 1)
}

@Test func aFewNearerStreamsAreLargerSofterAndBrighter() {
    // Pass 27, the films' depth: a second sheet `codeNear` times the main one's pitch and glyphs, sampled
    // `codeNearBlur` mipmap levels softer and `codeNearBright` times brighter, with `codeNearActive` heads a column:
    // a small minority beside the main sheet's.
    var counts: [(main: Int, near: Int)] = []
    for seed in UInt64(1)...5 {
        var r = Code(stage: stage, glyphs: glyphs, seed: seed)
        let out = fall(&r, for: T.codeBuildIn + 3, hz: 30), (main, nearer, halos) = sheets(out)
        counts.append((main.count, nearer.count))
        let scale = T.codeScale * T.codeNear
        #expect(nearer.allSatisfy { Int($0.parameter >> 12) == Int(T.codeNearBlur * 4) && $0.w < 0
            && near(Double($0.h), Double(glyphs.cell.height) * scale, 0.01) })
        #expect(main.allSatisfy { $0.parameter >> 12 == 0 })
        // Its heads brighter than the main sheet's (clamped at 1), and its halos wider.
        let heads = nearer.filter { $0.colour == Sprite.packed(ink.text) }.map(\.alpha).max()
        #expect(heads.map { near(Double($0), min(T.codeHead.idle * T.codeNearBright, 1), 1e-3) } ?? (r.nearFalling == 0))
        let wide = Sprite.ring(radius: 0, width: T.codeHaloWidth * r.nearPitch)
        #expect(halos.filter { $0.parameter == wide }.count == min(r.nearFalling, halos.count))
        #expect(Double(r.nearFalling) < 3 * T.codeNearActive.idle * Double(r.nearColumns) + 2)
    }
    print("code sheets at rest, main and near glyphs: \(counts)")
    #expect(counts.allSatisfy { $0.near * 8 < $0.main } && counts.contains { $0.near > 0 })
}

@Test func aHaloLiesUnderEveryHead() {
    // Pass 27: a soft disc in the head's colour under each head (the films' bloom, Rezmason's and matrix §1.3's), the
    // ring of radius 0, `codeHaloWidth` of the pitch wide, at `codeHalo`; drawn just before its head, so a head is
    // laid over it. Only where light adds (Lemna, Still by night): ink laid over a light wash does not glow.
    var r = Code(stage: stage, glyphs: glyphs, seed: 8)
    let out = fall(&r, for: T.codeBuildIn + 1, hz: 30), halos = out.indices.filter { out[$0].kind == .ring }
    #expect(halos.count == r.falling.count + r.nearFalling && halos.count > 30)
    for i in halos {
        let halo = out[i], head = out[i + 1]
        #expect(head.kind == .glyph && head.colour == Sprite.packed(ink.text) && halo.colour == head.colour)
        let nearer = Double(head.h) > Double(glyphs.cell.height) * T.codeScale * 1.2, pitch = nearer ? r.nearPitch : r.pitch
        #expect(halo.x == head.x && halo.y == head.y && near(Double(halo.alpha), T.codeHalo.idle * (nearer ? T.codeNearBright : 1), 1e-3))
        #expect(halo.parameter == Sprite.ring(radius: 0, width: T.codeHaloWidth * pitch)
            && near(Double(halo.w), 4 * T.codeHaloWidth * pitch, 1e-3))
    }
    var busy = Code(stage: stage, glyphs: glyphs, seed: 8)
    let own = Sprite.ring(radius: 0, width: T.codeHaloWidth * busy.pitch)
    let typing = fall(&busy, for: T.codeBuildIn + 1, rate: 6).filter { $0.kind == .ring && $0.parameter == own }
    #expect(!typing.isEmpty && typing.allSatisfy { near(Double($0.alpha), T.codeHalo.typing, 0.01) })  // brighter typing
    let day = Ambience.Stage(size: screen, box: box, style: Style(.still, dark: false, font: menlo))
    var still = Code(stage: day, glyphs: glyphs, seed: 8)
    #expect(!fall(&still, for: 1, hz: 30).contains { $0.kind == .ring })
}

@Test func aKeysHeadStepsACellATimeAndItsTrailDimsInPlace() {
    var r = Code(stage: stage, glyphs: glyphs, seed: 7)
    var out = fall(&r, [.typed(slot: m, at: column(7.5))], for: 1.0 / 60)
    #expect(r.frameRate == 60)  // a key: 60 Hz
    let typed = { (o: [Sprite]) in o.filter { $0.kind == .glyph && slot($0) == m } }
    let first = typed(out)[0], start = cell(first, on: r)!
    // The typed glyph, pale, as typed (not mirrored, the writer's own).
    #expect(first.colour == Sprite.packed(ink.text) && near(Double(first.alpha), T.codeKeyHead, 1e-3) && first.w > 0)
    var rows = [start.r], left: [Sprite] = []
    for _ in 0..<90 {  // 1.5 s at 60 Hz
        out = fall(&r, for: 1.0 / 60)
        let head = typed(out)
        #expect(head.count == 1 && cell(head[0], on: r)!.c == start.c)  // its column
        rows.append(cell(head[0], on: r)!.r)
        if rows.last! > start.r, let l = sheets(out).main.first(where: { cell($0, on: r)! == start }) {
            left.append(l)  // the cell it left, where it was
        }
    }
    #expect(zip(rows, rows.dropFirst()).allSatisfy { $1 - $0 == 0 || $1 - $0 == 1 })  // a cell a step, no slide
    // At its column's speed, 8–16 rows a second (pass 25), for 1.5 s.
    let travelled = rows.last! - start.r
    #expect((11...25).contains(travelled) && abs(Double(travelled) - 1.5 * r.speed[start.c]) <= 1.5)
    // The cell it left: pale for `codeNeckCells` cells of travel (the head's alpha times `codeNeck`, then its square),
    // then in the accent from the key's trail top at the cell's own brightness, dimming in place an equal step a frame
    // (`codeFade` 1, linear) while its glyph stays.
    let neck = left.prefix { $0.colour == Sprite.packed(ink.text) }, trail = left.dropFirst(neck.count)
    let necks = (1...T.codeNeckCells).map { T.codeKeyHead * pow(T.codeNeck, Double($0)) }
    #expect(!neck.isEmpty && neck.allSatisfy { a in necks.contains { near(Double(a.alpha), $0, 1e-3) } })
    #expect(trail.count > 10 && trail.allSatisfy { $0.colour == Sprite.packed(ink.accent) && glyphs.codeSet.contains(slot($0)) })
    #expect(Double(trail.first!.alpha) <= T.codeKeyTrailTop && T.codeFade == 1)
    var segments: [[Float]] = [[]]
    for (a, b) in zip(trail, trail.dropFirst()) {
        if a.parameter == b.parameter { segments[segments.count - 1].append(a.alpha - b.alpha) } else { segments.append([]) }
    }
    #expect(segments.joined().count > 10, "\(segments)")
    #expect(segments.allSatisfy { s in s.allSatisfy { $0 > 0 && near(Double($0), Double(s[0]), 2e-4) } }, "\(segments)")
}

@Test func everyLitGlyphChangesInPlaceFasterWhenTyping() {
    /// Changes a lit-cell second, over `seconds`: a trail cell in the accent from one step to the next with another
    /// glyph (a head relighting it turns it pale for `codeNeckCells` cells of travel first, so a cell in the accent in
    /// two steps running is still in one trail).
    func changes(_ r: inout Code, rate: Double, for seconds: Double) -> Double {
        var last: [Int: UInt32] = [:], changed = 0, seen = 0
        for _ in 0..<Int(seconds * 60) {
            var now: [Int: UInt32] = [:]
            for s in sheets(fall(&r, for: 1.0 / 60, rate: rate)).main where s.colour == Sprite.packed(ink.accent) {
                let c = cell(s, on: r)!, key = c.c * 1000 + c.r
                now[key] = s.parameter
                if let before = last[key] {
                    seen += 1
                    if before != s.parameter { changed += 1 }
                }
            }
            last = now
        }
        return Double(changed) / (Double(seen) / 60)
    }
    var r = Code(stage: stage, glyphs: glyphs, seed: 5)
    _ = fall(&r, for: T.codeBuildIn)  // past the build-in (pass 27b)
    let rest = changes(&r, rate: 0, for: 4)
    _ = fall(&r, for: 2, rate: 6)
    let typing = changes(&r, rate: 6, for: 3)
    // `codeChange`'s pair (a sixty-eighth of the picks land on the glyph that was there).
    let n = Double(glyphs.codeSet.count)
    #expect(near(rest, T.codeChange.idle * (n - 1) / n, 0.05) && near(typing, T.codeChange.typing * (n - 1) / n, 0.15),
            "\(rest) \(typing)")
}

@Test func aKeyStartsAHeadWhereTheKeyIsTheTypedGlyphAtIt() {
    func head(_ k: Keyboard.Position?, on st: Ambience.Stage = stage) -> Sprite {
        var r = Code(stage: st, glyphs: glyphs, seed: 3)
        return fall(&r, [.typed(slot: m, at: k)], for: 1.0 / 60).first { $0.kind == .glyph && slot($0) == m }!
    }
    // The left end of the keyboard a tenth across the screen, the right end nine tenths, anywhere on the key, on a
    // column; the number row starts higher than the bottom letter row.
    let within = 0.4 * 1512 * 0.8 / 15 + 18.5
    #expect(abs(Double(head(column(0.5)).x) - 1512 * (0.1 + 0.8 * 0.5 / 15)) <= within)
    #expect(abs(Double(head(column(14.5)).x) - 1512 * (0.1 + 0.8 * 14.5 / 15)) <= within)
    #expect(head(column(5, row: 0)).y > head(column(5, row: 3)).y + 150)
    #expect(abs(Double(head(nil).x) - Double(stage.caret)) <= 18.5)  // no position: at the caret
    #expect(abs(Double(head(column(14.5), on: elsewhere).x) - 1512 * (0.1 + 0.8 * 14.5 / 15)) <= within)  // every screen
    var again = Code(stage: stage, glyphs: glyphs, seed: 3), xs = Set<Float>()  // one key typed again and again
    for _ in 0..<20 {
        xs.formUnion(fall(&again, [.typed(slot: m, at: column(7.5))], for: 1.0 / 60).filter { $0.kind == .glyph && slot($0) == m }.map(\.x))
    }
    #expect(xs.count >= 3 && xs.allSatisfy { abs(Double($0) - 1512 * 0.5) <= within })  // spread over the key
    // A halo under it; its trail from the key's trail top, in its column above it.
    var r = Code(stage: stage, glyphs: glyphs, seed: 3)
    let out = fall(&r, [.typed(slot: m, at: column(7.5))], for: 0.5), i = out.firstIndex { $0.kind == .glyph && slot($0) == m }!
    #expect(i > 0 && out[i - 1].kind == .ring && out[i - 1].x == out[i].x && out[i - 1].y == out[i].y)
    let at = cell(out[i], on: r)!
    let trail = sheets(out).main.filter { cell($0, on: r).map { $0.c == at.c && $0.r < at.r - T.codeNeckCells } ?? false }
    #expect(trail.contains { $0.colour == Sprite.packed(ink.accent) && Double($0.alpha) <= T.codeKeyTrailTop })
    // Space, Return and ⌫ start none: the frames are those of no key at all.
    var quiet = Code(stage: stage, glyphs: glyphs, seed: 3), none = Code(stage: stage, glyphs: glyphs, seed: 3)
    let keys = fall(&quiet, [.space(column(6.75, row: 4)), .paragraph(nil), .backspace(column(14, row: 0))], for: 0.5)
    #expect(keys == fall(&none, for: 0.5) && quiet.falling.count == none.falling.count)
}

@Test func typingIntensifiesTheCodeAndAPauseSettlesIt() {
    var r = Code(stage: stage, glyphs: glyphs, seed: 9)
    #expect(r.intensity == 0)
    _ = fall(&r, [.space(nil)], for: T.codeRise, rate: 6)  // 6 keys a second (I* 1): up with τ `codeRise`
    #expect(near(r.intensity, 1 - exp(-1), 0.005))
    _ = fall(&r, [.space(nil)], for: 1.0 / 60, rate: 0)  // the last key, and the window empty: it holds `codeHold`
    let held = r.intensity
    _ = fall(&r, for: T.codeHold - 0.02, rate: 0)
    #expect(r.intensity == held && r.frameRate == 60)
    _ = fall(&r, for: 0.02 + T.codeSettle, rate: 0)  // then down with τ `codeSettle`
    #expect(near(r.intensity, held * exp(-1), 0.01))
    _ = fall(&r, for: 3, rate: 0)
    #expect(r.intensity < 0.05 && r.frameRate == 30)  // at rest again: 30 Hz
    // Every magnitude between its rest and its typing value: denser and brighter, not faster (pass 25): brighter heads,
    // halos and trails at once, more heads and longer trails as the new ones come down.
    var calm = Code(stage: stage, glyphs: glyphs, seed: 9), busy = Code(stage: stage, glyphs: glyphs, seed: 9)
    let a = fall(&calm, for: 4), b = fall(&busy, for: 4, rate: 6)
    #expect(near(busy.intensity, 1, 0.01) && b.count > a.count)
    let heads = { (o: [Sprite]) in sheets(o).main.filter { $0.colour == Sprite.packed(ink.text) }.map { Double($0.alpha) }.max()! }
    #expect(near(heads(a), T.codeHead.idle, 1e-3) && near(heads(b), T.codeHead.typing, 1e-3))
    let trail = { (o: [Sprite]) -> Double in
        let a = sheets(o).main.filter { $0.colour == Sprite.packed(ink.accent) }.map { Double($0.alpha) }
        return a.reduce(0, +) / Double(a.count)
    }
    #expect(trail(b) > 1.3 * trail(a))  // the trails' top from `codeTrailTop.idle` to its typing value at once
    let (a8, b8) = (fall(&calm, for: 4), fall(&busy, for: 4, rate: 6))
    print("code at rest and typing, 8 s: \(a8.count) and \(b8.count) sprites, \(calm.falling.count) and \(busy.falling.count) heads")
    #expect(Double(busy.falling.count) > 1.3 * Double(calm.falling.count) && busy.speed == calm.speed)
    #expect(Double(b8.count) > 1.15 * Double(a8.count))
}

@Test func aColumnKeepsItsSpeedWhateverTheIntensity() {
    // Pass 25 (the user, 2026-11-01: "I don't think the matrix code animation gets faster in the movie, it just gets
    // more intense"; matrix §2): each column's speed is drawn once from `codeSpeed`, about 2:1 between the slowest and
    // the fastest, and typing changes none of them: a key's head steps down its column at rest and at full intensity
    // alike, row for row.
    var calm = Code(stage: stage, glyphs: glyphs, seed: 9)
    var busy = calm
    let speeds = calm.speed
    #expect(speeds.count == calm.columns && speeds.allSatisfy { T.codeSpeed.contains($0) })
    #expect(speeds.min()! < 8.5 && speeds.max()! > 15.5)  // the films' spread, 2:1 between columns
    func head(_ out: [Sprite], _ r: Code) -> [Int]? {
        out.first { $0.kind == .glyph && slot($0) == m }.flatMap { cell($0, on: r) }.map { [$0.c, $0.r] }
    }
    let key: [Event] = [.typed(slot: m, at: column(7.5))]
    var a = fall(&calm, key, for: 1.0 / 60), b = fall(&busy, key, for: 1.0 / 60, rate: 6)
    var rows: [Int] = [], same = head(a, calm) != nil && head(a, calm) == head(b, busy)
    for _ in 0..<120 {  // 2 s at 60 Hz, one at rest, one typing at 6 keys a second
        (a, b) = (fall(&calm, for: 1.0 / 60), fall(&busy, for: 1.0 / 60, rate: 6))
        same = same && head(a, calm) != nil && head(a, calm) == head(b, busy)
        rows += head(a, calm).map { [$0[1]] } ?? []
    }
    #expect(same && calm.intensity == 0 && busy.intensity > 0.95 && rows.last! - rows.first! >= 14)
    #expect(calm.speed == speeds && busy.speed == speeds)
}

@Test func codeBuildsInAtTheSummon() {
    // Pass 27b (the user, 2026-11-02, of pass 27's Code: "it should build in, not start the animation so in your
    // face"): the rain stepped ahead at the birth is veiled, every head and lit cell of it, and builds in over
    // `codeBuildIn` on a smoothstep, while the heads that start from the show on fall in at their full alpha: a few
    // streams in the first half second, about half the rest's light at half the time, the rest's own from
    // `codeBuildIn` on (pass 27 showed the whole curtain in the first frame).
    #expect(Code.veil(at: 0) == 0 && Code.veil(at: T.codeBuildIn / 2) == 0.5 && Code.veil(at: T.codeBuildIn) == 1)
    #expect(Code.veil(at: T.codeBuildIn / 8) < 0.05 && Code.veil(at: 2 * T.codeBuildIn) == 1)
    /// The main sheet's share of the cells drawn, its light (the sum of its alphas), and its heads at their full alpha.
    func look(_ out: [Sprite], _ r: Code) -> (cover: Double, light: Double, heads: Int) {
        let main = sheets(out).main
        return (Double(main.count) / Double(r.columns * r.rows), main.reduce(0) { $0 + Double($1.alpha) },
                main.filter { $0.colour == Sprite.packed(ink.text) && near(Double($0.alpha), T.codeHead.idle, 1e-3) }.count)
    }
    var lines: [String] = []
    for seed in UInt64(1)...4 {
        var r = Code(stage: stage, glyphs: glyphs, seed: seed)
        let first = look(fall(&r, for: 1.0 / 30, hz: 30), r)
        let half = look(fall(&r, for: 0.5 - 1.0 / 30, hz: 30), r)
        let middle = look(fall(&r, for: T.codeBuildIn / 2 - 0.5, hz: 30), r)
        let built = look(fall(&r, for: T.codeBuildIn / 2, hz: 30), r)
        var rest: [(cover: Double, light: Double, heads: Int)] = []
        for _ in 0..<8 { rest.append(look(fall(&r, for: 1, hz: 30), r)) }  // a second apart after the build-in
        let cover = rest.map(\.cover).reduce(0, +) / 8, light = rest.map(\.light).reduce(0, +) / 8
        lines.append("seed \(seed): cells drawn \(Int(first.cover * 100)), \(Int(half.cover * 100)), \(Int(middle.cover * 100)), \(Int(built.cover * 100)) % (rest \(Int(cover * 100))); light \(Int(first.light)), \(Int(half.light)), \(Int(middle.light)), \(Int(built.light)) (rest \(Int(light))); heads at full at 0.5 s \(half.heads)")
        #expect(first.cover < 0.01 && first.light < 0.01 * light)  // the dim opens nearly empty
        #expect(half.cover < 0.2 * cover && half.light < 0.1 * light && half.heads >= 3)  // a few streams arriving
        #expect(middle.light > 0.3 * light && middle.light < 0.8 * light)  // half way
        #expect(near(built.cover, cover, 0.1 * cover) && near(built.light, light, 0.15 * light))  // the rest's look
    }
    print("code building in, at the first frame, 0.5 s, \(T.codeBuildIn / 2) s and \(T.codeBuildIn) s:\n" + lines.joined(separator: "\n"))
}

@Test func aKeyDuringTheBuildInStartsItsHeadAtOnce() throws {
    // Pass 27b: a key while the curtain is still veiled starts its head at once where the key is, at its full alpha,
    // over its halo, its trail brighter than any veiled cell can be.
    var r = Code(stage: stage, glyphs: glyphs, seed: 3)
    _ = fall(&r, for: 0.2, hz: 30)
    #expect(r.veil < 0.02)
    let out = fall(&r, [.typed(slot: m, at: column(7.5))], for: 1.0 / 60)
    let i = try #require(out.firstIndex { $0.kind == .glyph && slot($0) == m })
    #expect(near(Double(out[i].alpha), T.codeKeyHead, 1e-3) && out[i].w > 0)
    #expect(i > 0 && out[i - 1].kind == .ring && near(Double(out[i - 1].alpha), T.codeKeyHalo, 1e-3))
    #expect(abs(Double(out[i].x) - 1512 * (0.1 + 0.8 * 7.5 / 15)) <= 0.4 * 1512 * 0.8 / 15 + 18.5)
    let at = try #require(cell(out[i], on: r))
    let later = fall(&r, for: 0.7)
    let head = try #require(later.first { $0.kind == .glyph && slot($0) == m }.flatMap { cell($0, on: r) })
    let trail = sheets(later).main.filter {
        cell($0, on: r).map { $0.c == at.c && $0.r >= at.r && $0.r < head.r - T.codeNeckCells } ?? false
    }
    #expect(r.veil < 0.2 && trail.count >= 3)
    #expect(trail.map(\.alpha).max().map { Double($0) > T.codeTrailTop.idle * T.codeGain.upperBound * r.veil } ?? false)
}

@Test func typingLiftsTheCurtainMoreThanInPass27() {
    // Pass 27b (the user, 2026-11-02, of pass 27's Code: "it is way less reactive (which is okay, but it could be just
    // a bit more"): the light of the main sheet (the sum of its alphas) and its cells brighter than 0.3, each a mean
    // over 2 s, typing at `codeFast` keys a second against at rest, both 4 s after the build-in, over four seeds.
    // Pass 27 measured 2.16 and 2.67 times; now at least 15 and 20 % more, with the rest within a tenth of pass 27's
    // light (its trail's top 0.55, now `codeTrailTop.idle`) and the keys' heads over halos brighter than any other.
    let line = Array("the boats sat low in the water and the reeds bent over them ")
    func measure(_ seed: UInt64, keys: Double) -> (light: Double, bright: Double, keyHalo: Float, otherHalo: Float) {
        var r = Code(stage: stage, glyphs: glyphs, seed: seed), out: [Sprite] = []
        var (next, typed, light, bright, n) = (0.0, 0, 0.0, 0.0, 0), (keyHalo, otherHalo): (Float, Float) = (0, 0)
        let warm = T.codeBuildIn + 4
        for f in 0..<Int((warm + 2) * 30) {
            let t = Double(f) / 30
            var events: [Event] = []
            while keys > 0, next <= t {
                let c = line[typed % line.count]
                events.append(c == " " ? .space(key(c)) : .typed(slot: glyphs.slot(c), at: key(c)))
                (typed, next) = (typed + 1, next + 1 / keys)
            }
            out.removeAll()
            r.step(dt: 1.0 / 30, events: events, rate: min(Double(typed), keys * 2) / 2, into: &out)
            guard t >= warm else { continue }
            let main = sheets(out).main
            light += main.reduce(0) { $0 + Double($1.alpha) }
            bright += Double(main.filter { $0.alpha > 0.3 }.count)
            n += 1
            for i in out.indices.dropLast() where out[i].kind == .ring {  // a halo, then its head
                if out[i + 1].w > 0 { keyHalo = max(keyHalo, out[i].alpha) } else { otherHalo = max(otherHalo, out[i].alpha) }
            }
        }
        return (light / Double(n), bright / Double(n), keyHalo, otherHalo)
    }
    var (lights, brights, rests): ([Double], [Double], [Double]) = ([], [], [])
    for seed in UInt64(1)...4 {
        let (rest, busy) = (measure(seed, keys: 0), measure(seed, keys: T.codeFast))
        (lights, brights, rests) = (lights + [busy.light / rest.light], brights + [busy.bright / rest.bright],
                                    rests + [rest.light])
        #expect(near(Double(busy.keyHalo), T.codeKeyHalo, 1e-3) && busy.otherHalo < busy.keyHalo)
    }
    let (light, bright) = (lights.reduce(0, +) / 4, brights.reduce(0, +) / 4), rest = rests.reduce(0, +) / 4
    print("code typing against at rest: light \(light) times, cells over 0.3 \(bright) times (pass 27: 2.16, 2.67); the light at rest \(rest) (pass 27: 667)")
    #expect(light > 2.16 * 1.15 && bright > 2.67 * 1.2)
    #expect(near(rest, 667, 0.1 * 667))  // the rest kept close to pass 27's
}

/// The most and the mean sprites Code draws on `size` over 7 s after its build-in, at rest or typing at `keys` a second
/// on the keys of a sentence (the rate as `Typing` counts it), and the mean CPU time a step took in the best of its 14
/// batches of 30 steps (this thread's: the suite runs in parallel, and a batch on an efficiency core takes two to three
/// times as long).
private func sprites(on size: CGSize, keys: Double) -> (most: Int, mean: Int, drawn: Int, ms: Double) {
    let b = BoxFrame.line(in: CGRect(x: 0, y: 80, width: size.width, height: size.height - 114), height: 112)
    var r = Code(stage: Ambience.Stage(size: size, box: b, style: style), glyphs: glyphs, seed: 13)
    let line = Array("the boats sat low in the water and the reeds bent over them ")
    var out: [Sprite] = [], most = 0, sum = 0, drawn = 0, next = 0.0, typed = 0, ns: UInt64 = 0, best = UInt64.max
    out.reserveCapacity(T.cap)
    let from = Int(T.codeBuildIn * 60), frames = from + 420  // 7 s after the build-in (pass 27b; after 3 s before)
    for f in 0..<frames {
        let t = Double(f) / 60
        var events: [Event] = []
        while keys > 0, next <= t {
            let c = line[typed % line.count]
            events.append(c == " " ? .space(key(c)) : .typed(slot: glyphs.slot(c), at: key(c)))
            (typed, next) = (typed + 1, next + 1 / keys)
        }
        out.removeAll(keepingCapacity: true)
        let start = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)  // this thread's: the suite runs in parallel
        r.step(dt: 1.0 / 60, events: events, rate: min(Double(typed), keys * 2) / 2, into: &out)
        if f >= from {
            (most, sum, drawn) = (max(most, r.shown), sum + r.shown, max(drawn, out.count))
            ns += clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID) - start
            if (f - from + 1) % 30 == 0 { (best, ns) = (min(best, ns), 0) }
        }
    }
    return (most, sum / (frames - from), drawn, Double(best) / 30 / 1e6)
}

@Test func codeStaysUnderTheCapTypingOnALargeScreen() {
    // Every lit cell is a sprite (pass 27: about 3,500 at rest on a laptop's screen, 200 before), and as many again
    // for every 1,000 pt more of height and width: under the cap on a 6K display (3008 × 1692 pt) while typing (since
    // pass 27b, 20,000 for its 16,000). A step at rest, 30 a second, stays well under 4 ms in this debug build,
    // typing on a large screen under a 60 Hz frame (in release, `swift test -c release`, about 0.02 and 0.09 ms).
    let laptop = CGSize(width: 1512, height: 982), large = CGSize(width: 2560, height: 1440)
    let sixK = CGSize(width: 3008, height: 1692)
    let counts = [(laptop, 0.0), (laptop, 6), (large, 0), (large, 6), (large, 10), (sixK, 0), (sixK, 6)].map { (size, keys) in
        (size, keys, sprites(on: size, keys: keys))
    }
    for (size, keys, n) in counts {
        print("code sprites \(Int(size.width)) × \(Int(size.height)) at \(keys) keys/s: mean \(n.mean), most \(n.most), a step \(String(format: "%.2f", n.ms)) ms")
    }
    #expect(counts.allSatisfy { $0.2.most < T.cap && $0.2.drawn == $0.2.most })  // nothing thinned on any screen
    #expect(counts[0].2.mean < counts[1].2.mean && counts[2].2.mean < counts[3].2.mean)  // typing busier
    let (calm, busy) = (min(counts[0].2.ms, sprites(on: laptop, keys: 0).ms), counts[3].2.ms)  // the better of two runs
    print("code step: \(calm) ms at rest on 1512 × 982, \(busy) ms typing on 2560 × 1440")
    #expect(calm < 4 && busy < 16, "\(calm) ms at rest on 1512 × 982, \(busy) ms typing on 2560 × 1440")
}

@Test func aStageBeyondTheCapLosesItsDimmestCellsNotItsEdge() {
    // A stage with more lit cells than `Tuning.cap` (here 5120 × 2880 pt, four laptop screens and more): the scene
    // raises the alpha a trail cell needs, frame by frame, so the dimmest go and the rain still reaches the right edge
    // (drawn column by column, a cap alone would cut the columns on the right).
    let size = CGSize(width: 5120, height: 2880)
    var r = Code(stage: Ambience.Stage(size: size, style: style), glyphs: glyphs, seed: 2)
    var out: [Sprite] = []
    for _ in 0..<Int((T.codeBuildIn + 2) * 30) { out = fall(&r, for: 1.0 / 30, hz: 30) }  // 2 s after the build-in
    let main = sheets(out).main
    print("code on 5120 × 2880: \(out.count) sprites, \(r.shown) shown, under \(r.cut) not drawn")
    #expect(out.count <= T.cap && r.cut > T.codeShown && r.shown <= T.cap)
    #expect(main.map(\.x).max()! > Float(size.width) - 4 * Float(r.pitch) && main.map(\.x).min()! < 4 * Float(r.pitch))
    #expect(main.filter { $0.colour == Sprite.packed(ink.accent) }.allSatisfy { Double($0.alpha) > r.cut / 1.25 })
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
    var run = Ambience.Run(mode: .code, stage: stage, glyphs: glyphs, seed: 1), out: [Sprite] = []
    run.take((0..<3000).map { Ambience.Key(t: Double($0) / 1000, kind: .glyph("m"), code: 0x2E) })
    _ = run.frame(at: 3, dt: 1.0 / 60, into: &out)
    #expect(out.count <= T.cap && run.count <= T.cap && out.contains { $0.kind == .glyph && slot($0) == m })
}

// MARK: Still water (pass 24)

/// Still water stepped `seconds` at 30 Hz, `events(frame)` and `rate` in each step; the most drops and sprites alive at
/// once, every drop that landed (where), and the last step's sprites.
private func pond(_ w: inout Water, for seconds: Double, events: (Int) -> [Event] = { _ in [] }, rate: Double = 0)
    -> (most: Int, sprites: Int, landed: [CGPoint], out: [Sprite]) {
    var out: [Sprite] = [], most = 0, sprites = 0, landed: [CGPoint] = []
    for f in 0..<Int((seconds * 30).rounded()) {
        let before = w.landed
        out.removeAll()
        w.step(dt: 1.0 / 30, events: events(f), rate: rate, into: &out)
        landed += w.drops.suffix(w.landed - before).map { CGPoint(x: $0.x, y: $0.y) }  // the new ones, last
        (most, sprites) = (max(most, w.drops.count), max(sprites, out.count))
    }
    return (most, sprites, landed, out)
}

@Test func stillWaterDropsAtRestAtItsRateScaledToTheScreen() {
    // waterRate a second on a 1512 × 982 pt screen (0.5: a mean of 2 s apart), by the area on another; one at the
    // show above the middle of the box's top edge; every one at least 48 pt clear of the box; 30 Hz.
    let large = CGSize(width: 2560, height: 1440)
    for (size, rate) in [(screen, T.waterRate), (large, T.waterRate * 2560 * 1440 / (1512 * 982))] {
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

/// Where the drop of a word whose last key is `k` lands on `stage` (the panel's canvas): pass 16's place across the
/// screen, and the key's row between 40 pt under the top edge (the number row) and 48 pt above the box (the space
/// bar's); without a place at the caret's x, 48 pt above the box.
private func wordSpot(_ k: Keyboard.Position?) -> CGPoint {
    let low = Double(box.maxY) + 48, high = Double(screen.height) - 40
    return CGPoint(x: stage.screenX(k) ?? Double(stage.caret), y: low + (1 - (k?.down ?? 1)) * (high - low))
}

@Test func stillWaterDropsOneForEachWordAndNoneForAKey() {
    // Pass 25 (the user, 2026-11-01: "the rain drops should probably also be increasing when typing as well"; AM1 per
    // word + rest): glyph keys, ⌫ and the typing rate change nothing a frame draws, a flood of them for two minutes.
    var calm = Water(stage: stage, glyphs: glyphs, seed: 5)
    var typed = calm
    let keys: [Event] = [.typed(slot: m, at: key("m")), .backspace(nil), .typed(slot: m, at: key("q"))]
    var same = true, drawn = 0
    for _ in 0..<(30 * 120) {
        var a: [Sprite] = [], b: [Sprite] = []
        calm.step(dt: 1.0 / 30, events: [], rate: 0, into: &a)
        typed.step(dt: 1.0 / 30, events: keys, rate: 12, into: &b)
        (same, drawn) = (same && a == b, drawn + a.count)
    }
    #expect(same && drawn > 0 && calm.landed == typed.landed && calm.landed > 5)
    // A word's end (Space or Return after a glyph key): one drop, where the word's last key is, higher the higher its
    // row; none for a Space that ends no word, none within 0.8 s of the last word's; a key without a place: the caret.
    var w = Water(stage: stage, glyphs: glyphs, seed: 5)
    let words: [Int: [Event]] = [
        0: [.typed(slot: m, at: key("m")), .typed(slot: m, at: key("o")), .space(key(" "))],  // "mo ": at o
        3: [.typed(slot: m, at: key("a")), .space(key(" "))],  // 0.1 s on: too soon, none
        30: [.space(key(" ")), .paragraph(key("\n"))],  // 1 s: no word before them
        33: [.typed(slot: m, at: column(3, row: 0)), .paragraph(key("\n"))],  // a Return ends it: the number row's
        60: [.typed(slot: glyphs.slot("é"), at: nil), .space(key(" "))],  // the accent menu's pick: no place
    ]
    let spots = [wordSpot(key("o")), wordSpot(column(3, row: 0)), wordSpot(nil)]
    let landed = pond(&w, for: 3, events: { words[$0] ?? [] }).landed
    #expect(landed.filter { spots.contains($0) } == spots, "\(landed)")  // each once, in order, no other word's
    #expect(spots[1].y == 982 - 40 && spots[2].y == Double(box.maxY) + 48 && spots[2].x == Double(stage.caret))
    #expect(abs(spots[0].x - 1512 * (0.1 + 0.8 * 10 / 15)) < 1e-9 && spots[0].y < spots[1].y && spots[0].y > spots[2].y)
    // Through a run: the keys as the line hands them on, a word's drop at its last key; 30 Hz throughout.
    var run = Ambience.Run(mode: .water, stage: stage, glyphs: glyphs, seed: 9), out: [Sprite] = []
    run.take([Ambience.Key(t: 0, kind: .glyph("o"), code: 0x1F), Ambience.Key(t: 0.1, kind: .space, code: 0x31)])
    _ = run.frame(at: 0.1, dt: 1.0 / 30, into: &out)
    #expect((run.scene as? Water)?.drops.contains { $0.x == spots[0].x && $0.y == spots[0].y } == true)
    #expect(run.frameRate == 30)
}

@Test func stillWatersRestRateHoldsWhileWriting() {
    // A word every 1.5 s for 2,000 s: the drops that are not the words' still land at `waterRate` a second (± 15 %),
    // every one 48 pt clear of the box; every word's drop lands, at its last key.
    var w = Water(stage: stage, glyphs: glyphs, seed: 21)
    let word: [Event] = [.typed(slot: m, at: key("t")), .typed(slot: m, at: key("e")), .space(key(" "))]
    let p = pond(&w, for: 2000, events: { $0 % 45 == 0 ? word : [] }, rate: 4)
    let spot = wordSpot(key("e")), rest = p.landed.filter { $0 != spot }, words = p.landed.count - rest.count
    print("still water writing: \(words) words' drops, \(rest.count) at rest in 2000 s"
          + " (\(T.waterRate * 2000) expected), at most \(p.most) at once")
    let typed = (2000 * 30 + 44) / 45  // frames 0, 45, … of 60,000
    #expect(words == typed)
    #expect(abs(Double(rest.count) - T.waterRate * 2000) < 0.15 * T.waterRate * 2000)
    #expect(rest.allSatisfy { !box.insetBy(dx: -48, dy: -48).contains($0) })
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
    // With time: the lead crest's alpha falls frame on frame, as e^(−t/waterDecay) · √(12 / r).
    var lead: [Double] = [one.first!.a]
    for s in [1.5, 2, 2.5, 3] { lead += at(s).prefix(1).map(\.a) }
    #expect(lead.count >= 4 && zip(lead, lead.dropFirst()).allSatisfy { $0 > $1 }, "\(lead)")
    #expect(near(lead[0], peak * exp(-1 / T.waterDecay) * (12 / one[0].r).squareRoot(), 2e-3))
    // Gone by 4.5 s, its rings under 0.01 long before.
    #expect(at(T.waterLife + 0.1).isEmpty && !w.drops.contains { $0.x == 700 && $0.y == 500 })
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
    // Writing at 10 words a second for a minute (pass 25): a word's drop at most every 0.8 s, under the cap.
    var fast = Water(stage: Ambience.Stage(size: large, box: b, style: style), glyphs: glyphs, seed: 13)
    let word: [Event] = [.typed(slot: m, at: key("o")), .space(key(" "))]
    let typing = pond(&fast, for: 60, events: { $0 % 3 == 0 ? word : [] }, rate: 50)
    let (low, high) = (Double(b.maxY) + 48, 1440.0 - 40), o = key("o")!
    let spot = CGPoint(x: 2560 * (0.1 + 0.8 * o.across), y: low + (1 - o.down) * (high - low))
    let words = typing.landed.filter { $0 == spot }.count
    print("still water on 2560 × 1440 at 10 words a second: at most \(typing.most) drops, \(typing.sprites) sprites;"
          + " \(words) words' drops and \(typing.landed.count - words) at rest in 60 s")
    #expect(typing.most < T.waterDrops && typing.sprites <= T.cap && fast.count <= T.cap)
    #expect((66...76).contains(words))  // one every 0.8–0.9 s (the 30 Hz steps), not ten a second
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

@Test(.enabled(if: Ambience.Renderer.available)) func codesGlyphsDrawMirroredSoftAndInKatakana() throws {
    // Pass 27: a glyph sprite of negative width is its glyph mirrored left to right (the vertex shader runs the quad's
    // corners and the atlas cell the other way, nothing more); a blur of 2 samples two mipmap levels softer, fainter
    // at the core and wider; a katakana slot draws the fallback's glyph from the atlas.
    let renderer = try #require(Ambience.Renderer(font: menlo)), g = renderer.glyphs
    let size = CGSize(width: 100, height: 100), centre = CGPoint(x: 50, y: 50), z = try #require(g.slot("Z"))
    func frame(_ s: Sprite) throws -> [UInt8] { try #require(renderer.offscreen([s], size: size, scale: 2)) }
    func alpha(_ f: [UInt8], _ x: Int, _ y: Int) -> Int { Int(f[4 * (y * 200 + x) + 3]) }  // pixels, rows from the top
    let plain = try frame(g.sprite(z, centre: centre, scale: T.codeScale, alpha: 1, colour: 0xffffff))
    let mirrored = try frame(g.sprite(z, centre: centre, scale: T.codeScale, alpha: 1, colour: 0xffffff, mirrored: true))
    var differ = 0, inked = 0
    for y in 0..<200 {
        for x in 0..<200 {
            if alpha(plain, x, y) > 0 { inked += 1 }
            if abs(alpha(mirrored, x, y) - alpha(plain, 199 - x, y)) > 2 { differ += 1 }
        }
    }
    #expect(inked > 100 && differ == 0 && mirrored != plain)  // Z's diagonal runs the other way
    let soft = try frame(g.sprite(z, centre: centre, scale: T.codeScale * T.codeNear, alpha: 1, colour: 0xffffff, blur: 2))
    let sharp = try frame(g.sprite(z, centre: centre, scale: T.codeScale * T.codeNear, alpha: 1, colour: 0xffffff))
    let peak = { (f: [UInt8]) in stride(from: 3, to: f.count, by: 4).map { Int(f[$0]) }.max()! }
    let over = { (f: [UInt8], t: Int) in stride(from: 3, to: f.count, by: 4).filter { Int(f[$0]) > t }.count }
    #expect(peak(sharp) >= 250 && peak(soft) < peak(sharp) && over(soft, 8) > over(sharp, 8))
    let kana = try #require(g.slot("ｱ"))
    let a = try frame(g.sprite(kana, centre: centre, scale: T.codeScale, alpha: 1, colour: 0xffffff, mirrored: true))
    #expect(over(a, 128) > 60 && g.face[kana] == 1)
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

/// Code after 10 s of typing at 6 keys a second and 0.6 s after a Return, drawn by the Metal pipeline over a dimmed
/// dark app with the box on it, as the box's screen shows it: app/renders/ambience-code.png (each mode's until pass 24,
/// which removed Drift, Rings and Grid and with them ambience-grid-keyboard.png; ambience-rain.png until pass 25); Code
/// at rest 3 s after its build-in (ambience-code-idle.png, pass 19b; 3 s after the summon until pass 27b), and building
/// in, 0.5 s after the summon and at half of `codeBuildIn` (ambience-code-build-500ms.png and
/// ambience-code-build-2000ms.png, pass 27b). Still water's renders are Still's (`stillWaterShowsOnStillsDayAndNightDim`).
@Test(.enabled(if: Ambience.Renderer.available)) func ambienceRenders() throws {
    let renderer = try #require(Ambience.Renderer(font: menlo))
    let words = "the boats sat low in the water and the reeds bent over them"
    let r = typing(Array(words) + ["\n"] + Array("as"), .code, rate: 6, after: 0.27)
    let typed = try #require(r.alpha)
    #expect(!r.out.isEmpty)
    try compose(try #require(renderer.offscreen(r.out, size: screen, scale: 2, alpha: typed)), text: r.text,
                name: "ambience-code.png")
    // Code from the summon on at rest, building in and then as it rests (ambience-code.png above is Code while typing).
    var idle = Ambience.Run(mode: .code, stage: stage, glyphs: glyphs, seed: 11), out: [Sprite] = []
    var (a, f): (Double?, Int) = (nil, 0)
    for (seconds, name) in [(0.5, "ambience-code-build-500ms.png"),
                            (T.codeBuildIn / 2, "ambience-code-build-\(Int(T.codeBuildIn / 2 * 1000))ms.png"),
                            (T.codeBuildIn + 3, "ambience-code-idle.png")] {
        while Double(f) / 30 < seconds - 1e-9 {  // at 30 Hz
            a = idle.frame(at: Double(f) / 30, dt: 1.0 / 30, into: &out)
            f += 1
        }
        let alpha = try #require(a)
        try compose(try #require(renderer.offscreen(out, size: screen, scale: 2, alpha: alpha)), text: Text(String(words)),
                    name: name)
    }
}

/// Code at rest on Still's day dim (TH1, architecture §7): its ink laid over shows, where light added (Lemna's text
/// colour in both of Code's roles) would not. Code's frame 3 s after its build-in, in Menlo at Still's size (the atlas's face under a proportional line), laid
/// over the wash over a white app as Core Animation lays the ambience's layer over the shade; counted are the pixels
/// that differ from the wash alone by 8 or more of 255 in a channel. Written as app/renders/ambience-code-still-day.png,
/// beside the box at rest by day and by night (idle-still-day.png over a light app, idle-still-night.png over a dark
/// one) and Code at rest on Still's night (ambience-code-still-night.png, its ink added).
@Test(.enabled(if: Ambience.Renderer.available)) func codeShowsOnStillsDayDim() throws {
    let font = try #require(stillFont)  // Literata from app/Fonts, registered once for every test (ThemeTests)
    let renderer = try #require(Ambience.Renderer(font: Ambience.Glyphs.atlasFont(for: font)))
    let day = Style(.still, dark: false, font: font), night = Style(.still, dark: true, font: font)
    func code(_ stage: Ambience.Stage, scale: CGFloat) throws -> [UInt8] {
        var run = Ambience.Run(mode: .code, stage: stage, glyphs: renderer.glyphs, seed: 11), out: [Sprite] = []
        var a: Double?
        for f in 0..<Int((T.codeBuildIn + 3) * 30) {  // 3 s after the build-in (pass 27b; 3 s after the summon before)
            a = run.frame(at: Double(f) / 30, dt: 1.0 / 30, into: &out)
        }
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
    let (ours, light) = (shown(try code(stillInk, scale: 1)), shown(try code(added, scale: 1)))
    print("code on Still's day dim: \(ours) pixels show in its ink, \(light) in light added")
    #expect(ours > 1500 && light * 10 < ours)
    let words = Text("the boats sat low in the water and the reeds bent over them")
    try compose(try code(stillInk, scale: 2), text: words, name: "ambience-code-still-day.png", look: day, lightApp: true)
    try compose(try code(Ambience.Stage(size: screen, box: box, style: night), scale: 2), text: words,
                name: "ambience-code-still-night.png", look: night)
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
/// the drop at the show 1.2 s on, two drops whose rings cross to its left (0.9 and 0.6 s old) and a word's to its right
/// (1.0 s; pass 25: its last key o, one row under the number row, so high up and right of the middle). Counted, as `codeShowsOnStillsDayDim` counts them, are the pixels that differ from the wash alone by 8
/// or more of 255 in a channel by day (laid over, over a white app) and by 4 or more by night (added, over a dark one).
/// Written as app/renders/ambience-water-day.png and ambience-water-night.png.
@Test(.enabled(if: Ambience.Renderer.available)) func stillWaterShowsOnStillsDayAndNightDim() throws {
    #expect(Theme.still.defaults.ambience == .water && Theme.lemna.defaults.ambience == nil)  // the presets (TH1)
    let font = try #require(stillFont)  // registered first (the tests run in parallel)
    let renderer = try #require(Ambience.Renderer(font: Ambience.Glyphs.atlasFont(for: font)))
    let day = Style(.still, dark: false, font: font), night = Style(.still, dark: true, font: font)
    let shown = BoxFrame.line(in: CGRect(x: 0, y: 80, width: 1512, height: 868), height: BoxFrame.height(fontSize: day.size))
    func water(_ look: Style, scale: CGFloat) throws -> [UInt8] {
        let stage = Ambience.Stage(size: screen, box: shown, inset: 1, corner: 16, style: look)
        var w = Water(stage: stage, glyphs: renderer.glyphs, seed: 4), out: [Sprite] = []
        let word: [Event] = [.typed(slot: renderer.glyphs.slot("o"), at: key("o")), .space(key(" "))]
        for f in 0..<36 {  // 1.2 s at 30 Hz
            if f == 9 { w.drop(x: 470, y: 760) }
            if f == 18 { w.drop(x: 500, y: 748) }
            out.removeAll()
            w.step(dt: 1.0 / 30, events: f == 6 ? word : [], rate: 0, into: &out)
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
