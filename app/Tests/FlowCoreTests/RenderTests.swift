// Offscreen renders of the window's content, 1200 × 700 pt at 2×, drawn as the app draws them, written to app/renders/
// for a look by eye. No Foundation here: beside it, `import Testing` loads the _Testing_Foundation overlay, which the
// Command Line Tools ship without its module ("no such module '_Testing_Foundation'").
import CoreGraphics
import CoreText
import Darwin
import ImageIO
import Testing
@testable import FlowCore

/// app/renders, from this file's path (app/Tests/FlowCoreTests/RenderTests.swift).
let renders = #filePath.split(separator: "/", omittingEmptySubsequences: false).dropLast(3).joined(separator: "/")
    + "/renders"

/// One frame as the app shows it: the background the view's layer paints, the strip's band across the middle.
func render(_ text: Text, marked: String = "", offset: CGFloat, name: String) -> [UInt8] {
    let style = Style(font: menlo), size = CGSize(width: 1200, height: 700), (w, h) = (2400, 1400)
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    c.setFillColor(style.background)
    c.fill(CGRect(origin: .zero, size: size))
    Line.draw(Line.shape(text, marked: marked, font: menlo), offset: offset, in: c,
              band: Line.band(in: size, style: style), style: style)
    mkdir(renders, 0o755)  // fails harmlessly once it exists
    let url = CFURLCreateWithFileSystemPath(nil, renders + "/" + name as CFString, .cfurlposixPathStyle, false)!
    let png = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(png, c.makeImage()!, [kCGImagePropertyDPIWidth: 144, kCGImagePropertyDPIHeight: 144] as CFDictionary)
    #expect(CGImageDestinationFinalize(png))
    let px = c.data!.assumingMemoryBound(to: UInt8.self)
    return Array(UnsafeBufferPointer(start: px, count: 4 * w * h))
}

/// The first and last pixel columns (at 2×) that differ from the background anywhere.
func inkedColumns(_ px: [UInt8]) -> ClosedRange<Int> {
    px.withUnsafeBytes { raw in
        let words = raw.bindMemory(to: UInt32.self), bg = words[0]
        var (lo, hi) = (Int.max, Int.min)
        for i in words.indices where words[i] != bg { (lo, hi) = (min(lo, i % 2400), max(hi, i % 2400)) }
        return lo...hi
    }
}

@Test func offscreenRenders() {
    let before = Text(["The line glides left and the old words fade.", "Next on"])
    var after = before
    let key = after.type("e").added  // "Next one"
    var g = Glide()
    g.add(Double(Line.width(key, font: menlo)), at: 0, reduceMotion: false)

    let idle = render(before, offset: 0, name: "idle.png")
    let glide0 = render(after, offset: CGFloat(g.offset(at: 0)), name: "glide-0.png")
    let glide70 = render(after, offset: CGFloat(g.offset(at: 0.070)), name: "glide-70ms.png")
    let glide140 = render(after, offset: CGFloat(g.offset(at: 0.140)), name: "glide-140ms.png")
    let marked = render(before, marked: "´", offset: 0, name: "marked.png")

    #expect(glide0 == idle)  // the key's own instant: the new glyph is wholly under the caret, nothing else moved
    #expect(glide70 != glide0 && glide140 != glide70 && marked != idle)
    let caretEnd = 2 * (720 + 2), fadeEnd = 2 * Int(300 - advance)  // a glyph centred at 25 % reaches half a cell left
    for frame in [idle, glide0, glide70, glide140, marked] {
        let ink = inkedColumns(frame)
        #expect(ink.upperBound < caretEnd)  // nothing right of the caret
        #expect(ink.lowerBound >= fadeEnd)  // nothing left of the fade's end
    }
}
