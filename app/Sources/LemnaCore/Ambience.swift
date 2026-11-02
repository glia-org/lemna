// The ambience (DESIGN.md A1): a scene that plays on the dim around the box from the show to the close (Code since
// pass 19b, Still water since pass 24; until pass 24 the other modes played while you typed and died out within
// seconds of silence), one mode at a time from Session › Ambience ▸, Off at first. Here, free of AppKit and Metal: the
// choice, every magnitude (`Ambience.Tuning`), what the line sends (`Key`), what a scene is told (`Event`), where it
// plays (`Stage`), what it draws (`Sprite`), the atlas's index (`Glyphs`), the scenes' protocol and the run of one
// scene (`Run`), so the tests step every mode without a window. The scenes themselves are in Scenes.swift, the Metal
// pipeline that draws the sprites in Particles.swift.
import CoreGraphics
import CoreText

/// Session › Ambience ▸: the mode that plays, or Off (nil, the default, D0). One at a time. Reduce Motion forces Off
/// and greys the modes, and keeps the pick for when it is turned off again.
public struct Ambience: Equatable {
    public enum Mode: String, CaseIterable {
        /// M2 of `docs/design-panel-lemna-ambience.html` and, since pass 24, AM1 of
        /// `docs/design-panel-lemna-themes.html`, in the submenu's order. M8 Burn was not picked; pass 18 removed M4
        /// Beams, M6 Fireworks and M7 Swarm, pass 24 (RM1) M1 Drift, M3 Rings and M5 Grid: a kept `ambience` naming one
        /// of them is Off. M2 is Code since pass 25 (the films' effect is known as digital rain or code rain), Rain
        /// before, a name that clashed with the Rain bed and with the water's drops.
        case code, water

        public var title: String {
            switch self {
            case .code: "Code"
            case .water: "Still water"
            }
        }

        /// Plays on every screen's dim, not only on the box's: Code falls over the whole dim. Still water stays on the
        /// box's screen.
        public var everyScreen: Bool { self == .code }

        /// Plays from the show until the close, keys or none (pass 19b, I1): Code, and Still water (pass 24). The modes
        /// pass 24 removed started at the first key and were gone `Tuning.linger` after the last; `Run` and `Lifecycle`
        /// still have that path, which no mode takes now.
        public var ambient: Bool { true }
    }

    public private(set) var mode: Mode?

    public init(_ mode: Mode? = nil) { self.mode = mode }

    /// As kept across launches (`kept`); none, Off or a mode since removed is Off; `rain`, Code's name until pass 25,
    /// is Code.
    public init(kept: String?) { mode = kept.flatMap { Mode(rawValue: $0 == "rain" ? "code" : $0) } }

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
    /// 15: "The ambience effects are way too subtle") made every mode plain from its first frame. Times in seconds,
    /// lengths in points, alphas over the dim (times the ink's `alpha`). The colours are the theme's ink (`Stage.ink`;
    /// Lemna's the box's text and accent, C1): Code's heads in the text colour and its trails in the accent (C2, pass
    /// 19b); Still water's rings in the text colour.
    public enum Tuning {
        /// Every mode: at most this many sprites a frame, stepped and drawn at 60 Hz (Code at rest at `codeIdleRate`,
        /// Still water at `waterFrameRate`). 16,000 since pass 27 (the panel's 2,000 particles before): Code draws
        /// every lit cell, about 3,500 at rest on a laptop's screen and 15,500 at most typing on a 6K display's
        /// 3008 × 1692 pt; the instance buffers are 512 KB each, the GPU's work bound by the screen's area.
        public static let cap = 16_000, frameRate = 60.0
        /// Nothing new after the last key, and the scene is gone `linger` after it, fading out evenly over the last
        /// `fadeOut` (a decay nobody triggered, kept off the curve, so the scene does not drop half of itself in the
        /// first tenth of a second at a moment the writer did not choose; pass 18); then the display link pauses. Not
        /// for an ambient mode (Code, Still water), which plays until the close.
        public static let linger = 4.0, fadeOut = 1.0
        /// At the box's close the scene fades out over the dim's wait and fade less `closeAhead`, so its cleared frames
        /// are out and the link pauses while the dim is still on screen (a window gone gets no more frames).
        public static let closeAhead = 0.05
        /// The typing rate is the keys of the last `rateWindow` (pass 24 removed `fastRate`, Drift's top).
        public static let rateWindow = 2.0

