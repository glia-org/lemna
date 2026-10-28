// The ambience's display link (DESIGN.md A1, R1; pass 15b). Pass 15 ended a scene by shrinking the dim's layer and
// clearing it with a drawable of its own, `-[CAMetalLayer nextDrawable]`, which Core Animation refuses on a layer a
// CAMetalDisplayLink drives ("-nextDrawable should not be called when using CAMetalDisplayLink."): the exception
// crossed the link's callback and Lemna died at Esc, and 4 s after the last key, whenever a scene played. Here: that
// refusal on a real layer and link, and the lifecycle that replaces it, driven through Esc, the close's fade, the
// dim's, a hand-off, a close at once, a new show, the end 4 s after the last key and Off. No Foundation here.
import CoreGraphics
import LemnaCatch
import Metal
import QuartzCore
import Testing
@testable import LemnaCore

private typealias Life = Ambience.Lifecycle
private let screen = CGSize(width: 1512, height: 982)
private let box = BoxFrame.line(in: CGRect(x: 0, y: 80, width: 1512, height: 868), height: 112)
private let stage = Ambience.Stage(size: screen, box: box, style: Style(font: menlo))
private let glyphs = Ambience.Glyphs(font: menlo)
private let pixels = CGSize(width: 3024, height: 1964)

private func plan(_ mode: Ambience.Mode?, turn: Int) -> Ambience.Plan {
    Ambience.Plan(mode: mode, stage: stage, pixels: pixels, scale: 2, turn: turn)
}

/// One screen driven as the scene thread drives it: the app's start at the first key while the link is paused, a frame
/// every 60th of a second while the window is on screen (until `frames`), with the keys that came since the last frame
/// and the close from its time on, and the dim's end (`stop`). The steps with their times.
private func drive(_ life: inout Life, _ p: Ambience.Plan, from t0: Double, to t1: Double, keys: [Double],
                   close: (at: Double, over: Double)? = nil, stop: Double? = nil,
                   frames: Double = .infinity) -> [(t: Double, step: Life.Step)] {
    var steps: [(t: Double, step: Life.Step)] = [], out: [Sprite] = [], pending = keys.sorted(), stopped = false
    var t = t0
    while t < t1 {
        t += 1.0 / 60
        if let s = stop, t >= s, !stopped {
            life.stop()
            stopped = true
        }
        var due = Array(pending.prefix { $0 <= t })
        pending.removeFirst(due.count)
        if p.mode == nil || (stop.map { t >= $0 } ?? false) { due = [] }  // Off, or the box gone: no key reaches it
        if life.phase == .idle, !due.isEmpty { _ = life.start(p) }  // the key wakes the scene thread
        guard t < frames, life.phase != .idle else { continue }  // no frames off screen or paused
        let k = due.map { Ambience.Key(t: $0, kind: .glyph("m")) }
        let closing = close.flatMap { t >= $0.at ? $0 : nil }
        steps.append((t, life.frame(at: t, plan: p, keys: k, closing: closing, glyphs: glyphs, into: &out)))
    }
    return steps
}

/// What every sequence must hold: each frame draws into the link's drawable it was given (that is all a step can
/// do); the drawable parks and the link pauses only on a cleared frame; nothing is drawn before the turn's first
/// cleared frame and its show.
private func lawful(_ steps: [(t: Double, step: Life.Step)]) -> Bool {
    var shown = Set<Int>(), cleared = false
    for (_, s) in steps {
        if (s.pause || s.resize == Life.parked) && s.alpha != nil { return false }
        if let turn = s.show {
            guard cleared else { return false }
            shown.insert(turn)
        }
        if s.alpha == nil { cleared = true }
        if s.alpha != nil && shown.isEmpty { return false }
    }
    return true
}

@Test(.enabled(if: Ambience.Renderer.available)) func aLayerDrivenByADisplayLinkRefusesNextDrawable() {
    let layer = CAMetalLayer()
    layer.device = MTLCreateSystemDefaultDevice()
    layer.pixelFormat = .bgra8Unorm
    layer.drawableSize = CGSize(width: 64, height: 64)
    let link = CAMetalDisplayLink(metalLayer: layer)
    link.isPaused = true
    var message = [CChar](repeating: 0, count: 256)
    // Pass 15's end of a scene: the drawable shrunk, then a cleared frame from the layer itself. This aborted Lemna.
    let threw = LemnaCatch({
        layer.drawableSize = CGSize(width: 1, height: 1)
        _ = layer.nextDrawable()
    }, &message, 256)
    #expect(threw == 1)
    #expect(String(cString: message)
        == "CAMetalLayerInvalidOperation: -nextDrawable should not be called when using CAMetalDisplayLink.")
    // What the lifecycle does to the layer instead (a size between frames, a pause) is allowed.
    #expect(LemnaCatch({
        layer.drawableSize = Life.parked
        layer.drawableSize = CGSize(width: 64, height: 64)
        link.isPaused = false
        link.isPaused = true
    }, nil, 0) == 0)
    link.invalidate()
}

