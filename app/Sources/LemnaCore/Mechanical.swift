// The deterministic pass (DESIGN.md R1): only fixes that are mechanical and safe to apply unasked, because Done, Copy
// and Save… apply them silently, with no review and no undo (2026-10-28). No full stops added, no spelling, no style.
// Where a rule cannot tell, it leaves the text alone: a missed capital costs less than a wrong one.

public enum Mechanical {
    public struct Result: Equatable {
        /// The paragraphs joined by a blank line (Markdown).
        public var text: String
        /// Lowercase letters capitalised at a paragraph's or a sentence's start.
        public var capitals = 0
        /// Runs of spaces collapsed to one.
        public var spaces = 0
        /// Paragraphs that ended in spaces.
        public var trailing = 0
        /// Lone `i` made `I`.
        public var lone = 0

        public var count: Int { capitals + spaces + trailing + lone }
    }

    /// Applies R1 to plain text (paragraphs split at newlines): per paragraph, strips trailing spaces, collapses runs
    /// of spaces, capitalises the first letter and the letter after a sentence end, and makes a lone `i` `I`; then
    /// drops empty paragraphs (Markdown has no blank paragraph) and joins the rest by a blank line. Idempotent: its
    /// own output comes back unchanged with no fixes.
    public static func apply(_ text: String) -> Result {
        var r = Result(text: "")
        var out: [String] = []
        for line in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            var p = Array(line)
            if p.last == " " {
                r.trailing += 1
                while p.last == " " { p.removeLast() }
            }
            p = collapse(p, &r)
            guard !p.isEmpty else { continue }
            capitalise(&p, &r)
            loneI(&p, &r)
            out.append(String(p))
        }
        r.text = out.joined(separator: "\n\n")
        return r
    }

    /// Runs of U+0020 to one space. Only that space: a no-break space (⌥Space) is typed on purpose.
    private static func collapse(_ p: [Character], _ r: inout Result) -> [Character] {
        var q: [Character] = [], inRun = false
        q.reserveCapacity(p.count)
        for c in p {
            if c == " " && q.last == " " {
                if !inRun { r.spaces += 1 }
                inRun = true
                continue
            }
            inRun = false
            q.append(c)
        }
        return q
    }

    /// The paragraph's first letter (after any leading space) and each letter right after `. `, `! ` or `? `.
    private static func capitalise(_ p: inout [Character], _ r: inout Result) {
        if let first = p.firstIndex(where: { $0 != " " }) { upper(&p, first, &r) }
        var i = 0
        while i + 2 < p.count {
            if ".!?".contains(p[i]) && p[i + 1] == " " && endsSentence(p, i) { upper(&p, i + 2, &r) }
            i += 1
        }
    }

    /// Whether the `.!?` at `i` ends a sentence. A period does not after a word with another period in it ("e.g.",
    /// "z.B.", an ellipsis), after one letter ("z. B.", an initial) or after digits alone (an ordinal, "am 3. und 4.").
    private static func endsSentence(_ p: [Character], _ i: Int) -> Bool {
        guard p[i] == "." else { return true }
        var start = i
        while start > 0 && p[start - 1] != " " { start -= 1 }
        let word = p[start ..< i]
        if word.contains(".") { return false }
        if word.count == 1 && word.first!.isLetter { return false }
        if !word.isEmpty && word.allSatisfy(\.isNumber) { return false }
        return true
    }

    private static func upper(_ p: inout [Character], _ i: Int, _ r: inout Result) {
        guard p[i].isLowercase else { return }
        let u = p[i].uppercased()
        guard u.count == 1 else { return }  // ß → SS: no word starts with it, and the paragraph keeps its length
        p[i] = Character(u)
        r.capitals += 1
    }

    /// `i` as a word of its own: white space, an opening bracket or quote, or the paragraph's start before it; white
    /// space, closing punctuation, an apostrophe (i'm) or the end after it. Not "i.e.", not "i-th", not inside a word.
    private static func loneI(_ p: inout [Character], _ r: inout Result) {
        for k in p.indices where p[k] == "i" {
            let before = k > 0 ? p[k - 1] : nil, after = k + 1 < p.count ? p[k + 1] : nil
            guard before.map({ $0.isWhitespace || "([{\"“‘„«".contains($0) }) ?? true else { continue }
            let free = after.map { c in
                c.isWhitespace || ",;:!?)]}\"”’»'".contains(c) || (c == "." && (k + 2 >= p.count || !p[k + 2].isLetter))
            } ?? true
            guard free else { continue }
            p[k] = "I"
            r.lone += 1
        }
    }
}
