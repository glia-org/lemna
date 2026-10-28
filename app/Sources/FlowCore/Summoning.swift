// What the app shows around the surface (DESIGN.md W1 K1): the menu-bar mark and when the Bluetooth notice shows. Free
// of AppKit, so the tests check them.
import CoreGraphics

/// The menu-bar mark (W1): the surface in 16 pt, a 1.5 pt line with the caret's bar at 60 % of its width. Drawn in
/// black on clear; the app marks the image a template, so the menu bar tints it for its appearance. Edges on half
/// points, so they are sharp at 2×.
public enum StatusMark {
    public static let size = CGSize(width: 16, height: 16)
    public static let line = CGRect(x: 2, y: 7.5, width: 12, height: 1.5)
    /// 8.5 pt tall on the line's middle, its centre at 60 % of the line (to the half point).
    public static let caret = CGRect(x: ((line.minX + Line.caret * line.width - 0.75) * 2).rounded() / 2, y: 4,
                                     width: 1.5, height: 8.5)

    public static func draw(in c: CGContext) {
        c.setFillColor(CGColor(gray: 0, alpha: 1))
        c.fill([line, caret])
    }
}

/// The Bluetooth notice (K1): Bluetooth output plays every click 120–300 ms late, which no app can shorten, so the
/// surface says so once per output: at launch, after the output changed, or when the sound is turned on, whichever
/// comes first while the output is Bluetooth and the sound is on. With the sound off there is nothing to warn about.
public struct BluetoothNotice {
    public static let text = "Bluetooth output: clicks arrive late · ⌘K mutes"
    private var shown = false

    public init() {}

    /// The default output changed: the next check may show the notice again.
    public mutating func outputChanged() { shown = false }

    /// Whether to show the notice now.
    public mutating func check(bluetooth: Bool, sound: Bool) -> Bool {
        guard bluetooth, sound, !shown else { return false }
        shown = true
        return true
    }
}
