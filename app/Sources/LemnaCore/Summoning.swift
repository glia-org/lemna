// What the app shows around the surface (DESIGN.md W1 K1 G1): the menu-bar mark, when the Bluetooth notice shows and
// Start at Login's item. Free of AppKit, so the tests check them.
import CoreGraphics

/// The menu-bar mark (W1; DESIGN.md L1, M3 of `docs/design-panel-hypha-logo.html`): the surface in 16 pt, a line with
/// the caret's bar at 60 % of its width, the line tapered toward its left end. Drawn in black on clear; the app marks
/// the image a template, so the menu bar tints it for its appearance. Drawn per scale (Q2 of
/// `docs/design-panel-icon-round-2.html`): the image's drawing handler runs once for each, and the context's scale
/// says which. Every straight edge on half points, so they are sharp at 2×; only the taper's edges slant.
public enum StatusMark {
    public static let size = CGSize(width: 16, height: 16)
    /// The line's box: 1.5 pt tall from the caret to its right end.
    public static let line = CGRect(x: 2, y: 7.5, width: 12, height: 1.5)
    /// The line's left end at 1×: 1 pt tall along its last 2 pt, against the line's top edge, so that it is one whole
    /// row of pixels (M3's point is a grey wisp there). Between it and the caret only the bottom edge slants.
    public static let tip = CGRect(x: 2, y: 8, width: 2, height: 1)
    /// 8.5 pt tall on the line's middle, its centre at 60 % of the line (to the half point).
    public static let caret = CGRect(x: ((line.minX + Line.caret * line.width - 0.75) * 2).rounded() / 2, y: 4,
                                     width: 1.5, height: 8.5)

    public static func draw(in c: CGContext) {
        c.setFillColor(CGColor(gray: 0, alpha: 1))
        // From the caret's left edge to the line's left end: at 2× and up M3 as its SVG has it, narrowing to a point
        // on the line's middle; at 1× down to the 1 pt tip.
        let left = abs(c.userSpaceToDeviceSpaceTransform.a) >= 1.5
            ? [CGPoint(x: caret.minX, y: line.maxY), CGPoint(x: line.minX, y: line.midY)]
            : [CGPoint(x: tip.minX, y: line.maxY), CGPoint(x: tip.minX, y: tip.minY), CGPoint(x: tip.maxX, y: tip.minY)]
        c.addLines(between: left + [CGPoint(x: caret.minX, y: line.minY), CGPoint(x: line.maxX, y: line.minY),
                                    CGPoint(x: line.maxX, y: line.maxY)])
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

/// Start at Login in the menu-bar item's menu (Y1): its title, its tick and what choosing it does, from the login
/// item's status as the app reads it from ServiceManagement each time the menu opens (System Settings › General › Login
/// Items can change it meanwhile). Waiting for approval there, it stays ticked and choosing it opens that pane.
public struct LoginItem {
    /// `SMAppService.Status`; its `notFound` counts as not registered.
    public enum Status { case notRegistered, enabled, requiresApproval }
    public enum Act { case register, unregister, openSettings }

    public let title: String
    public let ticked: Bool
    public let act: Act

    public init(_ status: Status) {
        switch status {
        case .notRegistered: (title, ticked, act) = ("Start at Login", false, .register)
        case .enabled: (title, ticked, act) = ("Start at Login", true, .unregister)
        case .requiresApproval:
            (title, ticked, act) = ("Start at Login (approve in System Settings)", true, .openSettings)
        }
    }
}
