// What the app shows around the surface (DESIGN.md W1 K1): the menu-bar mark and when the Bluetooth notice shows. Free
// of AppKit, so the tests check them.
import CoreGraphics

/// The menu-bar mark (W1; DESIGN.md L1, M3 of `docs/design-panel-hypha-logo.html`): the surface in 16 pt, a line with
/// the caret's bar at 60 % of its width, the line tapered toward its left end. Drawn in black on clear; the app marks
/// the image a template, so the menu bar tints it for its appearance. Every straight edge on half points, so they are
/// sharp at 2×; only the taper's edge slants.
public enum StatusMark {
    public static let size = CGSize(width: 16, height: 16)
    /// The line's box: 1.5 pt tall from the caret to its right end.
    public static let line = CGRect(x: 2, y: 7.5, width: 12, height: 1.5)
    /// The line's left end: 1 pt tall along its last 2 pt, against the line's top edge, so that on a 1× display it is
    /// one whole row of pixels (M3's SVG narrows to a point, a grey wisp at 1×). Between it and the caret the line's
    /// bottom edge slants down to the full 1.5 pt.
    public static let tip = CGRect(x: 2, y: 8, width: 2, height: 1)
    /// 8.5 pt tall on the line's middle, its centre at 60 % of the line (to the half point).
    public static let caret = CGRect(x: ((line.minX + Line.caret * line.width - 0.75) * 2).rounded() / 2, y: 4,
                                     width: 1.5, height: 8.5)

    public static func draw(in c: CGContext) {
        c.setFillColor(CGColor(gray: 0, alpha: 1))
        c.addLines(between: [CGPoint(x: tip.minX, y: tip.minY), CGPoint(x: tip.maxX, y: tip.minY),
                             CGPoint(x: caret.minX, y: line.minY), CGPoint(x: line.maxX, y: line.minY),
                             CGPoint(x: line.maxX, y: line.maxY), CGPoint(x: tip.minX, y: line.maxY)])
        c.closePath()
        c.fillPath()
        c.fill(caret)
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
