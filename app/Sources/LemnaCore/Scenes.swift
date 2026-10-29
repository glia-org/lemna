// The four scenes of the ambience (DESIGN.md A1; M1, M2, M3 and M5 of docs/design-panel-lemna-ambience.html; pass 18
// removed M4 Beams, M6 Fireworks and M7 Swarm), each a particle system on the CPU, stepped once a frame by
// `Ambience.Run` on the scene's thread, fed by the keys as the panel couples them and, since pass 16, by where each key
// is on the keyboard (`Keyboard`; Drift follows the text instead).
// Each borrows one tte effect's motion, not its text (the dim has no characters to reveal). Every magnitude is
// `Ambience.Tuning`'s; a scene spawns nothing that would take it past `Tuning.cap` sprites.
import CoreGraphics
import Foundation

private typealias T = Ambience.Tuning

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

/// Columns of glyphs fall over the dim, matrix-like: each glyph key drops one where the key is across the screen
/// (column 0 of the keyboard at a tenth of the width, column 14 at nine tenths), starting higher the higher its row,
/// the typed glyph at its head in the accent and a trail of 4–8 glyphs above it, each fainter, growing as it falls row
/// by row, a trail glyph swapping now and then. Typing sets the density; 3 s after the last key the dim is clear.
/// Every screen.
struct Rain: Ambience.Scene {
    private struct Drop { let x, top, fall: Double; var age: Double; let head: Int; var trail: [Int] }
    private var drops: [Drop] = []
    /// Every drop's head and trail: what the drops may draw.
    private var cells = 0
    private let stage: Ambience.Stage, glyphs: Ambience.Glyphs, row: Double, column: Double
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.stage, self.glyphs, random) = (stage, glyphs, Ambience.Random(seed: seed))
        row = Double(glyphs.cell.height) * T.rainScale
        column = Double(glyphs.cell.width) * T.rainScale
    }

    var count: Int { cells }

    private mutating func letter() -> Int { glyphs.letters.randomElement(using: &random) ?? 0 }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        let (w, h, row, column) = (Double(stage.size.width), Double(stage.size.height), row, column)
        for case .typed(let slot, let key) in events {
            let n = Int.random(in: T.rainTrail, using: &random)
            guard cells + 1 + n <= T.cap else { continue }
            // Where the key is across the screen, anywhere within its width (a key typed again does not stack its
            // drops in one column); without a position the caret's x on the box's screen, anywhere else.
            let width = w * (T.screenSpan.upperBound - T.screenSpan.lowerBound) / Keyboard.columns * (key?.width ?? 0)
            let spread = random.pick(-0.4...0.4) * width
            let along = stage.screenX(key).map { $0 + spread } ?? (stage.box != nil ? Double(stage.caret) : random.pick(0...w))
            let x = ((along / column).rounded(.down) + 0.5) * column  // on the rain's grid of columns
            let height = key.map { mix(T.rainRows, 1 - $0.down) } ?? random.pick(T.rainRows)
            let top = h * (height + random.pick(-0.03...0.03)), fall = random.pick(T.rainFall), head = slot ?? letter()
            var trail: [Int] = []
            for _ in 0..<n { trail.append(letter()) }
            drops.append(Drop(x: x, top: top, fall: fall, age: 0, head: head, trail: trail))
            cells += 1 + n
        }
        for i in drops.indices {
            drops[i].age += dt
            for k in drops[i].trail.indices where random.unit() < T.rainSwap * dt {
                let swapped = letter()
                drops[i].trail[k] = swapped
            }
        }
        drops.removeAll { $0.age >= T.rainLife || $0.top - $0.fall * $0.age + Double($0.trail.count) * row < -row }
        cells = drops.reduce(0) { $0 + 1 + $1.trail.count }
        for d in drops {
            let rows = Int(d.fall * d.age / row), y = d.top - Double(rows) * row
            let fade = min(d.age / 0.08, 1) * min((T.rainLife - d.age) / T.rainOut, 1)
            out.append(glyphs.sprite(d.head, centre: CGPoint(x: d.x, y: y), scale: T.rainScale, alpha: T.rainHead * fade,
                                     colour: T.accent))
            var a = T.rainTrailStart * fade
            for k in 0..<min(d.trail.count, rows) {
                out.append(glyphs.sprite(d.trail[k], centre: CGPoint(x: d.x, y: y + Double(k + 1) * row),
                                         scale: T.rainScale, alpha: a, colour: T.text))
                a *= T.rainTrailFall
            }
        }
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
