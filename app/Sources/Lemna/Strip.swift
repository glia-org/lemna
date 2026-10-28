// The line's band on screen: a view backed by a CAMetalLayer. Core Graphics draws each frame into a shared Metal buffer
// and a blit copies it into the drawable, which works whatever the drawable's storage mode (a CPU write into its
// texture is not allowed when that is private).
import AppKit
import LemnaCore
import Metal
import QuartzCore

final class Strip: NSView {
    private let device = MTLCreateSystemDefaultDevice()!
    private lazy var queue = device.makeCommandQueue()!
    private var metal: CAMetalLayer { layer as! CAMetalLayer }
    /// One bitmap more than drawables, each with the command buffer that last read it.
    private var ring: [(buffer: MTLBuffer, context: CGContext, reader: MTLCommandBuffer?)] = []
    private var pixels = (w: 0, h: 0, row: 0), next = 0
    /// `ring[next]` holds a frame drawn since the last resize.
    private var drawn = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func makeBackingLayer() -> CALayer {
        let l = CAMetalLayer()
        l.device = device
        l.pixelFormat = .bgra8Unorm
        l.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        l.framebufferOnly = false  // the drawable's texture is a blit destination
        l.maximumDrawableCount = 2  // one frame less in the queue than the default 3 (the spike's known cut)
        l.isOpaque = true
        return l
    }
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {}  // frames come only from present(_:)

    /// While true (a live resize), a frame reaches the screen in the same Core Animation transaction as the layer's
    /// new size, so the old frame is never shown stretched.
    var synced: Bool {
        get { metal.presentsWithTransaction }
        set { metal.presentsWithTransaction = newValue }
    }

    /// Matches the drawable and the bitmaps to the view's size in pixels.
    func resize(scale: CGFloat) {
        let w = max(1, Int((bounds.width * scale).rounded())), h = max(1, Int((bounds.height * scale).rounded()))
        metal.contentsScale = scale
        metal.drawableSize = CGSize(width: w, height: h)
        pixels = (w, h, (w * 4 + 255) & ~255)
        ring = (0..<3).map { _ in
            let b = device.makeBuffer(length: pixels.row * h, options: .storageModeShared)!
            return (b, Line.context(width: w, height: h, rowBytes: pixels.row, scale: scale, data: b.contents()), nil)
        }
        drawn = false
    }

    /// The last frame presented, as an image (a copy of its bitmap), for the box's last look as it fades (P1, E1).
    func lastFrame() -> CGImage? { drawn ? ring[next].context.makeImage() : nil }

    /// Draws a frame with `draw` (in points, origin at the bottom left) and presents it.
    func present(_ draw: (CGContext) -> Void) {
        guard !ring.isEmpty, let drawable = metal.nextDrawable() else { return }
        next = (next + 1) % ring.count
        ring[next].reader?.waitUntilCompleted()  // done long ago in practice; this makes it certain
        draw(ring[next].context)
        drawn = true
        let commands = queue.makeCommandBuffer()!, blit = commands.makeBlitCommandEncoder()!
        let size = MTLSize(width: min(pixels.w, drawable.texture.width), height: min(pixels.h, drawable.texture.height),
                           depth: 1)  // a drawable from before a resize may be smaller
        blit.copy(from: ring[next].buffer, sourceOffset: 0, sourceBytesPerRow: pixels.row,
                  sourceBytesPerImage: pixels.row * pixels.h, sourceSize: size, to: drawable.texture, destinationSlice: 0,
                  destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blit.endEncoding()
        ring[next].reader = commands
        if synced {  // the sequence CAMetalLayer.presentsWithTransaction asks for
            commands.commit()
            commands.waitUntilScheduled()
            drawable.present()
        } else {
            commands.present(drawable)
            commands.commit()
        }
    }
}
