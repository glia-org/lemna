// The ambience on the dim (DESIGN.md A1, R1): over each screen's shade, a clear CAMetalLayer that its own
// CAMetalDisplayLink draws at 60 Hz on the scene thread, from the first key until the scene has died out (4 s after the
// last key, the last second fading, or with the dim as the box goes); then the link pauses and the layer holds one
// cleared pixel, so idle costs nothing. Rain (pass 19b, an ambient mode) runs it from the show until the close instead,
// at 30 Hz while it is at rest. The line's key path only hands it the key as a value (`key(_:)`: a lock and an
// append, after the key's frame); the scene is stepped and drawn off the main thread (`Ambience.Run`,
// `Ambience.Lifecycle` and `Ambience.Renderer` in LemnaCore). The line's own display link and its band are untouched.
// Every frame is drawn into the drawable the link hands its callback and into no other: `-[CAMetalLayer nextDrawable]`
// raises on a layer a CAMetalDisplayLink drives, and pass 15, which cleared the layer with it, died at Esc (pass 15b).
import AppKit
import Carbon.HIToolbox
import LemnaCatch
import LemnaCore
import Metal
import QuartzCore
import os

/// The keyboard's physical layout as macOS last saw it (pass 16): KBGetLayoutType of LMGetKbdType, 'ANSI', 'ISO ' or
/// 'JIS '. The SDK no longer has a header for KBGetLayoutType (HIToolbox still exports it), so it is looked up at run
/// time; nil when it is not there, and the scenes then take ANSI's places.
func physicalLayout() -> UInt32? {
    typealias Layout = @convention(c) (Int16) -> UInt32
    guard let f = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "KBGetLayoutType") else { return nil }  // RTLD_DEFAULT
    return unsafeBitCast(f, to: Layout.self)(Int16(LMGetKbdType()))
}

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

/// One screen's ambience: its layer over the shade, its display link, its scene. The layer's geometry and opacity are
/// the main thread's (the opacity fades with the dim at a close and comes back only once the scene thread has a
/// cleared frame out); the link, the drawable's size and everything drawn are the scene thread's.
final class Ambient: NSObject, CAMetalDisplayLinkDelegate {
    /// Over the shade, the screen's size: clear, one pixel large while nothing plays, hidden after a close.
    let layer = CAMetalLayer()
    private let font: CTFont

    /// Between the main thread and the scene thread, under one lock: the plan (from each show), the keys since the
    /// last frame, a close (the box went: when, and over how long the scene fades), whether the link runs, and whether
    /// the ambience is shut down for this launch (Metal failed, or an exception was caught).
    private struct Mail {
        var plan: Ambience.Plan?, keys: [Ambience.Key] = [], closing: (at: Double, over: Double)?, running = false
        var dead = false
    }
    private let mail = OSAllocatedUnfairLock(uncheckedState: Mail())

    /// The main thread's: the show whose layer may be shown again; nil once the box has closed.
    private var open: Int?

    // The scene thread's own.
    private var link: CAMetalDisplayLink?
    private var life = Ambience.Lifecycle(), keys: [Ambience.Key] = [], sprites: [Sprite] = []
    /// Three instance buffers, one per frame in flight.
    private var instances: [MTLBuffer] = [], next = 0
    private let inFlight = DispatchSemaphore(value: 3)
    /// What an Objective-C exception caught in the callback said.
    private var message = [CChar](repeating: 0, count: Ambient.messageSize)
    private static let messageSize = 512
    /// Made once on the scene thread (the shader's one compile), shared by every screen; nil until then, or when it
    /// failed.
    private static var renderer: Ambience.Renderer?, failed = false