@Test func escWhileAScenePlaysEndsOnTheLinksOwnDrawables() {
    var life = Life()
    // Typing at 6 keys a second for a second, Esc at 1.05: the dim fades over 0.2 s and goes at 1.25; the scene's
    // close ends `closeAhead` before (as `Ambient.close` hands it on).
    let steps = drive(&life, plan(.rain, turn: 1), from: 0, to: 2, keys: (0...6).map { Double($0) / 6 },
                      close: (1.05, 0.2 - Ambience.Tuning.closeAhead), stop: 1.25, frames: 1.25)
    #expect(lawful(steps))
    #expect(steps[0].step.alpha == nil && steps[0].step.resize == pixels)  // a cleared frame first, at the screen's size
    #expect(steps[1].step.show == 1 && steps[1].step.alpha == 1)  // then the layer may show, and the scene draws
    let fading = steps.filter { $0.t > 1.06 && $0.step.alpha != nil }.map { $0.step.alpha! }
    #expect(!fading.isEmpty && zip(fading, fading.dropFirst()).allSatisfy { $0 > $1 })  // the close's fade
    let parked = steps.firstIndex { $0.step.resize == Life.parked }
    #expect(parked != nil && steps[parked!].t <= 1.25 && steps[parked! + 1].step.pause)  // cleared, parked, paused
    #expect(life.phase == .idle && life.run == nil)
}

@Test func theNextShowNeverDrawsBeforeAClearedFrame() {
    // A hand-off (the close waits 0.15 s and fades 0.2 s) and a close at once (Pop off): the window goes before the
    // scene can clear itself, the next show starts over with a cleared frame.
    for close in [(at: 1.05, over: 0.35), (at: 1.05, over: 0.0)] {
        var life = Life()
        let first = drive(&life, plan(.rings, turn: 1), from: 0, to: 2, keys: [0, 0.5, 1], close: close,
                          stop: close.at + close.over, frames: close.at + close.over)
        let next = drive(&life, plan(.rings, turn: 2), from: 3, to: 4, keys: [3.1, 3.3])
        #expect(lawful(first) && lawful(next), "\(close)")
        // The link still runs as the window comes back: its first frame clears and parks, the next pauses; the key
        // at 3.1 starts the new scene with a cleared frame at the screen's size, and the layer shows after it.
        #expect(next[0].step.alpha == nil && next[0].step.resize == Life.parked && next[1].step.pause, "\(close)")
        let key = next.firstIndex { $0.t >= 3.1 }!
        #expect(next[key].step.alpha == nil && next[key].step.resize == pixels && next[key + 1].step.show == 2)
    }
}

@Test func fourSecondsAfterTheLastKeyTheSceneParksAndOffDrawsNothing() {
    var life = Life()
    let steps = drive(&life, plan(.drift, turn: 1), from: 0, to: 6, keys: [0, 0.2, 0.4, 1])
    #expect(lawful(steps) && life.phase == .idle)
    let end = steps.firstIndex { $0.step.resize == Life.parked }!
    #expect(abs(steps[end].t - 5) < 0.05 && steps[end + 1].step.pause && steps.count == end + 2)  // then no frames
    var again = drive(&life, plan(.drift, turn: 1), from: 6, to: 7, keys: [6.5])  // the same show, typing again
    #expect(lawful(again) && again.first { $0.step.alpha != nil } != nil)
    var off = Life()
    again = drive(&off, plan(nil, turn: 1), from: 0, to: 1, keys: [0, 0.5])
    #expect(again.allSatisfy { $0.step.alpha == nil } && off.phase == .idle)  // Off: cleared, parked, paused
}

