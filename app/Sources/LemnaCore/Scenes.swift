// The two scenes of the ambience (DESIGN.md A1): Code (M2 of docs/design-panel-lemna-ambience.html, Rain until pass
// 25) and Still water (pass 24, AM1 of docs/design-panel-lemna-themes.html), each a particle system on the CPU, stepped
// once a frame by `Ambience.Run` on the scene's thread. Pass 18 removed M4 Beams, M6 Fireworks and M7 Swarm, pass 24
// (RM1) M1 Drift, M3 Rings and M5 Grid. Code, since pass 19b (G1 I1 T1 C2 K1 W1 of docs/design-panel-lemna-rain.html),
// is the films' code rain as research_notes/Lemna rain/matrix.md §6 sets it: a fixed grid of glyphs lit by heads that
// step down it, falling from the show to the close, each column at its own speed, made more intense by typing and fed by
// where each key is on the keyboard (`Keyboard`, pass 16); since pass 27 the film's title sequence, a dim curtain over
// nearly the whole screen with brighter streams through it and a nearer sheet of a few larger, softer ones, its cells
// in one array a sheet. Still water is
// research_notes/Lemna themes/look.md §5.3's Ripples: soft rings on the dim from the show to the close, from drops at
// rest and, since pass 25, a drop for each word written; since pass 31 rain as busy as Code's curtain, hundreds of
// drops a second in gusts, of rain's own sizes, heavier while typing, its wide rings drawn as bands. Every magnitude is
// `Ambience.Tuning`'s; a scene draws no more than `Tuning.cap` sprites.
import CoreGraphics
import Foundation

private typealias T = Ambience.Tuning

extension Ambience.Scene {
    var frameRate: Double { T.frameRate }
    var bands: Int { 0 }
}

// MARK: M2 Code

/// A magnitude between its idle and its typing value (`Tuning`'s pairs), at intensity `i`: Code's.
private func between(_ p: (idle: Double, typing: Double), _ i: Double) -> Double { p.idle + (p.typing - p.idle) * i }
private func between(_ p: (idle: ClosedRange<Double>, typing: ClosedRange<Double>), _ i: Double) -> ClosedRange<Double> {
    between((p.idle.lowerBound, p.typing.lowerBound), i)...between((p.idle.upperBound, p.typing.upperBound), i)
}

/// The films' code rain over the dim (pass 19b; G1 I1 T1 C2 K1 W1 of docs/design-panel-lemna-rain.html; Rain until pass
/// 25; the film's title sequence since pass 27): glyphs fixed in a grid of square cells over the whole screen, and heads
/// stepping down the columns a cell at a time, each lighting the cell it enters in the text colour with a soft halo
/// under it; the cell behind it stays bright, then dims in place in the accent over the head's long trail, each glyph
/// at its own brightness. A column keeps the speed it drew at the birth, whatever the intensity (pass 25); its heads
/// (up to `codeMost` at a time, most at the top, some lower down) start after a random pause and end below the bottom,
/// their trails lingering; every lit glyph changes now and then, and its brightness with it. A second, nearer sheet
/// (`codeNear`) carries a few larger, softer, brighter streams over it. It falls from the show until the close, a dim
/// curtain with brighter streams through it that builds in over its first `codeBuildIn` while new streams fall in
/// (pass 27b), and typing raises one intensity that sets how many heads fall, how long their trails and how bright,
/// and how often the glyphs change, never how fast (the films' "more intense", matrix §2 and §3); each glyph key also
/// starts a head where the key is across the screen, higher the higher its row, the typed glyph at it, brighter than
/// the curtain's. Every screen.
struct Code: Ambience.Scene {
    /// A head: its column, its row (0 at the top; between two cells while it steps), its trail in cells, the typed
    /// glyph's slot at it (nil: the cell's own), whether a key started it, and whether it fell before the show (pass
    /// 27b: veiled, it and the cells it lights build in with the curtain).
    fileprivate struct Head {
        let column: Int; var row: Double; let trail: Double, gain: Double, glyph: Int?, key: Bool, veiled: Bool
    }

