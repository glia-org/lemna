// The seven scenes of the ambience (DESIGN.md A1; M1–M7 of docs/design-panel-lemna-ambience.html), each a particle
// system on the CPU, stepped once a frame by `Ambience.Run` on the scene's thread, fed by the keys as the panel
// couples them. Each borrows one tte effect's motion, not its text (the dim has no characters to reveal). Every
// magnitude is `Ambience.Tuning`'s; a scene spawns nothing that would take it past `Tuning.cap` sprites.
import CoreGraphics
import Foundation

private typealias T = Ambience.Tuning

/// A share of a range: `lo` at 0, `hi` at 1.
private func mix(_ r: ClosedRange<Double>, _ u: Double) -> Double { r.lowerBound + (r.upperBound - r.lowerBound) * u }

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
            let a = T.driftPeak * min(l.age / T.driftIn, 1) * min((T.driftLife - l.age) / (T.driftLife - T.driftIn), 1)
            out.append(glyphs.sprite(l.slot, baselineLeft: CGPoint(x: l.x, y: l.y), rotation: l.rotation, alpha: a,
                                     colour: T.text))
        }
    }
}

// MARK: M2 Rain

/// Faint columns of glyphs fall over the dim, matrix-like: each glyph key drops one at a random column, the typed glyph
/// at its head in the accent and a trail of 4–8 glyphs above it, each fainter, growing as it falls row by row, a
/// trail glyph swapping now and then. Typing sets the density; 3 s after the last key the dim is clear. Every screen.
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
        for case .typed(let slot) in events {
            let n = Int.random(in: T.rainTrail, using: &random)
            guard cells + 1 + n <= T.cap else { continue }
            let x = (Double(Int.random(in: 0..<max(Int(w / column), 1), using: &random)) + 0.5) * column
            let top = random.pick((0.35 * h)...(h + 2 * row)), fall = random.pick(T.rainFall), head = slot ?? letter()
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
            var a = T.rainHead * fade
            for k in 0..<min(d.trail.count, rows) {
                a *= T.rainTrailFall
                out.append(glyphs.sprite(d.trail[k], centre: CGPoint(x: d.x, y: y + Double(k + 1) * row),
                                         scale: T.rainScale, alpha: a, colour: T.text))
            }
        }
    }
}

// MARK: M3 Rings

/// Each key sends one faint ring out from the box's edge across the dim, rounding out as it grows (its corners grow
/// with it, its sides keep their length), gone in `ringLife`; ⌫ sends one in, onto the box. Rings add, so fast typing
/// reads as a shimmer. The box's screen only.
struct Rings: Ambience.Scene {
    private struct Ring { var age: Double; let inward: Bool }
    private var rings: [Ring] = []
    private let stage: Ambience.Stage

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) { self.stage = stage }

    var count: Int { rings.count * 8 }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        guard let box = stage.box else { return }
        for e in events where e.isKey && count + 8 <= T.cap { rings.append(Ring(age: 0, inward: e == .backspace)) }
        for i in rings.indices { rings[i].age += dt }
        rings.removeAll { $0.age >= T.ringLife }
        for r in rings {
            let u = r.age / T.ringLife, e = Curve.easeOutQuint(u)
            outline(box, corner: stage.corner, grown: r.inward ? T.ringInward * (1 - e) : T.ringReach * e,
                    width: T.ringWidth, alpha: T.ringPeak * (1 - u), colour: T.text, into: &out)
        }
    }
}

/// The box's outline grown by `r` on every side: its sides as thin rectangles and its corners as quarter rings of
/// radius `corner + r`, so that it rounds out as it grows. Eight sprites.
func outline(_ box: CGRect, corner: CGFloat, grown r: Double, width w: Double, alpha: Double, colour: UInt32,
             into out: inout [Sprite]) {
    let g = box.insetBy(dx: -r, dy: -r), rc = Double(corner) + r
    let (minX, maxX, minY, maxY) = (Double(g.minX), Double(g.maxX), Double(g.minY), Double(g.maxY))
    let across = Double(g.width) - 2 * rc, up = Double(g.height) - 2 * rc
    for y in [minY, maxY] {
        out.append(Sprite(x: Double(g.midX), y: y, w: across, h: w, alpha: alpha, colour: colour, kind: .rect))
    }
    for x in [minX, maxX] {
        out.append(Sprite(x: x, y: Double(g.midY), w: w, h: up, alpha: alpha, colour: colour, kind: .rect))
    }
    let s = rc + w, half = s / 2  // the quad from the circle's centre out past the stroke
    for (cx, cy, turn) in [(maxX - rc, maxY - rc, 0.0), (minX + rc, maxY - rc, Double.pi / 2), (minX + rc, minY + rc, .pi),
                           (maxX - rc, minY + rc, 3 * Double.pi / 2)] {
        out.append(Sprite(x: cx + half * (cos(turn) - sin(turn)), y: cy + half * (sin(turn) + cos(turn)), w: s, h: s,
                          rotation: turn, alpha: alpha, colour: colour, kind: .arc, parameter: Sprite.stroke(w)))
    }
}