        /// Where a key is (pass 16, `Keyboard`): across the screen, Code's columns and Still water's word drops from
        /// the left to the right end of `screenSpan`; down the keyboard, Code's start from the top of `codeRows` (the
        /// number row) to its bottom (the space bar's), a share of the screen's height. A key with no position (an
        /// arrow, the accent menu's pick) takes the caret's x. (Rings' `boxSpan` went with them in pass 24.)
        public static let screenSpan = 0.1...0.9, codeRows = 0.55...0.95

        /// M2 Code (Rain until pass 25; pass 19b's G1 I1 T1 C2 K1 W1 of `docs/design-panel-lemna-rain.html`, matrix
        /// §6.2), since pass 27 the film's title sequence (the user, 2026-11-02, of two of its frames: "in the movie it
        /// looks more like this ... Revise the animation (but do not use these colors)"): a dim curtain of glyphs over
        /// nearly the whole screen with brighter streams falling through it, a few nearer ones larger and softer. Glyphs
        /// of `Glyphs.codeSet` (digits, a few symbols, katakana), mirrored, fixed in a grid of square cells; heads step
        /// down the columns a cell at a time, each cell they enter lit and then dimming in place over the head's trail.
        /// Each pair is (idle, typing): one intensity, 0 at rest, 1 at `codeFast` keys a second (the keys of the last
        /// `rateWindow`), sets every magnitude between them, linearly: the films' "more intense", more heads, longer
        /// and brighter trails, brighter heads and halos, glyphs changing more often, never faster columns (pass 25); it
        /// rises with τ `codeRise` and falls with τ `codeSettle` from `codeHold` after the last key (so the pauses
        /// between words do not make it pulse; back near rest about 4 s after the last key). The head and the cells
        /// right behind it in the text colour, the trail in the accent (C2). From the show to the close
        /// (`Mode.ambient`), stepped `codeAhead` ahead at its birth so the summon finds it falling; at `codeIdleRate`
        /// frames a second while the intensity is at most `codeCalm` and no key came in the last `codeHold`. Pass 25's
        /// values, before the film's frame, in brackets.
        ///
        /// The grid: glyphs at `codeScale` of the line's size (16.8 pt at Menlo 28 [0.5, 14 pt]) on cells `codePitch`
        /// of the glyph cell's height at the line's size on a side (18.5 pt: 81 × 54 cells on 1512 × 982 pt, as
        /// before: the film's frame has about 82 columns across).
        public static let codeScale = 0.6, codePitch = 0.5
        /// A column's speed in rows a second, drawn once at the birth and kept whatever the intensity (pass 25; the
        /// user, 2026-11-01: "I don't think the matrix code animation gets faster in the movie, it just gets more
        /// intense"; matrix §2: constant within a column, about 2:1 between columns): 8–16 rows (148–296 pt) a second,
        /// about the geometric middle of pass 19b's 5–10 at rest and 15–30 typing, between Rezmason's twilight (5–10)
        /// and classic (15–30), so it neither crawls at rest nor rushes while typing; a laptop's 54 rows in 3.4–6.8 s.
        public static let codeSpeed = 8.0...16.0
        /// Heads: about `codeActive` in a column for each `codeHeight` of its height (a taller screen as dense as a
        /// laptop's; [a share of the columns falling, 0.3 / 0.7]), at most `codeMost` for each `codeHeight`, each at
        /// least `codeGap` rows from the others in its column [one trail and 3 / 2 cells behind the last], so a column
        /// often holds two at different heights and they never collide (one speed a column); a column's next head comes
        /// after a pause of `codeWait` of its mean (narrower than a Poisson pause's, which left one column in eight
        /// empty), the pause running at the intensity's rate so typing shortens the one under way; `codeHigh` of them
        /// start lower than the top edge, at a row within `codeHighRows` of the height, the rest at the top.
        public static let codeActive = (idle: 0.8, typing: 1.4), codeHeight = 1000.0, codeMost = 3
        public static let codeGap = (idle: 8.0, typing: 5.0), codeWait = 0.5...1.5
        public static let codeHigh = 0.3, codeHighRows = 0.05...0.6
        /// A head's trail in cells, log-uniform (more short than long), so most reach far up the screen and a head's
        /// trail lingers in the cells for seconds after it ran out at the bottom [6–18 / 10–30]; the cells dim in place
        /// to nothing over it, as (1 − age ÷ trail)^`codeFade` (linear, so a glyph dims an equal step a frame).
        public static let codeTrail = (idle: 30.0...150.0, typing: 40.0...200.0), codeFade = 1.0
        /// The head's alpha [0.35 / 0.85], and the `codeNeckCells` cells right behind it, still in the text colour, at
        /// `codeNeck` of it and then its square (the films' bright glyph or two under a head).
        public static let codeHead = (idle: 0.8, typing: 1.0), codeNeck = 0.7, codeNeckCells = 2
        /// The trail's top alpha [0.2 / 0.5], times its stream's gain, drawn once a head from `codeGain` (log-uniform:
        /// most streams dim, a few bright, which makes the curtain and the brighter streams through it), times the
        /// glyph's own brightness, drawn from `codeLevel` with each new glyph (u^`codeLevelSkew` across it: more dim
        /// than bright), so a bright glyph sits beside dim ones and flickers as it changes.
        public static let codeTrailTop = (idle: 0.55, typing: 0.85), codeGain = 0.3...2.0
        public static let codeLevel = 0.3...1.0, codeLevelSkew = 1.5
        /// The halo under a head where light adds (Lemna, Still by night; ink laid over Still's day wash does not
        /// glow): a soft disc in the text colour (`Sprite.halo`), at `codeHalo` in its middle, falling to e^(−2) of it
        /// `codeHaloWidth` of the pitch out and to nothing at twice that (the films' bloom, the cheapest kind).
        public static let codeHalo = (idle: 0.22, typing: 0.35), codeHaloWidth = 0.8
        /// Every lit glyph changes in place this often a second [0.3 / 1.5], its brightness with it.
        public static let codeChange = (idle: 0.5, typing: 2.0)
        /// Depth: a nearer sheet over the grid, `codeNear` times its pitch and glyphs (its own columns, 51 on a laptop),
        /// with about `codeNearActive` heads a column for each `codeHeight` (two to four streams on a laptop at rest),
        /// `codeNearBright` times the alphas and sampled `codeNearBlur` mipmap levels softer: a few streams larger,
        /// softer and brighter, falling as many rows a second as the far ones and so faster across the screen.
        public static let codeNear = 1.6, codeNearActive = (idle: 0.06, typing: 0.12), codeNearBright = 1.6
        public static let codeNearBlur = 1.5
        /// Each glyph key also starts a head in its column where the key is (`screenSpan`, `codeRows`), the typed glyph
        /// at it, not mirrored, at `codeKeyHead`, its trail from `codeKeyTrailTop` [0.55] at each glyph's own
        /// brightness over `codeKeyTrail` cells [8–20]; Space and Return none.
        public static let codeKeyHead = 0.95, codeKeyTrailTop = 0.8, codeKeyTrail = 12.0...40.0
        public static let codeFast = 6.0, codeRise = 0.25, codeSettle = 1.2, codeHold = 0.8
        /// A trail cell is drawn above `codeShown` (raised frame by frame on a stage with more lit cells than `cap`, so
        /// the dimmest go and not the columns on the right).
        public static let codeAhead = 20.0, codeIdleRate = 30.0, codeCalm = 0.05, codeShown = 0.02