@Test(.enabled(if: Ambience.Renderer.available)) func theEscSequenceRunsOnARealLayerAndLinkWithoutAnException() throws {
    // The same Esc as above, every step done to a real layer and link: the size between frames, the pause, and each
    // frame drawn by the renderer into a texture standing in for the link's drawable.
    let renderer = try #require(Ambience.Renderer(font: menlo))
    let layer = CAMetalLayer()
    (layer.device, layer.pixelFormat) = (renderer.device, .bgra8Unorm)
    let link = CAMetalDisplayLink(metalLayer: layer)
    link.isPaused = true
    var life = Life(), out: [Sprite] = []
    let p = plan(.rings, turn: 1)
    let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 64, height: 64, mipmapped: false)
    d.usage = [.renderTarget]
    d.storageMode = .private
    let drawable = try #require(renderer.device.makeTexture(descriptor: d)), instances = renderer.makeInstances()
    var message = [CChar](repeating: 0, count: 256)
    let threw = LemnaCatch({
        if let size = life.start(p) { layer.drawableSize = size }
        link.isPaused = false
        var t = 0.0
        while life.phase != .idle, t < 3 {
            t += 1.0 / 60
            let keys = t < 0.5 ? [Ambience.Key(t: t, kind: .space)] : []
            let step = life.frame(at: t, plan: p, keys: keys, closing: t >= 0.6 ? (0.6, 0.2) : nil, glyphs: renderer.glyphs,
                                  into: &out)
            let commands = renderer.queue.makeCommandBuffer()!
            out.withUnsafeBytes { raw in
                if let base = raw.baseAddress, let instances { instances.contents().copyMemory(from: base, byteCount: raw.count) }
            }
            renderer.encode(commands, instances: instances, count: step.alpha == nil ? 0 : out.count, into: drawable,
                            viewport: screen, scale: 2, alpha: step.alpha ?? 0)
            commands.commit()
            if let size = step.resize { layer.drawableSize = size }  // after the frame is committed
            if step.pause { link.isPaused = true }
        }
        if life.phase == .idle { life.stop() }  // the dim's end after the scene paused: nothing to do
    }, &message, 256)
    #expect(threw == 0, "\(String(cString: message))")
    #expect(life.phase == .idle && layer.drawableSize == Life.parked && link.isPaused)
    link.invalidate()
}

@Test func escDuringTypingAndDuringTheFadesEndsCleanlyInEveryModeAndOff() {
    let modes: [Ambience.Mode?] = Ambience.Mode.allCases + [nil]
    // Esc (the close's 0.2 s fade) and a hand-off (the dim waits 0.15 s for the sheen, then fades 0.2 s), at 1.05 while
    // typing at 6 keys a second (keys go on coming: the box is gone, none reaches the scene).
    for mode in modes {
        for (wait, fade) in [(0.0, 0.2), (0.15, 0.2)] {
            var life = Life()
            let gone = 1.05 + wait + fade
            let steps = drive(&life, plan(mode, turn: 1), from: 0, to: 2, keys: (0...11).map { Double($0) / 6 },
                              close: (1.05, wait + fade - Ambience.Tuning.closeAhead), stop: gone, frames: gone)
            #expect(lawful(steps), "\(String(describing: mode)) \(wait)")
            #expect(life.phase == .idle && life.run == nil, "\(String(describing: mode)) \(wait)")
            if mode == nil {
                #expect(steps.isEmpty, "Off: no frame at all")
            } else {
                let paused = steps.last { $0.step.pause }
                #expect(paused != nil && paused!.t < gone, "\(mode!): paused while the dim is still up")
                #expect(steps.contains { $0.t > 1.05 && ($0.step.alpha ?? 0) > 0 }, "\(mode!): it fades, not cut")
            }
        }
        // Summoned again during the dim's fade, typing, and Esc again: the new show starts with a cleared frame.
        var life = Life()
        _ = drive(&life, plan(mode, turn: 1), from: 0, to: 1.15, keys: [0, 0.5, 1], close: (1.05, 0.15), stop: nil)
        let again = drive(&life, plan(mode, turn: 2), from: 1.15, to: 3, keys: [1.2, 1.4], close: (1.6, 0.15),
                          stop: 1.8, frames: 1.8)
        #expect(lawful(again) && life.phase == .idle, "\(String(describing: mode)) again")
        if mode != nil {
            let first = again.firstIndex { $0.step.resize == pixels }!
            #expect(again[first].step.alpha == nil && again[first + 1].step.show == 2, "\(mode!) again")
        }
    }
}
