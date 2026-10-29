// The ambience (DESIGN.md A1): a scene that plays on the dim around the box while you type and dies out within seconds
// of silence, one mode at a time from Session › Ambience ▸, Off at first. Here, free of AppKit and Metal: the choice,
// every magnitude (`Ambience.Tuning`), what the line sends (`Key`), what a scene is told (`Event`), where it plays
// (`Stage`), what it draws (`Sprite`), the atlas's index (`Glyphs`), the scenes' protocol and the run of one scene from
// the first key to its last particle (`Run`), so the tests step every mode without a window. The scenes themselves are
// in Scenes.swift, the Metal pipeline that draws the sprites in Particles.swift.
import CoreGraphics
import CoreText

/// Session › Ambience ▸: the mode that plays, or Off (nil, the default, D0). One at a time. Reduce Motion forces Off
/// and greys the modes, and keeps the pick for when it is turned off again.
public struct Ambience: Equatable {
    public enum Mode: String, CaseIterable {
        /// M1, M2, M3 and M5 of `docs/design-panel-lemna-ambience.html`, in the submenu's order (M8 Burn was not
        /// picked; pass 18 removed M4 Beams, M6 Fireworks and M7 Swarm, whose kept `ambience` is now Off).
        case drift, rain, rings, grid

        public var title: String {
            switch self {
            case .drift: "Drift"
            case .rain: "Rain"
            case .rings: "Rings"
            case .grid: "Grid"
            }
        }

        /// Plays on every screen's dim, not only on the box's: Rain falls over the whole dim. The others come from the
        /// box and stay on its screen.
        public var everyScreen: Bool { self == .rain }
    }

    public private(set) var mode: Mode?

    public init(_ mode: Mode? = nil) { self.mode = mode }

    /// As kept across launches (`kept`); none, Off or a mode since removed is Off.
    public init(kept: String?) { mode = kept.flatMap(Mode.init(rawValue:)) }

    /// For UserDefaults (`ambience`): the mode's raw value, or "off".
    public var kept: String { mode?.rawValue ?? "off" }

    /// The mode that plays now: none under Reduce Motion.
    public func playing(reduceMotion: Bool) -> Mode? { reduceMotion ? nil : mode }

    /// Whether the submenu offers the modes: greyed under Reduce Motion (Off stays).
    public static func available(reduceMotion: Bool) -> Bool { !reduceMotion }

    /// A mode from the submenu, or Off (nil).
    public mutating func choose(_ mode: Mode?) { self.mode = mode }
}

extension Ambience {
    /// Every magnitude of the ambience in one place (A1, I1: fixed per mode). Pass 16 (the user, having tried pass
    /// 15: "The ambience effects are way too subtle") made every mode plain from its first frame, about two to three
    /// times pass 15's alphas, larger where that reads better, a little longer where the fade took them early; pass
    /// 15's values, the panel's, stand beside each as "subtle". Times in seconds, lengths in points, alphas over the
    /// dim. The colours are the box's (C1): text for glyphs, rings and grid lines, the accent for the rain's heads and the
    /// lit cells.
    public enum Tuning {
        /// Every mode: at most this many sprites a frame (the panel's 2,000 particles), stepped and drawn at 60 Hz.
        public static let cap = 2000, frameRate = 60.0
        /// Nothing new after the last key, and the scene is gone `linger` after it, fading out evenly over the last
        /// `fadeOut` (a decay nobody triggered, kept off the curve, so the scene does not drop half of itself in the
        /// first tenth of a second at a moment the writer did not choose; pass 18); then the display link pauses.
        public static let linger = 4.0, fadeOut = 1.0
        /// At the box's close the scene fades out over the dim's wait and fade less `closeAhead`, so its cleared frames
        /// are out and the link pauses while the dim is still on screen (a window gone gets no more frames).
        public static let closeAhead = 0.05
        /// The typing rate is the keys of the last `rateWindow`; magnitudes set by it reach their top at `fastRate`
        /// keys a second (about 100 words a minute).
        public static let rateWindow = 2.0, fastRate = 10.0
        /// C1: the box's text and accent (`Style.text`, `Style.accent`).
        public static let text: UInt32 = 0xd8dce3, accent: UInt32 = 0x7aa7f0

