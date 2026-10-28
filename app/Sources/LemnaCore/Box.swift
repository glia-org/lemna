// The box (DESIGN.md W2): where it sits on the screen, which of the two containers holds the line, and when a click
// outside hides it. Free of AppKit, so the tests check them.
import CoreGraphics

/// The box's frame in screen points (origin at the bottom left, as AppKit's).
public enum BoxFrame {
    /// The box's share of the visible frame's width, and its narrowest: v1's window was at least 600 pt wide.
    public static let share: CGFloat = 0.6, narrowest: CGFloat = 600

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

    /// The hotkey and Show Lemna: away when the container on screen has the keys, else on screen with them (a box left
    /// on screen after a click into another app comes back to the keys rather than going).
    public mutating func toggle(focused: Bool) { shown = !(shown && focused) }

    /// Done from the menu-bar item, a question, a reopen: on screen.
    public mutating func show() { shown = true }

    /// Esc in the box, a paste, the hotkey: off screen; the session stays.
    public mutating func hide() { shown = false }

    /// Open Window (⌃⌘F) and back, and the window's close button: the line moves to `c`, which comes on screen.
    public mutating func use(_ c: Container) { (mode, shown) = (c, true) }
}

/// A click outside the box (into another app, also through the dim) takes the keys from it, and then the box goes, as
/// with Esc; the session stays. But the box loses the keys for other reasons too, so this guards the hide: when it is
/// already going or not on screen (Esc, the hotkey, a paste, window mode), when a question of Lemna's is up or a sheet
/// hangs on it (Discard…, Save…, the journal's alert: the sheet took the keys), and when another window of Lemna's has
/// the keys.
public enum ClickOutside {
    public static func hides(boxOnScreen: Bool, asking: Bool, sheet: Bool, lemnaHasKeys: Bool) -> Bool {
        boxOnScreen && !asking && !sheet && !lemnaHasKeys
    }
}
