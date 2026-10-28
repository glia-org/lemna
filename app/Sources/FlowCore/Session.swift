// The end of a session (DESIGN.md O1 O2 O3 E2) as a state machine, free of AppKit and of clocks so the tests drive it:
// writing → handing off (Done, Copy or Save…: the keys stop) → cleared (pasted, copied or saved: finished at once; or
// discarded) → writing. Each event returns whether it applied; the app acts only on true, so a second ⌘⏎ or a late
// callback does nothing.

public enum Phase: Equatable {
    /// The surface takes keys.
    case writing
    /// Done, Copy or Save… is under way (Paste waits for Return to come up, the save panel is up); the surface keeps
    /// its last frame.
    case handingOff
    /// Finished or discarded: the key is gone, the surface clears and a new session starts.
    case cleared
}

public struct Session: Equatable {
    public private(set) var phase = Phase.writing

    public init() {}

    /// Done, Copy or Save…: the hand-off begins.
    @discardableResult public mutating func handOff() -> Bool {
        guard phase == .writing else { return false }
        phase = .handingOff
        return true
    }

    /// The hand-off did not happen (the save panel cancelled, the pasteboard refused): writing goes on and nothing is
    /// destroyed.
    @discardableResult public mutating func back() -> Bool {
        guard phase == .handingOff else { return false }
        phase = .writing
        return true
    }

    /// Pasted, copied or saved: the session is finished at once, with no grace (2026-10-28); the app finishes the
    /// journal and clears.
    @discardableResult public mutating func handedOff() -> Bool {
        guard phase == .handingOff else { return false }
        phase = .cleared
        return true
    }

    /// Discard, once confirmed (the menu-bar item's Discard…), while writing.
    @discardableResult public mutating func discard() -> Bool {
        guard phase == .writing else { return false }
        phase = .cleared
        return true
    }

    /// The key store refused to let go of the key: the session stays and writing goes on; an alert says why.
    @discardableResult public mutating func kept() -> Bool {
        guard phase == .cleared else { return false }
        phase = .writing
        return true
    }

    /// The surface is clear and a new session begins.
    @discardableResult public mutating func started() -> Bool {
        guard phase == .cleared else { return false }
        phase = .writing
        return true
    }
}
