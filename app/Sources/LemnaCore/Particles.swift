// The ambience's drawing (DESIGN.md A1, R1): one Metal pipeline that draws a frame's sprites as instanced quads,
// glyphs from an atlas of the line's font drawn once with Core Text, the rings' arcs and the grid's lines and cells as
// shapes in the fragment shader. The shader is Metal source compiled at runtime once per device (`makeLibrary(source:)`): the
// Command Line Tools have no Metal compiler, and the system compiles it in a few milliseconds. The app draws into a
// CAMetalLayer's drawable on the scene's thread; the tests draw into an offscreen texture.
import CoreGraphics
import CoreText
import Foundation
import Metal

extension Ambience {
    public final class Renderer {
        public let device: MTLDevice, queue: MTLCommandQueue, glyphs: Glyphs
        private let pipeline: MTLRenderPipelineState, atlas: MTLTexture, sampler: MTLSamplerState

        /// Whether this Mac has a Metal device at all.
        public static var available: Bool { MTLCreateSystemDefaultDevice() != nil }

        /// How long the one compile took, in seconds (0 until it ran).
        public private(set) static var compileSeconds = 0.0
        private static let lock = NSLock()
        private static var pipelines: [UInt64: MTLRenderPipelineState] = [:]

        /// Nil without a Metal device or when the shader does not compile (the app then plays no ambience, and says
        /// so once in the system log).
        public init?(device: MTLDevice? = MTLCreateSystemDefaultDevice(), font: CTFont,
                     pixelFormat: MTLPixelFormat = .bgra8Unorm) {
            guard let device, let queue = device.makeCommandQueue(),
                  let pipeline = Self.pipeline(device, pixelFormat), let sampler = Self.sampler(device) else { return nil }
            let glyphs = Glyphs(font: font)
            guard let atlas = Self.atlas(glyphs, device: device, queue: queue) else { return nil }
            (self.device, self.queue, self.glyphs, self.pipeline, self.atlas, self.sampler) =
                (device, queue, glyphs, pipeline, atlas, sampler)
        }

        /// A buffer with room for `Tuning.cap` sprites, for a frame's instances.
        public func makeInstances() -> MTLBuffer? {
            device.makeBuffer(length: MemoryLayout<Sprite>.stride * Tuning.cap, options: .storageModeShared)
        }

        /// Encodes one frame into `commands`: `target` cleared to nothing, then `count` sprites from `instances` (a
        /// buffer of `Sprite`s, written by the caller) at `alpha`, over a stage `viewport` points large at `scale`
        /// pixels a point. The caller presents and commits.
        public func encode(_ commands: MTLCommandBuffer, instances: MTLBuffer?, count: Int, into target: MTLTexture,
                           viewport: CGSize, scale: CGFloat, alpha: Double) {
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = target
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            pass.colorAttachments[0].storeAction = .store
            guard let draw = commands.makeRenderCommandEncoder(descriptor: pass) else { return }
            if count > 0, let instances {
                let (aw, ah) = glyphs.atlas
                var frame = FrameUniforms(viewport: SIMD2(Float(viewport.width), Float(viewport.height)), scale: Float(scale),
                                          alpha: Float(alpha),
                                          cell: SIMD2(Float(glyphs.pixels.w) / Float(aw), Float(glyphs.pixels.h) / Float(ah)),
                                          columns: UInt32(Glyphs.columns), unused: 0)
                draw.setRenderPipelineState(pipeline)
                draw.setVertexBuffer(instances, offset: 0, index: 0)
                draw.setVertexBytes(&frame, length: MemoryLayout<FrameUniforms>.stride, index: 1)
                draw.setFragmentBytes(&frame, length: MemoryLayout<FrameUniforms>.stride, index: 0)
                draw.setFragmentTexture(atlas, index: 0)
                draw.setFragmentSamplerState(sampler, index: 0)
                draw.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4,
                                    instanceCount: min(count, Tuning.cap))
            }
            draw.endEncoding()
        }

