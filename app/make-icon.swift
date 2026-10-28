// Draws the app icon (DESIGN.md L1) from an icon SVG at every size of an iconset and packs it into AppIcon.icns, with
// the Command Line Tools only (no Xcode). NSImage reads SVG, gradients and clipping included, but skips filters, so the
// drop shadow under the body is drawn here, as Apple's icon template has it.
// Idempotent: the iconset is written afresh on each run. Run: swift make-icon.swift <icon.svg> <out folder>, which
// writes <out folder>/AppIcon.iconset and <out folder>/AppIcon.icns (make-app.sh does, into build/).
import AppKit

let args = CommandLine.arguments
guard args.count == 3, let svg = NSImage(contentsOfFile: args[1]) else {
    FileHandle.standardError.write("usage: swift make-icon.swift <icon.svg> <out folder>\n".data(using: .utf8)!)
    exit(2)
}
let out = URL(fileURLWithPath: args[2]), iconset = out.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

/// The icon at `n` × `n` pixels, sRGB, as a PNG. The shadow (1024 px canvas: 10 px down, 24 px blur, 35 % black)
/// scales with the size; a transparency layer gives one shadow for the whole drawing, not one per shape.
func png(_ n: Int) -> Data {
    let c = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let k = CGFloat(n) / 1024
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: false)
    NSGraphicsContext.current!.imageInterpolation = .high
    c.setShadow(offset: CGSize(width: 0, height: -10 * k), blur: 24 * k, color: CGColor(gray: 0, alpha: 0.35))
    c.beginTransparencyLayer(auxiliaryInfo: nil)
    svg.draw(in: NSRect(x: 0, y: 0, width: n, height: n))
    c.endTransparencyLayer()
    NSGraphicsContext.restoreGraphicsState()
    let data = NSMutableData()
    let dest = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, c.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("cannot write the \(n) px PNG") }
    return data as Data
}

// iconutil's names: 16, 32, 128, 256 and 512 pt, each at 1× and 2× (16…1024 px).
for pt in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(pt)x\(pt)" + (scale == 2 ? "@2x" : "") + ".png"
        try png(pt * scale).write(to: iconset.appendingPathComponent(name))
    }
}
let pack = Process()
pack.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
pack.arguments = ["-c", "icns", iconset.path, "-o", out.appendingPathComponent("AppIcon.icns").path]
try pack.run()
pack.waitUntilExit()
exit(pack.terminationStatus)