    /// One sheet of the rain (pass 27; the films' depth, Reloaded's "multiple virtual sheets of glass", matrix §1.4):
    /// a grid of `columns` × `rows` cells of `pitch` points, row 0 at the top edge, the columns centred across, its
    /// glyphs at `scale` of the atlas's cell, `blur` mipmap levels soft and at `bright` times the alphas, with about
    /// `active` heads a column.
    fileprivate struct Sheet {
        /// A cell: its glyph and its brightness (`codeLevel`, drawn again with each new glyph), its column's travel
        /// when a head lit it (−∞: never), the trail it dims over (in cells), its trail's top alpha (0: the
        /// intensity's, times its stream's `gain`), whether a head is in it (set and cleared as the step draws), and
        /// whether a veiled head lit it (pass 27b: lit before the show, it builds in with the curtain).
        struct Cell {
            var glyph: Int, level: Double, lit: Double, trail: Double, top: Double, gain: Double
            var under: Bool, veiled: Bool
        }
        let columns: Int, rows: Int, pitch: Double, left: Double, scale: Double, blur: Double, bright: Double
        let active: (idle: Double, typing: Double)
        /// Each column's and each row's middle on the stage.
        let xs: [Float], ys: [Float]
        /// The cells, column by column: a cell at column × `rows` + row.
        var cells: [Cell]
        /// Each column's speed in rows a second (drawn once from `codeSpeed`, kept whatever the intensity), its cells
        /// stepped in all and in this step, how many of its heads are not a key's, and how far it is through its pause
        /// before the next head and how long that pause is (in its mean pauses at the intensity, `codeWait`).
        var speed: [Double], travel: [Double], moved: [Double], falling: [Int], due: [Double], wait: [Double]
        var heads: [Head] = []
        /// While the scene is stepped ahead at its birth: the heads it starts then are veiled (pass 27b).
        var veiling = true

        init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, depth: Double, blur: Double, bright: Double,
             active: (idle: Double, typing: Double), random r: inout Ambience.Random) {
            pitch = Double(glyphs.cell.height) * T.codePitch * depth
            let (w, h) = (Double(stage.size.width), Double(stage.size.height))
            (columns, rows) = (max(Int(w / pitch), 1), max(Int((h / pitch).rounded(.up)), 1))
            left = (w - Double(columns) * pitch) / 2
            (scale, self.blur, self.bright, self.active) = (T.codeScale * depth, blur, bright, active)
            let (left, pitch) = (left, pitch)
            xs = (0..<columns).map { Float(left + (Double($0) + 0.5) * pitch) }
            ys = (0..<rows).map { Float(h - (Double($0) + 0.5) * pitch) }
            let set = glyphs.codeSet.isEmpty ? [0] : glyphs.codeSet
            cells = (0..<columns * rows).map { _ in
                Cell(glyph: set.randomElement(using: &r)!, level: Code.level(&r), lit: -.infinity, trail: 1, top: 0, gain: 1,
                     under: false, veiled: false)
            }
            speed = (0..<columns).map { _ in mix(T.codeSpeed, r.unit()) }
            (travel, moved, falling) = (Array(repeating: 0, count: columns), Array(repeating: 0, count: columns),
                                        Array(repeating: 0, count: columns))
            wait = (0..<columns).map { _ in mix(T.codeWait, r.unit()) }
            due = wait.map { $0 * r.unit() }  // each column somewhere in its first pause
            heads.reserveCapacity(limit)
        }

        /// The most heads in a column at once, `codeMost` for each `codeHeight` of its height (no fewer); and in the
        /// sheet, one more a column from keys.
        var most: Int { max(T.codeMost, Int((Double(T.codeMost) * Double(rows) * pitch / T.codeHeight).rounded())) }
        var limit: Int { (most + 1) * columns }

        /// A head lights cell `r` of column `c`: it dims from now over `t` cells of the column's travel, from `a` (0: the
        /// intensity's trail top times `g`), veiled if the head is.
        mutating func light(_ c: Int, _ r: Int, trail t: Double, top a: Double, gain g: Double = 1,
                            veiled v: Bool = false) {
            let x = c * rows + r
            (cells[x].lit, cells[x].trail, cells[x].top, cells[x].gain, cells[x].veiled) = (travel[c], t, a, g, v)
        }