        /// One frame drawn into an offscreen texture `size` points large at `scale`, read back: BGRA, premultiplied,
        /// rows from the top; nil without a device. For the tests and the renders.
        public func offscreen(_ sprites: [Sprite], size: CGSize, scale: CGFloat, alpha: Double = 1) -> [UInt8]? {
            let (w, h) = (Int((size.width * scale).rounded()), Int((size.height * scale).rounded()))
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: w, height: h, mipmapped: false)
            d.usage = [.renderTarget]
            d.storageMode = .private
            guard let target = device.makeTexture(descriptor: d), let instances = makeInstances(),
                  let readBack = device.makeBuffer(length: 4 * w * h, options: .storageModeShared),
                  let commands = queue.makeCommandBuffer() else { return nil }
            let n = min(sprites.count, Tuning.cap)
            sprites.withUnsafeBytes {
                instances.contents().copyMemory(from: $0.baseAddress!, byteCount: n * MemoryLayout<Sprite>.stride)
            }
            encode(commands, instances: instances, count: n, into: target, viewport: size, scale: scale, alpha: alpha)
            guard let blit = commands.makeBlitCommandEncoder() else { return nil }
            blit.copy(from: target, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                      sourceSize: MTLSize(width: w, height: h, depth: 1), to: readBack, destinationOffset: 0,
                      destinationBytesPerRow: 4 * w, destinationBytesPerImage: 4 * w * h)
            blit.endEncoding()
            commands.commit()
            commands.waitUntilCompleted()
            let bytes = readBack.contents().assumingMemoryBound(to: UInt8.self)
            return Array(UnsafeBufferPointer(start: bytes, count: 4 * w * h))
        }

        // MARK: Made once

        /// The library compiled from `source` and the pipeline made from it, once per device: premultiplied output,
        /// the colours added (the scenes are light spilling onto the dim, and rings add) and the alpha laid over.
        private static func pipeline(_ device: MTLDevice, _ format: MTLPixelFormat) -> MTLRenderPipelineState? {
            lock.lock()
            defer { lock.unlock() }
            let key = device.registryID ^ UInt64(format.rawValue) << 56
            if let p = pipelines[key] { return p }
            let start = DispatchTime.now().uptimeNanoseconds
            do {
                let library = try device.makeLibrary(source: shader, options: nil)
                let d = MTLRenderPipelineDescriptor()
                d.vertexFunction = library.makeFunction(name: "sprite_vertex")
                d.fragmentFunction = library.makeFunction(name: "sprite_fragment")
                let c = d.colorAttachments[0]!
                c.pixelFormat = format
                c.isBlendingEnabled = true
                (c.rgbBlendOperation, c.sourceRGBBlendFactor, c.destinationRGBBlendFactor) = (.add, .one, .one)
                (c.alphaBlendOperation, c.sourceAlphaBlendFactor) = (.add, .one)
                c.destinationAlphaBlendFactor = .oneMinusSourceAlpha
                let p = try device.makeRenderPipelineState(descriptor: d)
                compileSeconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1e9
                pipelines[key] = p
                return p
            } catch {
                NSLog("Lemna: the ambience's shader did not compile: %@", String(describing: error))
                return nil
            }
        }

        private static func sampler(_ device: MTLDevice) -> MTLSamplerState? {
            let d = MTLSamplerDescriptor()
            (d.minFilter, d.magFilter, d.mipFilter) = (.linear, .linear, .linear)
            (d.sAddressMode, d.tAddressMode) = (.clampToEdge, .clampToEdge)
            return device.makeSamplerState(descriptor: d)
        }

        /// The atlas: every glyph of `glyphs` drawn once in white on black with Core Text at `Glyphs.scale`, one cell
        /// each, rows from the top, into an 8-bit texture with two mipmap levels below it (a 1× screen draws the glyphs
        /// at half the atlas's size).
        private static func atlas(_ glyphs: Glyphs, device: MTLDevice, queue: MTLCommandQueue) -> MTLTexture? {
            let (w, h) = glyphs.atlas, (cw, ch) = glyphs.pixels, s = Glyphs.scale
            guard w > 0, h > 0, let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                                                  space: CGColorSpaceCreateDeviceGray(),
                                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
            c.setFillColor(gray: 0, alpha: 1)
            c.fill(CGRect(x: 0, y: 0, width: w, height: h))
            c.setFillColor(gray: 1, alpha: 1)
            c.setShouldSmoothFonts(false)
            let font = CTFontCreateCopyWithAttributes(glyphs.font, CTFontGetSize(glyphs.font) * s, nil, nil)
            for (slot, id) in glyphs.ids.enumerated() {
                let col = slot % Glyphs.columns, row = slot / Glyphs.columns
                var g = id, p = CGPoint(x: CGFloat(col * cw) + glyphs.origin.x * s,
                                        y: CGFloat((glyphs.rows - 1 - row) * ch) + glyphs.origin.y * s)
                CTFontDrawGlyphs(font, &g, &p, 1, c)
            }
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: w, height: h, mipmapped: true)
            d.mipmapLevelCount = 3
            d.usage = [.shaderRead]
            guard let texture = device.makeTexture(descriptor: d), let data = c.data else { return nil }
            texture.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: data, bytesPerRow: w)
            guard let commands = queue.makeCommandBuffer(), let blit = commands.makeBlitCommandEncoder() else { return nil }
            blit.generateMipmaps(for: texture)
            blit.endEncoding()
            commands.commit()
            commands.waitUntilCompleted()
            return texture
        }

        /// The frame's values the shader reads: 32 bytes, as `Frame` in `shader`.
        private struct FrameUniforms {
            var viewport: SIMD2<Float>, scale: Float, alpha: Float, cell: SIMD2<Float>, columns: UInt32, unused: UInt32
        }

        /// The vertex shader places each sprite's quad (a triangle strip of four corners, turned about its centre;
        /// shapes a pixel larger for their soft edge); the fragment shader covers it by its kind and writes the colour
        /// premultiplied.
        static let shader = """
        #include <metal_stdlib>
        using namespace metal;

        struct Sprite { float2 centre; float2 size; float rotation; float alpha; uint colour; uint shape; };
        struct Frame { float2 viewport; float scale; float alpha; float2 cell; uint columns; uint unused; };

        struct Shaded {
            float4 position [[position]];
            float2 local;
            float2 half_size [[flat]];
            float4 colour [[flat]];
            float2 uv;
            uint kind [[flat]];
            float parameter [[flat]];
        };

        vertex Shaded sprite_vertex(uint v [[vertex_id]], uint i [[instance_id]],
                                    const device Sprite *sprites [[buffer(0)]], constant Frame &f [[buffer(1)]]) {
            Sprite s = sprites[i];
            uint kind = s.shape & 0xffu, parameter = s.shape >> 8;
            float2 corner = float2((v & 1u) ? 1.0 : -1.0, (v & 2u) ? 1.0 : -1.0);
            float2 half_size = s.size * 0.5;
            float2 local = corner * (half_size + (kind == 0u ? 0.0 : 1.0 / f.scale));
            float c = cos(s.rotation), n = sin(s.rotation);
            float2 p = s.centre + float2(c * local.x - n * local.y, n * local.x + c * local.y);
            Shaded o;
            o.position = float4(p / f.viewport * 2.0 - 1.0, 0.0, 1.0);
            o.local = local;
            o.half_size = half_size;
            o.colour = float4(unpack_unorm4x8_to_float(s.colour).rgb, s.alpha * f.alpha);
            o.kind = kind;
            o.parameter = float(parameter);
            float2 cell = float2(float(parameter % f.columns), float(parameter / f.columns));
            o.uv = (cell + float2(corner.x * 0.5 + 0.5, 0.5 - corner.y * 0.5)) * f.cell;
            return o;
        }

        fragment float4 sprite_fragment(Shaded q [[stage_in]], constant Frame &f [[buffer(0)]],
                                        texture2d<float> atlas [[texture(0)]], sampler smp [[sampler(0)]]) {
            float px = f.scale, cover = 0.0, a = q.colour.a;
            float3 rgb = q.colour.rgb;
            float2 h = q.half_size, p = q.local;
            switch (q.kind) {
            case 0u:  // a glyph
                cover = atlas.sample(smp, q.uv).r;
                break;
            case 1u: {  // a rectangle
                float2 e = (h - abs(p)) * px + 0.5;
                cover = saturate(min(e.x, e.y));
                break;
            }
            case 2u: {  // a stretch of a large circle's stroke, its centre the radius below the quad's middle
                uint k = uint(q.parameter);
                float r = float(k & 0x3fffu) / 2.0, w = float(k >> 14) / 16.0;
                float d = abs(length(p + float2(0.0, r)) - r);
                cover = saturate((w * 0.5 - d) * px + 0.5) * step(abs(p.x), h.x);  // cut square at the quad's ends
                break;
            }
            default:
                break;
            }
            float alpha = saturate(a * cover);
            return float4(rgb * alpha, alpha);
        }
        """
    }
}