// MARK: M4 Beams

/// Horizontal beams of added light sweep the dim, in the accent with a white head: on Space a short one beside the
/// box, on Return one across the screen (every screen). A beam grows out of where it starts and fades at its ends.
struct Beams: Ambience.Scene {
    private struct Beam { let y, from, travel, length, life, height: Double; var age: Double }
    private var beams: [Beam] = []
    private let stage: Ambience.Stage
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.stage, random) = (stage, Ambience.Random(seed: seed))
    }

    var count: Int { beams.count }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        let (w, h) = (Double(stage.size.width), Double(stage.size.height))
        for e in events where beams.count < T.cap {
            switch e {
            case .space:
                guard let box = stage.box else { continue }
                let gap = random.pick(10...70), above = random.unit() < 0.5, along = random.pick(0.3...0.7)
                let b = T.wordBeam
                beams.append(Beam(y: above ? Double(box.maxY) + gap : Double(box.minY) - gap,
                                  from: Double(box.minX) + along * Double(box.width),
                                  travel: b.travel, length: b.length, life: b.life, height: b.height, age: 0))
            case .paragraph:
                let length = min(T.lineBeam.share * w, T.lineLongest), y = random.pick(0.12...0.88) * h
                beams.append(Beam(y: y, from: 0, travel: w + length, length: length, life: T.lineBeam.life,
                                  height: T.lineBeam.height, age: 0))
            default: break
            }
        }
        for i in beams.indices { beams[i].age += dt }
        beams.removeAll { $0.age >= $0.life }
        for b in beams {
            let u = b.age / b.life, head = b.from + b.travel * u, tail = min(b.length, b.travel * u)
            let fade = min(u / 0.1, 1) * min((1 - u) / 0.25, 1)
            guard tail > 1 else { continue }
            out.append(Sprite(x: head - tail / 2, y: b.y, w: tail, h: b.height, alpha: T.beamPeak * fade, colour: T.accent,
                              kind: .beam, parameter: UInt32((T.beamHead * fade * 255).rounded())))
        }
    }
}

// MARK: M5 Grid

/// A faint grid of square cells shows on the dim of the box's screen while you type (aligned to the box); each key
/// lights one cell within `gridReach` cells of the box, near the caret more often, nearest first, which fades within
/// `gridLife`. Anchored pulses, no travel.
struct Grid: Ambience.Scene {
    private var lines: [Sprite] = []
    private var cells: [(centre: CGPoint, weight: Double)] = []
    private var lit: [(cell: Int, age: Double)] = [], isLit: [Bool] = []
    /// Since the first key: the lines fade in over `gridIn`; nil before it.
    private var shown: Double?
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        random = Ambience.Random(seed: seed)
        guard let box = stage.box else { return }
        let c = T.gridCell, (w, h) = (Double(stage.size.width), Double(stage.size.height))
        let (x0, y0) = (Double(box.minX), Double(box.minY))
        for k in Int((-x0 / c).rounded(.up))...max(Int(((w - x0) / c).rounded(.down)), Int((-x0 / c).rounded(.up))) {
            lines.append(Sprite(x: x0 + Double(k) * c, y: h / 2, w: 1, h: h, alpha: 1, colour: T.text, kind: .rect))
        }
        for k in Int((-y0 / c).rounded(.up))...max(Int(((h - y0) / c).rounded(.down)), Int((-y0 / c).rounded(.up))) {
            lines.append(Sprite(x: w / 2, y: y0 + Double(k) * c, w: w, h: 1, alpha: 1, colour: T.text, kind: .rect))
        }
        if lines.count > T.cap / 2 { lines.removeLast(lines.count - T.cap / 2) }
        let nx = Int((Double(box.width) / c).rounded(.up)), ny = Int((Double(box.height) / c).rounded(.up)), r = T.gridReach
        let caret = stage.caretPoint
        for i in -r..<(nx + r) {
            for j in -r..<(ny + r) where !(0..<nx).contains(i) || !(0..<ny).contains(j) {
                let p = CGPoint(x: x0 + (Double(i) + 0.5) * c, y: y0 + (Double(j) + 0.5) * c)
                guard p.x > 0, p.y > 0, Double(p.x) < w, Double(p.y) < h else { continue }
                cells.append((p, exp(-Double(hypot(p.x - caret.x, p.y - caret.y)) / T.gridNear)))
            }
        }
        isLit = Array(repeating: false, count: cells.count)
    }

    var count: Int { (shown == nil ? 0 : lines.count) + lit.count }

    /// One cell not lit now, by its weight: near the caret more often.
    private mutating func light() {
        guard count < T.cap, lit.count < cells.count else { return }
        var total = 0.0
        for i in cells.indices where !isLit[i] { total += cells[i].weight }
        var pick = random.unit() * total, chosen = -1
        for i in cells.indices where !isLit[i] {
            chosen = i
            pick -= cells[i].weight
            if pick <= 0 { break }
        }
        guard chosen >= 0 else { return }
        isLit[chosen] = true
        lit.append((chosen, 0))
    }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        guard !cells.isEmpty else { return }
        for e in events where e.isKey {
            if shown == nil { shown = 0 }
            light()
        }
        guard let since = shown.map({ $0 + dt }) else { return }
        shown = since
        for i in lit.indices {
            lit[i].age += dt
            if lit[i].age >= T.gridLife { isLit[lit[i].cell] = false }
        }
        lit.removeAll { $0.age >= T.gridLife }
        let a = Float(T.gridLines * min(since / T.gridIn, 1))
        for var l in lines {
            l.alpha = a
            out.append(l)
        }
        let side = T.gridCell - 1  // inside the lines
        for (cell, age) in lit {
            let p = cells[cell].centre
            out.append(Sprite(x: Double(p.x), y: Double(p.y), w: side, h: side,
                              alpha: T.gridLit * min(age / 0.05, 1) * (1 - age / T.gridLife), colour: T.accent, kind: .rect))
        }
    }
}

