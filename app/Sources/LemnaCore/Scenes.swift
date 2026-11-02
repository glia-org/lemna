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
// rest and, since pass 25, a drop for each word written. Every magnitude is `Ambience.Tuning`'s; a scene draws no more
// than `Tuning.cap` sprites.
import CoreGraphics
import Foundation

private typealias T = Ambience.Tuning

extension Ambience.Scene {
    var frameRate: Double { T.frameRate }
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
/// curtain with brighter streams through it, and typing raises one intensity that sets how many heads fall, how long
/// their trails and how bright, and how often the glyphs change, never how fast (the films' "more intense", matrix §2
/// and §3); each glyph key also starts a head where the key is across the screen, higher the higher its row, the typed
/// glyph at it. Every screen.
struct Code: Ambience.Scene {
    /// A head: its column, its row (0 at the top; between two cells while it steps), its trail in cells, the typed
    /// glyph's slot at it (nil: the cell's own), and whether a key started it.
    fileprivate struct Head { let column: Int; var row: Double; let trail: Double, gain: Double, glyph: Int?, key: Bool }

    /// One sheet of the rain (pass 27; the films' depth, Reloaded's "multiple virtual sheets of glass", matrix §1.4):
    /// a grid of `columns` × `rows` cells of `pitch` points, row 0 at the top edge, the columns centred across, its
    /// glyphs at `scale` of the atlas's cell, `blur` mipmap levels soft and at `bright` times the alphas, with about
    /// `active` heads a column.
    fileprivate struct Sheet {
        /// A cell: its glyph and its brightness (`codeLevel`, drawn again with each new glyph), its column's travel
        /// when a head lit it (−∞: never), the trail it dims over (in cells), its trail's top alpha (0: the
        /// intensity's, times its stream's `gain`), and whether a head is in it (set and cleared as the step draws).
        struct Cell { var glyph: Int, level: Double, lit: Double, trail: Double, top: Double, gain: Double, under: Bool }
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
                     under: false)
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
        /// intensity's trail top times `g`).
        mutating func light(_ c: Int, _ r: Int, trail t: Double, top a: Double, gain g: Double = 1) {
            let x = c * rows + r
            (cells[x].lit, cells[x].trail, cells[x].top, cells[x].gain) = (travel[c], t, a, g)
        }

