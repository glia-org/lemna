// What surrounds the surface (W1 K1): the menu-bar mark, the Bluetooth notice and the muted colour.
import CoreGraphics
import Darwin
import Testing
@testable import FlowCore

@Test func statusMarkIsALineWithTheCaretAt60Percent() {
    #expect(StatusMark.size == CGSize(width: 16, height: 16))
    let (w, h) = (32, 32)  // 16 × 16 pt at 2×
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    StatusMark.draw(in: c)
    let px = c.data!.assumingMemoryBound(to: UInt8.self)
    /// The alpha at a point in points (the bitmap's first row is its top).
    func ink(_ x: CGFloat, _ y: CGFloat) -> UInt8 { px[4 * ((h - 1 - Int(y * 2)) * w + Int(x * 2)) + 3] }
    #expect(ink(4, 8.25) == 255 && ink(12.5, 8.25) == 255)  // the line, on both sides of the caret
    #expect(ink(9.25, 11) == 255 && ink(9.25, 5) == 255)  // the caret's bar, above and below the line
    #expect(ink(4, 11) == 0 && ink(12.5, 11) == 0 && ink(9.25, 14) == 0 && ink(9.25, 1) == 0)
    // Above the line only the caret is inked, its middle at 60 % of the line.
    let columns = (0..<w).filter { px[4 * ((h - 1 - 22) * w + $0) + 3] > 0 }
    let middle = (CGFloat(columns.min()!) + CGFloat(columns.max()!) + 1) / 4  // in points
    #expect(abs((middle - StatusMark.line.minX) / StatusMark.line.width - 0.6) < 0.01)
    #expect(columns.count == 3)  // 1.5 pt
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
