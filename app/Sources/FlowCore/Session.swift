// The end of a session (DESIGN.md O1 O2 E2) as a state machine, free of AppKit and of clocks so the tests drive it:
// writing → review (Done) → graced (copied or saved: finished at `until` unless undone) → cleared → writing.
// Each event returns whether it applied; the app acts only on true, so a stale timer or a second click does nothing.

public enum Handoff: Equatable {
    case copied
    case saved(name: String)
}

public enum Phase: Equatable {
    /// The surface takes keys.
    case writing
    /// The review is up; the surface keeps its last frame.
    case review
    /// Copied or saved: the session is finished at `until` unless Undo comes first.
    case graced(Handoff, until: Double)
    /// Finished or discarded: the key is gone, the surface clears and a new session starts.
    case cleared
}

public struct Session: Equatable {
    /// How long a hand-off can be undone before the session is finished (the plan's "shred after a confirmed hand-off
    /// with an undo grace").
    public static let grace = 10.0
    public private(set) var phase = Phase.writing

    public init() {}

    /// Done: the review opens.
    @discardableResult public mutating func done() -> Bool {
        guard phase == .writing else { return false }
        phase = .review
        return true
    }

    /// Back: writing goes on and nothing is destroyed, a running grace included.
    @discardableResult public mutating func back() -> Bool {
        guard phase == .review || isGraced else { return false }
        phase = .writing
        return true
    }

    /// Copied or saved at `t`. Another hand-off during a grace starts it again.
    @discardableResult public mutating func handedOff(_ how: Handoff, at t: Double) -> Bool {
        guard phase == .review || isGraced else { return false }
        phase = .graced(how, until: t + Self.grace)
        return true
    }

    /// Undo within the grace: the review stays and the session is kept.
    @discardableResult public mutating func undo() -> Bool {
        guard isGraced else { return false }
        phase = .review
        return true
    }

    /// The clock at `t`: true once, when the grace has run out; the app then finishes the journal and clears.
    @discardableResult public mutating func tick(at t: Double) -> Bool {
        guard case .graced(_, let until) = phase, t >= until else { return false }
        phase = .cleared
        return true
    }

    /// Discard, once confirmed: from the surface (Session › Discard…) or the review.
    @discardableResult public mutating func discard() -> Bool {
        guard phase != .cleared else { return false }
        phase = .cleared
        return true
    }

    /// The key store refused to let go of the key: the session stays, and the review shows why.
    @discardableResult public mutating func kept() -> Bool {
        guard phase == .cleared else { return false }
        phase = .review
        return true
    }

    /// The surface is clear and a new session begins.
    @discardableResult public mutating func started() -> Bool {
        guard phase == .cleared else { return false }
        phase = .writing
        return true
    }

    private var isGraced: Bool {
        if case .graced = phase { return true }
        return false
    }

    /// A duration for the review: "< 1 min", "12 min", "1 h 5 min", "2 h"; minutes rounded down.
    public static func duration(_ seconds: Double) -> String {
        let m = Int(max(seconds, 0) / 60)
        if m < 1 { return "< 1 min" }
        if m < 60 { return "\(m) min" }
        return m % 60 == 0 ? "\(m / 60) h" : "\(m / 60) h \(m % 60) min"
    }
}
