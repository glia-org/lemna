// The two scenes of the ambience (DESIGN.md A1): Code (M2 of docs/design-panel-lemna-ambience.html, Rain until pass
// 25) and Still water (pass 24, AM1 of docs/design-panel-lemna-themes.html), each a particle system on the CPU, stepped
// once a frame by `Ambience.Run` on the scene's thread. Pass 18 removed M4 Beams, M6 Fireworks and M7 Swarm, pass 24
// (RM1) M1 Drift, M3 Rings and M5 Grid. Code, since pass 19b (G1 I1 T1 C2 K1 W1 of docs/design-panel-lemna-rain.html),
// is the films' code rain as research_notes/Lemna rain/matrix.md §6 sets it: a fixed grid of glyphs lit by heads that
// step down it, its cells in flat arrays, falling from the show to the close, each column at its own speed, made more
// intense by typing and fed by where each key is on the keyboard (`Keyboard`, pass 16). Still water is
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
/// 25): glyphs fixed in a grid of square cells over the whole screen, and heads stepping down the columns a cell at a
/// time, each lighting the cell it enters in the text colour; behind it the cell dims in place in the accent, linearly,
/// over the head's trail. A column keeps the speed it drew at the birth, whatever the intensity (pass 25); its heads
/// (one or two at a time) start at the top after a random pause and end below the bottom; every lit glyph changes now
/// and then. It falls low-key from the show until the close, and typing raises one intensity that sets how many columns
/// fall, how long and how bright, and how often the glyphs change, never how fast (the films' "more intense", matrix §2
/// and §3); each glyph key also starts a head where the key is across the screen, higher the higher its row, the typed
/// glyph at it. Every screen.
struct Code: Ambience.Scene {
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
    /// Each column's speed in rows a second (drawn once from `codeSpeed`, kept whatever the intensity).
    private(set) var speed: [Double]
    /// Each column's cells its heads have stepped in all and in this step, how many of its heads are not a key's, and
    /// the youngest of those: its start (in travel) and its trail.
    private var travel: [Double], moved: [Double], falling: [Int]
    private var youngest: [(at: Double, trail: Double)]
    private var heads: [Head] = []
    /// 0 at rest, 1 at `codeFast` keys a second; the time since the last key.
    private(set) var intensity = 0.0
    private var sinceKey = Double.infinity
    /// The sprites the last step would have drawn, before the cap.
    private(set) var shown = 0
    private var random: Ambience.Random

    init(stage: Ambience.Stage, glyphs: Ambience.Glyphs, seed: UInt64) {
        (self.stage, self.glyphs) = (stage, glyphs)
        pitch = Double(glyphs.cell.height) * T.codeScale * T.codePitch
        let (w, h) = (Double(stage.size.width), Double(stage.size.height))
        (columns, rows) = (max(Int(w / pitch), 1), max(Int((h / pitch).rounded(.up)), 1))
        left = (w - Double(columns) * pitch) / 2
        var r = Ambience.Random(seed: seed)
        let n = columns * rows, set = glyphs.codeSet.isEmpty ? [0] : glyphs.codeSet
        glyph = (0..<n).map { _ in set.randomElement(using: &r)! }
        (lit, trail, top, under) = (Array(repeating: -.infinity, count: n), Array(repeating: 1, count: n),
                                    Array(repeating: 0, count: n), Array(repeating: false, count: n))
        speed = (0..<columns).map { _ in mix(T.codeSpeed, r.unit()) }
        (travel, moved, falling) = (Array(repeating: 0, count: columns), Array(repeating: 0, count: columns),
                                    Array(repeating: 0, count: columns))
        youngest = Array(repeating: (-.infinity, 0), count: columns)
        random = r
        heads.reserveCapacity(limit)
        // Stepped ahead, undrawn, at rest: the summon finds the rain falling, the slowest column's first head through.
        for _ in 0..<Int(T.codeAhead * T.codeIdleRate) {
            advance(dt: 1 / T.codeIdleRate, events: [], rate: 0, changing: false)
        }
    }

