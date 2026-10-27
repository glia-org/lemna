// What the app shows around the surface (DESIGN.md W1 K1 O1): the menu-bar mark, when the Bluetooth notice shows,
// and what a key does in the review sheet. Free of AppKit, so the tests check them.
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

/// What a key does in the review sheet. Plain Return does nothing: a reflexive Return after Done replaced the
/// clipboard and started the grace. ⌘⏎, Done's own chord, copies, so ⌘⏎ twice is done and copied; its auto-repeat
/// does not, so ⌘⏎ held a little long after Done does not copy. Esc is Back.
public enum ReviewKey: Equatable {
    case copy, back
    /// Swallowed: the read-only text would otherwise take it and do nothing.
    case nothing
    /// Not the sheet's: the panel handles it as usual.
    case pass

    /// `keyCode`: 36 Return, 76 keypad Enter, 53 Esc. `command`: ⌘ is down; `others`: ⌥, ⌃ or ⇧ is.
    public static func route(keyCode: UInt16, command: Bool, others: Bool, isRepeat: Bool) -> ReviewKey {
        switch keyCode {
        case 36, 76:
            if others { return .pass }
            return command && !isRepeat ? .copy : .nothing
        case 53:
            return command || others ? .pass : .back
        default:
            return .pass
        }
    }
}
