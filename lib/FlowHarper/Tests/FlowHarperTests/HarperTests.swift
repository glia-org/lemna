import Darwin
import Testing
import FlowHarper

/// `text` with `suggestion`'s first replacement applied.
private func applying(_ suggestion: Suggestion, to text: String) -> String {
    var fixed = text
    fixed.replaceSubrange(suggestion.range, with: suggestion.replacements.first ?? "")
    return fixed
}

// Serialized: the lints queue on one linter anyway, and the timing test's numbers mean nothing while other tests
// hold it.
@Suite(.serialized) struct HarperTests {
    @Test(arguments: [
        ("I saw teh cat.", "teh", "I saw the cat."),
        ("It was a idea worth keeping.", "a", "It was an idea worth keeping."),
        ("We read the the draft.", "the the", "We read the draft."),
    ])
    func plantedErrorIsFound(text: String, flagged: String, fixed: String) throws {
        let suggestions = Harper.lint(text)
        #expect(suggestions.count == 1)
        let suggestion = try #require(suggestions.first)
        #expect(String(text[suggestion.range]) == flagged)
        #expect(applying(suggestion, to: text) == fixed)
    }

    @Test func cleanSentenceHasNoSuggestions() {
        #expect(Harper.lint("The river was high this spring, so we kept the sandbags in the shed.").isEmpty)
        #expect(Harper.lint("").isEmpty)
    }

    @Test func offsetsMapPastMultibyteCharacters() {
        // é and ö take 2 UTF-8 bytes, 🙂 4, the ZWJ sequence 👩‍💻 11 in one Character: byte, scalar and Character
        // counts all differ before the error.
        let text = "Café, Köln and 🙂 👩‍💻: teh end."
        let flagged = Harper.lint(text).map { String(text[$0.range]) }
        #expect(flagged == ["Köln", "teh"])  // Köln is not in Harper's dictionary
    }

    @Test func suggestionInsideACharacterIsSkipped() {
        // Harper flags "teh" but ends its range before the combining acute accent, inside the Character "h́".
        #expect(Harper.lint("I saw teh\u{301} cat.").isEmpty)
        #expect(Harper.lint("I saw teh cat.").count == 1)
    }

    @Test func versionNamesHarperCore() {
        #expect(Harper.version == "harper-core 3.0.0")
    }

    /// The 996-word text the Rust latency test reads too (../prose-1000.txt). Darwin's stdio: Foundation would bring
    /// the Testing overlay the Command Line Tools lack.
    private func prose() throws -> String {
        let path = #filePath.split(separator: "/", omittingEmptySubsequences: false).dropLast(2).joined(separator: "/")
            + "/prose-1000.txt"
        let file = try #require(fopen(path, "r"))
        defer { fclose(file) }
        var bytes: [UInt8] = []
        var chunk = [UInt8](repeating: 0, count: 1 << 16)
        while case let count = fread(&chunk, 1, chunk.count, file), count > 0 { bytes += chunk[..<count] }
        return String(decoding: bytes, as: UTF8.self)
    }

    @Test func thousandWordsLintQuickly() throws {
        let text = try prose()
        let edited = text.replacing("one bakery", with: "one bakry", maxReplacements: 1)
        let clock = ContinuousClock()
        var found: [Suggestion] = []
        // Other tests may run first and build the linter; the Rust test measures the cold call.
        let first = clock.measure { found = Harper.lint(text) }
        let second = clock.measure { found = Harper.lint(text) }
        let afterEdit = clock.measure { _ = Harper.lint(edited) }
        let ms = { (d: Duration) in  // to 0.1 ms, without Foundation's formatting
            (Double(d.components.seconds) * 1e4 + Double(d.components.attoseconds) / 1e14).rounded() / 10
        }
        print("\(text.split(whereSeparator: \.isWhitespace).count) words, \(found.count) suggestions: first call "
              + "\(ms(first)) ms, second \(ms(second)) ms, after a one-word edit \(ms(afterEdit)) ms")
        #expect(found.map { String(text[$0.range]) }.contains("recieve"))
        #expect(second < .milliseconds(100))
        #expect(afterEdit < .milliseconds(100))
    }
}