        /// Still water (pass 24; AM1 of `docs/design-panel-lemna-themes.html`, per word and at rest since pass 25;
        /// `research_notes/Lemna themes/look.md` §5.3's Ripples): drops land at random on the dim at least `waterClear`
        /// from the box, Poisson at `waterRate` a second on a 1512 × 982 pt screen, scaled to the stage's area, and one
        /// at the show `waterSummon` above the middle of the box's top edge. While you write (pass 25; the user,
        /// 2026-11-01: "the rain drops should probably also be increasing when typing as well"), one more for each word
        /// at its end (a Space or a Return after a glyph key), at least `waterWordGap` after the last word's, where the
        /// word's last key is across the screen (`screenSpan`) and higher the higher the key's row: from `waterTop`
        /// under the screen's top edge for the number row to `waterClear` above the box for the space bar's (a key
        /// without a position: at the caret's x there), as the panel's canvas drops it (look §3.4, §5.3); none for a
        /// key, and the rest rate unchanged. A drop is `waterCrests` rings that leave together at `waterSpeed`, each
        /// further one `waterSpread` slower than the one outside it (±`waterJitter` of that), so the calm centre
        /// follows the lead at about 0.7 of its speed and the crests stand about 9 pt apart at 1.7 s; each a Gaussian
        /// across it `waterWidth` wide, its start within ±`waterStart` of the drop's, with a fainter trough ring
        /// `waterTrough` inside it at `waterTroughShare` of its alpha. A ring's alpha rises over `waterOnset` on the
        /// curve to the peak, laid over on a light wash and added on a dark one (`waterPeak`; times Still's ink alpha,
        /// 0.6 by day and 0.5 by night: 0.36 laid over by day and 0.2 added by night on screen; look §5.3's 0.16 and
        /// 0.07, one drop every 8 s, were not to be seen on a real screen, the user 2026-11-01: "it's showing
        /// nothing"), then falls as e^(−age / `waterDecay`) · √(`waterNear` / r); under `waterShown` it is not drawn,
        /// and a drop is gone at `waterLife`. Rings that cross add. At most `waterDrops` alive, at `waterFrameRate`
        /// frames a second (36 pt/s is 1.2 pt a frame).
        public static let waterRate = 0.5, waterClear = 48.0, waterSummon = 48.0, waterDrops = 32
        public static let waterWordGap = 0.8, waterTop = 40.0
        public static let waterCrests = 3, waterSpeed = 36.0, waterSpread = 0.15, waterJitter = 0.15
        public static let waterWidth = 2.0...3.5, waterStart = 0.04, waterTrough = 3.0, waterTroughShare = 0.4
        public static let waterOnset = 0.18, waterPeak = (over: 0.6, add: 0.4), waterDecay = 2.0, waterNear = 12.0
        public static let waterShown = 0.01, waterLife = 6.0, waterFrameRate = 30.0
    }
}

