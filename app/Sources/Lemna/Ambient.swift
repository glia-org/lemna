// The ambience on the dim (DESIGN.md A1, R1): over each screen's shade, a clear CAMetalLayer that its own
// CAMetalDisplayLink draws at 60 Hz on the scene thread, from the first key until the scene has died out (4 s after the
// last key, the last second fading, or with the dim as the box goes); then the link pauses and the layer holds one
// clear pixel, so idle costs nothing. The line's key path only hands it the key as a value (`key(_:)`: a lock and an
// append, after the key's frame); the scene is stepped and drawn off the main thread (`Ambience.Run` and
// `Ambience.Renderer` in LemnaCore). The line's own display link and its band are untouched.
import AppKit
import LemnaCore
import Metal
import QuartzCore
import os

/// The thread every screen's scene steps and draws on, with a run loop for the display links: nothing of the ambience
/// runs on the main thread, where the line's keys and its own display link are.
final class SceneThread: Thread {
    static let shared: SceneThread = {
        let t = SceneThread()
        t.name = "dev.lemna.ambience"
        t.qualityOfService = .userInteractive
        t.start()
        t.ready.wait()  // until its run loop exists: microseconds, once
        return t
    }()
    private let ready = DispatchSemaphore(value: 0)
    private var loop: CFRunLoop?

    override func main() {
        loop = CFRunLoopGetCurrent()
        RunLoop.current.add(NSMachPort(), forMode: .default)  // a source, so the loop waits instead of returning
        ready.signal()
        while true { _ = RunLoop.current.run(mode: .default, before: .distantFuture) }
    }

    /// `block` on the scene thread, soon; nothing waits for it.
    func perform(_ block: @escaping () -> Void) {
        guard let loop else { return }
        CFRunLoopPerformBlock(loop, CFRunLoopMode.defaultMode.rawValue, block)
        CFRunLoopWakeUp(loop)
    }
}

/// One screen's ambience: its layer over the shade, its display link, its scene.
final class Ambient: NSObject, CAMetalDisplayLinkDelegate {
    /// Over the shade, the screen's size: clear, and one pixel large while nothing plays.
    let layer = CAMetalLayer()
    private let font: CTFont

    /// What a show hands the scene thread: the mode on this screen (nil: none), its stage, the drawable's size and
    /// scale; `turn` moves on with each, so the scene thread sees a new one.
    private struct Plan { var mode: Ambience.Mode?, stage: Ambience.Stage, pixels: CGSize, scale: CGFloat, turn: Int }
    /// Between the main thread and the scene thread, under one lock: the plan, the keys since the last frame, a close
    /// (the box went: when and over how long), whether the link runs, and whether Metal failed (then nothing plays).
    private struct Mail {
        var plan: Plan?, keys: [Ambience.Key] = [], closing: (at: Double, over: Double)?, running = false, dead = false
    }
    private let mail = OSAllocatedUnfairLock(uncheckedState: Mail())

    // The scene thread's own.
    private var link: CAMetalDisplayLink?
    private var plan: Plan?, run: Ambience.Run?, keys: [Ambience.Key] = [], sprites: [Sprite] = []
    /// Three instance buffers, one per frame in flight.
    private var instances: [MTLBuffer] = [], next = 0
    private let inFlight = DispatchSemaphore(value: 3)
    private var last: Double?, live = false
    /// Made once on the scene thread (the shader's one compile), shared by every screen; nil until then, or when it failed.
    private static var renderer: Ambience.Renderer?, failed = false

    init(font: CTFont) {
        self.font = font
        super.init()
        layer.device = MTLCreateSystemDefaultDevice()
        layer.pixelFormat = .bgra8Unorm
        layer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        layer.isOpaque = false
        layer.framebufferOnly = true
        layer.drawableSize = CGSize(width: 1, height: 1)
        SceneThread.shared.perform { [self] in
            let l = CAMetalDisplayLink(metalLayer: layer)
            l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
            l.isPaused = true
            l.delegate = self
            l.add(to: .current, forMode: .default)
            link = l
        }
    }

    // MARK: From the main thread

    /// At each show: the mode on this screen (nil: none) on `stage`, at the screen's `scale`. A scene still playing
    /// gives way to a new one at the next key; with a mode, the renderer is made now on the scene thread, so the first
    /// key finds the shader compiled.
    func begin(_ mode: Ambience.Mode?, on stage: Ambience.Stage, scale: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = CGRect(origin: .zero, size: stage.size)
        layer.contentsScale = scale
        CATransaction.commit()
        let pixels = CGSize(width: (stage.size.width * scale).rounded(), height: (stage.size.height * scale).rounded())
        mail.withLockUnchecked { m in
            m.plan = Plan(mode: mode, stage: stage, pixels: pixels, scale: scale, turn: (m.plan?.turn ?? 0) + 1)
            m.closing = nil
        }
        if mode != nil { SceneThread.shared.perform { [self] in _ = prepare() } }
    }