        /// One sheet's sprites at `look` in `ink`, written at `sp` from `k` on, at most `room` in all (`shown` counts
        /// them all): its heads first, each with its halo under it where light adds (a key's before the others, at
        /// `codeKeyHead` and `codeKeyHalo`), so the cap takes trail cells, not heads; then every lit cell, its glyph
        /// first changed to another of `set` at odds `p` (`codeChange` a second, its brightness with it), the ones
        /// right behind a head in the text colour, the rest in the accent at its own brightness along the trail's fade,
        /// unless under `cut`; a veiled head and a veiled cell at `veil` of their alpha (the build-in, pass 27b), under
        /// `cut` not drawn. Thousands a frame: one pass over the cells, which it reads and writes the sprites through
        /// pointers, their fields as the shader reads them; the lit cells passed between two changes drawn at once
        /// (geometric: the odds of a draw a cell for a draw a change).
        mutating func draw(_ look: (head: Double, top: Double, halo: Double), veil: Double, cut: Double, ink: Theme.Ink,
                           glyphs: Ambience.Glyphs, change p: Double, random: inout Ambience.Random,
                           into sp: UnsafeMutablePointer<Sprite>, count k: inout Int, room: Int, shown: inout Int) {
            let (text, accent) = (Sprite.packed(ink.text), Sprite.packed(ink.accent))
            let glow = ink.blend == .add  // light spills from a head; ink laid over a light wash does not glow
            let (rows, columns, bright) = (rows, columns, bright)
            func put(_ s: Sprite) {
                shown += 1
                if k < room { (sp[k], k) = (s, k + 1) }
            }
            for pass in 0..<2 {
                let key = pass == 0
                for h in heads where h.key == key {
                    let r = Int(h.row), x = h.column * rows + r
                    guard !cells[x].under else { continue }
                    cells[x].under = true
                    let v = h.veiled ? veil : 1
                    guard v > cut else { continue }  // fell before the show, and the curtain not yet built in
                    let at = CGPoint(x: Double(xs[h.column]), y: Double(ys[r]))
                    if glow {
                        put(Sprite.halo(x: at.x, y: at.y, width: T.codeHaloWidth * pitch,
                                        alpha: (key ? T.codeKeyHalo : look.halo) * bright * v, colour: ink.text))
                    }
                    put(glyphs.sprite(h.glyph ?? cells[x].glyph, centre: at, scale: scale,
                                      alpha: (key ? T.codeKeyHead : look.head) * bright * v, colour: ink.text,
                                      mirrored: h.glyph == nil, blur: blur))
                }
            }
            let w = -Float(Double(glyphs.cell.width) * scale), h = Float(Double(glyphs.cell.height) * scale)  // mirrored
            let soft = UInt32(min(max((blur * 4).rounded(), 0), 15)) << 20  // the blur above the slot, both above the kind
            let (keyHead, neck, necks, fade) = (T.codeKeyHead, T.codeNeck, Double(T.codeNeckCells + 1), T.codeFade)
            var (n, j) = (shown, k)
            let set = glyphs.codeSet, odds = log(1 - min(max(p, 1e-9), 0.5))
            var skip = Int(log(1 - random.unit()) / odds)
            assert(cells.count == columns * rows && ys.count == rows && xs.count == columns)  // what the pointers read
            ys.withUnsafeBufferPointer { ys in cells.withUnsafeMutableBufferPointer { buffer in
                let cells = buffer.baseAddress!, ys = ys.baseAddress!  // a pointer's subscript inlines even in debug
                for c in 0..<columns {
                    let now = travel[c], cx = xs[c]
                    for r in 0..<rows {
                        let x = c * rows + r
                        var cell = cells[x]
                        let age = now - cell.lit, t = cell.trail
                        guard age < t else { continue }
                        if skip > 0 {
                            skip -= 1
                        } else if !set.isEmpty {
                            (cell.glyph, cell.level) = (set[Int(random.next() % UInt64(set.count))], Code.level(&random))
                            (cells[x].glyph, cells[x].level) = (cell.glyph, cell.level)
                            skip = Int(log(1 - random.unit()) / odds)
                        }
                        if cell.under {
                            cells[x].under = false
                            continue
                        }
                        var a: Double, colour = text
                        if age < necks {  // right behind a head: bright, in the head's colour
                            a = (cell.top > 0 ? keyHead : look.head) * pow(neck, age.rounded(.down)) * bright
                        } else {
                            let f = 1 - age / t, top = cell.top > 0 ? cell.top : look.top * cell.gain
                            a = top * cell.level * (fade == 1 ? f : pow(f, fade)) * bright
                            guard a > cut else { continue }
                            colour = accent
                        }
                        if cell.veiled {  // lit before the show: building in
                            a *= veil
                            guard a > cut else { continue }
                        }
                        n += 1
                        guard j < room else { continue }
                        sp[j] = Sprite(x: cx, y: ys[r], w: w, h: h, alpha: Float(min(a, 1)), packed: colour,
                                       shape: UInt32(cell.glyph) << 8 | soft)
                        j += 1
                    }
                }
            } }
            (shown, k) = (n, j)
        }

