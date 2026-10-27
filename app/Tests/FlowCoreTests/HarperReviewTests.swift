// The review through the real Harper (lib/FlowHarper, R2), as the app runs it: R1 first, then the lint on one serial
// queue, Harper's ranges made FlowCore's suggestions, accepted. And how long Done takes to the suggestions on
// the 1,000-word text the library's latency tests read. Needs the Rust library built and its -L (README.md). No
// Foundation here (RenderTests.swift): the text is read with Darwin's stdio.
import Darwin
import Dispatch
import FlowHarper
import Testing
@testable import FlowCore

/// As the app's `Lint.lint`: numbered in text order, FlowCore's values.
private func suggestions(_ text: String) -> [FlowCore.Suggestion] {
    Harper.lint(text).enumerated().map { i, s in
        FlowCore.Suggestion(number: i + 1, in: text, range: s.range, replacements: s.replacements, kind: s.kind,
                            message: s.message)
    }
}

private func ms(_ d: Duration) -> Double {  // to 0.1 ms, without Foundation's formatting
    (Double(d.components.seconds) * 1e4 + Double(d.components.attoseconds) / 1e14).rounded() / 10
}

/// lib/FlowHarper/Tests/prose-1000.txt, from this file's path (app/Tests/FlowCoreTests/HarperReviewTests.swift).
private func prose() throws -> String {
    let path = #filePath.split(separator: "/", omittingEmptySubsequences: false).dropLast(4).joined(separator: "/")
        + "/lib/FlowHarper/Tests/prose-1000.txt"
    let file = try #require(fopen(path, "r"))
    defer { fclose(file) }
    var bytes: [UInt8] = []
    var chunk = [UInt8](repeating: 0, count: 1 << 16)
    while case let count = fread(&chunk, 1, chunk.count, file), count > 0 { bytes += chunk[..<count] }
    return String(decoding: bytes, as: UTF8.self)
}

// Serialized: the lints share one linter, and the timings mean little while another test holds it.
@Suite(.serialized) struct HarperReviewTests {
    /// Done → the suggestions in hand: R1 on the raw text, the lint on the queue that ran the launch's warm-up, the
    /// ranges converted, back to the caller (the app's hop to the main thread and the rows are not in it). Printed;
    /// under the review's patience by far. First in the suite, so its warm-up is the process's first lint, as at
    /// launch.
    @Test func doneToSuggestionsOnAThousandWords() throws {
        let raw = try prose()
        let clock = ContinuousClock(), harper = DispatchQueue(label: "test.harper", qos: .userInitiated)
        let warmUp = clock.measure { _ = harper.sync { Harper.lint("Warm up.") } }
        var found: [FlowCore.Suggestion] = [], r1 = Duration.zero
        let done = clock.measure {
            var shown = ""
            r1 = clock.measure { shown = Mechanical.apply(raw).text }
            found = harper.sync { suggestions(shown) }
        }
        let again = clock.measure { _ = harper.sync { suggestions(Mechanical.apply(raw).text) } }
        print("\(Mechanical.words(raw)) words, \(found.count) suggestions: warm-up \(ms(warmUp)) ms; Done → "
              + "suggestions \(ms(done)) ms (R1 \(ms(r1)) ms), the same text again \(ms(again)) ms")
        #expect(found.contains { $0.wrong == "recieve" })
        #expect(done < .seconds(1))  // the review waits two
    }

    /// The handoff's sample: what the review shows after R1, what Harper flags in it, and accept all.
    @Test func sampleThroughR1AndAcceptAll() throws {
        let shown = Mechanical.apply("teh boats sat low, a idea the the").text
        #expect(shown == "Teh boats sat low, a idea the the")
        let found = suggestions(shown)
        let flagged = found.map(\.wrong)
        #expect(flagged.contains("a") || flagged.contains("a idea"))
        #expect(flagged.contains("the the"))
        var list = SuggestionList(text: shown, items: found)
        list.acceptAll()
        print("sample: \(found.map { "\($0.number) \($0.label): \($0.wrong) → \($0.replacement ?? "(none)")" }); "
              + "accept all: \"\(list.text)\"")
        #expect(list.text.contains("an idea") && !list.text.contains("the the"))
        // Linted again, the accepted text has nothing left of what was accepted.
        #expect(!suggestions(list.text).contains { $0.wrong == "the the" })
    }
}