        /// Where a key is (pass 16, `Keyboard`): across the screen, Rain's columns from the left to the right end of
        /// `screenSpan`; along the box, where Rings start, `boxSpan` of its width; down the keyboard, Rain's start from
        /// the top of `rainRows` (the number row) to its bottom (the space bar's), a share of the screen's height. A key
        /// with no position (an arrow, the accent menu's pick) takes the caret's x.
        public static let screenSpan = 0.1...0.9, boxSpan = 0.05...0.95, rainRows = 0.55...0.95

        /// M1 Drift: a glyph that leaves the box's left edge fades in over `driftIn` to `driftPeak`, holds it for
        /// `driftHold` and fades out by `driftLife`. It leaves at the line's own speed (its advance times the typing
        /// rate), so the glyphs keep their spacing as they come out, and slows over `driftCarry` onto a current of
        /// 8–40 pt/s set by the rate (eased over `driftEase`), rising at its own pace (more often up than down),
        /// wandering and turning slowly. About 20 live at 5 keys/s. Subtle: peak 0.35, no hold.
        public static let driftPeak = 0.7, driftIn = 0.3, driftHold = 1.5, driftLife = 4.0, driftEase = 0.6
        public static let driftCarry = 1.0, driftCurrent = 8.0...40.0, driftRise = -6.0...18.0, driftWander = 6.0
        public static let driftTurn = 0.05...0.2

        /// M2 Rain: each glyph key drops one column where the key is across the screen (anywhere within its width),
        /// higher the higher its row, the
        /// typed glyph at its head in the accent at `rainHead`, a trail of 4–8 glyphs in the text colour above it from
        /// `rainTrailStart`, each `rainTrailFall` of the one below, a trail glyph swapping `rainSwap` times a second;
        /// falling 150–300 pt/s, row by row, for `rainLife`, its last `rainOut` fading. Space and Return drop none.
        /// The glyphs at `rainScale` of the line's size. Subtle: head 0.3, the trail from 0.18 by 0.6, 2.5 s, 0.8 of
        /// the line's size.
        public static let rainHead = 0.8, rainTrailStart = 0.55, rainTrailFall = 0.75, rainLife = 3.0, rainOut = 0.6
        public static let rainScale = 1.0, rainSwap = 1.5, rainFall = 150.0...300.0, rainTrail = 4...8

        /// M3 Rings: each key sends one circle of `ringWidth` out from the box's top edge where the key is, to the
        /// screen's farthest corner on the curve, its alpha from `ringPeak` to nothing over `ringLife`; ⌫ (at its key)
        /// sends one in from `ringInward`. Drawn as arcs of about `ringArc` points (8 to `ringArcs` a circle). Subtle:
        /// the box's outline grown to 400 pt, 1 pt, peak 0.25, 1.5 s, inward from 160 pt.
        public static let ringPeak = 0.6, ringWidth = 2.0, ringLife = 2.0, ringInward = 240.0, ringArc = 100.0
        public static let ringArcs = 96

        /// M5 Grid: square cells of `gridCell` over the box's screen, the lines at `gridLines` fading in over `gridIn`
        /// at the first key; each key lights its own cells in a keyboard of 5 × 15 cells `gridGap` cells under the
        /// box (over it where there is no room), in the accent at `gridLit`, fading out by `gridLife`, so typing
        /// draws the keyboard's shape. A key with no position lights one cell within `gridReach` of the box, near the
        /// caret more often (weight e^(−distance / `gridNear`)). Subtle: 24 pt cells, lines 0.06, lit 0.2 for 0.6 s,
        /// a random cell near the caret for every key.
        public static let gridCell = 32.0, gridLines = 0.12, gridIn = 0.3, gridLit = 0.6, gridLife = 0.9
        public static let gridGap = 1, gridReach = 3, gridNear = 150.0
    }
}

// MARK: What the line sends, what a scene is told