        /// One sheet's sprites at `look` in `ink`, written at `sp` from `k` on, at most `room` in all (`shown` counts
        /// them all): its heads first, each with its halo under it where light adds (a key's before the others), so
        /// the cap takes trail cells, not heads; then every lit cell, its glyph first changed to another of `set` at
        /// odds `p` (`codeChange` a second, its brightness with it), the ones right behind a head in the text colour,
        /// the rest in the accent at its own brightness along the trail's fade, unless under `cut`. Thousands a frame:
        /// one pass over the cells, which it reads and writes the sprites through pointers, their fields as the shader
        /// reads them; the lit cells passed between two changes drawn at once (geometric: the odds of a draw a cell
        /// for a draw a change).
        mutating func draw(_ look: (head: Double, top: Double, halo: Double), cut: Double, ink: Theme.Ink,
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
                    let at = CGPoint(x: Double(xs[h.column]), y: Double(ys[r]))
                    if glow {
                        put(Sprite.halo(x: at.x, y: at.y, width: T.codeHaloWidth * pitch, alpha: look.halo * bright,
                                        colour: ink.text))
                    }
                    put(glyphs.sprite(h.glyph ?? cells[x].glyph, centre: at, scale: scale,
                                      alpha: (key ? T.codeKeyHead : look.head) * bright, colour: ink.text,
                                      mirrored: h.glyph == nil, blur: blur))
                }
            }
            let w = -Float(Double(glyphs.cell.width) * scale), h = Float(Double(glyphs.cell.height) * scale)  // mirrored
            let soft = UInt32(min(max((blur * 4).rounded(), 0), 15)) << 20  // the blur above the slot, both above the kind
            let (keyHead, neck, necks, fade) = (T.codeKeyHead, T.codeNeck, Double(T.codeNeckCells + 1), T.codeFade)
            var (n, j) = (shown, k)
            let set = glyphs.codeSet, odds = log(1 - min(max(p, 1e-9), 0.5))
            var skip = Int(log(1 - random.unit()) / odds)
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
                        light(h.column, r, trail: h.trail, top: h.key ? T.codeKeyTrailTop : 0, gain: h.gain)
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
                heads.append(Head(column: c, row: Double(row), trail: t, gain: g, glyph: nil, key: false))
                light(c, row, trail: t, top: 0, gain: g)
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
        // Stepped ahead, undrawn, at rest: the summon finds the rain falling, the slowest column's first head through.
        for _ in 0..<Int(T.codeAhead * T.codeIdleRate) {
            advance(dt: 1 / T.codeIdleRate, events: [], rate: 0)
        }
    }

    var count: Int { min(shown, T.cap) }

    /// Fewer frames at rest: a head steps a cell at a time, and the films ran at 24.
    var frameRate: Double { intensity > T.codeCalm || sinceKey < T.codeHold ? T.frameRate : T.codeIdleRate }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        advance(dt: dt, events: events, rate: rate)
        let i = intensity, change = between(T.codeChange, i) * dt
        let look = (head: between(T.codeHead, i), top: between(T.codeTrailTop, i), halo: between(T.codeHalo, i))
        shown = 0
        var (buffer, k, room) = ([Sprite](), 0, max(T.cap - out.count, 0))
        swap(&buffer, &scratch)  // out of the scene, so the sheets can draw into it
        buffer.withUnsafeMutableBufferPointer { b in
            main.draw(look, cut: cut, ink: stage.ink, glyphs: glyphs, change: change, random: &random,
                      into: b.baseAddress!, count: &k, room: room, shown: &shown)
            near.draw(look, cut: cut, ink: stage.ink, glyphs: glyphs, change: change, random: &random,
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
        main.heads.append(Head(column: c, row: Double(r), trail: t, gain: 1, glyph: slot, key: true))
        main.light(c, r, trail: t, top: T.codeKeyTrailTop)
    }

    /// A trail length, log-uniform in `range`: more short than long.
    fileprivate static func logUniform(_ range: ClosedRange<Double>, _ r: inout Ambience.Random) -> Double {
        range.lowerBound * pow(range.upperBound / range.lowerBound, r.unit())
    }
}

// MARK: Still water