// MARK: What the line sends, what a scene is told

extension Ambience {
    /// A key the line took, as it hands it on after the key's frame (on the main thread: a value and an enqueue,
    /// nothing else). `code`: the physical key (NSEvent's keyCode), nil when no key event brought it (the accent
    /// menu's pick); the scene's thread finds where it is (`Keyboard`). `pushed`: how far the text before the caret
    /// moved left (typing; 0 or less for a delete), and `line`, the line as now shaped (a reference to its glyphs,
    /// copied by no one): Drift found in them what left the box's left edge; no scene reads them since pass 24.
    public struct Key {
        public enum Kind: Equatable { case glyph(Character), space, paragraph, backspace }
        public var t: Double, kind: Kind, code: UInt16?, line: Shaped?, pushed: Double
        public init(t: Double, kind: Kind, code: UInt16? = nil, line: Shaped? = nil, pushed: Double = 0) {
            (self.t, self.kind, self.code, self.line, self.pushed) = (t, kind, code, line, pushed)
        }
    }

    /// What a scene is told, in order, since its last step: a key, where it is on the keyboard (nil: no position,
    /// the caret's x then), a glyph key with its atlas slot (nil when the atlas lacks it). (Drift's glyph leaving the
    /// box's left edge went with it in pass 24.)
    public enum Event: Equatable {
        case typed(slot: Int?, at: Keyboard.Position?), space(Keyboard.Position?), paragraph(Keyboard.Position?)
        case backspace(Keyboard.Position?)

        /// The key's place on the keyboard.
        var key: Keyboard.Position? {
            switch self {
            case .typed(_, let p), .space(let p), .paragraph(let p), .backspace(let p): p
            }
        }
    }

    /// Where a scene plays: one screen's dim, in its points (origin at the bottom left, as AppKit's). On the box's screen
    /// `box` is the box there and `band` and `caret` are the line's; on another screen `box` is nil. `ink`: the theme's
    /// colours, blend and alpha for the scenes (TH1).
    public struct Stage: Equatable {
        public var size: CGSize, box: CGRect?, corner: CGFloat, keyboard: Keyboard.Kind, ink: Theme.Ink
        public var band = CGRect.zero, caret: CGFloat = 0

        /// `box` in the stage's points; the line sits `inset` inside it (its border), its band as `Line.draw` places
        /// it, the caret's left edge at 60 % of the band. `keyboard`: the physical layout, for where a key is; the ink
        /// is `style`'s palette's.
        public init(size: CGSize, box: CGRect? = nil, inset: CGFloat = 1, corner: CGFloat = 10,
                    keyboard: Keyboard.Kind = .ansi, style: Style) {
            (self.size, self.box, self.corner, self.keyboard, ink) = (size, box, corner, keyboard, style.palette.ink)
            guard let box else { return }
            let line = box.insetBy(dx: inset, dy: inset)
            band = Line.band(in: line.size, style: style).offsetBy(dx: line.minX, dy: line.minY)
            caret = band.minX + Line.caret * band.width
        }