extension Ambience {
    /// A key the line took, as it hands it on after the key's frame (on the main thread: a value and an enqueue,
    /// nothing else). `code`: the physical key (NSEvent's keyCode), nil when no key event brought it (the accent
    /// menu's pick); the scene's thread finds where it is (`Keyboard`). `pushed`: how far the text before the caret
    /// moved left (typing; 0 or less for a delete); with `line`, the line as now shaped (a reference to its glyphs,
    /// copied by no one), the scene's thread finds what left the box's left edge.
    public struct Key {
        public enum Kind: Equatable { case glyph(Character), space, paragraph, backspace }
        public var t: Double, kind: Kind, code: UInt16?, line: Shaped?, pushed: Double
        public init(t: Double, kind: Kind, code: UInt16? = nil, line: Shaped? = nil, pushed: Double = 0) {
            (self.t, self.kind, self.code, self.line, self.pushed) = (t, kind, code, line, pushed)
        }
    }

    /// What a scene is told, in order, since its last step: a key, where it is on the keyboard (nil: no position,
    /// the caret's x then), a glyph key with its atlas slot (nil when the atlas lacks it); or a glyph of the line that
    /// left the box's left edge, its baseline-left there.
    public enum Event: Equatable {
        case typed(slot: Int?, at: Keyboard.Position?), space(Keyboard.Position?), paragraph(Keyboard.Position?)
        case backspace(Keyboard.Position?)
        case leaving(slot: Int, at: CGPoint)

        /// Any key (not a glyph leaving).
        var isKey: Bool { if case .leaving = self { false } else { true } }

        /// The key's place on the keyboard.
        var key: Keyboard.Position? {
            switch self {
            case .typed(_, let p), .space(let p), .paragraph(let p), .backspace(let p): p
            case .leaving: nil
            }
        }
    }

    /// Where a scene plays: one screen's dim, in its points (origin at the bottom left, as AppKit's). On the box's screen
    /// `box` is the box there and `band`, `baseline` and `caret` are the line's; on another screen `box` is nil.
    public struct Stage: Equatable {
        public var size: CGSize, box: CGRect?, corner: CGFloat, keyboard: Keyboard.Kind
        public var band = CGRect.zero, baseline: CGFloat = 0, caret: CGFloat = 0

        /// `box` in the stage's points; the line sits `inset` inside it (its border), its band and baseline as
        /// `Line.draw` places them, the caret's left edge at 60 % of the band. `keyboard`: the physical layout, for
        /// where a key is.
        public init(size: CGSize, box: CGRect? = nil, inset: CGFloat = 1, corner: CGFloat = 10,
                    keyboard: Keyboard.Kind = .ansi, style: Style) {
            (self.size, self.box, self.corner, self.keyboard) = (size, box, corner, keyboard)
            guard let box else { return }
            let line = box.insetBy(dx: inset, dy: inset)
            band = Line.band(in: line.size, style: style).offsetBy(dx: line.minX, dy: line.minY)
            baseline = band.midY - (CTFontGetAscent(style.font) - CTFontGetDescent(style.font)) / 2
            caret = band.minX + Line.caret * band.width
        }

        /// The caret's point: its x on the band's middle.
        public var caretPoint: CGPoint { CGPoint(x: caret, y: band.midY) }

        /// Where a key is across the screen (`Tuning.screenSpan`); nil without a position.
        public func screenX(_ key: Keyboard.Position?) -> Double? {
            key.map { Double(size.width) * mix(Tuning.screenSpan, $0.across) }
        }

        /// Where a key is along the box (`Tuning.boxSpan`), or the caret's x without a position; nil off the box's
        /// screen.
        public func boxX(_ key: Keyboard.Position?) -> Double? {
            guard let box else { return nil }
            return key.map { Double(box.minX) + Double(box.width) * mix(Tuning.boxSpan, $0.across) } ?? Double(caret)
        }
    }
}

/// A share of a range: its lower bound at 0, its upper at 1.
func mix(_ r: ClosedRange<Double>, _ u: Double) -> Double { r.lowerBound + (r.upperBound - r.lowerBound) * u }

// MARK: What a scene draws

/// One sprite: a quad centred at (x, y), w × h points, turned by `rotation` radians about its centre, at `alpha` (times
/// the run's), in `colour` (0xRRGGBB packed as the shader unpacks it). `shape`: the kind in its low byte and a
/// parameter above it (a glyph's atlas slot; a bend's radius and stroke width). 32 bytes, the layout the shader reads.
public struct Sprite: Equatable {
    public var x: Float, y: Float, w: Float, h: Float, rotation: Float, alpha: Float, colour: UInt32, shape: UInt32