        /// The sheet moved on by `dt` at intensity `i`: every head a step down its column at the column's speed,
        /// lighting the cells it enters, those below the bottom gone, and new heads.
        mutating func advance(dt: Double, intensity i: Double, random: inout Ambience.Random) {
            for c in 0..<columns {
                moved[c] = speed[c] * dt
                travel[c] += moved[c]
            }
            var k = 0
            while k < heads.count {
                var h = heads[k]
                let from = Int(h.row)
                h.row += moved[h.column]
                let to = Int(h.row)
                if to > from, from + 1 < rows {
                    for r in (from + 1)...min(to, rows - 1) {
                        light(h.column, r, trail: h.trail, top: h.key ? T.codeKeyTrailTop : 0, gain: h.gain,
                              veiled: h.veiled)
                    }
                }
                if to >= rows {  // below the bottom: it ends, its trail lingering in the cells
                    if !h.key { falling[h.column] -= 1 }
                    heads.swapAt(k, heads.count - 1)
                    heads.removeLast()
                    continue
                }
                heads[k] = h
                k += 1
            }
            // New heads after a random pause, `codeWait` of the mean pause that keeps about `active` heads in a column
            // for each `codeHeight` of its height (each falls the rows below its start at the column's speed; the
            // pause runs at the intensity's rate, so typing shortens the one under way), at least `codeGap` rows from
            // every other in the column: at the top, or (`codeHigh` of them) at a row in `codeHighRows` of the height.
            // A pause far narrower than a Poisson one's keeps a column from standing empty (about one in eight of them
            // did, pass 27's first try); heads by the height keep a tall screen as dense as a laptop's.
            let trails = between(T.codeTrail, i), gap = between(T.codeGap, i)
            let active = between(self.active, i) * Double(rows) * pitch / T.codeHeight
            let fall = Double(rows) * (1 - T.codeHigh * (T.codeHighRows.lowerBound + T.codeHighRows.upperBound) / 2)
            for c in 0..<columns {
                due[c] += active * speed[c] / fall * dt
                guard due[c] >= wait[c], falling[c] < most, heads.count < limit else { continue }
                let row = random.unit() < T.codeHigh ? Int(mix(T.codeHighRows, random.unit()) * Double(rows)) : 0
                guard !heads.contains(where: { $0.column == c && abs($0.row - Double(row)) < gap }) else { continue }
                let (t, g) = (Code.logUniform(trails, &random), Code.logUniform(T.codeGain, &random))
                (due[c], wait[c]) = (0, mix(T.codeWait, random.unit()))
                falling[c] += 1
                heads.append(Head(column: c, row: Double(row), trail: t, gain: g, glyph: nil, key: false,
                                  veiled: veiling))
                light(c, row, trail: t, top: 0, gain: g, veiled: veiling)
            }
        }
    }

    private let stage: Ambience.Stage, glyphs: Ambience.Glyphs
    /// The sheets: the rain's own grid, and the nearer one over it.
    private var main: Sheet, near: Sheet
    /// The main sheet's grid (the keys' heads fall in it).
    var columns: Int { main.columns }
    var rows: Int { main.rows }
    var pitch: Double { main.pitch }
    /// Each column's speed in rows a second, the main sheet's.
    var speed: [Double] { main.speed }
    /// The nearer sheet's pitch and columns, for the tests.
    var nearPitch: Double { near.pitch }
    var nearColumns: Int { near.columns }
    /// The heads falling now, for the tests: the main sheet's (column, row, whether a key's), the nearer sheet's count.
    var falling: [(column: Int, row: Double, key: Bool)] { main.heads.map { ($0.column, $0.row, $0.key) } }
    var nearFalling: Int { near.heads.count }
    /// 0 at rest, 1 at `codeFast` keys a second; the time since the last key.
    private(set) var intensity = 0.0
    private var sinceKey = Double.infinity
    /// The time since the birth, and the curtain's share of its alpha then (pass 27b): 0 at the birth, 1 from
    /// `codeBuildIn` on.
    private(set) var age = 0.0
    var veil: Double { Code.veil(at: age) }
    /// The sprites the last step would have drawn, before the cap; the alpha under which a trail cell is not drawn,
    /// `codeShown` unless a stage too large for the cap raised it (the dimmest go first).
    private(set) var shown = 0
    private(set) var cut = T.codeShown
    private var random: Ambience.Random
    /// Room for a frame's sprites, written through a pointer and then appended to the frame's at once.
    private var scratch = [Sprite](repeating: Sprite(x: 0, y: 0, w: 0, h: 0, alpha: 0, packed: 0, shape: 0), count: T.cap)

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.stage, self.glyphs) = (stage, glyphs)
        var r = Ambience.Random(seed: seed)
        main = Sheet(stage: stage, glyphs: glyphs, depth: 1, blur: 0, bright: 1, active: T.codeActive, random: &r)
        near = Sheet(stage: stage, glyphs: glyphs, depth: T.codeNear, blur: T.codeNearBlur, bright: T.codeNearBright,
                     active: T.codeNearActive, random: &r)
        random = r
        // Stepped ahead, undrawn, at rest: the rain is falling at the summon, the slowest column's first head through;
        // but veiled, every head of it and every cell it lit, so the curtain builds in over `codeBuildIn` while the
        // heads that start from the show on fall in at once, one by one, as do the keys' (pass 27b).
        for _ in 0..<Int(T.codeAhead * T.codeIdleRate) {
            advance(dt: 1 / T.codeIdleRate, events: [], rate: 0)
        }
        (main.veiling, near.veiling) = (false, false)
    }

    /// The curtain's share at `age` after the birth (pass 27b): smoothstep over `codeBuildIn`, so it opens from
    /// nothing and reaches the rest's look without a kink at either end.
    static func veil(at age: Double) -> Double {
        let u = min(max(age / T.codeBuildIn, 0), 1)
        return u * u * (3 - 2 * u)
    }

    var count: Int { min(shown, T.cap) }

    /// Fewer frames at rest: a head steps a cell at a time, and the films ran at 24.
    var frameRate: Double { intensity > T.codeCalm || sinceKey < T.codeHold ? T.frameRate : T.codeIdleRate }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        advance(dt: dt, events: events, rate: rate)
        age += dt
        let i = intensity, change = between(T.codeChange, i) * dt, veil = self.veil
        let look = (head: between(T.codeHead, i), top: between(T.codeTrailTop, i), halo: between(T.codeHalo, i))
        shown = 0
        var (buffer, k) = ([Sprite](), 0)
        swap(&buffer, &scratch)  // out of the scene, so the sheets can draw into it
        // Never more than it holds, through the pointer (pass 27c: two threads stepping this scene at once left it
        // empty, and the sprites went over the runtime's globals, among them the hook every allocation calls).
        assert(buffer.count == T.cap, "Code's room for its sprites is gone: is it stepped on two threads at once?")
        let room = min(max(T.cap - out.count, 0), buffer.count)
        buffer.withUnsafeMutableBufferPointer { b in
            main.draw(look, veil: veil, cut: cut, ink: stage.ink, glyphs: glyphs, change: change, random: &random,
                      into: b.baseAddress!, count: &k, room: room, shown: &shown)
            near.draw(look, veil: veil, cut: cut, ink: stage.ink, glyphs: glyphs, change: change, random: &random,
                      into: b.baseAddress!, count: &k, room: room, shown: &shown)
        }
        out.append(contentsOf: buffer[0..<k])
        swap(&buffer, &scratch)
        // A stage with more lit cells than the cap: the dimmest trail cells go first, from the next frame on.
        if shown > T.cap {
            cut = min(cut * 1.25, 0.25)
        } else if shown < T.cap * 3 / 4 {
            cut = max(cut / 1.05, T.codeShown)
        }
    }

    /// The scene moved on by `dt`: the keys' heads, the intensity, and every head of each sheet a step down its column
    /// at the column's speed lighting the cells it enters, those below the bottom gone, and new heads (a step's draw
    /// changes the lit glyphs).
    private mutating func advance(dt: Double, events: [Ambience.Event], rate: Double) {
        for e in events {
            sinceKey = 0
            if case .typed(let slot, let key) = e { startHead(slot: slot, at: key) }
        }
        let target = min(rate / T.codeFast, 1)  // up at once, down only after a pause
        if target > intensity {
            intensity += (target - intensity) * (1 - exp(-dt / T.codeRise))
        } else if sinceKey >= T.codeHold {
            intensity += (target - intensity) * (1 - exp(-dt / T.codeSettle))
        }
        sinceKey += dt
        main.advance(dt: dt, intensity: intensity, random: &random)
        near.advance(dt: dt, intensity: intensity, random: &random)
    }

    /// A glyph's brightness along its trail (pass 27): from `codeLevel`'s lower bound to 1, more dim than bright
    /// (`codeLevelSkew`), so a bright glyph sits among dimmer ones.
    fileprivate static func level(_ r: inout Ambience.Random) -> Double {
        mix(T.codeLevel, pow(r.unit(), T.codeLevelSkew))
    }

    /// A glyph key's head: in the main sheet's column where the key is across the screen (anywhere within its width, so
    /// a key typed again does not stack its heads in one column; without a position the caret's x on the box's screen,
    /// anywhere on another), higher the higher its row, the typed glyph at it.
    private mutating func startHead(slot: Int?, at key: Keyboard.Position?) {
        guard main.heads.count < main.limit else { return }
        let (w, h) = (Double(stage.size.width), Double(stage.size.height))
        let width = w * (T.screenSpan.upperBound - T.screenSpan.lowerBound) / Keyboard.columns * (key?.width ?? 0)
        let spread = random.pick(-0.4...0.4) * width
        let along = stage.screenX(key).map { $0 + spread } ?? (stage.box != nil ? Double(stage.caret) : random.pick(0...w))
        let height = key.map { mix(T.codeRows, 1 - $0.down) } ?? random.pick(T.codeRows)
        let c = min(max(Int((along - main.left) / main.pitch), 0), main.columns - 1)
        let r = min(max(Int((1 - height + random.pick(-0.03...0.03)) * h / main.pitch), 0), main.rows - 1)
        let t = Code.logUniform(T.codeKeyTrail, &random)
        main.heads.append(Head(column: c, row: Double(r), trail: t, gain: 1, glyph: slot, key: true, veiled: false))
        main.light(c, r, trail: t, top: T.codeKeyTrailTop)
    }

    /// A trail length, log-uniform in `range`: more short than long.
    fileprivate static func logUniform(_ range: ClosedRange<Double>, _ r: inout Ambience.Random) -> Double {
        range.lowerBound * pow(range.upperBound / range.lowerBound, r.unit())
    }
}