    /// A key the line took, after its frame: a lock and an append. The first after a pause wakes the scene thread.
    func key(_ k: Ambience.Key) {
        let wake = mail.withLockUnchecked { m -> Bool in
            guard m.plan?.mode != nil, m.closing == nil, !m.dead else { return false }
            m.keys.append(k)
            guard !m.running else { return false }
            m.running = true
            return true
        }
        if wake { SceneThread.shared.perform { [self] in start() } }
    }

    /// The box goes: the scene fades out over `d`, with the dim; `stop` follows once the dim is gone.
    func close(over d: Double) {
        let t = CACurrentMediaTime()
        mail.withLockUnchecked { $0.closing = (t, d) }
    }

    /// The dim is gone: whatever still plays stops, and the layer is cleared.
    func stop() { SceneThread.shared.perform { [self] in halt() } }

    // MARK: On the scene thread

    private func prepare() -> Ambience.Renderer? {
        if Self.renderer == nil, !Self.failed {
            Self.renderer = Ambience.Renderer(font: font)
            if Self.renderer == nil {
                Self.failed = true
                NSLog("Lemna: no ambience: no Metal device, or its shader did not compile")
            }
        }
        return Self.renderer
    }

    /// The first key after a pause: the drawable back at the screen's size, the link running.
    private func start() {
        guard let renderer = prepare(), let link else {
            mail.withLockUnchecked { $0.dead = true }
            return halt()
        }
        if instances.isEmpty { instances = (0..<3).compactMap { _ in renderer.makeInstances() } }
        if let pixels = mail.withLockUnchecked({ $0.plan?.pixels }) { layer.drawableSize = pixels }
        (last, live) = (nil, true)
        link.isPaused = false
    }

    /// One frame: the mail taken, the scene made at the first key of a show (and anew for another mode), stepped with
    /// the keys, drawn into the link's drawable; when it is over, the link pauses.
    func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
        let t = update.targetTimestamp
        let (newest, closing) = mail.withLockUnchecked { m -> (Plan?, (at: Double, over: Double)?) in
            swap(&m.keys, &keys)
            return (m.plan, m.closing)
        }
        if newest?.turn != plan?.turn {
            (plan, run) = (newest, nil)
            if let p = plan, layer.drawableSize != p.pixels { layer.drawableSize = p.pixels }
        }
        if run == nil, let p = plan, let mode = p.mode, !keys.isEmpty, closing == nil, let renderer = Self.renderer {
            run = Ambience.Run(mode: mode, stage: p.stage, glyphs: renderer.glyphs, seed: UInt64(t * 1000))
        }
        if let c = closing { run?.close(at: c.at, over: c.over) }
        run?.take(keys)
        keys.removeAll(keepingCapacity: true)
        let dt = last.map { min(max(t - $0, 0), 0.05) } ?? 1 / Ambience.Tuning.frameRate
        last = t
        guard let alpha = run?.frame(at: t, dt: dt, into: &sprites) else {  // stepped in place: no copy of the scene
            run = nil
            return halt()
        }
        draw(sprites.count, alpha: alpha, into: update.drawable)
    }

    /// Nothing plays: the link pauses and the layer shows one clear pixel, so the screen-sized drawables go; unless keys
    /// came meanwhile, and then it goes on.
    private func halt() {
        let resume = mail.withLockUnchecked { m -> Bool in
            if !m.keys.isEmpty, m.plan?.mode != nil, m.closing == nil, !m.dead { return true }
            m.running = false
            return false
        }
        if resume {
            if !live { start() }
            return
        }
        guard live else { return }
        (live, run, last) = (false, nil, nil)
        link?.isPaused = true
        layer.drawableSize = CGSize(width: 1, height: 1)
        if let d = layer.nextDrawable() { draw(0, alpha: 0, into: d) }
    }

    /// The first `count` of `sprites` into `drawable`, at `alpha`, presented; at most three frames in flight.
    private func draw(_ count: Int, alpha: Double, into drawable: CAMetalDrawable) {
        guard let renderer = Self.renderer, let plan, let commands = renderer.queue.makeCommandBuffer() else { return }
        inFlight.wait()
        let buffer = instances.isEmpty ? nil : instances[next]
        next = (next + 1) % max(instances.count, 1)
        let n = min(count, Ambience.Tuning.cap)
        if let buffer, n > 0 {
            sprites.withUnsafeBytes {
                buffer.contents().copyMemory(from: $0.baseAddress!, byteCount: n * MemoryLayout<Sprite>.stride)
            }
        }
        renderer.encode(commands, instances: buffer, count: n, into: drawable.texture, viewport: plan.stage.size,
                        scale: plan.scale, alpha: alpha)
        commands.addCompletedHandler { [inFlight] _ in inFlight.signal() }
        commands.present(drawable)
        commands.commit()
    }
}
