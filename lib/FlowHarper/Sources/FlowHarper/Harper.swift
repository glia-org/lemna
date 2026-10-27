import CFlowHarper
import Foundation

/// One change Harper suggests: replace `range` of the linted text with one of `replacements`.
public struct Suggestion {
    public let range: Range<String.Index>
    /// Harper's lint kind: Spelling, Typo, Grammar, Repetition, Capitalization, …
    public let kind: String
    /// Harper's text; may hold Markdown (`code`, **bold**).
    public let message: String
    /// Each replaces `range` in full; "" deletes it. May be empty (the lint only points at the text).
    public let replacements: [String]
}

/// Harper's English grammar and spelling check, offline (rust/, harper-core).
public enum Harper {
    /// Suggestions for `text`, in text order, ranges disjoint. Any thread; calls run one at a time. The first call
    /// in a process also builds the linter (about 0.3 s, README), so make one off the main thread before the review.
    public static func lint(_ text: String) -> [Suggestion] {
        var contiguous = text  // withUTF8 may copy a bridged string; the indices below come from `text` itself
        let json: Data = contiguous.withUTF8 { utf8 in
            utf8.withMemoryRebound(to: CChar.self) { bytes in
                let json = fh_lint(bytes.baseAddress, bytes.count)
                defer { fh_free(json) }
                return Data(bytes: json, count: strlen(json))
            }
        }
        guard let raws = try? JSONDecoder().decode([Raw].self, from: json) else { return [] }
        let utf8 = text.utf8
        return raws.compactMap { raw in
            guard 0 <= raw.start, raw.start <= raw.end, raw.end <= utf8.count else { return nil }
            // Harper's offsets sit on Unicode scalars; one inside a grapheme cluster (an accent's combining mark,
            // an emoji sequence) has no String.Index, and such a suggestion is dropped rather than split a character.
            guard let start = String.Index(utf8.index(utf8.startIndex, offsetBy: raw.start), within: text),
                  let end = String.Index(utf8.index(utf8.startIndex, offsetBy: raw.end), within: text)
            else { return nil }
            return Suggestion(range: start..<end, kind: raw.kind, message: raw.message, replacements: raw.replacements)
        }
    }

    /// "harper-core x.y.z", the version linked in.
    public static var version: String { String(cString: fh_version()) }

    /// One element of fh_lint's JSON (include/flow_harper.h).
    private struct Raw: Decodable {
        let start: Int
        let end: Int
        let kind: String
        let message: String
        let replacements: [String]
    }
}