    /// The most heads at once: two a column of its own and as many again from keys.
    private var limit: Int { 4 * columns }

    var count: Int { min(shown, T.cap) }

    /// Fewer frames at rest: a head steps a cell at a time, and the films ran at 24.
    var frameRate: Double { intensity > T.codeCalm || sinceKey < T.codeHold ? T.frameRate : T.codeIdleRate }

    mutating func step(dt: Double, events: [Ambience.Event], rate: Double, into out: inout [Sprite]) {
        advance(dt: dt, events: events, rate: rate, changing: true)
        let head = between(T.codeHead, intensity), trailTop = between(T.codeTrailTop, intensity)
        shown = 0
        for pass in 0..<2 {  // first, so the cap takes trail cells, not heads; one a cell, a key's before the others
            let key = pass == 0
            for h in heads where h.key == key {
                let r = Int(h.row), x = h.column * rows + r
                guard !under[x] else { continue }
                under[x] = true
                add(h.glyph ?? glyph[x], h.column, r, alpha: key ? T.codeKeyHead : head, colour: stage.ink.text,
                    into: &out)
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
                if a > T.codeShown { add(glyph[x], c, x - c * rows, alpha: a, colour: stage.ink.accent, into: &out) }
            }
        }
    }

    /// One cell's glyph sprite, unless the cap is reached.
    private mutating func add(_ slot: Int, _ c: Int, _ r: Int, alpha: Double, colour: UInt32, into out: inout [Sprite]) {
        shown += 1
        guard out.count < T.cap else { return }
        let centre = CGPoint(x: left + (Double(c) + 0.5) * pitch, y: Double(stage.size.height) - (Double(r) + 0.5) * pitch)
        out.append(glyphs.sprite(slot, centre: centre, scale: T.codeScale, alpha: alpha, colour: colour))
    }

    /// The scene moved on by `dt`: the keys' heads, the intensity, every head a step down its column at the column's
    /// speed lighting the cells it enters, those below the bottom gone, new heads at the top, and (`changing`) the lit
    /// glyphs changed.
    private mutating func advance(dt: Double, events: [Ambience.Event], rate: Double, changing: Bool) {
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
        let i = intensity
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
                    light(h.column, r, trail: h.trail, top: h.key ? T.codeKeyTrailTop : 0)
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
        // A new head at the top after a random pause, at the rate that keeps `codeActive` of the columns showing one
        // (each shows for its crossing: the rows and its trail at the column's speed), and only `codeGap` cells behind
        // the last one's trail.
        let trails = between(T.codeTrail, i), gap = between(T.codeGap, i), active = between(T.codeActive, i)
        let crossing = Double(rows) + (trails.upperBound - trails.lowerBound) / log(trails.upperBound / trails.lowerBound)
        for c in 0..<columns where falling[c] < 2 && travel[c] - youngest[c].at >= youngest[c].trail + gap {
            guard random.unit() < active * speed[c] / crossing * dt, heads.count < limit else { continue }
            let t = logUniform(trails)
            youngest[c] = (travel[c], t)
            falling[c] += 1
            heads.append(Head(column: c, row: 0, trail: t, glyph: nil, key: false))
            light(c, 0, trail: t, top: 0)
        }
        guard changing else { return }
        let change = between(T.codeChange, i) * dt
        for c in 0..<columns {
            let now = travel[c]
            for x in c * rows..<(c + 1) * rows where now - lit[x] < trail[x] && random.unit() < change {
                glyph[x] = glyphs.codeSet.randomElement(using: &random) ?? glyph[x]
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
        let height = key.map { mix(T.codeRows, 1 - $0.down) } ?? random.pick(T.codeRows)
        let c = min(max(Int((along - left) / pitch), 0), columns - 1)
        let r = min(max(Int((1 - height + random.pick(-0.03...0.03)) * h / pitch), 0), rows - 1)
        let t = logUniform(T.codeKeyTrail)
        heads.append(Head(column: c, row: Double(r), trail: t, glyph: slot, key: true))
        light(c, r, trail: t, top: T.codeKeyTrailTop)
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
