// The four scenes of the ambience (DESIGN.md A1; M1, M2, M3 and M5 of docs/design-panel-lemna-ambience.html; pass 18
// removed M4 Beams, M6 Fireworks and M7 Swarm), each a particle system on the CPU, stepped once a frame by
// `Ambience.Run` on the scene's thread, fed by the keys as the panel couples them and, since pass 16, by where each key
// is on the keyboard (`Keyboard`; Drift follows the text instead).
// Drift, Rings and Grid each borrow one tte effect's motion, not its text (the dim has no characters to reveal). Rain,
// since pass 19b (G1 I1 T1 C2 K1 W1 of docs/design-panel-lemna-rain.html), is the films' rain as research_notes/Lemna
// rain/matrix.md §6 sets it: a fixed grid of glyphs lit by heads that step down it, its cells in flat arrays, falling
// from the show to the close and raised by typing. Every magnitude is `Ambience.Tuning`'s; a scene draws no more than
// `Tuning.cap` sprites.
import CoreGraphics
import Foundation

private typealias T = Ambience.Tuning

extension Ambience.Scene {
    var frameRate: Double { T.frameRate }
}

/// How far the typing rate is to `Tuning.fastRate`, 0 to 1.
private func pace(_ rate: Double) -> Double { min(max(rate / T.fastRate, 0), 1) }

// MARK: M1 Drift

/// Glyphs that leave the box's left edge float off over the dim like duckweed on slow water: each fades in where it
/// came out from under the box, at the line's speed, and slows onto a current the typing rate sets, rising or sinking
/// at its own pace, wandering and turning, gone after `driftLife`. The one mode made of your own words; the box's
/// screen only.
struct Drift: Ambience.Scene {
    private struct Leaf { var x, y, vx, age, rotation: Double; let slot: Int, rise, turn, phase: Double }
    private var leaves: [Leaf] = []
    /// The current's speed now, easing toward the one the rate sets.
    private(set) var current = T.driftCurrent.lowerBound
    private let glyphs: Ambience.Glyphs, advance: Double
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.glyphs, random) = (glyphs, Ambience.Random(seed: seed))
        advance = Double(glyphs.cell.width - 2 * Ambience.Glyphs.pad)  // one cell of the monospaced line
    }

    var count: Int { leaves.count }

    /// Up over `driftIn`, held for `driftHold`, down to nothing at `driftLife`.
    static func alpha(age: Double) -> Double {
        let out = T.driftLife - T.driftIn - T.driftHold
        return T.driftPeak * min(age / T.driftIn, 1) * min((T.driftLife - age) / out, 1)
    }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        current += (mix(T.driftCurrent, pace(rate)) - current) * (1 - exp(-dt / T.driftEase))
        let current = current, carry = 1 - exp(-dt / T.driftCarry)
        for case .leaving(let slot, let p) in events where leaves.count < T.cap {
            let turn = random.pick(T.driftTurn) * (random.unit() < 0.5 ? -1 : 1)
            let leaf = Leaf(x: Double(p.x), y: Double(p.y), vx: max(advance * rate, current), age: 0, rotation: 0,
                            slot: slot, rise: random.pick(T.driftRise), turn: turn, phase: random.pick(0...(2 * .pi)))
            leaves.append(leaf)
        }
        for i in leaves.indices {
            var l = leaves[i]
            l.age += dt
            l.vx += (current - l.vx) * carry
            l.x -= l.vx * dt
            l.y += (l.rise + T.driftWander * sin(l.phase + 0.8 * l.age)) * dt
            l.rotation += l.turn * dt
            leaves[i] = l
        }
        leaves.removeAll { $0.age >= T.driftLife || $0.x < -100 }
        for l in leaves {
            out.append(glyphs.sprite(l.slot, baselineLeft: CGPoint(x: l.x, y: l.y), rotation: l.rotation,
                                     alpha: Self.alpha(age: l.age), colour: T.text))
        }
    }
}

// MARK: M2 Rain