    public enum Kind: UInt32 {
        /// A glyph from the atlas; a filled rectangle; a stretch of a large circle's stroke (`bend`: the circle's centre
        /// lies below the quad's middle by the radius, on its turned y axis, and the stroke is cut square at the quad's
        /// ends, so arcs side by side make the circle). Pass 18 took out the disc, the small circle's stroke and the
        /// beam, which only the removed modes drew.
        case glyph, rect, bend
    }

    public init(x: Double, y: Double, w: Double, h: Double, rotation: Double = 0, alpha: Double, colour: UInt32,
                kind: Kind, parameter: UInt32 = 0) {
        (self.x, self.y, self.w, self.h) = (Float(x), Float(y), Float(w), Float(h))
        (self.rotation, self.alpha) = (Float(rotation), Float(min(max(alpha, 0), 1)))
        self.colour = Self.packed(colour)
        shape = kind.rawValue | parameter << 8
    }

    public var kind: Kind { Kind(rawValue: shape & 0xff) ?? .rect }
    public var parameter: UInt32 { shape >> 8 }

    /// 0xRRGGBB as the shader's unpack_unorm4x8 reads it: red in the low byte, alpha (unused) full.
    public static func packed(_ rgb: UInt32) -> UInt32 {
        (rgb >> 16 & 0xff) | (rgb >> 8 & 0xff) << 8 | (rgb & 0xff) << 16 | 0xff << 24
    }

    /// A bend's radius (in half points, to 8,191 pt) and stroke width (in sixteenths, to 63 pt) as a parameter.
    static func bend(radius r: Double, width w: Double) -> UInt32 {
        UInt32(min(max((r * 2).rounded(), 0), 16383)) | UInt32(min(max((w * 16).rounded(), 0), 1023)) << 14
    }
}

// MARK: The atlas's index

extension Ambience {
    /// Which glyphs of the line's font the atlas holds, in which cell, and a cell's size. The renderer draws them once
    /// with Core Text (Particles.swift); the scenes place glyph sprites by it. ASCII, Latin-1's letters and the common
    /// punctuation of German and English text; a character outside it does not drift or rain.
    public struct Glyphs {
        public static let characters: [Character] = {
            var cs = (33...126).map { Character(Unicode.Scalar(UInt8($0))) }
            cs += (0xC0...0xFF).filter { $0 != 0xD7 && $0 != 0xF7 }.map { Character(Unicode.Scalar(UInt8($0))) }
            return cs + Array("–—…„“”‚‘’«»·§€¶")
        }()
        /// The atlas is drawn at 2× (a 1× screen samples it down) with `pad` points around each glyph, 16 cells a row.
        public static let scale: CGFloat = 2, pad: CGFloat = 2, columns = 16

        public let font: CTFont
        /// Each slot's glyph.
        public let ids: [CGGlyph]
        /// One cell in the atlas's pixels, and where a glyph's baseline-left sits in it, in points from its bottom-left.
        public let pixels: (w: Int, h: Int), origin: CGPoint
        /// The slots of a to z, for rain's other glyphs.
        public let letters: [Int]
        private let byCharacter: [Character: Int], byGlyph: [CGGlyph: Int]

        public init(font: CTFont) {
            self.font = font
            var ids: [CGGlyph] = [], byCharacter: [Character: Int] = [:], byGlyph: [CGGlyph: Int] = [:]
            for c in Self.characters {
                var units = Array(String(c).utf16), g = [CGGlyph](repeating: 0, count: units.count)
                guard units.count == 1, CTFontGetGlyphsForCharacters(font, &units, &g, 1), g[0] != 0 else { continue }
                if let slot = byGlyph[g[0]] { byCharacter[c] = slot; continue }
                byCharacter[c] = ids.count
                byGlyph[g[0]] = ids.count
                ids.append(g[0])
            }
            var advances = [CGSize](repeating: .zero, count: ids.count)
            CTFontGetAdvancesForGlyphs(font, .horizontal, ids, &advances, ids.count)
            let ink = CTFontGetBoundingRectsForGlyphs(font, .horizontal, ids, nil, ids.count)
            let left = min(ink.minX, 0), right = max(ink.maxX, advances.map(\.width).max() ?? 0)
            let p = Self.pad, s = Self.scale
            pixels = (Int(((right - left + 2 * p) * s).rounded(.up)), Int(((ink.maxY - ink.minY + 2 * p) * s).rounded(.up)))
            origin = CGPoint(x: p - left, y: p - ink.minY)
            (self.ids, self.byCharacter, self.byGlyph) = (ids, byCharacter, byGlyph)
            letters = "abcdefghijklmnopqrstuvwxyz".compactMap { byCharacter[$0] }
        }

