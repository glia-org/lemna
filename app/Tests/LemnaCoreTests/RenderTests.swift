// Offscreen renders of the window's content, 1200 × 700 pt at 2×, drawn as the app draws them, written to app/renders/
// for a look by eye. No Foundation here: beside it, `import Testing` loads the _Testing_Foundation overlay, which the
// Command Line Tools ship without its module ("no such module '_Testing_Foundation'").
import CoreGraphics
import CoreText
import Darwin
import ImageIO
import Testing
@testable import LemnaCore

/// app/renders, from this file's path (app/Tests/LemnaCoreTests/RenderTests.swift).
let renders = #filePath.split(separator: "/", omittingEmptySubsequences: false).dropLast(3).joined(separator: "/")
    + "/renders"

/// One frame as the app shows it: the background the view's layer paints, the strip's band across the middle.
/// `offset` moves the text before the caret (an edit's glide), `moved` all of it (a caret move's); `newest` the glyphs
/// a key just added (F1: K1, E2).
func render(_ text: Text, marked: String = "", offset: CGFloat, moved: CGFloat = 0, newest: Newest = Newest(),
            name: String) -> [UInt8] {
    let style = Style(font: menlo), size = CGSize(width: 1200, height: 700), (w, h) = (2400, 1400)
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    c.setFillColor(style.background)
    c.fill(CGRect(origin: .zero, size: size))
    Line.draw(Line.shape(text, marked: marked, font: menlo), before: offset + moved, after: moved, newest: newest,
              in: c, band: Line.band(in: size, style: style), style: style)
    savePNG(c, name, dpi: 144)
    let px = c.data!.assumingMemoryBound(to: UInt8.self)
    return Array(UnsafeBufferPointer(start: px, count: 4 * w * h))
}

/// Writes a context's bitmap to app/renders/<name>, at `dpi` (72 for 1×, 144 for 2×).
func savePNG(_ c: CGContext, _ name: String, dpi: Int) {
    mkdir(renders, 0o755)  // fails harmlessly once it exists
    let url = CFURLCreateWithFileSystemPath(nil, renders + "/" + name as CFString, .cfurlposixPathStyle, false)!
    let png = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(png, c.makeImage()!, [kCGImagePropertyDPIWidth: dpi, kCGImagePropertyDPIHeight: dpi] as CFDictionary)
    #expect(CGImageDestinationFinalize(png))
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
    let before = Text("The line glides left and the old words fade.\nNext on")
    var after = before
    after.insert("e")  // "Next one"
    var g = Glide()
    g.add(Double(Line.width("e", font: menlo)), at: 0, reduceMotion: false)

    let idle = render(before, offset: 0, name: "idle.png")
    let glide0 = render(after, offset: CGFloat(g.offset(at: 0)), name: "glide-0.png")
    let glide70 = render(after, offset: CGFloat(g.offset(at: 0.070)), name: "glide-70ms.png")
    let glide140 = render(after, offset: CGFloat(g.offset(at: 0.140)), name: "glide-140ms.png")
    let marked = render(before, marked: "´", offset: 0, name: "marked.png")
    // The first 120 Hz frame after the key with the pop-in (K1): the "e" a quarter out from under the caret, at 22 %,
    // 77 % of its size and 2.3 pt low; and a Return's ` ¶ ` 25 ms in (E2), at 48 %.
    let t1 = 1.0 / 120, entrance = Entrance.glyph(units: 1, at: 0)
    let popping = render(after, offset: CGFloat(g.offset(at: t1)), newest: entrance.newest(at: t1), name: "pop-in-8ms.png")
    #expect(popping != render(after, offset: CGFloat(g.offset(at: t1)), name: "glide-8ms.png"))
    var returned = before
    returned.insert("\n")
    var r = Glide()
    r.add(Double(Line.width("\n", font: menlo)), at: 0, reduceMotion: false)
    let fading = render(returned, offset: CGFloat(r.offset(at: 0.025)),
                        newest: Entrance.paragraph(units: 3, at: 0).newest(at: 0.025), name: "paragraph-fade-25ms.png")
    #expect(fading != render(returned, offset: CGFloat(r.offset(at: 0.025)), name: "paragraph-25ms.png"))

    #expect(glide0 == idle)  // the key's own instant: the new glyph is wholly under the caret, nothing else moved
    // In Lemna's own colours (F1 T2): the background #0e1013 (BGRA in memory) and the caret #7aa7f0 at 60 %, mid-band.
    #expect(Array(idle[0..<4]) == [0x13, 0x10, 0x0e, 0xff])
    let caretPixel = 4 * (700 * 2400 + 2 * 720 + 1)
    #expect(Array(idle[caretPixel..<caretPixel + 4]) == [0xf0, 0xa7, 0x7a, 0xff])
    #expect(glide70 != glide0 && glide140 != glide70 && marked != idle)
    let caretEnd = 2 * (720 + 2), fadeEnd = 2 * Int(300 - advance)  // a glyph centred at 25 % reaches half a cell left
    for frame in [idle, glide0, glide70, glide140, marked, popping, fading] {
        let ink = inkedColumns(frame)
        #expect(ink.upperBound < caretEnd)  // nothing right of the caret
        #expect(ink.lowerBound >= fadeEnd)  // nothing left of the fade's end
    }

    // Editing in the middle (B4): the caret back in "glides", the text after it fading out toward the right edge; and
    // the frame 70 ms into a ← (the whole text gliding right, passing under the caret).
    var middle = Text("The line glides left and the old words fade.\nNext one", caret: 15)
    let editing = render(middle, offset: 0, name: "editing.png")
    let passed = middle.moveLeft()
    var s = Glide()
    if case .caret(let p, _) = passed.motion { s.add(-Double(Line.width(p, font: menlo)), at: 0, reduceMotion: false) }
    let moving = render(middle, offset: 0, moved: CGFloat(s.offset(at: 0.070)), name: "move-left-70ms.png")
    #expect(moving != editing)
    for frame in [editing, moving] {
        let ink = inkedColumns(frame)
        #expect(ink.upperBound < 2 * 1140)  // nothing from 95 % of the width on
        #expect(ink.lowerBound >= fadeEnd)
    }
}