/// A magnitude between its idle and its typing value (`Tuning`'s pairs), at intensity `i`: Rain's.
private func between(_ p: (idle: Double, typing: Double), _ i: Double) -> Double { p.idle + (p.typing - p.idle) * i }
private func between(_ p: (idle: ClosedRange<Double>, typing: ClosedRange<Double>), _ i: Double) -> ClosedRange<Double> {
    between((p.idle.lowerBound, p.typing.lowerBound), i)...between((p.idle.upperBound, p.typing.upperBound), i)
}

/// The films' rain over the dim (pass 19b; G1 I1 T1 C2 K1 W1 of docs/design-panel-lemna-rain.html): glyphs fixed in a
/// grid of square cells over the whole screen, and heads stepping down the columns a cell at a time, each lighting the
/// cell it enters in the text colour; behind it the cell dims in place in the accent, linearly, over the head's trail.
/// A column keeps its speed; its heads (one or two at a time) start at the top after a random pause and end below the
/// bottom; every lit glyph changes now and then. It falls low-key from the show until the close, and typing raises one
/// intensity that sets how many columns fall, how fast, how long and how bright, and how often the glyphs change; each
/// glyph key also starts a head where the key is across the screen, higher the higher its row, the typed glyph at it.
/// Every screen.
struct Rain: Ambience.Scene {
    /// A head: its column, its row (0 at the top; between two cells while it steps), its trail in cells, the typed
    /// glyph's slot at it (nil: the cell's own), and whether a key started it.
    private struct Head { let column: Int; var row: Double; let trail: Double, glyph: Int?, key: Bool }
    private let stage: Ambience.Stage, glyphs: Ambience.Glyphs
    /// The grid: `columns` × `rows` cells of `pitch` points, row 0 at the top edge, the columns centred across.
    let columns: Int, rows: Int, pitch: Double
    private let left: Double
    /// Each cell's glyph, its column's travel when a head lit it (−∞: never), the trail it dims over (in cells), its
    /// trail's top alpha (0: the intensity's), and whether a head is in it (set and cleared as the step draws); a cell
    /// at column × `rows` + row.
    private var glyph: [Int], lit: [Double], trail: [Double], top: [Double], under: [Bool]
    /// Each column's share of `rainSpeed` (its own, kept), the cells its heads have stepped in all and in this step,
    /// how many of its heads are not a key's, and the youngest of those: its start (in travel) and its trail.
    private var share: [Double], travel: [Double], moved: [Double], falling: [Int]
    private var youngest: [(at: Double, trail: Double)]
    private var heads: [Head] = []
    /// 0 at rest, 1 at `rainFast` keys a second; the time since the last key.
    private(set) var intensity = 0.0
    private var sinceKey = Double.infinity
    /// The sprites the last step would have drawn, before the cap.
    private(set) var shown = 0
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.stage, self.glyphs) = (stage, glyphs)
        pitch = Double(glyphs.cell.height) * T.rainScale * T.rainPitch
        let (w, h) = (Double(stage.size.width), Double(stage.size.height))
        (columns, rows) = (max(Int(w / pitch), 1), max(Int((h / pitch).rounded(.up)), 1))
        left = (w - Double(columns) * pitch) / 2
        var r = Ambience.Random(seed: seed)
        let n = columns * rows, set = glyphs.rainSet.isEmpty ? [0] : glyphs.rainSet
        glyph = (0..<n).map { _ in set.randomElement(using: &r)! }
        (lit, trail, top, under) = (Array(repeating: -.infinity, count: n), Array(repeating: 1, count: n),
                                    Array(repeating: 0, count: n), Array(repeating: false, count: n))
        share = (0..<columns).map { _ in r.unit() }
        (travel, moved, falling) = (Array(repeating: 0, count: columns), Array(repeating: 0, count: columns),
                                    Array(repeating: 0, count: columns))
        youngest = Array(repeating: (-.infinity, 0), count: columns)
        random = r
        heads.reserveCapacity(limit)
        // Stepped ahead, undrawn, at rest: the summon finds the rain falling, the slowest column's first head through.
        for _ in 0..<Int(T.rainAhead * T.rainIdleRate) {
            advance(dt: 1 / T.rainIdleRate, events: [], rate: 0, changing: false)
        }
    }

    /// The most heads at once: two a column of its own and as many again from keys.
    private var limit: Int { 4 * columns }

    var count: Int { min(shown, T.cap) }

    /// Fewer frames at rest: a head steps a cell at a time, and the films ran at 24.
    var frameRate: Double { intensity > T.rainCalm || sinceKey < T.rainHold ? T.frameRate : T.rainIdleRate }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        advance(dt: dt, events: events, rate: rate, changing: true)
        let head = between(T.rainHead, intensity), trailTop = between(T.rainTrailTop, intensity)
        shown = 0
        for pass in 0..<2 {  // first, so the cap takes trail cells, not heads; one a cell, a key's before the others
            let key = pass == 0
            for h in heads where h.key == key {
                let r = Int(h.row), x = h.column * rows + r
                guard !under[x] else { continue }
                under[x] = true
                add(h.glyph ?? glyph[x], h.column, r, alpha: key ? T.rainKeyHead : head, colour: T.text, into: &out)
            }
        }
        for c in 0..<columns {
            let now = travel[c]
            for x in c * rows..<(c + 1) * rows {
                if under[x] {
                    under[x] = false
                    continue
                }
                let age = now - lit[x]
                guard age < trail[x] else { continue }
                let a = (top[x] > 0 ? top[x] : trailTop) * (1 - age / trail[x])
                if a > T.rainShown { add(glyph[x], c, x - c * rows, alpha: a, colour: T.accent, into: &out) }
            }
        }
    }

    /// One cell's glyph sprite, unless the cap is reached.
    private mutating func add(_ slot: Int, _ c: Int, _ r: Int, alpha: Double, colour: UInt32, into out: inout [Sprite]) {
        shown += 1
        guard out.count < T.cap else { return }
        let centre = CGPoint(x: left + (Double(c) + 0.5) * pitch, y: Double(stage.size.height) - (Double(r) + 0.5) * pitch)
        out.append(glyphs.sprite(slot, centre: centre, scale: T.rainScale, alpha: alpha, colour: colour))
    }

    /// The scene moved on by `dt`: the keys' heads, the intensity, every head a step down its column lighting the
    /// cells it enters, those below the bottom gone, new heads at the top, and (`changing`) the lit glyphs changed.
    private mutating func advance(dt: Double, events: [Ambience.Event], rate: Double, changing: Bool) {
        for e in events where e.isKey {
            sinceKey = 0
            if case .typed(let slot, let key) = e { startHead(slot: slot, at: key) }
        }
        let target = min(rate / T.rainFast, 1)  // up at once, down only after a pause
        if target > intensity {
            intensity += (target - intensity) * (1 - exp(-dt / T.rainRise))
        } else if sinceKey >= T.rainHold {
            intensity += (target - intensity) * (1 - exp(-dt / T.rainSettle))
        }
        sinceKey += dt
        let i = intensity, speeds = between(T.rainSpeed, i)
        for c in 0..<columns {
            moved[c] = mix(speeds, share[c]) * dt
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
                    light(h.column, r, trail: h.trail, top: h.key ? T.rainKeyTrailTop : 0)
                }
            }
            if to >= rows {  // below the bottom: it ends
                if !h.key { falling[h.column] -= 1 }
                heads.swapAt(k, heads.count - 1)
                heads.removeLast()
                continue
            }
            heads[k] = h
            k += 1
        }
        // A new head at the top after a random pause, at the rate that keeps `rainActive` of the columns showing one
        // (each shows for its crossing: the rows and its trail at the column's speed), and only `rainGap` cells behind
        // the last one's trail.
        let trails = between(T.rainTrail, i), gap = between(T.rainGap, i), active = between(T.rainActive, i)
        let crossing = Double(rows) + (trails.upperBound - trails.lowerBound) / log(trails.upperBound / trails.lowerBound)
        for c in 0..<columns where falling[c] < 2 && travel[c] - youngest[c].at >= youngest[c].trail + gap {
            guard random.unit() < active * mix(speeds, share[c]) / crossing * dt, heads.count < limit else { continue }
            let t = logUniform(trails)
            youngest[c] = (travel[c], t)
            falling[c] += 1
            heads.append(Head(column: c, row: 0, trail: t, glyph: nil, key: false))
            light(c, 0, trail: t, top: 0)
        }
        guard changing else { return }
        let change = between(T.rainChange, i) * dt
        for c in 0..<columns {
            let now = travel[c]
            for x in c * rows..<(c + 1) * rows where now - lit[x] < trail[x] && random.unit() < change {
                glyph[x] = glyphs.rainSet.randomElement(using: &random) ?? glyph[x]
            }
        }
    }

    /// A glyph key's head: in the column where the key is across the screen (anywhere within its width, so a key typed
    /// again does not stack its heads in one column; without a position the caret's x on the box's screen, anywhere on
    /// another), higher the higher its row, the typed glyph at it.
    private mutating func startHead(slot: Int?, at key: Keyboard.Position?) {
        guard heads.count < limit else { return }
        let (w, h) = (Double(stage.size.width), Double(stage.size.height))
        let width = w * (T.screenSpan.upperBound - T.screenSpan.lowerBound) / Keyboard.columns * (key?.width ?? 0)
        let spread = random.pick(-0.4...0.4) * width
        let along = stage.screenX(key).map { $0 + spread } ?? (stage.box != nil ? Double(stage.caret) : random.pick(0...w))
        let height = key.map { mix(T.rainRows, 1 - $0.down) } ?? random.pick(T.rainRows)
        let c = min(max(Int((along - left) / pitch), 0), columns - 1)
        let r = min(max(Int((1 - height + random.pick(-0.03...0.03)) * h / pitch), 0), rows - 1)
        let t = logUniform(T.rainKeyTrail)
        heads.append(Head(column: c, row: Double(r), trail: t, glyph: slot, key: true))
        light(c, r, trail: t, top: T.rainKeyTrailTop)
    }

    /// A head lights cell `r` of column `c`: it dims from now over `t` cells of the column's travel, from `a` (0: the
    /// intensity's trail top).
    private mutating func light(_ c: Int, _ r: Int, trail t: Double, top a: Double) {
        let x = c * rows + r
        (lit[x], trail[x], top[x]) = (travel[c], t, a)
    }

    /// A trail length, log-uniform in `range`: more short than long.
    private mutating func logUniform(_ range: ClosedRange<Double>) -> Double {
        range.lowerBound * pow(range.upperBound / range.lowerBound, random.unit())
    }
}

