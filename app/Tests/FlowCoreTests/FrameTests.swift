// What surrounds the surface (W1 K1 L1): the menu-bar mark, the Bluetooth notice and the muted colour.
import CoreGraphics
import Darwin
import Testing
@testable import FlowCore

/// The mark drawn at `scale` (16 × 16 pt), written to app/renders/<name>, and its alpha at a point in points (the
/// bitmap's first row is its top).
func drawMark(scale: Int, name: String) -> (CGFloat, CGFloat) -> UInt8 {
    let n = 16 * scale
    let c = Line.context(width: n, height: n, rowBytes: 4 * n, scale: CGFloat(scale), data: nil)
    StatusMark.draw(in: c)
    savePNG(c, name, dpi: 72 * scale)
    let px = Array(UnsafeBufferPointer(start: c.data!.assumingMemoryBound(to: UInt8.self), count: 4 * n * n))
    let s = CGFloat(scale)
    return { x, y in px[4 * ((n - 1 - Int(y * s)) * n + Int(x * s)) + 3] }
}

@Test func statusMarkIsATaperedLineWithTheCaretAt60Percent() {
    #expect(StatusMark.size == CGSize(width: 16, height: 16))
    let ink = drawMark(scale: 2, name: "mark-M3-2x.png")  // 1 px = 0.5 pt; sampled at pixel centres
    // Right of the caret the line is 1.5 pt: three rows, nothing above or below.
    for x: CGFloat in [10.25, 12.5, 13.75] {
        #expect(ink(x, 7.75) == 255 && ink(x, 8.25) == 255 && ink(x, 8.75) == 255)
        #expect(ink(x, 7.25) == 0 && ink(x, 9.25) == 0)
    }
    // The top edge is straight from end to end.
    for x in stride(from: CGFloat(2.25), through: 13.75, by: 0.5) { #expect(ink(x, 8.75) == 255) }
    // The last 2 pt are 1 pt tall: the two upper rows, the lowest empty.
    for x: CGFloat in [2.25, 2.75, 3.25, 3.75] {
        #expect(ink(x, 8.25) == 255 && ink(x, 8.75) == 255)
        #expect(ink(x, 7.75) == 0 && ink(x, 9.25) == 0)
    }
    // The taper: between the tip and the caret the lowest row fills from nothing to full.
    let taper = stride(from: CGFloat(4.25), through: 8.25, by: 0.5).map { ink($0, 7.75) }
    #expect(zip(taper, taper.dropFirst()).allSatisfy { $0 < $1 })
    #expect(taper.first! < 64 && taper.last! > 192)
    #expect(ink(1.75, 8.75) == 0 && ink(14.25, 8.75) == 0)  // the line ends at 2 and 14
    // The caret's bar, above and below the line, and nothing beyond its 8.5 pt.
    #expect(ink(9.25, 11) == 255 && ink(9.25, 5) == 255)
    #expect(ink(9.25, 12.75) == 0 && ink(9.25, 3.75) == 0)
    #expect(ink(4, 11) == 0 && ink(12.5, 11) == 0 && ink(4, 5) == 0)
    // Above the line only the caret is inked, its middle at 60 % of the line, 1.5 pt wide.
    let columns = (0..<32).filter { ink(CGFloat($0) / 2 + 0.25, 11) > 0 }
    let middle = (CGFloat(columns.min()!) + CGFloat(columns.max()!) + 1) / 4  // in points
    #expect(abs((middle - StatusMark.line.minX) / StatusMark.line.width - 0.6) < 0.01)
    #expect(columns.count == 3)

    // At 1× the line's top row is one whole row of pixels from end to end: the thin end does not fade out.
    let ink1 = drawMark(scale: 1, name: "mark-M3-1x.png")
    for x in stride(from: CGFloat(2.5), through: 13.5, by: 1) { #expect(ink1(x, 8.5) == 255) }
    #expect(ink1(2.5, 7.5) == 0 && ink1(3.5, 7.5) == 0)  // the tip: that row alone
    #expect(ink1(12.5, 7.5) > 96 && ink1(12.5, 7.5) < 160)  // right of the caret: the half-point below it at half alpha
    #expect(ink1(1.5, 8.5) == 0 && ink1(14.5, 8.5) == 0)
}

@Test func bluetoothNoticeShowsOncePerOutput() {
    var n = BluetoothNotice()
    // Mutating calls stay outside #expect, which takes its operands as constants.
    let launch = n.check(bluetooth: true, sound: true), twice = n.check(bluetooth: true, sound: true)
    #expect(launch && !twice)  // once: not again for the same output (⌘K off and on again included)
    n.outputChanged()
    let wired = n.check(bluetooth: false, sound: true)
    #expect(!wired)  // to wired headphones: nothing to say
    n.outputChanged()
    let back = n.check(bluetooth: true, sound: true)
    #expect(back)  // back to Bluetooth: once more
    var muted = BluetoothNotice()
    let off = muted.check(bluetooth: true, sound: false), on = muted.check(bluetooth: true, sound: true)
    #expect(!off && on)  // muted at launch: nothing to warn about, until the sound is turned on
}

@Test func mutedTextReachesTheHIGsContrastUnderIncreaseContrast() {
    /// WCAG's contrast ratio of two sRGB colours.
    func ratio(_ a: CGColor, _ b: CGColor) -> Double {
        func luminance(_ c: CGColor) -> Double {
            let v = c.components!.prefix(3).map { x -> Double in
                let x = Double(x)
                return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]
        }
        let (x, y) = (luminance(a), luminance(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }
    let background = Style(font: menlo).background
    #expect(Style(font: menlo).muted == Style.muted(increasedContrast: false))
    #expect(abs(ratio(Style.muted(increasedContrast: false), background) - 3.2) < 0.05)  // as designed: below 4.5:1
    #expect(ratio(Style.muted(increasedContrast: true), background) >= 4.5)  // HIG Dark Mode's minimum
}