        /// Where a key is across the screen (`Tuning.screenSpan`); nil without a position.
        public func screenX(_ key: Keyboard.Position?) -> Double? {
            key.map { Double(size.width) * mix(Tuning.screenSpan, $0.across) }
        }
    }
}

/// A share of a range: its lower bound at 0, its upper at 1.
func mix(_ r: ClosedRange<Double>, _ u: Double) -> Double { r.lowerBound + (r.upperBound - r.lowerBound) * u }

// MARK: What a scene draws

/// One sprite: a quad centred at (x, y), w × h points (a glyph's w negative: mirrored, pass 27), turned by `rotation`
/// radians about its centre, at `alpha` (times the run's), in `colour` (0xRRGGBB packed as the shader unpacks it).
/// `shape`: the kind in its low byte and a parameter above it (a glyph's atlas slot in its low 12 bits and its blur in
/// quarter mipmap levels in the 4 above, `Glyphs.sprite`; a ring's radius and width). 32 bytes, the layout the shader
/// reads.
public struct Sprite: Equatable {
    public var x: Float, y: Float, w: Float, h: Float, rotation: Float, alpha: Float, colour: UInt32, shape: UInt32

    public enum Kind: UInt32 {
        /// A glyph from the atlas; a soft ring (pass 24, Still water: a circle about the quad's middle, its coverage a
        /// Gaussian across the circle, `Sprite.ring`; the quad is the circle's square with the falloff; of radius 0 a
        /// soft disc, a Gaussian about the middle, Code's halo under a head since pass 27, `Sprite.halo`). Pass 18 took
        /// out the disc, the small circle's stroke and the beam, pass 24 the filled rectangle and the large circle's
        /// stroke (`bend`), which only the removed modes drew.
        case glyph, ring
    }

    public init(x: Double, y: Double, w: Double, h: Double, rotation: Double = 0, alpha: Double, colour: UInt32,
                kind: Kind, parameter: UInt32 = 0) {
        (self.x, self.y, self.w, self.h) = (Float(x), Float(y), Float(w), Float(h))
        (self.rotation, self.alpha) = (Float(rotation), Float(min(max(alpha, 0), 1)))
        self.colour = Self.packed(colour)
        shape = kind.rawValue | parameter << 8
    }

    /// A sprite from its fields as the shader reads them, `colour` packed and `shape` the kind with its parameter:
    /// for Code's thousands a frame (pass 27), without the conversions of the init above; `alpha` within 0...1.
    init(x: Float, y: Float, w: Float, h: Float, alpha: Float, packed colour: UInt32, shape: UInt32) {
        (self.x, self.y, self.w, self.h, rotation, self.alpha, self.colour, self.shape) = (x, y, w, h, 0, alpha, colour, shape)
    }

    public var kind: Kind { Kind(rawValue: shape & 0xff) ?? .glyph }
    public var parameter: UInt32 { shape >> 8 }

    /// 0xRRGGBB as the shader's unpack_unorm4x8 reads it: red in the low byte, alpha (unused) full.
    public static func packed(_ rgb: UInt32) -> UInt32 {
        (rgb >> 16 & 0xff) | (rgb >> 8 & 0xff) << 8 | (rgb & 0xff) << 16 | 0xff << 24
    }

    /// A ring's radius (in half points, to 8,191 pt) and width (in sixteenths, to 63 pt) as a parameter: the circle on
    /// which its coverage peaks, and the width over which the Gaussian across it falls to e^(−2) on either side (σ half
    /// of it), nothing beyond twice that.
    static func ring(radius r: Double, width w: Double) -> UInt32 {
        UInt32(min(max((r * 2).rounded(), 0), 16383)) | UInt32(min(max((w * 16).rounded(), 0), 1023)) << 14
    }

    /// A soft ring about (x, y): the quad is the circle's square, out to twice the width beyond the radius.
    static func ring(x: Double, y: Double, radius r: Double, width w: Double, alpha: Double, colour: UInt32) -> Sprite {
        let side = 2 * (r + 2 * w)
        return Sprite(x: x, y: y, w: side, h: side, alpha: alpha, colour: colour, kind: .ring,
                      parameter: ring(radius: r, width: w))
    }

