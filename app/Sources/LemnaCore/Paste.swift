// Paste at Done (DESIGN.md O3): whether ⌘⏎ in the box's review pastes into the app behind or copies instead, and what
// the footer then says; since pass 17a also the paste's steps in their order and the wait for Return to come up. Free
// of AppKit, so the tests check them. After a paste Lemna's text stays on the clipboard.

public enum Paste {
    public enum Step: Equatable {
        /// Pasteboard, hide the box, the app behind in front, a posted ⌘V.
        case paste
        /// Copied as Copy does, the footer saying why; `ask`: request the permission to post events first (macOS shows
        /// its Accessibility prompt once; later requests return at once).
        case copy(note: String, ask: Bool)
    }

    public static let secureNote = "Secure input is on: copied instead"
    public static let permissionNote = "Copied · allow Lemna under Privacy & Security › Accessibility to paste"
    public static let noTargetNote = "Copied · no app to paste into"

    /// In this order: Secure Input on (a password field has the keys, and a posted ⌘V would go into it), no permission
    /// to post events (the ⌘V would be dropped without a word), no app to paste into (none was in front at the summon,
    /// or it quit since); else paste.
    public static func decide(secureInput: Bool, mayPost: Bool, hasTarget: Bool) -> Step {
        if secureInput { return .copy(note: secureNote, ask: false) }
        if !mayPost { return .copy(note: permissionNote, ask: true) }
        if !hasTarget { return .copy(note: noTargetNote, ask: false) }
        return .paste
    }

    /// From the box's going to the posted ⌘V, in seconds: the time the app behind gets to have its keys back, and a
    /// password field there to turn Secure Input on again for the check before the ⌘V. `settleInFront` when it was in
    /// front all along (the box never activates Lemna: the usual case), so only the window server's move of the keys
    /// back is waited for; `settle` when it had to be brought forward (after the window or a question Lemna is the
    /// active app), its activation as well. Until pass 17a it was 120 ms in every case.
    public static let settle = 0.12, settleInFront = 0.03

    /// A paste's steps once Return is up (pass 17a), in this order. Nothing slow comes before the ⌘V: finishing the
    /// session (the key deleted from the keychain, the file deleted, the next session's key and file made: 30 ms on
    /// this Mac, up to 90) comes after it, in the same turn, which still finishes the session at once (E2).
    public enum Act: Equatable {
        /// Lemna's text on the pasteboard, as Copy writes it; the session handed off.
        case write
        /// The box off screen at once; its last look, the text as it was handed off, and the dim fade in windows that
        /// take no keys.
        case hide
        /// The app to paste into brought forward; only when it is not in front.
        case bringForward
        /// A wait, in seconds, for it to have its keys back.
        case settle(Double)
        /// Secure Input read again: on, the text stays copied, the session is finished and the box comes back saying
        /// so; no ⌘V.
        case checkSecureInput
        /// ⌘V posted.
        case post
        /// The session finished: key destroyed, journal deleted, the next session's opened, the line cleared.
        case finish
    }

    public static func acts(targetInFront: Bool) -> [Act] {
        [.write, .hide] + (targetInFront ? [.settle(settleInFront)] : [.bringForward, .settle(settle)])
            + [.checkSecureInput, .post, .finish]
    }
}

/// Done and Copy wait for Return to come up before the box goes (O3, pass 6): ⌘⏎ held into the app behind would reach
/// it as auto-repeated ⌘⏎, which sends a message in many apps. The app feeds this the key-ups its local monitor sees
/// (AppKit gives a key-up with ⌘ down to no window, so the box's own `sendEvent` misses Return's whenever ⌘ is still
/// held: until pass 17a every such paste waited the whole second) and, every `poll`, whether the key is still down, in
/// case its key-up went elsewhere. Free of AppKit and of clocks: times are the key event's, in seconds.
public struct ReturnUp {
    /// kVK_Return and kVK_ANSI_KeypadEnter.
    public static let keys: Set<UInt16> = [36, 76]
    /// How often the key's own state is read, in seconds.
    public static let poll = 0.05
    /// The most a key held down keeps the box, in seconds from its key-down (auto-repeat starts at the system's delay
    /// until repeat, 0.5 s here, so a key held past it repeats into Lemna's box, where Done is off).
    public static let cap = 1.0

    public enum Signal: Equatable {
        /// A key-up the monitor saw, with its key code.
        case keyUp(UInt16)
        /// A read of the key's state: whether Return or Enter is still down.
        case check(down: Bool)
    }

    /// Why the wait ended, for the timing log.
    public enum End: Equatable { case keyUp, released, cap }

    /// Whether a hand-off waits at all: only one that a Return or Enter key-down brought (⌘⏎, ⌘⇧⏎, the menu's key
    /// equivalent as much as the box's); Done from the menu-bar item's menu goes at once.
    public static func waits(keyDown: Bool, code: UInt16) -> Bool { keyDown && keys.contains(code) }

    private let start: Double

    /// `start`: the key-down's time.
    public init(at start: Double) { self.start = start }

    /// nil: still waiting.
    public func take(_ signal: Signal, at t: Double) -> End? {
        switch signal {
        case .keyUp(let code) where Self.keys.contains(code): return .keyUp
        case .check(down: false): return .released
        default: return t - start >= Self.cap ? .cap : nil
        }
    }
}
