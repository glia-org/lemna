// Paste at Done (DESIGN.md O3): whether ⌘⏎ in the box's review pastes into the app behind or copies instead, and what
// the footer then says. Free of AppKit, so the tests check them. After a paste Lemna's text stays on the clipboard.

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

    /// From the app's activation to the posted ⌘V, in seconds.
    public static let settle = 0.12
}