    /// A soft disc about (x, y), the ring of radius 0 (pass 27, Code's halo, the cheapest bloom): `alpha` at its
    /// middle, falling as a Gaussian to e^(−2) of it `width` out and to nothing at twice that.
    static func halo(x: Double, y: Double, width w: Double, alpha: Double, colour: UInt32) -> Sprite {
        ring(x: x, y: y, radius: 0, width: w, alpha: alpha, colour: colour)
    }
}

// MARK: The atlas's index

extension Ambience {
    /// Which glyphs the atlas holds, in which cell, and a cell's size. The renderer draws them once with Core Text
    /// (Particles.swift); the scenes place glyph sprites by it. ASCII, Latin-1's letters and the common punctuation of
    /// German and English text in the line's font, and since pass 27 Code's katakana (`kana`) from the font Core Text
    /// falls back on for them (Hiragino Sans, its bold); a character outside it does not rain.
    public struct Glyphs {
        public static let characters: [Character] = {
            var cs = (33...126).map { Character(Unicode.Scalar(UInt8($0))) }
            cs += (0xC0...0xFF).filter { $0 != 0xD7 && $0 != 0xF7 }.map { Character(Unicode.Scalar(UInt8($0))) }
            return cs + Array("–—…„“”‚‘’«»·§€¶") + kana
        }()
        /// Code's katakana (pass 27; matrix §1.2: the films' glyphs are mostly mirrored half-width katakana): ｦ and ｱ to
        /// ﾝ (U+FF66, U+FF71–U+FF9D), 46 of them, without the small ones (ｧ to ｯ, too small beside the digits) and the
        /// prolonged sound mark (the set has its dashes). No font of the line has them: Core Text's fallback for the
        /// line's font does (`CTFontCreateForString`, Hiragino Sans W3 for Menlo), taken in its bold (W6, Menlo's
        /// weight) and centred on the cell's advance; one that would not fit the cell the line's own glyphs make is
        /// left out, so the cell, and Code's grid, are as before.
        public static let kana: [Character] = ([0xFF66] + Array(0xFF71...0xFF9D)).map { Character(Unicode.Scalar($0)!) }
        /// The atlas is drawn at 2× (a 1× screen samples it down) with `pad` points around each glyph, 16 cells a row.
        public static let scale: CGFloat = 2, pad: CGFloat = 2, columns = 16

        public let font: CTFont
        /// Each slot's glyph, the font it is drawn in (an index into `faces`: 0 the line's font, 1 the fallback's) and
        /// how far right of the cell's origin (in points), so a narrower fallback glyph sits in the middle.
        public let ids: [CGGlyph], face: [Int], shift: [CGFloat]
        /// The line's font, then the fallback's for the katakana if one had them.
        public let faces: [CTFont]
        /// One cell in the atlas's pixels, and where a glyph's baseline-left sits in it, in points from its bottom-left.
        public let pixels: (w: Int, h: Int), origin: CGPoint
        /// The slots of a to z; and of Code's glyphs (K1, pass 19b; pass 27): the films' set as far as the atlas has it,
        /// digits without 6, Z z : . " = * + - < > | _ and the katakana, drawn mirrored (`sprite(mirrored:)`).
        public let letters: [Int], codeSet: [Int]
        private let byCharacter: [Character: Int]