// MARK: M3 Rings

/// Each key sends one circle out from the box's top edge where the key is along the box, out past the screen's
/// farthest corner on the curve, gone in `ringLife`; ⌫ sends one in from its key, onto the box. Rings add, so fast
/// typing reads as a shimmer. The box's screen only.
struct Rings: Ambience.Scene {
    private struct Ring { var age: Double; let inward: Bool, x, y, reach: Double }
    private var rings: [Ring] = []
    private let stage: Ambience.Stage

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) { self.stage = stage }

    /// A circle draws at most `Tuning.ringArcs` arcs.
    var count: Int { rings.count * T.ringArcs }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        guard let box = stage.box else { return }
        let (w, h) = (Double(stage.size.width), Double(stage.size.height))
        for e in events where e.isKey && count + T.ringArcs <= T.cap {
            let x = stage.boxX(e.key) ?? Double(stage.caret), y = Double(box.maxY)
            let reach = [(0.0, 0.0), (w, 0), (0, h), (w, h)].map { hypot($0.0 - x, $0.1 - y) }.max()!
            var inward = false
            if case .backspace = e { inward = true }
            rings.append(Ring(age: 0, inward: inward, x: x, y: y, reach: reach))
        }
        for i in rings.indices { rings[i].age += dt }
        rings.removeAll { $0.age >= T.ringLife }
        for r in rings {
            let u = r.age / T.ringLife, e = Curve.easeOutQuint(u)
            circle(x: r.x, y: r.y, radius: r.inward ? T.ringInward * (1 - e) : r.reach * e, width: T.ringWidth,
                   alpha: T.ringPeak * (1 - u), colour: T.text, on: stage.size, into: &out)
        }
    }
}

