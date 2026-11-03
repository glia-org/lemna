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
/// a key just added, fading in (F1: K1, E2); `style` the theme as it shows, Lemna's unless given.
func render(_ text: Text, marked: String = "", offset: CGFloat, moved: CGFloat = 0, newest: Newest = Newest(),
            style: Style = Style(font: menlo), name: String) -> [UInt8] {
    let size = CGSize(width: 1200, height: 700), (w, h) = (2400, 1400)
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    c.setFillColor(style.background)
    c.fill(CGRect(origin: .zero, size: size))
    Line.draw(Line.shape(text, marked: marked, font: style.font), before: offset + moved, after: moved, newest: newest,
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
    // The first 120 Hz frame after the key with the glyph fade (K1): the "e" a quarter out from under the caret, at
    // 41 %; and a Return's ` ¶ ` 25 ms in (E2), at 48 %.
    let t1 = 1.0 / 120, entrance = Entrance.glyph(units: 1, at: 0)
    let fadingIn = render(after, offset: CGFloat(g.offset(at: t1)), newest: entrance.newest(at: t1),
                         name: "glyph-fade-8ms.png")
    #expect(fadingIn != render(after, offset: CGFloat(g.offset(at: t1)), name: "glide-8ms.png"))
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
    for frame in [idle, glide0, glide70, glide140, marked, fadingIn, fading] {
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

/// The pixel (BGRA) where `render` drew the middle of the glyph at line unit `i` of `text`, mid-band, with no glide.
func pixel(_ frame: [UInt8], glyph i: Int, of text: Text, style: Style) -> [Int] {
    let size = CGSize(width: 1200, height: 700), band = Line.band(in: size, style: style)
    let bar = Line.caretRect(in: band, style: style), line = Line.shape(text, marked: "", font: style.font)
    let g = line.glyphs.first { $0.index == i }!
    let x = (g.after ? bar.maxX : bar.minX) - line.caret + g.x + g.advance / 2
    let k = 4 * (Int((size.height - band.midY) * 2) * 2400 + Int(x * 2))
    return frame[k..<k + 4].map { Int($0) }
}

/// The selection's band (pass 29) as Core Graphics lays it over `surface`: the accent at `Line.selectionAlpha`. BGRA.
func band(_ accent: UInt32, over surface: UInt32) -> [Int] {
    let a = Double(Line.selectionAlpha)
    func channel(_ shift: UInt32) -> Int {
        let (x, y) = (Double(accent >> shift & 255), Double(surface >> shift & 255))
        return Int((a * x + (1 - a) * y).rounded())
    }
    return [channel(0), channel(8), channel(16), 255]
}

func near(_ p: [Int], _ q: [Int]) -> Bool { zip(p, q).allSatisfy { abs($0 - $1) <= 2 } }

/// The selection (B4, pass 29) in the window, as `editing.png` is the caret in the middle: "old words" selected by
/// ⇧⌥→ twice, before the caret (selection.png), and by ⇧⌥← twice, after it (selection-after.png); everything by ⌘A, the
/// caret at the end and the band fading out with the text toward 25 % (select-all.png); and Still's by day and by
/// night (selection-still-day.png, selection-still-night.png). Sampled mid-band in the spaces, where no glyph inks: in
/// the selection the band's colour, outside it and across the caret the surface.
@Test func selectionRenders() throws {
    let words = "The line glides left and the old words fade.\nNext one"  // "old" at 29, "words" ends at 38
    var before = Text(words, caret: 29), after = Text(words, caret: 38), all = Text(words, caret: 38)
    for _ in 0 ..< 2 {
        before.moveWordRight(extending: true)
        after.moveWordLeft(extending: true)
    }
    all.selectAll()
    #expect(before.selectedText == "old words" && after.selectedText == "old words" && after.caret == 29)
    let lemna = Style(font: menlo), surface = [0x13, 0x10, 0x0e, 0xff], blue = band(0x7aa7f0, over: 0x0e1013)
    let left = render(before, offset: 0, name: "selection.png"), right = render(after, offset: 0, name: "selection-after.png")
    #expect(left != render(Text(words, caret: 38), offset: 0, name: "selection-none.png"))
    for (frame, text) in [(left, before), (right, after)] {
        #expect(near(pixel(frame, glyph: 32, of: text, style: lemna), blue))  // the space between "old" and "words"
        #expect(pixel(frame, glyph: 28, of: text, style: lemna) == surface)  // before "old": not selected
        #expect(pixel(frame, glyph: 38, of: text, style: lemna) == surface)  // after "words", past the caret or not
    }
    let ink = inkedColumns(left)
    #expect(ink.upperBound < 2 * 1140 && ink.lowerBound >= 2 * Int(300 - advance))  // inside the fades, as editing.png
    let everything = render(all, offset: 0, name: "select-all.png")
    #expect(all.caret == all.count && near(pixel(everything, glyph: 51, of: all, style: lemna), blue))  // "Next one"
    let faded = pixel(everything, glyph: 32, of: all, style: lemna)  // at 28 % of the width: in the fade
    #expect(faded[0] > surface[0] + 2 && faded[0] < blue[0] - 2 && faded[1] > surface[1] && faded[1] < blue[1])
    #expect(pixel(everything, glyph: 20, of: all, style: lemna) == surface)  // left of 25 %: none of it
    #expect(inkedColumns(everything).lowerBound >= 2 * Int(300 - advance))
    let font = try #require(stillFont)
    for (dark, name) in [(false, "selection-still-day.png"), (true, "selection-still-night.png")] {
        let style = Style(.still, dark: dark, font: font), p = style.palette
        let frame = render(before, offset: 0, style: style, name: name)
        let paper: [Int] = [Int(p.surface & 255), Int(p.surface >> 8 & 255), Int(p.surface >> 16 & 255), 255]
        #expect(near(pixel(frame, glyph: 32, of: before, style: style), band(p.accent, over: p.surface)), "\(name)")
        #expect(pixel(frame, glyph: 28, of: before, style: style) == paper && pixel(frame, glyph: 38, of: before,
                                                                                  style: style) == paper, "\(name)")
    }
}
