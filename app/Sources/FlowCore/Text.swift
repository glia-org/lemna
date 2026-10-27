// The writing as one string, paragraphs apart by "\n", with a caret anywhere in it (DESIGN.md S1 B4 P0), rebuilt from
// the journal's edits (E2). One unit everywhere: Characters (the caret, the journal's offsets, the line's parts), so a
// letter with its accent or an emoji is one step of ← and one ⌫.
import FlowJournal
import Foundation

public struct Text: Equatable {
    /// The text, a paragraph end as "\n": for the journal, the review and the output.
    public private(set) var plainText: String
    /// Characters before the caret, 0 … `count`.
    public private(set) var caret: Int
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

    public static func == (a: Text, b: Text) -> Bool { a.plainText == b.plainText && a.caret == b.caret }

    /// The paragraphs; the last one may be empty.
    public var paragraphs: [String] { plainText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) }

    /// The caret in UTF-16 units: the text input system indexes the document in these.
    public var utf16Caret: Int { plainText.utf16.distance(from: plainText.startIndex, to: at) }

    // MARK: Keys

    /// Typing at the caret, which ends after `s`; a newline of any kind in it is a paragraph end. `replacing`: first
    /// take the Characters that hold the last `n` UTF-16 units before the caret (the press-and-hold accent menu
    /// replaces the letter just typed, and names it in the input system's units).
    @discardableResult
    public mutating func insert(_ s: String, replacing n: Int = 0) -> Change {
        let s = String(s.map { $0.isNewline ? "\n" : $0 })
        var change = Change(), removed = ""
        if n > 0 {
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

    /// ⌫: the Character before the caret, across spaces and paragraph ends alike (B4); at the start, nothing.
    @discardableResult
    public mutating func deleteBackward() -> Change { cutBackward(to: max(caret - 1, 0)) }

    /// ⌥⌫: back to where ⌥← lands.
    @discardableResult
    public mutating func deleteWordBackward() -> Change { cutBackward(to: wordLeft().offset) }

    /// ⌦: the Character after the caret; at the end, nothing.
    @discardableResult
    public mutating func deleteForward() -> Change { cutForward(to: min(caret + 1, count)) }

    /// ⌥⌦: on to where ⌥→ lands.
    @discardableResult
    public mutating func deleteWordForward() -> Change { cutForward(to: wordRight().offset) }

    /// ← and →: one Character, a paragraph end included (it shows as ` ¶ `).
    @discardableResult
    public mutating func moveLeft() -> Change {
        caret > 0 ? move(to: plainText.index(before: at), caret - 1) : Change()
    }
    @discardableResult
    public mutating func moveRight() -> Change {
        caret < count ? move(to: plainText.index(after: at), caret + 1) : Change()
    }

    /// ⌥← and ⌥→: words are runs between white space of any kind (⌥Space's no-break space and a paragraph end
    /// included). ⌥← goes back over white space and then the word before it, to its start; ⌥→ on over white space and
    /// the next word, to its end, as in a Mac text field.
    @discardableResult
    public mutating func moveWordLeft() -> Change { let w = wordLeft(); return move(to: w.index, w.offset) }
    @discardableResult
    public mutating func moveWordRight() -> Change { let w = wordRight(); return move(to: w.index, w.offset) }

    /// ⌘← and ⌘→: the paragraph's start (just after the paragraph end before the caret) or its end (just before the
    /// next one). Already there: nothing.
    @discardableResult
    public mutating func moveToParagraphStart() -> Change {
        var (i, n) = (at, caret)
        while i > plainText.startIndex, plainText[plainText.index(before: i)] != "\n" {
            (i, n) = (plainText.index(before: i), n - 1)
        }
        return move(to: i, n)
    }
    @discardableResult
    public mutating func moveToParagraphEnd() -> Change {
        var (i, n) = (at, caret)
        while i < plainText.endIndex, plainText[i] != "\n" { (i, n) = (plainText.index(after: i), n + 1) }
        return move(to: i, n)
    }

    // MARK: The journal

    /// One journal edit applied, the caret staying with the text after it (and after text typed at it). The replay
    /// goes through here, and so does every key that changes the text, so a restore rebuilds exactly what was typed.
    /// Offsets past the text are clamped. Returns the edit, for the key's `Change`.
    @discardableResult
    public mutating func apply(_ edit: Edit) -> Edit {
        let old = count
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

    /// What the line shows around the caret: up to `n` Characters before it and `n` after it, each paragraph end as
    /// ` ¶ ` (muted). Only these can be on screen, so the rest is never shaped.
    public func line(around n: Int) -> (before: [(text: String, muted: Bool)], after: [(text: String, muted: Bool)]) {
        let lo = plainText.index(at, offsetBy: -n, limitedBy: plainText.startIndex) ?? plainText.startIndex
        let hi = plainText.index(at, offsetBy: n, limitedBy: plainText.endIndex) ?? plainText.endIndex
        return (Self.runs(plainText[lo..<at]), Self.runs(plainText[at..<hi]))
    }

    private static func runs(_ s: Substring) -> [(text: String, muted: Bool)] {
        var out: [(text: String, muted: Bool)] = []
        for (k, part) in s.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            if k > 0 { out.append((Line.paragraphEnd, true)) }
            if !part.isEmpty { out.append((String(part), false)) }
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

    private func wordLeft() -> (index: String.Index, offset: Int) {
        var (i, n) = (at, caret)
        for inWord in [false, true] {  // over white space first, then over the word
            while i > plainText.startIndex, plainText[plainText.index(before: i)].isWhitespace != inWord {
                (i, n) = (plainText.index(before: i), n - 1)
            }
        }
        return (i, n)
    }

    private func wordRight() -> (index: String.Index, offset: Int) {
        var (i, n) = (at, caret)
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
    }

    /// In order; empty when the key changed no text (a caret move is not journaled).
    public var edits: [Edit]
    public var motion: Motion

    public init(edits: [Edit] = [], motion: Motion = .none) {
        self.edits = edits
        self.motion = motion
    }
}
