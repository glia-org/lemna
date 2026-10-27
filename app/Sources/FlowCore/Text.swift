// The writing as paragraphs, typed only at the end (DESIGN.md S1 B1 P0), and rebuilt from the journal's edits (E2).
import FlowJournal
import Foundation

public struct Text: Equatable {
    /// Never empty: the last paragraph is the one being typed, and it may be empty.
    public private(set) var paragraphs: [String]

    public init(_ paragraphs: [String] = [""]) { self.paragraphs = paragraphs.isEmpty ? [""] : paragraphs }

    /// Paragraphs joined by "\n", for the journal and the output of later milestones.
    public var plainText: String { paragraphs.joined(separator: "\n") }

    /// The length of `plainText` in UTF-16 units: the text input system indexes the document in these.
    public var utf16Count: Int { paragraphs.reduce(paragraphs.count - 1) { $0 + $1.utf16.count } }

    /// Appends `s` to the last paragraph, a newline in it ending the paragraph, after taking the last `n` UTF-16 units
    /// off that paragraph (the press-and-hold accent menu replaces the letter just typed; never past the paragraph's
    /// start). Returns what the line lost and gained at its end, as the line shows it.
    @discardableResult
    public mutating func type(_ s: String, replacing n: Int = 0) -> (removed: String, added: String) {
        let i = paragraphs.count - 1
        var removed = "", added = ""
        if n > 0 {
            let last = paragraphs[i] as NSString, cut = max(last.length - n, 0)
            removed = last.substring(from: cut)
            paragraphs[i] = last.substring(to: cut)
        }
        for (k, part) in s.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).enumerated() {
            if k > 0 { added += endParagraph() }
            paragraphs[paragraphs.count - 1] += part
            added += part
        }
        return (removed, added)
    }

    /// Return: ends the last paragraph; the next starts empty, so two in a row leave a blank line. Returns what the
    /// line gained.
    @discardableResult
    public mutating func endParagraph() -> String {
        paragraphs.append("")
        return Line.paragraphEnd
    }

    /// Backspace within the current word only (B1): takes the last character off the last paragraph unless that is
    /// empty or ends in white space, so it never crosses a paragraph end or goes back past a typed space (a
    /// no-break space, easily typed with ⌥Space, counts as one). Returns the character taken.
    public mutating func backspace() -> Character? {
        let i = paragraphs.count - 1
        guard let c = paragraphs[i].last, !c.isWhitespace else { return nil }
        paragraphs[i].removeLast()
        return c
    }

    /// One journal edit applied. The restore replays through here, and every edit the app journals is one this applies
    /// exactly as typing did (`deleteBackward` counts UTF-16 units, as the press-and-hold replacement does), so a
    /// restore rebuilds the text that was typed.
    @discardableResult
    public mutating func apply(_ edit: Edit) -> (removed: String, added: String) {
        switch edit {
        case .insert(let s): type(s)
        case .deleteBackward(let n): type("", replacing: n)
        case .paragraphEnd: ("", endParagraph())
        }
    }

    /// The text a journal's edits leave: the silent restore at launch.
    public init(replaying edits: [Edit]) {
        self.init()
        for e in edits { apply(e) }
    }

    /// What the line shows: about the last `n` characters, each paragraph end as ` ¶ ` (muted). Only the tail can be
    /// on screen, so the rest is never shaped.
    public func line(last n: Int) -> [(text: String, muted: Bool)] {
        var out: [(text: String, muted: Bool)] = [], left = n
        for i in paragraphs.indices.reversed() {
            guard left > 0 else { break }
            if i < paragraphs.count - 1 {
                out.append((Line.paragraphEnd, true))
                left -= Line.paragraphEnd.count
            }
            let tail = paragraphs[i].suffix(max(left, 0))
            if !tail.isEmpty {
                out.append((String(tail), false))
                left -= tail.count
            }
        }
        return out.reversed()
    }
}