        public init(font: CTFont) {
            self.font = font
            var ids: [CGGlyph] = [], byCharacter: [Character: Int] = [:], byGlyph: [CGGlyph: Int] = [:]
            var missing: [Character] = []
            for c in Self.characters {
                var units = Array(String(c).utf16), g = [CGGlyph](repeating: 0, count: units.count)
                guard units.count == 1, CTFontGetGlyphsForCharacters(font, &units, &g, 1), g[0] != 0 else {
                    if units.count == 1 { missing.append(c) }
                    continue
                }
                if let slot = byGlyph[g[0]] { byCharacter[c] = slot; continue }
                byCharacter[c] = ids.count
                byGlyph[g[0]] = ids.count
                ids.append(g[0])
            }
            var advances = [CGSize](repeating: .zero, count: ids.count)
            CTFontGetAdvancesForGlyphs(font, .horizontal, ids, &advances, ids.count)
            let ink = CTFontGetBoundingRectsForGlyphs(font, .horizontal, ids, nil, ids.count)
            let advance = advances.map(\.width).max() ?? 0
            let left = min(ink.minX, 0), right = max(ink.maxX, advance)
            let p = Self.pad, s = Self.scale
            pixels = (Int(((right - left + 2 * p) * s).rounded(.up)), Int(((ink.maxY - ink.minY + 2 * p) * s).rounded(.up)))
            origin = CGPoint(x: p - left, y: p - ink.minY)
            var face = [Int](repeating: 0, count: ids.count), shift = [CGFloat](repeating: 0, count: ids.count)
            var faces = [font]
            // The katakana from the fallback, in its bold, each centred on the advance and kept only within the cell.
            if let first = missing.first(where: Self.kana.contains) {
                let found = CTFontCreateForString(font, String(first) as CFString, CFRange(location: 0, length: 1))
                let fallback = CTFontCreateCopyWithSymbolicTraits(found, 0, nil, .traitBold, .traitBold) ?? found
                if CTFontCopyPostScriptName(fallback) as String != "LastResort" {
                    for c in missing where Self.kana.contains(c) {
                        var units = Array(String(c).utf16), g: [CGGlyph] = [0], a = CGSize.zero
                        guard CTFontGetGlyphsForCharacters(fallback, &units, &g, 1), g[0] != 0 else { continue }
                        CTFontGetAdvancesForGlyphs(fallback, .horizontal, g, &a, 1)
                        let dx = (advance - a.width) / 2
                        let r = CTFontGetBoundingRectsForGlyphs(fallback, .horizontal, g, nil, 1).offsetBy(dx: dx, dy: 0)
                        guard r.minX >= left, r.maxX <= right, r.minY >= ink.minY, r.maxY <= ink.maxY else { continue }
                        byCharacter[c] = ids.count
                        ids.append(g[0])
                        face.append(1)
                        shift.append(dx)
                    }
                    if face.contains(1) { faces.append(fallback) }
                }
            }
            (self.ids, self.face, self.shift, self.faces, self.byCharacter) = (ids, face, shift, faces, byCharacter)
            letters = "abcdefghijklmnopqrstuvwxyz".compactMap { byCharacter[$0] }
            codeSet = ("012345789Zz:.\"=*+-<>|_" + String(Self.kana)).compactMap { byCharacter[$0] }
        }

        /// A cell in points.
        public var cell: CGSize { CGSize(width: CGFloat(pixels.w) / Self.scale, height: CGFloat(pixels.h) / Self.scale) }
        public var rows: Int { (ids.count + Self.columns - 1) / Self.columns }
        /// The atlas's size in pixels.
        public var atlas: (w: Int, h: Int) { (Self.columns * pixels.w, rows * pixels.h) }

        /// The atlas's font for a line in `font`: the same when it is monospaced, else Menlo at its size, so Code's grid
        /// keeps a monospaced face whatever the theme's line uses (TY1; architecture §6).
        public static func atlasFont(for font: CTFont) -> CTFont {
            CTFontGetSymbolicTraits(font).contains(.traitMonoSpace) ? font
                : CTFontCreateWithName("Menlo" as CFString, CTFontGetSize(font), nil)
        }

        public func slot(_ c: Character) -> Int? { byCharacter[c] }

        /// A glyph sprite with its cell's middle at `centre`; `mirrored` left to right (pass 27, the films' code: a
        /// negative width, which the vertex shader turns into the quad's corners and the atlas cell's run the other
        /// way), and `blur` in mipmap levels the shader adds to its sample's (in quarters, to 3.75; the atlas has two
        /// levels below its own, so 2 is as soft as it gets).
        public func sprite(_ slot: Int, centre: CGPoint, scale: Double = 1, rotation: Double = 0, alpha: Double,
                           colour: UInt32, mirrored: Bool = false, blur: Double = 0) -> Sprite {
            Sprite(x: centre.x, y: centre.y, w: cell.width * scale * (mirrored ? -1 : 1), h: cell.height * scale,
                   rotation: rotation, alpha: alpha, colour: colour, kind: .glyph,
                   parameter: UInt32(slot) | UInt32(min(max((blur * 4).rounded(), 0), 15)) << 12)
        }
    }
}

// MARK: Scenes and their run

extension Ambience {
    /// One mode's scene on one stage: particles on the CPU, stepped once a frame (Scenes.swift has the two).
    public protocol Scene {
        init(stage: Stage, glyphs: Glyphs, seed: UInt64)
        /// Moves the scene on by `dt` seconds, `events` having come since the last step, at the typing `rate` (keys a
        /// second), and appends what it shows now to `out`: at most `Tuning.cap` sprites in all.
        mutating func step(dt: Double, events: [Event], rate: Double, into out: inout [Sprite])
        /// The most sprites it draws now, which never passes `Tuning.cap`: a scene spawns nothing that would.
        var count: Int { get }
        /// The frames a second it wants now: `Tuning.frameRate`, Code at rest and Still water fewer.
        var frameRate: Double { get }
    }

