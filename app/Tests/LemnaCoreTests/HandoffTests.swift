// The hand-off's motion (DESIGN.md F1's H1 and C1, pass 17b): where each glyph is and when, the box's collapse and the
// dim's lift, when it plays at all, and renders of it over a light app; since pass 24 MO1's ring under Still: when it
// plays, where each line of it is and when, its alpha and the wash's lift, and a render. No Foundation here (see
// RenderTests.swift).
import CoreGraphics
import CoreText
import Testing
@testable import LemnaCore

private typealias T = Effects.Tuning

/// The box on a 1512 pt screen (60 %: 907 pt) as the app lays it out: the line inside its 1 pt border, the band across
/// the line's middle, the pieces cut at 2× in the band's own points (the strip's), placed by the band's origin.
private enum Geometry {
    static let box = CGSize(width: 907, height: 112), style = Style(font: menlo), scale: CGFloat = 2
    static let line = CGSize(width: box.width - 2, height: box.height - 2)
    static let band = Line.band(in: line, style: style)  // in the line: (0, 27, 905, 56)
    static let strip = CGRect(origin: .zero, size: band.size)  // the band as the strip draws it
    static let origin = CGPoint(x: 1 + band.minX, y: 1 + band.minY)  // the strip's origin in the box
    static let caret = Line.caretRect(in: strip, style: style)
}

private func pieces(_ text: Text) -> [Handoff.Piece] {
    Handoff.pieces(Line.shape(text, marked: "", font: menlo), before: 0, after: 0, band: Geometry.strip,
                   style: Geometry.style, scale: Geometry.scale)
}

/// A piece's left edge, or bottom edge, in the box at `t`.
private func edge(_ p: Handoff.Piece, _ way: Handoff.Way, at t: Double) -> CGFloat {
    let reach = Handoff.reach(way, box: Geometry.box)
    return way == .send ? Geometry.origin.x + p.rect.minX + Handoff.offset(p, .send, reach: reach, at: t)
        : Geometry.origin.y + p.rect.minY + Handoff.offset(p, .rise, reach: reach, at: t)
}

/// Gone: wholly past the box's right edge (send) or its top edge (rise), where its rounded clip ends.
private func gone(_ p: Handoff.Piece, _ way: Handoff.Way, at t: Double) -> Bool {
    edge(p, way, at: t) >= (way == .send ? Geometry.box.width : Geometry.box.height)
}

private let sentence = Text("The line glides left and the old words fade.\nNext one")
private let long = Text(String(String(repeating: "the quick brown fox jumps over the lazy dog, ", count: 56).prefix(2500)))

