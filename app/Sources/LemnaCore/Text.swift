// The writing as one string, paragraphs apart by "\n", with a caret anywhere in it and a selection from an anchor to
// the caret (DESIGN.md S1 B4 P0; the selection since pass 29), rebuilt from the journal's edits (E2). One unit
// everywhere: Characters (the caret, the anchor, the journal's offsets, the line's parts), so a letter with its accent
// or an emoji is one step of ← and one ⌫.
import LemnaJournal
import Foundation

public struct Text: Equatable {
    /// The text, a paragraph end as "\n": for the journal and the output.
    public private(set) var plainText: String
    /// Characters before the caret, 0 … `count`.
    public private(set) var caret: Int
    /// The selection's fixed end (B4, pass 29), in Characters; the caret is its moving end, where ⇧ with a move takes
    /// it. Nil when nothing is selected, never the caret itself. Any edit ends it; the journal never sees it.
    public private(set) var anchor: Int?
    /// `plainText.count`, kept: a String counts its Characters by walking them.
    public private(set) var count: Int
    /// The caret as an index into `plainText`, kept for the same reason, so a step of the caret walks one Character.
    private var at: String.Index

    public init(_ text: String = "", caret: Int? = nil) {
        plainText = text
        count = text.count
        self.caret = min(max(caret ?? count, 0), count)
        at = text.index(text.startIndex, offsetBy: self.caret)
    }

    public static func == (a: Text, b: Text) -> Bool {
        a.plainText == b.plainText && a.caret == b.caret && a.anchor == b.anchor
    }