/// A circle of stroke `w` about (x, y) as arcs of about `Tuning.ringArc` points side by side (8 to `ringArcs`), each a
/// `bend` sprite the shader curves; the arcs off `size` are left out. Thin quads, so a circle across the screen costs
/// its stroke's pixels, not the screen's.
func circle(x: Double, y: Double, radius r: Double, width w: Double, alpha: Double, colour: UInt32, on size: CGSize,
            into out: inout [Sprite]) {
    guard r > 0.5 else { return }
    let n = min(max(Int((2 * .pi * r / T.ringArc).rounded(.up)), 8), T.ringArcs), turn = 2 * Double.pi / Double(n)
    let chord = 2 * r * sin(turn / 2), sag = r * (1 - cos(turn / 2)), height = w + 2 * sag + 2
    let parameter = Sprite.bend(radius: r, width: w)
    for k in 0..<n {
        let a = (Double(k) + 0.5) * turn, mx = x + r * cos(a), my = y + r * sin(a)
        guard mx > -chord, my > -chord, mx < Double(size.width) + chord, my < Double(size.height) + chord else { continue }
        out.append(Sprite(x: mx, y: my, w: chord, h: height, rotation: a - .pi / 2, alpha: alpha, colour: colour,
                          kind: .bend, parameter: parameter))
    }
}