    init(font: CTFont) {
        self.font = font
        super.init()
        layer.device = MTLCreateSystemDefaultDevice()
        layer.pixelFormat = .bgra8Unorm
        layer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        layer.isOpaque = false
        layer.framebufferOnly = true
        layer.drawableSize = Ambience.Lifecycle.parked
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
    /// gives way to a new one, which starts at the next key with a cleared frame (an ambient mode's at once: the show
    /// wakes the scene thread as a key would); with a mode, the renderer is made now on the scene thread, so the first
    /// key finds the shader compiled.
    func begin(_ mode: Ambience.Mode?, on stage: Ambience.Stage, scale: CGFloat) {
        let frame = CGRect(origin: .zero, size: stage.size)
        if layer.frame != frame || layer.contentsScale != scale {  // a screen changed: else nothing to commit
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            (layer.frame, layer.contentsScale) = (frame, scale)
            CATransaction.commit()
        }
        let pixels = CGSize(width: (stage.size.width * scale).rounded(), height: (stage.size.height * scale).rounded())
        let wake: Bool
        (open, wake) = mail.withLockUnchecked { m -> (Int, Bool) in
            let turn = (m.plan?.turn ?? 0) + 1
            m.plan = Ambience.Plan(mode: mode, stage: stage, pixels: pixels, scale: scale, turn: turn)
            m.closing = nil
            guard mode?.ambient == true, !m.dead, !m.running else { return (turn, false) }
            m.running = true
            return (turn, true)
        }
        if wake {
            SceneThread.shared.perform { [self] in start() }
        } else if mode != nil {
            SceneThread.shared.perform { [self] in _ = prepare() }
        }
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

    /// The box goes: the scene fades out over `d` (less `Tuning.closeAhead`, so it clears and pauses while the dim is
    /// still up) and the layer stays hidden until the next show's first cleared frame. Its opacity fades with the
    /// shade (the box does that); `stop` follows once the dim is gone.
    func close(over d: Double) {
        open = nil
        let t = CACurrentMediaTime()
        mail.withLockUnchecked { $0.closing = (t, max(d - Ambience.Tuning.closeAhead, 0)) }
    }

    /// The dim is gone: whatever still plays ends; the next frame, if one comes, clears and parks.
    func stop() { SceneThread.shared.perform { [self] in life.stop() } }

    /// The scene thread has a cleared frame of `turn` out: the layer shows again, unless the box closed since.
    private func show(_ turn: Int) {
        DispatchQueue.main.async { [self] in
            guard open == turn else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.removeAnimation(forKey: "fade")
            layer.opacity = 1
            CATransaction.commit()
        }
    }

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

    /// The first key after a pause, or an ambient mode's show: the drawable back at the screen's size, the link running.
    private func start() {
        guard prepare() != nil, let link, !mail.withLockUnchecked({ $0.dead }) else { return shutDown(nil) }
        if instances.isEmpty, let renderer = Self.renderer { instances = (0..<3).compactMap { _ in renderer.makeInstances() } }
        if let size = life.start(mail.withLockUnchecked({ $0.plan })) { layer.drawableSize = size }
        link.isPaused = false
    }

    /// One frame of the link, its body guarded: an Objective-C exception must not cross Core Animation's callback (it
    /// aborts the app, as pass 15's did); if one comes, the ambience shuts down for this launch and Lemna goes on.
    func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
        guard link === self.link else { return }  // a link invalidated after an exception: nothing more from it
        if LemnaCatch({ self.frame(link, update) }, &message, UInt(Self.messageSize)) == 1 {
            shutDown(String(cString: message))
        }
    }

    /// The mail taken, the lifecycle's step drawn into the link's own drawable and committed, then the drawable's
    /// size changed, the layer shown, the link's frame rate changed or the link paused, as the step says.
    private func frame(_ link: CAMetalDisplayLink, _ update: CAMetalDisplayLink.Update) {
        guard let renderer = Self.renderer else { return link.isPaused = true }
        let (plan, closing) = mail.withLockUnchecked { m -> (Ambience.Plan?, (at: Double, over: Double)?) in
            swap(&m.keys, &keys)
            return (m.plan, m.closing)
        }
        let step = life.frame(at: update.targetTimestamp, plan: plan, keys: keys, closing: closing,
                              glyphs: renderer.glyphs, into: &sprites)
        keys.removeAll(keepingCapacity: true)
        draw(step.alpha == nil ? 0 : sprites.count, alpha: step.alpha ?? 0, plan: plan, into: update.drawable)
        if let size = step.resize { layer.drawableSize = size }  // after the frame is committed
        if let turn = step.show { show(turn) }
        if let hz = step.rate {
            link.preferredFrameRateRange = CAFrameRateRange(minimum: Float(hz), maximum: Float(hz), preferred: Float(hz))
        }
        if step.pause { pause(link) }
    }

    /// The lifecycle pauses: unless keys came since this frame took them, or an ambient mode's show (which found the
    /// link running and so did not wake it), and then it goes on.
    private func pause(_ link: CAMetalDisplayLink) {
        let plan = mail.withLockUnchecked { m -> Ambience.Plan?? in
            if !m.keys.isEmpty || m.plan?.mode?.ambient == true, m.plan?.mode != nil, m.closing == nil, !m.dead {
                return .some(m.plan)
            }
            m.running = false
            return nil
        }
        guard let plan else { return link.isPaused = true }
        if let size = life.start(plan) { layer.drawableSize = size }
    }

    /// No more ambience this launch: the link paused and invalidated here, on its own thread, so it calls back no
    /// more; keys dropped from now on; the layer hidden by the main thread. `why`: the exception's text, logged once.
    private func shutDown(_ why: String?) {
        if let why { NSLog("Lemna: the ambience stopped: %@", why) }
        mail.withLockUnchecked { m in (m.dead, m.running, m.keys) = (true, false, []) }
        if let l = link {
            link = nil
            l.isPaused = true
            l.invalidate()
        }
        DispatchQueue.main.async { [self] in
            open = nil
            layer.opacity = 0
        }
    }

    /// The first `count` of `sprites` into the link's `drawable` at `alpha` (none: it is cleared), committed and
    /// presented; at most three frames in flight.
    private func draw(_ count: Int, alpha: Double, plan: Ambience.Plan?, into drawable: CAMetalDrawable) {
        guard let renderer = Self.renderer, let commands = renderer.queue.makeCommandBuffer() else { return }
        inFlight.wait()
        let buffer = instances.isEmpty ? nil : instances[next]
        next = (next + 1) % max(instances.count, 1)
        let n = min(count, Ambience.Tuning.cap)
        if let buffer, n > 0 {
            sprites.withUnsafeBytes {
                buffer.contents().copyMemory(from: $0.baseAddress!, byteCount: n * MemoryLayout<Sprite>.stride)
            }
        }
        renderer.encode(commands, instances: buffer, count: n, into: drawable.texture,
                        viewport: plan?.stage.size ?? layer.bounds.size, scale: plan?.scale ?? layer.contentsScale,
                        alpha: alpha)
        commands.addCompletedHandler { [inFlight] _ in inFlight.signal() }
        commands.present(drawable)
        commands.commit()
    }
}