    /// The paragraphs; the last one may be empty.
    public var paragraphs: [String] { plainText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) }

    /// The caret in UTF-16 units: the text input system indexes the document in these.
    public var utf16Caret: Int { plainText.utf16.distance(from: plainText.startIndex, to: at) }

    /// The selected Characters, from the anchor to the caret whichever comes first; empty, at the caret, when nothing
    /// is selected.
    public var selection: Range<Int> { anchor.map { min($0, caret)..<max($0, caret) } ?? caret..<caret }

    /// The selection as text, for ⌘C and ⌘X; "" when nothing is selected.
    public var selectedText: String { String(plainText[index(selection.lowerBound)..<index(selection.upperBound)]) }

    /// The selection in UTF-16 units, for the text input system's `selectedRange`.
    public var utf16Selection: Range<Int> {
        let (lo, hi) = (index(selection.lowerBound), index(selection.upperBound)), u = plainText.utf16
        let start = u.distance(from: plainText.startIndex, to: lo)
        return start..<start + u.distance(from: lo, to: hi)
    }

    // MARK: Keys

    /// Typing at the caret, which ends after `s`; a newline of any kind in it is a paragraph end. `replacing`: first
    /// take the Characters that hold the last `n` UTF-16 units before the caret (the press-and-hold accent menu
    /// replaces the letter just typed, and names it in the input system's units). A selection is replaced instead
    /// (pass 29): taken first, as ⌫ or ⌦ takes it, then `s` typed where it was; `n` is then not used.
    @discardableResult
    public mutating func insert(_ s: String, replacing n: Int = 0) -> Change {
        let s = String(s.map { $0.isNewline ? "\n" : $0 })
        var change = Change(), removed = ""
        if let cut = deleteSelection() {
            if s.isEmpty { return cut }
            change.edits = cut.edits
            if case .before(_, let r) = cut.motion { removed = r }  // a selection after the caret closed up at once
        } else if n > 0 {
            var start = at, units = 0
            while units < n, start > plainText.startIndex {
                start = plainText.index(before: start)
                units += plainText[start].utf16.count
            }
            removed = String(plainText[start..<at])
            if !removed.isEmpty { change.edits.append(apply(.delete(at: caret - removed.count, count: removed.count))) }
        }
        if !s.isEmpty { change.edits.append(apply(.insert(at: caret, s))) }
        if !change.edits.isEmpty { change.motion = .before(added: s, removed: removed) }
        return change
    }

    /// ⌫: the Character before the caret, across spaces and paragraph ends alike (B4); at the start, nothing. With a
    /// selection, the selection (pass 29), and so for the three below.
    @discardableResult
    public mutating func deleteBackward() -> Change { deleteSelection() ?? cutBackward(to: max(caret - 1, 0)) }

    /// ⌥⌫: back to where ⌥← lands.
    @discardableResult
    public mutating func deleteWordBackward() -> Change {
        deleteSelection() ?? cutBackward(to: wordLeft(from: (at, caret)).offset)
    }

    /// ⌦: the Character after the caret; at the end, nothing.
    @discardableResult
    public mutating func deleteForward() -> Change { deleteSelection() ?? cutForward(to: min(caret + 1, count)) }

    /// ⌥⌦: on to where ⌥→ lands.
    @discardableResult
    public mutating func deleteWordForward() -> Change {
        deleteSelection() ?? cutForward(to: wordRight(from: (at, caret)).offset)
    }

    // Every move below takes `extending` (pass 29): with ⇧ the caret goes as it would and the anchor stays (set where
    // the caret was when nothing was selected), so the selection grows or shrinks at the caret, gone where the caret
    // comes back to the anchor. Without ⇧ a selection collapses as in a Mac text field: the move starts from the
    // selection's end on its side, its start for a leftward one, its end for a rightward one, and ← and → stop there.

    /// ← and →: one Character, a paragraph end included (it shows as ` ¶ `).
    @discardableResult
    public mutating func moveLeft(extending: Bool = false) -> Change {
        go(leftward: true, extending: extending, stopsAtSelection: true) { t, p in
            p.offset > 0 ? (t.plainText.index(before: p.index), p.offset - 1) : p
        }
    }
    @discardableResult
    public mutating func moveRight(extending: Bool = false) -> Change {
        go(leftward: false, extending: extending, stopsAtSelection: true) { t, p in
            p.offset < t.count ? (t.plainText.index(after: p.index), p.offset + 1) : p
        }
    }

    /// ⌥← and ⌥→: words are runs between white space of any kind (⌥Space's no-break space and a paragraph end
    /// included). ⌥← goes back over white space and then the word before it, to its start; ⌥→ on over white space and
    /// the next word, to its end, as in a Mac text field.
    @discardableResult
    public mutating func moveWordLeft(extending: Bool = false) -> Change {
        go(leftward: true, extending: extending) { t, p in t.wordLeft(from: p) }
    }
    @discardableResult
    public mutating func moveWordRight(extending: Bool = false) -> Change {
        go(leftward: false, extending: extending) { t, p in t.wordRight(from: p) }
    }

    /// ⌘← and ⌘→: the paragraph's start (just after the paragraph end before the caret) or its end (just before the
    /// next one). Already there: nothing.
    @discardableResult
    public mutating func moveToParagraphStart(extending: Bool = false) -> Change {
        go(leftward: true, extending: extending) { t, p in
            var (i, n) = p
            while i > t.plainText.startIndex, t.plainText[t.plainText.index(before: i)] != "\n" {
                (i, n) = (t.plainText.index(before: i), n - 1)
            }
            return (i, n)
        }
    }
    @discardableResult
    public mutating func moveToParagraphEnd(extending: Bool = false) -> Change {
        go(leftward: false, extending: extending) { t, p in
            var (i, n) = p
            while i < t.plainText.endIndex, t.plainText[i] != "\n" { (i, n) = (t.plainText.index(after: i), n + 1) }
            return (i, n)
        }
    }

    /// ⌘A: the whole text, the anchor at its start and the caret at its end, so the text glides as a ⌘→ to the end
    /// would; the box keeps the caret at its place (S1). An empty text selects nothing.
    @discardableResult
    public mutating func selectAll() -> Change {
        guard count > 0 else { return Change() }
        let had = anchor
        anchor = 0
        return settled(move(to: plainText.endIndex, count), had: had)
    }

    // MARK: The journal

    /// One journal edit applied, the caret staying with the text after it (and after text typed at it). The replay
    /// goes through here, and so does every key that changes the text, so a restore rebuilds exactly what was typed.
    /// Offsets past the text are clamped. Returns the edit, for the key's `Change`. It ends a selection.
    @discardableResult
    public mutating func apply(_ edit: Edit) -> Edit {
        let old = count
        anchor = nil
        switch edit {
        case .insert(let i, let s):
            let i = min(max(i, 0), count)
            plainText.insert(contentsOf: s, at: index(i))
            count = plainText.count
            if i <= caret { caret += count - old }  // less than s.count where s joins a neighbour into one Character
        case .delete(let i, let n):
            let i = min(max(i, 0), count), j = min(i + max(n, 0), count)
            guard j > i else { return edit }
            let lo = index(i)
            plainText.removeSubrange(lo..<plainText.index(lo, offsetBy: j - i))
            count = plainText.count
            if caret > i { caret = max(i, caret - (j - i)) }
        }
        caret = min(caret, count)
        at = plainText.index(plainText.startIndex, offsetBy: caret)
        return edit
    }

    /// The text a journal's edits leave, the caret at its end (moves are not journaled): the silent restore at launch.
    public init(replaying edits: [Edit]) {
        self.init()
        for e in edits { apply(e) }
        (caret, at) = (count, plainText.endIndex)
    }

    // MARK: The line

    /// A part of the line: its text, whether it is a paragraph end's ` ¶ ` (muted), whether it is selected.
    public typealias Run = (text: String, muted: Bool, selected: Bool)

    /// What the line shows around the caret: up to `n` Characters before it and `n` after it, each paragraph end as
    /// ` ¶ ` (muted), the selection's part of them marked. Only these can be on screen, so the rest is never shaped;
    /// the anchor may lie beyond them.
    public func line(around n: Int) -> (before: [Run], after: [Run]) {
        let lo = plainText.index(at, offsetBy: -n, limitedBy: plainText.startIndex) ?? plainText.startIndex
        let hi = plainText.index(at, offsetBy: n, limitedBy: plainText.endIndex) ?? plainText.endIndex
        var (from, to) = (at, at)  // the selection inside lo..<hi: before the caret or after it
        if let a = anchor, a < caret { from = plainText.index(at, offsetBy: a - caret, limitedBy: lo) ?? lo }
        if let a = anchor, a > caret { to = plainText.index(at, offsetBy: a - caret, limitedBy: hi) ?? hi }
        return (Self.runs(plainText[lo..<from], selected: false) + Self.runs(plainText[from..<at], selected: true),
                Self.runs(plainText[at..<to], selected: true) + Self.runs(plainText[to..<hi], selected: false))
    }

    private static func runs(_ s: Substring, selected: Bool) -> [Run] {
        var out: [Run] = []
        for (k, part) in s.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            if k > 0 { out.append((Line.paragraphEnd, true, selected)) }
            if !part.isEmpty { out.append((String(part), false, selected)) }
        }
        return out
    }

    // MARK: Inside

    /// The index of Character `i`, walked from the caret: a key's edit is at it or next to it.
    private func index(_ i: Int) -> String.Index { plainText.index(at, offsetBy: i - caret) }

    private mutating func move(to i: String.Index, _ n: Int) -> Change {
        guard n != caret else { return Change() }
        let leftward = n < caret, passed = String(leftward ? plainText[i..<at] : plainText[at..<i])
        (at, caret) = (i, n)
        return Change(motion: .caret(passed: passed, leftward: leftward))
    }

    /// A place in the text: its index and its offset in Characters.
    private typealias Place = (index: String.Index, offset: Int)

    /// A move by `step` from the caret, or with ⇧ (`extending`) the selection's moving end; without it a selection
    /// collapses (the comment above `moveLeft`), and with `stopsAtSelection` (← and →) the move ends at its side.
    private mutating func go(leftward: Bool, extending: Bool, stopsAtSelection: Bool = false,
                             _ step: (Text, Place) -> Place) -> Change {
        let had = anchor
        var from: Place = (at, caret), stop = false
        if !extending, let a = anchor {
            let side = leftward ? min(a, caret) : max(a, caret)
            (from, stop) = ((index(side), side), stopsAtSelection)
        }
        anchor = extending ? anchor ?? caret : nil
        let to = stop ? from : step(self, from)
        return settled(move(to: to.index, to.offset), had: had)
    }

    /// A move's change, the anchor dropped where the caret came back to it; `.selected` when only the selection
    /// changed (a collapse at the caret's own side, ⌘A with the caret at the end already), so the line draws it.
    private mutating func settled(_ change: Change, had: Int?) -> Change {
        if anchor == caret { anchor = nil }
        return change.motion == .none && anchor != had ? Change(motion: .selected) : change
    }

    /// The selection taken, as ⌫ takes what lies before the caret (the caret at its end) and ⌦ what lies after it (at
    /// its start): one delete edit; nil when nothing is selected.
    private mutating func deleteSelection() -> Change? {
        guard let a = anchor else { return nil }
        return a < caret ? cutBackward(to: a) : cutForward(to: a)
    }

    private mutating func cutBackward(to n: Int) -> Change {
        guard n < caret else { return Change() }
        let removed = String(plainText[index(n)..<at])
        return Change(edits: [apply(.delete(at: n, count: caret - n))], motion: .before(added: "", removed: removed))
    }

    private mutating func cutForward(to n: Int) -> Change {
        guard n > caret else { return Change() }
        let removed = String(plainText[at..<index(n)])
        return Change(edits: [apply(.delete(at: caret, count: n - caret))], motion: .after(removed: removed))
    }

    private func wordLeft(from p: Place) -> Place {
        var (i, n) = p
        for inWord in [false, true] {  // over white space first, then over the word
            while i > plainText.startIndex, plainText[plainText.index(before: i)].isWhitespace != inWord {
                (i, n) = (plainText.index(before: i), n - 1)
            }
        }
        return (i, n)
    }

    private func wordRight(from p: Place) -> Place {
        var (i, n) = p
        for inWord in [false, true] {
            while i < plainText.endIndex, plainText[i].isWhitespace != inWord {
                (i, n) = (plainText.index(after: i), n + 1)
            }
        }
        return (i, n)
    }
}

/// What a key did: the journal's edits, and what the line needs to move (S1 B4).
public struct Change: Equatable {
    public enum Motion: Equatable {
        /// Nothing changed (⌫ at the start, → at the end): no click, no frame.
        case none
        /// The text before the caret gained `added` and lost `removed` at its end: that part glides, out from under
        /// the caret for an insertion, back for a deletion.
        case before(added: String, removed: String)
        /// The text after the caret lost `removed` at its start: that part closes up at once, since a glide would move
        /// text the eye rests on.
        case after(removed: String)
        /// The caret passed over `passed`, leftwards or rightwards: the whole text glides by its width, so the caret
        /// stays where it is.
        case caret(passed: String, leftward: Bool)
        /// Only the selection changed, the caret stayed (pass 29): the line draws again, nothing moves, no click.
        case selected
    }

    /// In order; empty when the key changed no text (a caret move is not journaled).
    public var edits: [Edit]
    public var motion: Motion

    public init(edits: [Edit] = [], motion: Motion = .none) {
        self.edits = edits
        self.motion = motion
    }
}
