// Harper's suggestions in the review (DESIGN.md R2) as plain values: the app lints with lib/FlowHarper and hands the
// results here, so accepting one, moving the ones after it, accepting all and the selection run without Harper or
// AppKit, and the tests check them. Also where the list goes for a given width.
import CoreGraphics

/// One change Harper suggests for the review's text. Offsets count UTF-16 units, as the review's NSTextView does, so a
/// suggestion's range is the text view's range as it is.
public struct Suggestion: Equatable {
    /// Which of Harper's answers it is (its place in text order when linted), kept while others go. The list shows
    /// each row's place instead (`SuggestionList.items`, from 1), renumbered as rows go.
    public let number: Int
    /// Where `wrong` starts in the text, in UTF-16 units; moved as earlier suggestions are accepted.
    public private(set) var start: Int
    /// The flagged text, as it stands in the text.
    public let wrong: String
    /// Harper's first replacement for `wrong` ("" deletes it); nil when Harper only points at it (skip only).
    public let replacement: String?
    /// Harper's lint kind ("Spelling", "WordChoice", …) and its explanation, which may hold Markdown.
    public let kind: String, message: String

    public init(number: Int, start: Int, wrong: String, replacement: String?, kind: String, message: String) {
        (self.number, self.start, self.wrong, self.replacement) = (number, start, wrong, replacement)
        (self.kind, self.message) = (kind, message)
    }

    /// From what FlowHarper returns for `text`: a range of String indices on Character boundaries, and every
    /// replacement Harper has (the review offers the first).
    public init(number: Int, in text: String, range: Range<String.Index>, replacements: [String], kind: String,
                message: String) {
        self.init(number: number, start: range.lowerBound.utf16Offset(in: text), wrong: String(text[range]),
                  replacement: replacements.first, kind: kind, message: message)
    }

    public var length: Int { wrong.utf16.count }
    public var end: Int { start + length }

    /// The kind as the list shows it: "WordChoice" → "word choice".
    public var label: String {
        var out = ""
        for c in kind {
            if c.isUppercase && !out.isEmpty { out += " " }
            out += c.lowercased()
        }
        return out
    }

    /// `text` with `s`'s replacement in place of its range. Nil when `s` has no replacement, or when `text` does not
    /// hold `wrong` there (a list made for another text): a stale suggestion never edits the wrong words.
    public static func apply(_ s: Suggestion, to text: String) -> String? {
        let u = text.utf16
        guard let replacement = s.replacement, s.start >= 0, s.end <= u.count else { return nil }
        let lo = u.index(u.startIndex, offsetBy: s.start), hi = u.index(lo, offsetBy: s.length)
        guard let a = String.Index(lo, within: text), let b = String.Index(hi, within: text), text[a..<b] == s.wrong
        else { return nil }
        var out = text
        out.replaceSubrange(a..<b, with: replacement)
        return out
    }

    /// The others once `s` was accepted: those after it move by the change in length, those before it stay. One that
    /// overlaps it is dropped (Harper's ranges are disjoint, so none should).
    public static func shift(_ others: [Suggestion], after s: Suggestion) -> [Suggestion] {
        let delta = (s.replacement ?? s.wrong).utf16.count - s.length
        return others.compactMap { o in
            if o.end <= s.start { return o }
            guard o.start >= s.end else { return nil }
            var moved = o
            moved.start += delta
            return moved
        }
    }
}

/// The review's text with Harper's suggestions for it: what is selected, what was accepted. Starts from the text the
/// review shows (R1 applied, or the raw text after R1's Undo) and the suggestions linted for exactly that text.
public struct SuggestionList: Equatable {
    /// The text as accepted so far: what Copy, Save and Paste hand off.
    public private(set) var text: String
    /// In text order, those not yet accepted or skipped; the list numbers its rows by their place here, from 1.
    public private(set) var items: [Suggestion]
    public private(set) var selected: Int?
    public private(set) var accepted = 0

    public init(text: String, items: [Suggestion] = []) {
        // By position in the text, whatever order they came in: the rows are numbered as they are shown.
        (self.text, self.items) = (text, items.sorted { $0.start < $1.start })
        selected = items.isEmpty ? nil : 0
    }

    public var current: Suggestion? { selected.map { items[$0] } }

    /// The footer's addition to the R1 line, once something was accepted: "· Harper: 2 accepted".
    public var note: String? { accepted == 0 ? nil : "· Harper: \(accepted) accepted" }

    public mutating func select(_ i: Int) {
        if items.indices.contains(i) { selected = i }
    }

    /// ↑ (-1) and ↓ (+1): stops at the first and the last.
    public mutating func move(_ by: Int) {
        guard let i = selected else { return }
        selected = min(max(i + by, 0), items.count - 1)
    }

    /// Accepts the selected suggestion: the text changes, the row goes, the ones after it move, and the selection stays
    /// at its place (the next row, or the last). False when it has no replacement (or does not fit the text).
    @discardableResult public mutating func accept() -> Bool {
        guard let i = selected, take(i) else { return false }
        reselect(i)
        return true
    }

    /// Skips the selected suggestion: the row goes, the text stays.
    @discardableResult public mutating func skip() -> Bool {
        guard let i = selected else { return false }
        items.remove(at: i)
        reselect(i)
        return true
    }

    /// Accepts every suggestion that has a replacement, in text order, each after the ones before it moved it; those
    /// Harper only points at stay, the first of them selected. Returns how many were accepted.
    @discardableResult public mutating func acceptAll() -> Int {
        let before = accepted
        var i = 0
        while i < items.count {
            if !take(i) { i += 1 }
        }
        selected = items.isEmpty ? nil : 0
        return accepted - before
    }

    /// Applies item `i`, drops it and moves the rest.
    private mutating func take(_ i: Int) -> Bool {
        guard let fixed = Suggestion.apply(items[i], to: text) else { return false }
        text = fixed
        let s = items.remove(at: i)
        items = Suggestion.shift(items, after: s)
        accepted += 1
        return true
    }

    private mutating func reselect(_ i: Int) { selected = items.isEmpty ? nil : min(i, items.count - 1) }
}

/// Where the review puts Harper's list: right of the text column when the review is wide enough (the box's 60 % of a
/// laptop screen, a wide window's sheet), else below it. The text column keeps its 72 characters either way.
public enum ReviewLayout {
    /// From this width of the review (points) on, the list goes beside the text.
    public static let besideFrom: CGFloat = 820
    /// The list's widest (the panel's mock-up), and the gap between it and the text column.
    public static let listWidest: CGFloat = 330, gap: CGFloat = 16

    public struct Columns: Equatable {
        public var beside: Bool
        public var textX: CGFloat, textWidth: CGFloat, listX: CGFloat, listWidth: CGFloat
    }

    /// For a review `width` wide with a text column `column` wide and `margin` on either side. Beside: the column at
    /// its width, the list right of it as wide as the room allows up to `listWidest`, the pair centred. Below: the
    /// column centred (narrowed to the room), the list under it as wide as it. On whole points.
    public static func columns(width: CGFloat, column: CGFloat, margin: CGFloat) -> Columns {
        if width >= besideFrom {
            let list = max(min(listWidest, width - 2 * margin - gap - column), 0)
            let x = ((width - column - gap - list) / 2).rounded(.down)
            return Columns(beside: true, textX: x, textWidth: column, listX: x + column + gap, listWidth: list)
        }
        let w = max(min(column, width - 2 * margin), 0), x = ((width - w) / 2).rounded(.down)
        return Columns(beside: false, textX: x, textWidth: w, listX: x, listWidth: w)
    }
}