/// Still water (pass 24; AM1 of docs/design-panel-lemna-themes.html, per word and at rest since pass 25): the dim is
/// still water, and drops land on it at random at a slow rate, at least `waterClear` from the box, and one above the
/// box at the show; while you write, one for each word, where its last key is, and never one for a key. Each drop is a
/// few soft rings that leave together, the outer leading and the calm centre following, each with a fainter trough
/// inside it; a ring rises softly, then fades with its radius and with time, and rings that cross add (the sprites'
/// blend). The box's screen only.
struct Water: Ambience.Scene {
    /// A crest: its speed, its width and its start (from the drop's landing).
    struct Crest { let speed, width, start: Double }
    /// A drop: where it landed, its age and its crests.
    struct Drop { let x, y: Double; var age: Double; let crests: [Crest] }
    /// The drops alive, and how many have landed since the show.
    private(set) var drops: [Drop] = [], landed = 0
    private let stage: Ambience.Stage, peak: Double, rate: Double
    private var random: Ambience.Random
    /// Whether a glyph key came since the last word's end, and where the last one is on the keyboard (nil: no place);
    /// the time since the last word's drop.
    private var inWord = false, lastKey: Keyboard.Position?, sinceWord = Double.infinity

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.stage, random) = (stage, Ambience.Random(seed: seed))
        peak = stage.ink.blend == .over ? T.waterPeak.over : T.waterPeak.add
        rate = T.waterRate * Double(stage.size.width * stage.size.height) / (1512 * 982)  // a screen's, by its area
        drops.reserveCapacity(T.waterDrops)
        if let box = stage.box { drop(x: Double(box.midX), y: Double(box.maxY) + T.waterSummon) }  // the show's
    }

    /// The most it draws: every crest of every drop, with its trough.
    var count: Int { drops.count * T.waterCrests * 2 }

    var frameRate: Double { T.waterFrameRate }

    /// A drop at (x, y), unless `waterDrops` are alive: its crests leave together, each further one slower.
    mutating func drop(x: Double, y: Double) {
        guard drops.count < T.waterDrops else { return }
        let crests = (0..<T.waterCrests).map { k in
            Crest(speed: T.waterSpeed * (1 - T.waterSpread * Double(k) * (1 + random.pick(-1...1) * T.waterJitter)),
                  width: random.pick(T.waterWidth), start: random.pick(-1...1) * T.waterStart)
        }
        drops.append(Drop(x: x, y: y, age: 0, crests: crests))
        landed += 1
    }

    /// A drop anywhere on the stage, at least `waterClear` from the box (a few tries, else none this time).
    private mutating func restDrop() {
        let (w, h) = (Double(stage.size.width), Double(stage.size.height))
        let clear = stage.box?.insetBy(dx: -T.waterClear, dy: -T.waterClear)
        for _ in 0..<20 {
            let (x, y) = (random.pick(0...w), random.pick(0...h))
            if let clear, clear.contains(CGPoint(x: x, y: y)) { continue }
            return drop(x: x, y: y)
        }
    }

    /// A ring's alpha: up over `waterOnset` on the curve since its start (`a`), then down with the drop's `age` and
    /// with its radius `r`.
    func alpha(a: Double, age: Double, r: Double) -> Double {
        let spread = (T.waterNear / max(r, T.waterNear)).squareRoot()  // its energy over its circumference
        return peak * Curve.easeOutQuint(a / T.waterOnset) * exp(-age / T.waterDecay) * spread
    }

    /// A word's drop (pass 25), where the panel's canvas drops it: across the screen where the word's last key is
    /// (`Stage.screenX`), higher the higher the key's row, from `waterTop` under the stage's top edge for the number
    /// row to `waterClear` above the box for the space bar's; a key without a place drops at the caret's x,
    /// `waterClear` above the box.
    private mutating func wordDrop(at key: Keyboard.Position?) {
        let low = Double(stage.box?.maxY ?? 0) + T.waterClear, high = Double(stage.size.height) - T.waterTop
        let x = stage.screenX(key) ?? Double(stage.box == nil ? stage.size.width / 2 : stage.caret)
        drop(x: x, y: low + (1 - (key?.down ?? 1)) * max(high - low, 0))
    }

    /// `events`: a word's end (Space or Return after a glyph key) drops the word's drop, unless the last word's came
    /// less than `waterWordGap` ago; a glyph key, ⌫ and the typing rate change nothing it draws.
    mutating func step(dt: Double, events: [Ambience.Event], rate _: Double, into out: inout [Sprite]) {
        sinceWord += dt
        for e in events {
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
        if random.unit() < rate * dt { restDrop() }  // Poisson, at `rate` a second
        for i in drops.indices { drops[i].age += dt }
        drops.removeAll { $0.age >= T.waterLife }
        let colour = stage.ink.text
        for d in drops {
            for c in d.crests {
                let a = d.age - c.start, r = c.speed * a
                guard a > 0, out.count + 2 <= T.cap else { continue }
                let alpha = alpha(a: a, age: d.age, r: r)
                guard alpha >= T.waterShown else { continue }
                out.append(Sprite.ring(x: d.x, y: d.y, radius: r, width: c.width, alpha: alpha, colour: colour))
                if r > T.waterTrough, alpha * T.waterTroughShare >= T.waterShown {  // the trough inside it
                    out.append(Sprite.ring(x: d.x, y: d.y, radius: r - T.waterTrough, width: c.width,
                                           alpha: alpha * T.waterTroughShare, colour: colour))
                }
            }
        }
    }
}
