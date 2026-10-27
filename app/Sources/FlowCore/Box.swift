// The box (DESIGN.md W2): where it sits on the screen, how the review grows it in place, and which of the two
// containers holds the line. Free of AppKit, so the tests check them.
import CoreGraphics

/// The box's frame in screen points (origin at the bottom left, as AppKit's).
public enum BoxFrame {
    /// The box's share of the visible frame's width, and its narrowest: v1's window was at least 600 pt wide, which the
    /// review's 72-character column fits.
    public static let share: CGFloat = 0.6, narrowest: CGFloat = 600
    /// The review grows the box to this share of the visible frame's height, and to at least v1's shortest sheet.
    public static let grownShare: CGFloat = 0.6, grownLeast: CGFloat = 240

    /// One line tall plus margins: the line's band (two em, `Line.band`) with one em above and below it.
    public static func height(fontSize: CGFloat) -> CGFloat { 4 * fontSize }

    /// The box over `visible` (the active screen's frame less the menu bar and the Dock): 60 % of its width, but not
    /// under 600 pt nor wider than it; `height` tall, but not taller than it; centred across, its centre two thirds of
    /// the way down (the lower third); on whole points and inside `visible`.
    public static func line(in visible: CGRect, height: CGFloat) -> CGRect {
        let w = min(max((share * visible.width).rounded(), narrowest), visible.width), h = min(height, visible.height)
        let x = (visible.midX - w / 2).rounded(), y = (visible.minY + visible.height / 3 - h / 2).rounded()
        return CGRect(x: max(x, visible.minX), y: min(max(y, visible.minY), visible.maxY - h), width: w, height: h)
    }

    /// The review's box: `box` grown upward with its bottom edge where it was, to 60 % of the visible height (at least
    /// 240 pt), its top kept inside `visible`, never shorter than the box was.
    public static func grown(_ box: CGRect, in visible: CGRect) -> CGRect {
        let want = max((grownShare * visible.height).rounded(), grownLeast)
        return CGRect(x: box.minX, y: box.minY, width: box.width, height: max(min(want, visible.maxY - box.minY), box.height))
    }

    /// Back from the review: the line's box again, from the same bottom edge up.
    public static func shrunk(_ box: CGRect, height: CGFloat) -> CGRect {
        CGRect(x: box.minX, y: box.minY, width: box.width, height: height)
    }
}

/// Which container holds the line: the box over whatever the user is doing, or v1's window for long sessions. At most
/// one is on screen; the one not in use is never shown.
public struct Surface: Equatable {
    public enum Container: Equatable { case box, window }
    /// Where the line lives now.
    public private(set) var mode = Container.box
    public private(set) var shown = false

    public init() {}

    /// The container on screen, if any.
    public var onScreen: Container? { shown ? mode : nil }

    /// The hotkey and Show Flow: away when the container on screen has the keys, else on screen with them (a box left
    /// on screen after a click into another app comes back to the keys rather than going).
    public mutating func toggle(focused: Bool) { shown = !(shown && focused) }

    /// Done from the menu-bar item, a question, a reopen: on screen.
    public mutating func show() { shown = true }

    /// Esc in the box, a paste, the hotkey: off screen; the session stays.
    public mutating func hide() { shown = false }

    /// Open Window (⌃⌘F) and back, and the window's close button: the line moves to `c`, which comes on screen.
    public mutating func use(_ c: Container) { (mode, shown) = (c, true) }
}