        /// A cell in points.
        public var cell: CGSize { CGSize(width: CGFloat(pixels.w) / Self.scale, height: CGFloat(pixels.h) / Self.scale) }
        public var rows: Int { (ids.count + Self.columns - 1) / Self.columns }
        /// The atlas's size in pixels.
        public var atlas: (w: Int, h: Int) { (Self.columns * pixels.w, rows * pixels.h) }

        public func slot(_ c: Character) -> Int? { byCharacter[c] }
        /// A shaped glyph's slot: only the line's own font (not a fallback for a character Menlo lacks).
        public func slot(glyph: CGGlyph, font f: CTFont) -> Int? { CFEqual(f, font) ? byGlyph[glyph] : nil }

        /// A glyph sprite with its baseline-left at `p`, `scale` times the line's size, turned about its cell's middle.
        public func sprite(_ slot: Int, baselineLeft p: CGPoint, scale: Double = 1, rotation: Double = 0,
                           alpha: Double, colour: UInt32) -> Sprite {
            let c = cell, k = CGFloat(scale)
            let centre = CGPoint(x: p.x + (c.width / 2 - origin.x) * k, y: p.y + (c.height / 2 - origin.y) * k)
            return sprite(slot, centre: centre, scale: scale, rotation: rotation, alpha: alpha, colour: colour)
        }

        /// A glyph sprite with its cell's middle at `centre`.
        public func sprite(_ slot: Int, centre: CGPoint, scale: Double = 1, rotation: Double = 0, alpha: Double,
                           colour: UInt32) -> Sprite {
            Sprite(x: centre.x, y: centre.y, w: cell.width * scale, h: cell.height * scale, rotation: rotation,
                   alpha: alpha, colour: colour, kind: .glyph, parameter: UInt32(slot))
        }
    }
}

// MARK: Scenes and their run

extension Ambience {
    /// One mode's scene on one stage: particles on the CPU, stepped once a frame (Scenes.swift has the four).
    public protocol Scene {
        init(stage: Stage, glyphs: Glyphs, seed: UInt64)
        /// Moves the scene on by `dt` seconds, `events` having come since the last step, at the typing `rate` (keys a
        /// second), and appends what it shows now to `out`: at most `Tuning.cap` sprites in all.
        mutating func step(dt: Double, events: [Event], rate: Double, into out: inout [Sprite])
        /// The most sprites it draws now, which never passes `Tuning.cap`: a scene spawns nothing that would.
        var count: Int { get }
    }

    /// The scene of `mode`.
    public static func scene(_ mode: Mode, stage: Stage, glyphs: Glyphs, seed: UInt64) -> any Scene {
        switch mode {
        case .drift: Drift(stage: stage, glyphs: glyphs, seed: seed)
        case .rain: Rain(stage: stage, glyphs: glyphs, seed: seed)
        case .rings: Rings(stage: stage, glyphs: glyphs, seed: seed)
        case .grid: Grid(stage: stage, glyphs: glyphs, seed: seed)
        }
    }

    /// The typing rate: keys in the last `Tuning.rateWindow`, per second.
    public struct Typing {
        private var times: [Double] = []
        public init() {}
        public mutating func key(at t: Double) {
            times.append(t)
            if times.count > 64 { times.removeFirst(times.count - 64) }
        }
        public func rate(at t: Double) -> Double {
            Double(times.lazy.filter { $0 > t - Tuning.rateWindow && $0 <= t }.count) / Tuning.rateWindow
        }
    }

    /// A seeded generator (SplitMix64), so a scene steps the same way in a test every time.
    public struct Random: RandomNumberGenerator {
        private var state: UInt64
        public init(seed: UInt64) { state = seed }
        public mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        mutating func pick(_ r: ClosedRange<Double>) -> Double { Double.random(in: r, using: &self) }
        mutating func unit() -> Double { Double.random(in: 0..<1, using: &self) }
    }