// MARK: M6 Fireworks

/// On Return a spark rises from the box's top edge at the caret and bursts above it: the last glyphs you typed and
/// dots, in the text colour and the accent by turns, flung out, slowed, falling, each with a short trail. The box's
/// screen only.
struct Fireworks: Ambience.Scene {
    private struct Rocket { let x, y: Double; var age: Double }
    private struct Spark { var x, y, vx, vy, age: Double; let slot: Int?, colour: UInt32 }
    private var rockets: [Rocket] = [], sparks: [Spark] = []
    /// The last glyphs typed, for the burst.
    private var recent: [Int] = []
    private let stage: Ambience.Stage, glyphs: Ambience.Glyphs
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.stage, self.glyphs, random) = (stage, glyphs, Ambience.Random(seed: seed))
    }

    /// A rocket counts with the burst it will be.
    var count: Int { rockets.count * (2 + 3 * T.fireSparks) + sparks.count * 3 }

    private mutating func burst(at x: Double, _ y: Double) {
        let n = T.fireSparks
        for i in 0..<n {
            let angle = Double(i) * 2 * .pi / Double(n) + random.pick(-0.1...0.1), speed = random.pick(T.fireSpeed)
            let slot = i % 2 == 1 && !recent.isEmpty ? recent[(i / 2) % recent.count] : nil
            sparks.append(Spark(x: x, y: y, vx: speed * cos(angle), vy: speed * sin(angle), age: 0, slot: slot,
                                colour: (i / 2) % 2 == 0 ? T.text : T.accent))
        }
    }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        guard let box = stage.box else { return }
        for e in events {
            switch e {
            case .typed(let slot?):
                recent.append(slot)
                if recent.count > 16 { recent.removeFirst() }
            case .paragraph where count + 2 + 3 * T.fireSparks <= T.cap:  // room for its burst
                rockets.append(Rocket(x: Double(stage.caret), y: Double(box.maxY), age: 0))
            default: break
            }
        }
        for i in rockets.indices { rockets[i].age += dt }
        for r in rockets where r.age >= T.fireLaunch { burst(at: r.x, r.y + T.fireRise) }
        rockets.removeAll { $0.age >= T.fireLaunch }
        let drag = exp(-T.fireDrag * dt)
        for i in sparks.indices {
            var s = sparks[i]
            s.age += dt
            (s.vx, s.vy) = (s.vx * drag, s.vy * drag - T.fireGravity * dt)
            (s.x, s.y) = (s.x + s.vx * dt, s.y + s.vy * dt)
            sparks[i] = s
        }
        sparks.removeAll { $0.age >= T.fireLife }
        for r in rockets {
            let u = r.age / T.fireLaunch, y = r.y + T.fireRise * (1 - pow(1 - u, 3))
            out.append(Sprite(x: r.x, y: (r.y + y) / 2, w: 1, h: y - r.y, alpha: 0.18, colour: T.text, kind: .rect))
            out.append(Sprite(x: r.x, y: y, w: 4, h: 4, alpha: T.firePeak, colour: T.accent, kind: .dot))
        }
        for s in sparks {
            let a = T.firePeak * (1 - s.age / T.fireLife)
            for (back, share) in [(0.07, 0.29), (0.035, 0.62)] {
                out.append(Sprite(x: s.x - s.vx * back, y: s.y - s.vy * back, w: 2.4, h: 2.4, alpha: a * share,
                                  colour: s.colour, kind: .dot))
            }
            if let slot = s.slot {
                out.append(glyphs.sprite(slot, centre: CGPoint(x: s.x, y: s.y), scale: T.fireScale, alpha: a,
                                         colour: s.colour))
            } else {
                out.append(Sprite(x: s.x, y: s.y, w: 3, h: 3, alpha: a, colour: s.colour, kind: .dot))
            }
        }
    }
}