// MARK: M5 Grid

/// A grid of square cells shows on the dim of the box's screen while you type (aligned to the box); each key lights
/// its own cells in a keyboard of 5 × 15 cells under the box (over it where there is no room), so typing draws the
/// keyboard's shape: one cell a letter, a bar for the space bar. A key with no position lights a cell near the box,
/// near the caret more often. Anchored pulses, no travel.
struct Grid: Ambience.Scene {
    private var lines: [Sprite] = []
    /// The cells near the box, for a key with no position, and the keyboard's: its left edge and each row's bottom.
    private var cells: [(centre: CGPoint, weight: Double)] = []
    private var keyboard: (left: Double, rows: [Double])?
    /// The keyboard's cells' ages, row by row (negative: not lit), and how many are lit; the near cells lit now (their
    /// index in `cells`, their age).
    private var keys = [Double](repeating: -1, count: Keyboard.rows * Int(Keyboard.columns)), keysLit = 0
    private var lit: [(cell: Int, age: Double)] = []
    /// Since the first key: the lines fade in over `gridIn`; nil before it.
    private var shown: Double?
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        random = Ambience.Random(seed: seed)
        guard let box = stage.box else { return }
        let c = T.gridCell, (w, h) = (Double(stage.size.width), Double(stage.size.height))
        let (x0, y0) = (Double(box.minX), Double(box.minY))
        let first = Int((-x0 / c).rounded(.up)), last = max(Int(((w - x0) / c).rounded(.down)), first)
        for k in first...last {
            lines.append(Sprite(x: x0 + Double(k) * c, y: h / 2, w: 1, h: h, alpha: 1, colour: T.text, kind: .rect))
        }
        let low = Int((-y0 / c).rounded(.up)), high = max(Int(((h - y0) / c).rounded(.down)), low)
        for k in low...high {
            lines.append(Sprite(x: w / 2, y: y0 + Double(k) * c, w: w, h: 1, alpha: 1, colour: T.text, kind: .rect))
        }
        if lines.count > T.cap / 2 { lines.removeLast(lines.count - T.cap / 2) }
        // The keyboard: centred under the box on the grid's cells, a gap of `gridGap` cells below it; over it if the
        // screen has no room below.
        let gap = Double(T.gridGap), n = Double(Keyboard.rows)
        let left = x0 + ((Double(box.width) / 2 - Keyboard.columns / 2 * c) / c).rounded() * c
        let over = y0 + (Double(box.height) / c).rounded(.up) * c, below = y0 - (gap + n) * c >= 0
        var rows: [Double] = []
        for r in 0..<Keyboard.rows {
            let k = Double(r)
            rows.append(below ? y0 - (gap + 1 + k) * c : over + (gap + n - 1 - k) * c)
        }
        keyboard = (left, rows)
        // The cells near the box, for a key with no position: within `gridReach` cells, weighted toward the caret.
        let nx = Int((Double(box.width) / c).rounded(.up)), ny = Int((Double(box.height) / c).rounded(.up)), r = T.gridReach
        let caret = stage.caretPoint
        for i in -r..<(nx + r) {
            for j in -r..<(ny + r) where !(0..<nx).contains(i) || !(0..<ny).contains(j) {
                let p = CGPoint(x: x0 + (Double(i) + 0.5) * c, y: y0 + (Double(j) + 0.5) * c)
                guard p.x > 0, p.y > 0, Double(p.x) < w, Double(p.y) < h else { continue }
                cells.append((p, exp(-Double(hypot(p.x - caret.x, p.y - caret.y)) / T.gridNear)))
            }
        }
    }

    var count: Int { (shown == nil ? 0 : lines.count) + keysLit + lit.count }

    /// The middle of the keyboard's cell at `row`, `column` (row 0 at the top).
    func centre(row: Int, column: Int) -> CGPoint? {
        keyboard.map { CGPoint(x: $0.left + (Double(column) + 0.5) * T.gridCell, y: $0.rows[row] + 0.5 * T.gridCell) }
    }

    /// A key with no position: one near cell not lit now, by its weight.
    private mutating func lightNear() {
        guard count < T.cap else { return }
        let free = cells.indices.filter { i in !lit.contains { $0.cell == i } }
        var pick = random.unit() * free.reduce(0) { $0 + cells[$1].weight }
        for i in free {
            pick -= cells[i].weight
            if pick <= 0 || i == free.last { return lit.append((i, 0)) }
        }
    }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        guard keyboard != nil else { return }
        for e in events where e.isKey {
            if shown == nil { shown = 0 }
            guard let key = e.key else {
                lightNear()
                continue
            }
            for r in key.rows {
                for c in key.columns {  // lit, or lit afresh
                    let i = r * Int(Keyboard.columns) + c
                    if keys[i] < 0 { keysLit += 1 }
                    keys[i] = 0
                }
            }
        }
        guard let since = shown.map({ $0 + dt }) else { return }
        shown = since
        for i in lit.indices { lit[i].age += dt }
        lit.removeAll { $0.age >= T.gridLife }
        if keysLit > 0 {
            for i in keys.indices where keys[i] >= 0 {
                keys[i] += dt
                if keys[i] >= T.gridLife { (keys[i], keysLit) = (-1, keysLit - 1) }
            }
        }
        let a = Float(T.gridLines * min(since / T.gridIn, 1))
        for var l in lines {
            l.alpha = a
            out.append(l)
        }
        let side = T.gridCell - 1  // inside the lines
        func cell(_ p: CGPoint, _ age: Double) -> Sprite {
            Sprite(x: Double(p.x), y: Double(p.y), w: side, h: side,
                   alpha: T.gridLit * min(age / 0.05, 1) * (1 - age / T.gridLife), colour: T.accent, kind: .rect)
        }
        if keysLit > 0 {
            for i in keys.indices where keys[i] >= 0 {
                let n = Int(Keyboard.columns)
                if let p = centre(row: i / n, column: i % n) { out.append(cell(p, keys[i])) }
            }
        }
        for (i, age) in lit { out.append(cell(cells[i].centre, age)) }
    }
}
