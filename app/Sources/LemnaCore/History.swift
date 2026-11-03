// ⌘Z and ⌘⇧Z (DESIGN.md B4, pass 30): the undo stack, beside the text and never in the journal. A group is the text as
// it stood before some keys and as they left it; ⌘Z makes the text the one before again, ⌘⇧Z the one after, through
// `Text.become`, which takes the journal's ordinary delete and insert: the journal stays the truth, and its replay
// shows what the screen showed. Not NSUndoManager: free of AppKit, so the tests drive it as the line does.

public struct History {
    /// How a key's edit joins the group before it.
    public enum Kind: Equatable {
        /// Typing: glyphs and spaces, the accent menu's pick, pending text committed. Joins the typing before it.
        case typing
        /// ⌫, ⌦, ⌥⌫, ⌥⌦. Joins the deletes before it.
        case deleting
        /// ⌘V, Return, ⇧⏎, ⌘X: a group of its own, which nothing joins.
        case alone
    }

    /// A pause this long or longer between two keys of a group closes it, so the next key starts one: 1 s, about four
    /// times the gap between the keys of steady typing (about 240 ms, DESIGN.md G1 H1), so one ⌘Z takes back one burst
    /// of typing, not all the bursts since the caret last moved (a Mac text view's group runs until the caret moves).
    public static let pause = 1.0

    /// The text before the group's first key and after its last, the group's kind, and when its last key came.
    private struct Group { var before: Text, after: Text, kind: Kind, last: Double }
    private var undos: [Group] = [], redos: [Group] = []
    /// Whether the last group takes the next key of its kind: not after ⌘Z, ⌘⇧Z, a move or a group of its own.
    private var open = false

    public init() {}

    /// A key's change, from the text `before` it to the text `after` it, at `t` (seconds, a clock that only goes on).
    /// It joins the last group when that is open, of its kind (not `alone`), ended where this key starts (the same
    /// text, caret and selection: a selection replaced starts a group, which the typing after it joins) and less than
    /// `pause` ago; else it starts a group. Any edit ends what ⌘⇧Z could bring back. A change without edits: nothing.
    public mutating func record(_ change: Change, from before: Text, to after: Text, kind: Kind, at t: Double) {
        guard !change.edits.isEmpty else { return }
        redos.removeAll()
        if open, kind != .alone, let last = undos.last, last.kind == kind, last.after == before,
           t - last.last < Self.pause {
            (undos[undos.count - 1].after, undos[undos.count - 1].last) = (after, t)
        } else {
            undos.append(Group(before: before, after: after, kind: kind, last: t))
        }
        open = kind != .alone
    }

    /// A move or a change of the selection: the next key starts a group.
    public mutating func close() { open = false }

    /// ⌘Z: the text, its caret and its selection as they stood before the last group, by `Text.become`'s edits; nothing
    /// when there is none.
    public mutating func undo(_ text: inout Text) -> Change {
        guard let g = undos.popLast() else { return Change() }
        redos.append(g)
        open = false
        return text.become(g.before)
    }

    /// ⌘⇧Z: the group ⌘Z took back, again, the caret where its last key left it; nothing when there is none.
    public mutating func redo(_ text: inout Text) -> Change {
        guard let g = redos.popLast() else { return Change() }
        undos.append(g)
        open = false
        return text.become(g.after)
    }
}