    /// One scene from the first key until it has died out: the keys turned into its events (what left the box's left
    /// edge found from each key's push), the typing rate, and the alpha every sprite is drawn at, 1 until the last
    /// second of `Tuning.linger` after the last key (fading evenly), or fading over a close (the box going, on the
    /// curve, as the dim it goes with). Stepped by the scene's
    /// thread once a frame; `frame` says when it is over, and the caller pauses.
    public struct Run {
        public let mode: Mode, stage: Stage
        let glyphs: Glyphs
        var scene: any Scene
        var typing = Typing()
        /// The events taken since the last frame (internal: the tests read them).
        var events: [Event] = []
        /// When the last key came; when the box went and over how long the scene fades out.
        public private(set) var lastKey = -Double.infinity
        private var closing: (at: Double, over: Double)?

        public init(mode: Mode, stage: Stage, glyphs: Glyphs, seed: UInt64) {
            (self.mode, self.stage, self.glyphs) = (mode, stage, glyphs)
            scene = Ambience.scene(mode, stage: stage, glyphs: glyphs, seed: seed)
        }

        public var count: Int { scene.count }

        /// The keys since the last frame, in order.
        public mutating func take(_ keys: [Key]) {
            for k in keys {
                lastKey = max(lastKey, k.t)
                typing.key(at: k.t)
                if k.pushed > 0, let line = k.line, stage.box != nil { leaving(line, pushed: k.pushed) }
                let at = k.code.flatMap { Keyboard.position(of: $0, on: stage.keyboard) }
                switch k.kind {
                case .glyph(let c): events.append(.typed(slot: glyphs.slot(c), at: at))
                case .space: events.append(.space(at))
                case .paragraph: events.append(.paragraph(at))
                case .backspace: events.append(.backspace(at))
                }
            }
        }

        /// The glyphs before the caret whose middle the push took past the band's left edge (the box's inner edge),
        /// where the line has them at rest: their baseline-left there. V2 has faded them out long before, so Drift's
        /// glyph is the line's own glyph coming out from under the box.
        private mutating func leaving(_ line: Shaped, pushed: Double) {
            let edge = Double(stage.band.minX), x0 = Double(stage.caret - line.caret)
            for g in line.glyphs where !g.after && !g.muted {
                let left = x0 + Double(g.x), middle = left + Double(g.advance) / 2
                guard middle < edge, middle + pushed >= edge, let slot = glyphs.slot(glyph: g.id, font: g.font)
                else { continue }
                events.append(.leaving(slot: slot, at: CGPoint(x: left, y: stage.baseline)))
            }
        }

        /// The box went at `t`: the scene fades out over `d`; no key comes after it.
        public mutating func close(at t: Double, over d: Double) {
            if closing == nil { closing = (t, d) }
        }

        /// The alpha every sprite is drawn at, at `t`: the last second before `linger` after the last key fades
        /// evenly, and a close fades over its time on the curve (evenly until pass 18); 0 when it is over.
        public func alpha(at t: Double) -> Double {
            var a = min(max((lastKey + Tuning.linger - t) / Tuning.fadeOut, 0), 1)
            if let c = closing { a *= c.over > 0 ? 1 - Curve.easeOutQuint((t - c.at) / c.over) : 0 }
            return a
        }

        /// One frame at `t`, `dt` after the last: the scene stepped with the events since, its sprites appended to
        /// `out` (cleared first, at most `Tuning.cap`), and the alpha to draw them at; nil when it is over.
        public mutating func frame(at t: Double, dt: Double, into out: inout [Sprite]) -> Double? {
            out.removeAll(keepingCapacity: true)
            let a = alpha(at: t)
            guard a > 0 else { return nil }
            scene.step(dt: dt, events: events, rate: typing.rate(at: t), into: &out)
            events.removeAll(keepingCapacity: true)
            if out.count > Tuning.cap { out.removeLast(out.count - Tuning.cap) }
            return a
        }
    }
}

// MARK: One screen's lifecycle on the scene thread