// MARK: M7 Swarm

/// Bubbles rise from the box's top edge near the caret with the rhythm (one a glyph or Space, five a Return), faster
/// as you type faster, then join a swarm that circles above the caret at the key rate; each pops at the end of its
/// life into four ticks. The box's screen only.
struct Swarm: Ambience.Scene {
    private struct Bubble { var x, y, vx, vy, age: Double; let life, radius, phase, dx, dy: Double }
    private var bubbles: [Bubble] = []
    /// The swarm's angle about its circle above the caret.
    private var turn = 0.0
    private let stage: Ambience.Stage
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.stage, random) = (stage, Ambience.Random(seed: seed))
    }

    /// A popping bubble draws four ticks.
    var count: Int { bubbles.count * 4 }

    private mutating func rise(from box: CGRect) {
        let spread = (random.unit() + random.unit() + random.unit() - 1.5) * 0.3 * Double(box.width)  // about the caret
        let x = min(max(Double(stage.caret) + spread, Double(box.minX) + 10), Double(box.maxX) - 10)
        let r = random.pick(T.swarmRadius), angle = random.pick(0...(2 * .pi)), off = 60 * random.unit().squareRoot()
        let life = random.pick(T.swarmLife), phase = random.pick(0...(2 * .pi))
        bubbles.append(Bubble(x: x, y: Double(box.maxY) + r, vx: 0, vy: 0, age: 0, life: life, radius: r, phase: phase,
                              dx: off * cos(angle), dy: off * sin(angle)))
    }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        guard let box = stage.box else { return }
        for e in events {
            let n: Int
            switch e {
            case .typed, .space: n = 1
            case .paragraph: n = 5
            default: n = 0
            }
            for _ in 0..<n where count + 4 <= T.cap { rise(from: box) }
        }
        turn += (0.5 + T.swarmTurnRate * rate) * dt
        let cx = Double(stage.caret) + 0.25 * Double(box.width) * cos(turn)
        let cy = Double(box.maxY) + T.swarmHeight + 40 * sin(turn), up = T.swarmRise + T.swarmRiseRate * rate
        for i in bubbles.indices {
            var b = bubbles[i]
            b.age += dt
            if b.age < 0.6 {  // rising off the box
                (b.vx, b.vy) = (0, up)
            } else {  // a spring toward its place in the swarm, damped: it swirls in and circles with it
                b.vx += (3 * (cx + b.dx - b.x) - 1.8 * b.vx) * dt
                b.vy += (3 * (cy + b.dy - b.y) - 1.8 * b.vy) * dt
            }
            b.x += (b.vx + 10 * sin(b.phase + 4 * b.age)) * dt
            b.y += b.vy * dt
            bubbles[i] = b
        }
        bubbles.removeAll { $0.age >= $0.life + T.swarmPop }
        for b in bubbles {
            if b.age < b.life {
                let u = b.age / b.life, r = b.radius * (1 + 0.3 * u)
                let a = T.swarmPeak * min(b.age / 0.15, 1) * (1 - 0.5 * u)
                out.append(Sprite(x: b.x, y: b.y, w: 2 * r, h: 2 * r, alpha: a, colour: T.text, kind: .ring,
                                  parameter: Sprite.stroke(1.2)))
            } else {  // the pop: four ticks flying out
                let p = (b.age - b.life) / T.swarmPop, d = b.radius * 1.3 * (1.2 + 0.8 * p)
                for k in 0..<4 {
                    let a = Double(k) * .pi / 2
                    out.append(Sprite(x: b.x + d * cos(a), y: b.y + d * sin(a), w: 4, h: 1.2, rotation: a,
                                      alpha: T.swarmPeak * 0.8 * (1 - p), colour: T.text, kind: .rect))
                }
            }
        }
    }
}