    /// The scene of `mode`.
    public static func scene(_ mode: Mode, stage: Stage, glyphs: Glyphs, seed: UInt64) -> any Scene {
        switch mode {
        case .code: Code(stage: stage, glyphs: glyphs, seed: seed)
        case .water: Water(stage: stage, glyphs: glyphs, seed: seed)
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

    /// One scene from the first key until it has died out (an ambient mode's, every mode's since pass 24, from the
    /// show until the close): the keys turned into its events, the typing rate, and the alpha every sprite is drawn
    /// at, 1 until the last second of `Tuning.linger` after the last key (fading evenly; an ambient mode stays at 1),
    /// or fading over a close (the box going, on the curve, as the dim it goes with).
    /// Stepped by the scene's thread once a frame; `frame` says when it is over, and the caller pauses.
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
        /// The frames a second the scene wants now.
        public var frameRate: Double { scene.frameRate }

        /// The keys since the last frame, in order.
        public mutating func take(_ keys: [Key]) {
            for k in keys {
                lastKey = max(lastKey, k.t)
                typing.key(at: k.t)
                let at = k.code.flatMap { Keyboard.position(of: $0, on: stage.keyboard) }
                switch k.kind {
                case .glyph(let c): events.append(.typed(slot: glyphs.slot(c), at: at))
                case .space: events.append(.space(at))
                case .paragraph: events.append(.paragraph(at))
                case .backspace: events.append(.backspace(at))
                }
            }
        }

        /// The box went at `t`: the scene fades out over `d`; no key comes after it.
        public mutating func close(at t: Double, over d: Double) {
            if closing == nil { closing = (t, d) }
        }

        /// The alpha every sprite is drawn at, at `t`: the last second before `linger` after the last key fades
        /// evenly (not in an ambient mode), and a close fades over its time on the curve (evenly until pass 18); 0 when
        /// it is over. Times the theme's ink's alpha (1 for Lemna).
        public func alpha(at t: Double) -> Double {
            var a = mode.ambient ? 1 : min(max((lastKey + Tuning.linger - t) / Tuning.fadeOut, 0), 1)
            if let c = closing { a *= c.over > 0 ? 1 - Curve.easeOutQuint((t - c.at) / c.over) : 0 }
            return a * stage.ink.alpha
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
    /// after a cleared frame is on screen, so the last frame of a scene cut short never shows at the next summon. An
    /// ambient mode's scene (Code, Still water) is made at the show's first frame, keys or none, and plays until the close; the
    /// link's frame rate follows what the scene wants (`Step.rate`). Free of Metal: the tests drive whole sequences.
    public struct Lifecycle {
        public enum Phase: Equatable {
            /// The link is paused; the app's start runs it again at a key (or at an ambient mode's show).
            case idle
            /// Frames come: a scene plays, or is waited for.
            case playing
            /// A cleared frame is out and the drawable parked; the next frame clears again and pauses.
            case parking
        }

        /// What one frame does: the sprites drawn at `alpha` into the link's drawable, or (nil) that drawable cleared;
        /// `resize` the drawable's size from the next frame on, set once this frame is committed; `show` the turn
        /// whose layer may be shown again (a cleared frame of it is already out); `pause` the link after this frame;
        /// `rate` the link's frames a second from now on, when it changes.
        public struct Step: Equatable {
            public var alpha: Double?, resize: CGSize?, show: Int?, pause = false, rate: Double?
        }

        /// The drawable while nothing plays: one pixel, so the screen-sized ones go.
        public static let parked = CGSize(width: 1, height: 1)

        public private(set) var phase = Phase.idle
        public private(set) var run: Run?
        private var plan: Plan?, fresh = false, showNext = false, last: Double?
        /// The link's frames a second as last asked (it starts at `Tuning.frameRate`).
        private var rate = Tuning.frameRate

        public init() {}

        /// The first key after a pause, or the show of an ambient mode: frames again, the drawable at the screen's size
        /// (the caller sets it, then runs the link).
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
            if run == nil, let plan, let mode = plan.mode, !keys.isEmpty || mode.ambient, closing == nil {
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
                if let r = run?.frameRate, r != rate { (step.rate, rate) = (r, r) }
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