extension Ambience {
    /// What a show hands a screen's ambience: the mode on it (nil: none), its stage, the drawable's size in pixels and
    /// the scale; `turn` moves on with each show, so the scene thread sees a new one.
    public struct Plan: Equatable {
        public var mode: Mode?, stage: Stage, pixels: CGSize, scale: CGFloat, turn: Int
        public init(mode: Mode?, stage: Stage, pixels: CGSize, scale: CGFloat, turn: Int) {
            (self.mode, self.stage, self.pixels, self.scale, self.turn) = (mode, stage, pixels, scale, turn)
        }
    }

    /// One screen's ambience as the scene thread runs it, frame by frame of its CAMetalDisplayLink (pass 15b): which
    /// scene plays, what each frame draws into the drawable the link hands it, when the drawable parks at one pixel and
    /// the link pauses, and when the layer may be shown again. Every frame draws into the link's own drawable and
    /// nothing else ever does: `-[CAMetalLayer nextDrawable]` raises on a layer a CAMetalDisplayLink drives ("should not
    /// be called when using CAMetalDisplayLink"), which pass 15 called to clear the layer at a scene's end and so died
    /// at Esc. The layer is hidden at a close (its opacity fades with the dim, on the main thread) and shown again only
    /// after a cleared frame is on screen, so the last frame of a scene cut short never shows at the next summon.
    /// Free of Metal: the tests drive whole sequences.
    public struct Lifecycle {
        public enum Phase: Equatable {
            /// The link is paused; the app's start runs it again at a key.
            case idle
            /// Frames come: a scene plays, or is waited for.
            case playing
            /// A cleared frame is out and the drawable parked; the next frame clears again and pauses.
            case parking
        }

        /// What one frame does: the sprites drawn at `alpha` into the link's drawable, or (nil) that drawable cleared;
        /// `resize` the drawable's size from the next frame on, set once this frame is committed; `show` the turn
        /// whose layer may be shown again (a cleared frame of it is already out); `pause` the link after this frame.
        public struct Step: Equatable {
            public var alpha: Double?, resize: CGSize?, show: Int?, pause = false
        }

        /// The drawable while nothing plays: one pixel, so the screen-sized ones go.
        public static let parked = CGSize(width: 1, height: 1)

        public private(set) var phase = Phase.idle
        public private(set) var run: Run?
        private var plan: Plan?, fresh = false, showNext = false, last: Double?

        public init() {}

        /// The first key after a pause: frames again, the drawable at the screen's size (the caller sets it, then runs
        /// the link).
        public mutating func start(_ plan: Plan?) -> CGSize? {
            (phase, last) = (.playing, nil)
            return plan?.pixels
        }

        /// The dim is gone: the scene ends here; the next frame, if one comes, clears and parks.
        public mutating func stop() {
            if phase == .playing { run = nil }
        }

        /// One frame at `t`: the plan as the last show made it, the keys since the last frame, the close if the box
        /// went; the sprites in `out`.
        public mutating func frame(at t: Double, plan p: Plan?, keys: [Key], closing: (at: Double, over: Double)?,
                                   glyphs: Glyphs, into out: inout [Sprite]) -> Step {
            out.removeAll(keepingCapacity: true)
            var step = Step()
            let dt = last.map { min(max(t - $0, 0), 0.05) } ?? 1 / Tuning.frameRate
            last = t
            if p?.turn != plan?.turn { (plan, run) = (p, nil) }  // a new show, or another mode: a new scene
            if run == nil, let plan, let mode = plan.mode, !keys.isEmpty, closing == nil {
                run = Run(mode: mode, stage: plan.stage, glyphs: glyphs, seed: UInt64(max(t, 0) * 1000))
                (fresh, showNext, phase) = (true, false, .playing)
                step.resize = plan.pixels
            }
            if let c = closing { run?.close(at: c.at, over: c.over) }
            run?.take(keys)
            if showNext {
                (step.show, showNext) = (plan?.turn, false)
            }
            if let a = run?.frame(at: t, dt: dt, into: &out) {
                guard fresh else {
                    step.alpha = a
                    return step
                }
                (fresh, showNext) = (false, true)  // a new scene's first frame: cleared, the layer shown after it
                out.removeAll(keepingCapacity: true)
                return step
            }
            run = nil  // nothing plays: clear and park, then clear again and pause
            if phase == .playing {
                phase = .parking
                step.resize = Self.parked
            } else {
                (phase, step.pause) = (.idle, true)
            }
            return step
        }
    }
}