@Test func theLineIsCutIntoTheGlyphsItShows() {
    #expect(long.plainText.count == 2500)
    let cut = pieces(long)
    // What shows of it: the text before the caret from 25 % to 60 % of 905 pt, about 19 Menlo cells at 28 pt.
    #expect((19...21).contains(cut.count) && cut.allSatisfy { !$0.after })
    #expect(cut.map(\.rank).sorted() == Array(0..<cut.count))  // from the caret outwards, none left out
    let byX = cut.sorted { $0.rect.minX < $1.rect.minX }
    for (a, b) in zip(byX, byX.dropFirst()) { #expect(a.rect.maxX <= b.rect.minX && b.rank == a.rank - 1) }  // tiled
    #expect(byX.last!.rect.maxX <= Geometry.caret.minX && byX.last!.rank == 0)  // the caret in none
    #expect(byX.first!.rect.minX + advance / 2 > 0.25 * Geometry.strip.width - advance)  // nothing from the clear end
    for p in cut {  // on whole pixels at 2×, as tall as the font and inside the band
        #expect(p.rect.minX * 2 == (p.rect.minX * 2).rounded() && p.rect.maxY * 2 == (p.rect.maxY * 2).rounded())
        #expect(p.rect.minY >= 0 && p.rect.maxY <= Geometry.strip.height && p.rect.height > CTFontGetAscent(menlo))
        let px = p.pixels(bandHeight: Geometry.strip.height, scale: 2)
        #expect(px.width == 2 * p.rect.width && px.minY == 2 * (Geometry.strip.height - p.rect.maxY))
    }
}

@Test func aPasteSendsTheGlyphsOffTheRightEdgeFromTheCaretOutwards() {
    let frame1 = 1.0 / 120  // the first 120 Hz frame after the key-down
    for text in [sentence, long] {
        let cut = pieces(text), first = cut.first { $0.rank == 0 }!
        // Frame 1: the glyph at the caret has gone at least 30 % of its way to the box's right edge (42 %: 160 pt of
        // 380), on easeOutQuint; the panel's ease-in would have moved it 1 %.
        let way = Geometry.box.width - (Geometry.origin.x + first.rect.minX)
        #expect(edge(first, .send, at: frame1) - edge(first, .send, at: 0) >= 0.3 * way)
        #expect(first.start(.send) == 0)
        // 7 ms apart from the caret outwards; the last that shows sets off by the cap, 120 ms, whatever the line's length.
        for p in cut { #expect(abs(p.start(.send) - min(Double(p.rank) * 0.007, 0.120)) < 1e-12) }
        #expect(cut.map { $0.start(.send) }.max()! <= 0.120)
        // The line has left by 200 ms, every glyph long before 260 ms; none has left before it set off.
        #expect(cut.allSatisfy { gone($0, .send, at: 0.200) })
        #expect(cut.allSatisfy { !gone($0, .send, at: $0.start(.send)) })
        // No glyph runs into the one ahead of it, at any frame.
        let byX = cut.sorted { $0.rect.minX < $1.rect.minX }
        for i in 0...68 {
            let t = Double(i) / 240
            for (a, b) in zip(byX, byX.dropFirst()) {
                #expect(edge(a, .send, at: t) + a.rect.width <= edge(b, .send, at: t) + 1e-6)
            }
        }
    }
}

@Test func theTextAfterTheCaretLeavesWithItAndACopyRisesBothWays() {
    let middle = Text("The line glides left and the old words fade.\nNext one", caret: 15)  // in "glides"
    let cut = pieces(middle), after = cut.filter(\.after), before = cut.filter { !$0.after }
    #expect(!after.isEmpty && !before.isEmpty)
    #expect(after.allSatisfy {  // on the nearest whole pixel to the clip
        $0.rect.minX >= Geometry.caret.maxX && $0.rect.maxX <= 0.95 * Geometry.strip.width + 0.25
    })
    // Sent right, the text after the caret is ahead of it and sets off at once with the glyph at the caret.
    #expect(after.allSatisfy { $0.start(.send) == 0 })
    let byX = cut.sorted { $0.rect.minX < $1.rect.minX }
    for i in 0...68 {
        let t = Double(i) / 240
        for (a, b) in zip(byX, byX.dropFirst()) { #expect(edge(a, .send, at: t) + a.rect.width <= edge(b, .send, at: t) + 1e-6) }
    }
    #expect(cut.allSatisfy { gone($0, .send, at: 0.200) })
    // Rising (C1), both sides go from the caret outwards, 7 ms apart up to the cap; the glyph at the caret has gone 30 %
    // of its way to the box's top edge at frame 1, and every glyph is past that edge by 200 ms.
    #expect(after.allSatisfy { $0.start(.rise) == min(Double($0.rank) * 0.007, 0.120) })
    #expect(after.contains { $0.rank == 0 } && before.contains { $0.rank == 0 })
    for text in [middle, long] {
        let rising = pieces(text), first = rising.first { $0.rank == 0 }!
        let way = Geometry.box.height - (Geometry.origin.y + first.rect.minY)
        #expect(edge(first, .rise, at: 1.0 / 120) - edge(first, .rise, at: 0) >= 0.3 * way)
        #expect(rising.allSatisfy { gone($0, .rise, at: 0.200) && !gone($0, .rise, at: $0.start(.rise)) })
        #expect(rising.map { $0.start(.rise) }.max()! <= 0.120)
    }
}

@Test func theDimLiftsAtOnceAndTheBoxCollapsesBy260ms() {
    #expect(Handoff.end == 0.260)  // pass 18: 280 ms before, the lift and the collapse 160 ms
    #expect(Handoff.dim(at: 0) == 1 && Handoff.dim(at: 1.0 / 120) < 0.8 && Handoff.dim(at: 0.140) == 0)
    #expect(Handoff.box(at: 0) == (1, 1) && Handoff.box(at: 0.120) == (1, 1))
    let early = Handoff.box(at: 0.120 + 1.0 / 120)
    #expect(early.alpha < 0.85 && early.scale < 0.99 && early.scale > 0.9)
    let gone = Handoff.box(at: 0.260)
    #expect(abs(gone.scale - 0.9) < 1e-12 && gone.alpha == 0 && Handoff.box(at: 1) == gone)
    #expect(Handoff.reach(.send, box: Geometry.box) == 907 && Handoff.reach(.rise, box: Geometry.box) == 140)
}

@Test func theHandOffGoesAtOnceUnderReduceMotionAndOff() {
    #expect(Handoff.leaving(Effects(), reduceMotion: false) == .motion)
    #expect(Handoff.leaving(Effects(), reduceMotion: true) == .atOnce)  // it moves, and so does Pop's fade
    var off = Effects()
    off.toggle()
    #expect(Handoff.leaving(off, reduceMotion: false) == .atOnce)
    var unticked = Effects()
    unticked.choose(.handOff)
    #expect(Handoff.leaving(unticked, reduceMotion: false) == .fade(T.close))  // as Esc's
    unticked.choose(.pop)
    #expect(Handoff.leaving(unticked, reduceMotion: false) == .atOnce)
}

// MARK: Renders

/// One frame of the hand-off `t` seconds after the key, over a light app, at 2×, composed as Core Animation composes
/// the app's layers: the app, the dim at its share of 0.5, and the box shrunk and faded about its middle, holding the
/// pieces cut from the band's last frame at their offsets and its accent border over them. Written to app/renders/
/// `name` when one is given.
private func handOffFrame(_ text: Text, _ way: Handoff.Way, at t: Double, name: String? = nil) -> [UInt8] {
    let size = CGSize(width: 1100, height: 300), (w, h) = (2200, 600), style = Geometry.style
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    // A light app: a white page with grey lines of text.
    c.setFillColor(rgb(0xffffff))
    c.fill(CGRect(origin: .zero, size: size))
    c.setFillColor(rgb(0xaeb3ba))
    for (i, len) in [620, 860, 740, 520, 900, 680, 800, 430, 760, 640, 880, 560].enumerated() {
        c.fill(CGRect(x: 40, y: size.height - 30 - CGFloat(i) * 22, width: CGFloat(len), height: 6))
    }
    c.setFillColor(rgb(style.palette.dim).copy(alpha: CGFloat(Double(style.palette.dimAlpha) * Handoff.dim(at: t)))!)
    c.fill(CGRect(origin: .zero, size: size))
    // The band's last frame, as the strip drew it.
    let shaped = Line.shape(text, marked: "", font: menlo), strip = Geometry.strip
    let b = Line.context(width: Int(strip.width * 2), height: Int(strip.height * 2), rowBytes: 4 * Int(strip.width * 2),
                         scale: 2, data: nil)
    Line.draw(shaped, before: 0, after: 0, in: b, band: strip, style: style)
    let frame = b.makeImage()!
    let box = CGRect(origin: CGPoint(x: ((size.width - Geometry.box.width) / 2).rounded(.down),
                                     y: ((size.height - Geometry.box.height) / 2).rounded(.down)), size: Geometry.box)
    let (scale, alpha) = Handoff.box(at: t), reach = Handoff.reach(way, box: Geometry.box)
    c.saveGState()
    c.setAlpha(CGFloat(alpha))
    c.beginTransparencyLayer(auxiliaryInfo: nil)
    c.translateBy(x: box.midX, y: box.midY)
    c.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    c.translateBy(x: -box.midX, y: -box.midY)
    let outline = CGPath(roundedRect: box, cornerWidth: 10, cornerHeight: 10, transform: nil)
    c.saveGState()
    c.addPath(outline)
    c.clip()
    c.setFillColor(style.background)
    c.fill(box)
    for p in pieces(text) {
        let image = frame.cropping(to: p.pixels(bandHeight: strip.height, scale: 2))!
        let d = Handoff.offset(p, way, reach: reach, at: t)
        let r = p.rect.offsetBy(dx: box.minX + Geometry.origin.x + (way == .send ? d : 0),
                                dy: box.minY + Geometry.origin.y + (way == .rise ? d : 0))
        c.draw(image, in: r)
    }
    c.restoreGState()
    c.addPath(CGPath(roundedRect: box.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 9.5, cornerHeight: 9.5, transform: nil))
    c.setStrokeColor(style.border)
    c.setLineWidth(1)
    c.strokePath()
    c.endTransparencyLayer()
    c.restoreGState()
    if let name { savePNG(c, name, dpi: 144) }
    let px = c.data!.assumingMemoryBound(to: UInt8.self)
    return Array(UnsafeBufferPointer(start: px, count: 4 * w * h))
}

@Test func handOffRenders() {
    let text = sentence, w = 2200
    let rest = handOffFrame(text, .send, at: 0)  // the key-down's instant: the line where the band had it
    let at60 = handOffFrame(text, .send, at: 0.060, name: "handoff-send-60ms.png")
    let at120 = handOffFrame(text, .send, at: 0.120, name: "handoff-send-120ms.png")
    let at200 = handOffFrame(text, .send, at: 0.200, name: "handoff-send-200ms.png")
    let rising = handOffFrame(text, .rise, at: 0.120, name: "handoff-rise-120ms.png")
    /// The pixel (BGRA) at 2× pixel column x, row y from the top.
    func pixel(_ f: [UInt8], _ x: Int, _ y: Int) -> [UInt8] { Array(f[4 * (y * w + x)..<4 * (y * w + x) + 4]) }
    /// Whether any pixel of the rows `rows` and columns `cols` differs from the box's background #0e1013.
    func inked(_ f: [UInt8], cols: Range<Int>, rows: Range<Int>) -> Bool {
        rows.contains { y in cols.contains { x in pixel(f, x, y) != [0x13, 0x10, 0x0e, 0xff] } }
    }
    // The box spans columns 192…2006 and rows 188…412 (from the top) at 2×, its border the outer 2 px; the band rows
    // 244…356, the glyphs' cells 262…338; the caret at 60 % of the line, column 2 × (96 + 1 + 543) = 1280.
    let band = 246..<354, caret = 1280
    #expect(inked(rest, cols: 1000..<caret - 2, rows: band) && !inked(rest, cols: caret + 6..<1990, rows: band))
    #expect(inked(at60, cols: caret + 6..<1990, rows: band))  // glyphs on their way past the caret's place
    #expect(inked(at120, cols: 400..<1990, rows: band))  // the faded rest still leaving as the collapse begins
    #expect(pixel(rest, 20, 20) != pixel(at200, 20, 20) && pixel(at200, 20, 20) == [0xff, 0xff, 0xff, 0xff])  // dim gone
    #expect(pixel(at200, 1100, 300)[0] > 240)  // the box nearly gone at 200 ms (2 % left)
    #expect(inked(rising, cols: 400..<1990, rows: 192..<244))  // risen above the band, still inside the box
    #expect(rising != at120)
}

// MARK: MO1's ring (pass 24)

@Test func stillsPasteSendsOneRingAndCopySaveAndReduceMotionNone() {
    // A paste under a theme whose hand-off is the box's fade, on Hand-off's tick: the ring, beside P1's 200 ms fade.
    #expect(Handoff.rings(.send, Effects(), reduceMotion: false, handOff: .fade))
    #expect(Handoff.leaving(Effects(), reduceMotion: false, handOff: .fade) == .fade(0.200))
    // Copy and Save… keep the plain fade; Lemna's stream never rings.
    #expect(!Handoff.rings(.rise, Effects(), reduceMotion: false, handOff: .fade))
    #expect(!Handoff.rings(.send, Effects(), reduceMotion: false, handOff: .stream))
    // Reduce Motion: no ring, and the box goes at once as before (it stops Pop's fade too); Effects ▸ Off the same;
    // Hand-off unticked: P1's close alone, no ring.
    #expect(!Handoff.rings(.send, Effects(), reduceMotion: true, handOff: .fade))
    #expect(Handoff.leaving(Effects(), reduceMotion: true, handOff: .fade) == .atOnce)
    var off = Effects()
    off.toggle()
    #expect(!Handoff.rings(.send, off, reduceMotion: false, handOff: .fade))
    var unticked = Effects()
    unticked.choose(.handOff)
    #expect(!Handoff.rings(.send, unticked, reduceMotion: false, handOff: .fade))
    #expect(Handoff.leaving(unticked, reduceMotion: false, handOff: .fade) == .fade(T.close))
    #expect(Theme.still.motion.handOff == .fade && Theme.lemna.motion.handOff == .stream)
}

@Test func theRingLeavesTheOutlineAndTheWashLiftsWithItOver1200ms() {
    // The panel's MO1 preview and look §5.3: two crests 9 pt apart at 60 pt/s from the box's outline, each with a
    // trough 3 pt inside at 0.4 of its alpha, drawn as three strokes; peak 0.18 by day, 0.08 by night; gone by 1.2 s.
    #expect(T.ringCrests == 2 && T.ringSpacing == 9 && T.ringSpeed == 60 && T.ringTrough == 3)
    #expect(T.ringTroughShare == 0.4 && T.ringOnset == 0.18 && T.ringPeak == (0.18, 0.08) && T.ringLife == 1.2)
    #expect(T.ringStrokes.map(\.width) == [3.2, 1.8, 0.9] && T.ringStrokes.map(\.share) == [0.2, 0.35, 0.45])
    #expect(Handoff.ring.map(\.share) == [1, 0.4, 1, 0.4])
    // From the key-down: the first crest on the outline, the rest still inside it; at 600 ms 36, 33, 27 and 24 pt out.
    #expect(Handoff.ring[0].offset(at: 0) == 0 && Handoff.ring.dropFirst().allSatisfy { $0.offset(at: 0) < 0 })
    #expect(zip(Handoff.ring.map { $0.offset(at: 0.6) }, [36, 33, 27, 24] as [CGFloat]).allSatisfy { abs($0 - $1) < 1e-9 })
    // Its alpha: nothing at the key, up on the curve to its peak at 180 ms, down every frame after, nothing at 1.2 s.
    let peak = Handoff.ringAlpha(at: 0.18, dark: false)
    #expect(Handoff.ringAlpha(at: 0, dark: false) == 0 && Handoff.ringAlpha(at: 1.2, dark: false) == 0)
    #expect(abs(peak - 0.18 * 0.85 * 0.85.squareRoot()) < 1e-12 && Handoff.ringAlpha(at: 1.0 / 60, dark: false) < peak / 2)
    let falling = stride(from: 0.18, to: 1.2, by: 1.0 / 60).map { Handoff.ringAlpha(at: $0, dark: false) }
    #expect(zip(falling, falling.dropFirst()).allSatisfy { $0 > $1 })
    #expect(abs(Handoff.ringAlpha(at: 0.5, dark: true) / Handoff.ringAlpha(at: 0.5, dark: false) - 0.08 / 0.18) < 1e-12)
    // The wash lifts evenly under it, half at 600 ms, gone with the ring (the stream's lift stays 140 ms on the curve).
    #expect(Handoff.washUnderRing(at: 0) == 1 && abs(Handoff.washUnderRing(at: 0.6) - 0.5) < 1e-12)
    #expect(Handoff.washUnderRing(at: 1.2) == 0 && Handoff.washUnderRing(at: 2) == 0 && Handoff.dim(at: 0.140) == 0)
    // The outline: the box grown by the offset, its corners with it, a stroke centred on it.
    let o = Handoff.ringOutline(CGRect(x: 100, y: 100, width: 907, height: 120), corner: 16, offset: 36, width: 2)
    #expect(o.rect == CGRect(x: 63, y: 63, width: 981, height: 194) && o.corner == 53)
}

/// MO1's ring `t` seconds after ⌘⏎ under Still by day, over a light app, at 2×, as Core Animation composes the box's
/// screen's dim: the app, the wash at its share under the ring, and each line of the ring as the borders of its three
/// layers (each inside its bounds, `Handoff.ringOutline`) at the ring's alpha times its share; the box's last look has
/// faded by then (P1's 200 ms from Return's key-up, about 100 ms in). Written to app/renders/`name` when one is given.
private func stillRingFrame(at t: Double, name: String? = nil) -> [UInt8] {
    let size = CGSize(width: 1100, height: 400), (w, h) = (2200, 800), style = Style(.still, dark: false, font: menlo)
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    c.setFillColor(rgb(0xffffff))
    c.fill(CGRect(origin: .zero, size: size))
    c.setFillColor(rgb(0xaeb3ba))
    for (i, len) in [620, 860, 740, 520, 900, 680, 800, 430, 760, 640, 880, 560, 700, 820, 610, 900].enumerated() {
        c.fill(CGRect(x: 40, y: size.height - 30 - CGFloat(i) * 22, width: CGFloat(len), height: 6))
    }
    let wash = Double(style.palette.dimAlpha) * Handoff.washUnderRing(at: t)
    c.setFillColor(rgb(style.palette.dim).copy(alpha: CGFloat(wash))!)
    c.fill(CGRect(origin: .zero, size: size))
    let box = CGRect(x: 96, y: 140, width: 907, height: BoxFrame.height(fontSize: 30)), a = Handoff.ringAlpha(at: t, dark: false)
    for line in Handoff.ring where line.offset(at: t) > 0 {
        for s in T.ringStrokes {
            let o = Handoff.ringOutline(box, corner: style.theme.box.corner, offset: line.offset(at: t), width: s.width)
            let mid = o.rect.insetBy(dx: s.width / 2, dy: s.width / 2), r = o.corner - s.width / 2  // the border's middle
            c.addPath(CGPath(roundedRect: mid, cornerWidth: r, cornerHeight: r, transform: nil))
            c.setStrokeColor(rgb(style.palette.ink.text).copy(alpha: CGFloat(a * line.share * s.share))!)
            c.setLineWidth(s.width)
            c.strokePath()
        }
    }
    if let name { savePNG(c, name, dpi: 144) }
    let px = c.data!.assumingMemoryBound(to: UInt8.self)
    return Array(UnsafeBufferPointer(start: px, count: 4 * w * h))
}

@Test func stillHandOffRenders() {
    let at600 = stillRingFrame(at: 0.6, name: "handoff-still-600ms.png"), at0 = stillRingFrame(at: 0)
    /// The pixel (BGRA) at points (x, y), origin at the bottom left.
    func pixel(_ f: [UInt8], _ x: CGFloat, _ y: CGFloat) -> [Int] {
        let i = 4 * (Int((400 - y) * 2) * 2200 + Int(x * 2))
        return f[i..<i + 4].map { Int($0) }
    }
    // The first crest 36 pt above the box's top edge (260): darker than the wash 20 pt further out, where no line is.
    let crest = pixel(at600, 550, 260 + 36), beyond = pixel(at600, 550, 260 + 56)
    #expect((0..<3).allSatisfy { crest[$0] < beyond[$0] - 4 }, "\(crest) \(beyond)")
    // The wash at half its strength: lighter far from the ring than at the key-down.
    #expect((0..<3).allSatisfy { pixel(at600, 1080, 10)[$0] > pixel(at0, 1080, 10)[$0] })
}