// MARK: Still water

/// Still water (pass 24; AM1 of docs/design-panel-lemna-themes.html, per word and at rest since pass 25; rain on it as
/// busy as Code's curtain since pass 31): the dim is still water seen from above, and rain falls on it from the show to
/// the close, hundreds of drops a second scattered at random over the dim at least `waterClear` from the box, in gusts
/// and lulls, and one above the box at the show. A drop's size is drawn from rain's own skew (many small, few large):
/// a small one makes a small ring that fades fast, a large one a wider, brighter ring that lasts, with one or two
/// fainter crests following it; each drop starts with a short bright splash, and its rings fade as they widen (their
/// energy spread over the circle) and with time, thinning as they go; rings that cross add (the sprites' blend). The
/// rain builds in at the summon (the rain starting), and typing makes it heavier, as it makes Code more intense:
/// more drops and larger, a little brighter; while you write, one large, bright drop for each word, where its last key
/// is. The box's screen only.
struct Water: Ambience.Scene {
    /// A drop: where it landed, its age, and what its size (0 the smallest, 1 the largest) set when it landed: its
    /// crests, the lead crest's speed, the rings' width, the radius out to which a ring keeps its peak (the crater's),
    /// the peak, how long its rings take to fade, how far behind each other its crests start (in seconds) and its
    /// splash's width.
    struct Drop {
        let x, y: Double
        var age: Double
        let size: Double, crests: Int, speed, width, near, peak, decay, lag, splash: Double
    }
    /// The drops alive, and how many have landed since the show.
    private(set) var drops: [Drop] = [], landed = 0
    private let stage: Ambience.Stage, ink: Double, area: Double
    /// The drops' draws, and the gusts' own (so typing, which draws more drops, leaves the gusts as they were).
    private var random: Ambience.Random, gusting: Ambience.Random
    /// Whether a glyph key came since the last word's end, and where the last one is on the keyboard (nil: no place);
    /// the time since the last word's drop.
    private var inWord = false, lastKey: Keyboard.Position?, sinceWord = Double.infinity
    /// 0 at rest, 1 at `waterFast` keys a second (Code's); the time since the last key.
    private(set) var intensity = 0.0
    private var sinceKey = Double.infinity
    /// The time since the birth: the rain's rate rises from 0 to its own over `waterBuildIn` (`buildIn(at:)`).
    private(set) var age = 0.0
    /// The gust under way: the rate's share it glides from and to, how far it is and how long it takes.
    private var gust: (from: Double, to: Double, at: Double, over: Double)
    /// The drops still to fall before the next lands (an exponential gap, in drops: the rain is Poisson in time).
    private var due: Double
    /// The last step's rings wider than `waterBand`, its last sprites, drawn as bands (`Renderer.encode`).
    private(set) var bands = 0
    /// Room for a frame's sprites, written through a pointer and then appended to the frame's at once (as Code's).
    private var scratch = [Sprite](repeating: Sprite(x: 0, y: 0, w: 0, h: 0, alpha: 0, packed: 0, shape: 0),
                                   count: T.cap)

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        var r = Ambience.Random(seed: seed), g = Ambience.Random(seed: r.next())
        self.stage = stage
        ink = stage.ink.blend == .over ? T.waterPeak.over : T.waterPeak.add
        area = Double(stage.size.width * stage.size.height) / (1512 * 982)  // a screen's rate, by its area
        let (from, to, over) = (mix(T.waterGust, g.unit()), mix(T.waterGust, g.unit()), mix(T.waterGustTime, g.unit()))
        gust = (from, to, over * g.unit(), over)  // somewhere in a gust at the show
        due = -log(1 - r.unit())
        (random, gusting) = (r, g)
        drops.reserveCapacity(1024)
        if let box = stage.box {  // the show's: a large drop, at its full brightness while the rain builds in
            drop(x: Double(box.midX), y: Double(box.maxY) + T.waterSummon, size: 1, bright: T.waterWord)
        }
    }

    /// The most it draws: every crest of every drop, and its splash.
    var count: Int { drops.count * (T.waterCrests + 1) }

    var frameRate: Double { T.waterFrameRate }

    /// The rain's share of its rate at `age` after the birth (the build-in): smoothstep over `waterBuildIn`, as Code's
    /// veil, so it starts from nothing and reaches its own rate without a kink.
    static func buildIn(at age: Double) -> Double {
        let u = min(max(age / T.waterBuildIn, 0), 1)
        return u * u * (3 - 2 * u)
    }

    /// The gust's share of the rate now: from one level to the next on a smoothstep.
    var gustLevel: Double {
        let u = min(max(gust.at / gust.over, 0), 1)
        return gust.from + (gust.to - gust.from) * u * u * (3 - 2 * u)
    }

    /// The drops a second now: the intensity's rate on this screen, in the gust, built in.
    var rate: Double {
        let r = T.waterRate.idle + (T.waterRate.typing - T.waterRate.idle) * intensity
        return r * area * gustLevel * Water.buildIn(at: age)
    }

    /// A drop's size, 0 to 1 (a diameter's share of the largest), exponential as rain's drop sizes are
    /// (Marshall–Palmer) with the intensity's slope: many small, few large, more of them large as the rain gets heavier.
    private mutating func size() -> Double {
        let slope = T.waterSize.idle + (T.waterSize.typing - T.waterSize.idle) * intensity
        return -log(1 - random.unit() * (1 - exp(-slope))) / slope
    }

    /// A drop of `size` at (x, y), `age` seconds old (one that landed within the step), `bright` times its peak,
    /// unless `waterDrops` are alive: one crest, two from `waterCrestSizes`' first, three from its second; the lead's
    /// speed, the width, the crater and the fade grow with the size, the peak too.
    mutating func drop(x: Double, y: Double, size s: Double, bright: Double = 1, age: Double = 0) {
        guard drops.count < T.waterDrops else { return }
        let crests = s >= T.waterCrestSizes.1 ? 3 : s >= T.waterCrestSizes.0 ? 2 : 1
        let speed = mix(T.waterSpeed, s) * (1 + random.pick(-1...1) * T.waterJitter)
        drops.append(Drop(x: x, y: y, age: age, size: s, crests: min(crests, T.waterCrests), speed: speed,
                          width: mix(T.waterWidth, s), near: mix(T.waterNear, s),
                          peak: ink * mix(T.waterBright, s) * bright, decay: mix(T.waterFade, s),
                          lag: mix(T.waterGap, s) / speed, splash: mix(T.waterSplashWidth, s)))
        landed += 1
    }

    /// A drop anywhere on the stage, at least `waterClear` from the box (a few tries, else none this time).
    private mutating func restDrop(age: Double) {
        let (w, h) = (Double(stage.size.width), Double(stage.size.height))
        let clear = stage.box?.insetBy(dx: -T.waterClear, dy: -T.waterClear)
        let lift = T.waterLift.idle + (T.waterLift.typing - T.waterLift.idle) * intensity
        for _ in 0..<20 {
            let (x, y) = (random.pick(0...w), random.pick(0...h))
            if let clear, clear.contains(CGPoint(x: x, y: y)) { continue }
            return drop(x: x, y: y, size: size(), bright: lift, age: age)
        }
    }

    /// Crest `k` of drop `d` (0 the lead): `a` its age (each further one starts `waterGap` of the drop's size behind
    /// the one before it and runs `waterSpread` slower), `r` its radius, and its alpha: up over `waterOnset` on the
    /// curve, then down with time, as e^(−a / the drop's fade), and with the radius, as its energy spreads over the
    /// circle (the crater's radius ÷ r from there out), each further crest at `waterFollow` of the one before.
    static func crest(_ k: Int, of d: Drop) -> (a: Double, r: Double, alpha: Double) {
        let a = d.age - Double(k) * d.lag, r = d.speed * (1 - T.waterSpread * Double(k)) * max(a, 0)
        guard a > 0 else { return (a, r, 0) }
        let onset = a < T.waterOnset ? Curve.easeOutQuint(a / T.waterOnset) : 1
        let follow = k == 0 ? 1 : k == 1 ? T.waterFollow : pow(T.waterFollow, Double(k))
        return (a, r, d.peak * follow * onset * exp(-a / d.decay) * min(d.near / max(r, 1e-9), 1))
    }

    /// The splash at a drop's landing: a soft disc (the ring of radius 0), as bright as the drop's peak times
    /// `waterSplashBright`, gone over `waterSplash` on (1 − t ÷ it)².
    static func splash(of d: Drop) -> Double {
        guard d.age < T.waterSplash else { return 0 }
        let f = 1 - d.age / T.waterSplash
        return d.peak * T.waterSplashBright * f * f
    }

    /// A word's drop (pass 25), where the panel's canvas drops it: across the screen where the word's last key is
    /// (`Stage.screenX`), higher the higher the key's row, from `waterTop` under the stage's top edge for the number
    /// row to `waterClear` above the box for the space bar's; a key without a place drops at the caret's x,
    /// `waterClear` above the box. The largest drop, at `waterWord` of its peak (pass 31), so it stands out of the rain.
    private mutating func wordDrop(at key: Keyboard.Position?) {
        let low = Double(stage.box?.maxY ?? 0) + T.waterClear, high = Double(stage.size.height) - T.waterTop
        let x = stage.screenX(key) ?? Double(stage.box == nil ? stage.size.width / 2 : stage.caret)
        drop(x: x, y: low + (1 - (key?.down ?? 1)) * max(high - low, 0), size: 1, bright: T.waterWord)
    }

    /// `events`: a word's end (Space or Return after a glyph key) drops the word's drop, unless the last word's came
    /// less than `waterWordGap` ago; every key and the typing `rate` raise the intensity (pass 31, as Code's: up with
    /// τ `waterRise`, down with τ `waterSettle` from `waterHold` after the last key).
    mutating func step(dt: Double, events: [Ambience.Event], rate typing: Double, into out: inout [Sprite]) {
        sinceWord += dt
        for e in events {
            sinceKey = 0
            switch e {
            case .typed(_, let at): (inWord, lastKey) = (true, at)
            case .space, .paragraph:
                if inWord, sinceWord >= T.waterWordGap {
                    wordDrop(at: lastKey)
                    sinceWord = 0
                }
                inWord = false
            case .backspace: break
            }
        }
        let target = min(typing / T.waterFast, 1)  // up at once, down only after a pause
        if target > intensity {
            intensity += (target - intensity) * (1 - exp(-dt / T.waterRise))
        } else if sinceKey >= T.waterHold {
            intensity += (target - intensity) * (1 - exp(-dt / T.waterSettle))
        }
        sinceKey += dt
        age += dt
        gust.at += dt
        while gust.at >= gust.over {  // the next gust: from where this one ended to a new level
            (gust.from, gust.to) = (gust.to, mix(T.waterGust, gusting.unit()))
            (gust.at, gust.over) = (gust.at - gust.over, mix(T.waterGustTime, gusting.unit()))
        }
        for i in drops.indices { drops[i].age += dt }
        // The rain: drops at exponential gaps at the rate, each landed where in the step its gap ended.
        let now = rate
        if now > 0 {
            var left = now * dt
            while left >= due {
                left -= due
                restDrop(age: left / now)
                due = -log(1 - random.unit())
            }
            due -= left
        }
        // Each drop's splash and crests, the drops whose crests have all faded gone (they fade on from their
        // onset): the narrow rings written from the front of the room, the wide ones from its back and appended after
        // them (as bands), through pointers (a debug build's Array append and Sprite init cost about 100 ns each).
        let (colour, ring, life, shown, band) = (Sprite.packed(stage.ink.text), Sprite.Kind.ring.rawValue, T.waterLife,
                                                 T.waterShown, T.waterBand)
        var (buffer, list) = ([Sprite](), [Drop]())
        swap(&buffer, &scratch)  // out of the scene, so it can be written while the drops are read
        swap(&list, &drops)
        assert(buffer.count == T.cap, "Still water's room for its sprites is gone: is it stepped on two threads at once?")
        let room = min(max(T.cap - out.count, 0), buffer.count)
        var (j, h, kept) = (0, room, 0)  // the narrow at [0, j), the wide at [h, room)
        list.withUnsafeMutableBufferPointer { ds in buffer.withUnsafeMutableBufferPointer { b in
            let sp = b.baseAddress!
            for i in 0..<ds.count {
                let d = ds[i]
                guard d.age < life else { continue }
                var alive = d.age < Double(d.crests - 1) * d.lag + T.waterOnset  // not every crest out yet
                let dot = Water.splash(of: d)
                if dot >= shown {
                    alive = true
                    if j < h {
                        sp[j] = Sprite.halo(x: d.x, y: d.y, width: d.splash, alpha: dot, colour: stage.ink.text)
                        j += 1
                    }
                }
                let (x, y) = (Float(d.x), Float(d.y))
                for k in 0..<d.crests {
                    let c = Water.crest(k, of: d)
                    guard c.alpha >= shown else { continue }
                    alive = true
                    guard j < h else { continue }
                    let w = d.width * (T.waterThin + (1 - T.waterThin) * d.near / (d.near + c.r))  // thinning
                    let side = Float(2 * (c.r + 2 * w))
                    let s = Sprite(x: x, y: y, w: side, h: side, alpha: Float(min(c.alpha, 1)), packed: colour,
                                   shape: ring | Sprite.ring(radius: c.r, width: w) << 8)
                    if c.r > band {
                        h -= 1
                        sp[h] = s
                    } else {
                        sp[j] = s
                        j += 1
                    }
                }
                if alive {
                    if kept != i { ds[kept] = d }
                    kept += 1
                }
            }
        } }
        list.removeLast(list.count - kept)
        out.append(contentsOf: buffer[0..<j])
        out.append(contentsOf: buffer[h..<room])
        bands = room - h
        swap(&buffer, &scratch)
        swap(&list, &drops)
    }
}
