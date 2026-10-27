// The journal in the app's terms: the edits the surface records, written through a real Journal (with a key store in
// memory) and read back by the app's replay, give the text that was typed, edits in the middle included (B4). No
// Foundation here (see RenderTests.swift): the journal's URL comes from its own parameter type, the temporary folder
// from Darwin.
import Darwin
import FlowJournal
import Testing
@testable import FlowCore

/// Types as the surface (LineView) does and keeps the edits it hands the journal: each key's `Change.edits`.
struct Typist {
    var text = Text(), edits: [Edit] = []

    mutating func key(_ k: (inout Text) -> Change) { edits += k(&text).edits }
    mutating func type(_ s: String) { key { $0.insert(s) } }
    mutating func returnKey() { key { $0.insert("\n") } }
    mutating func pressAndHold(_ s: String, replacing n: Int) { key { $0.insert(s, replacing: n) } }
    mutating func backspace() { key { $0.deleteBackward() } }
}

@Test func deletesReplayAsTheSameCut() {
    for word in ["cat", "🙂", "🇩🇪", "e\u{301}", "naïve", "日本", "👩‍💻"] {
        var t = Typist()
        t.type("x " + word + " y")
        t.key { $0.moveLeft() }
        t.key { $0.moveLeft() }
        t.backspace()  // the word's last Character, from the middle
        t.key { $0.deleteForward() }  // the space after it
        #expect(Text(replaying: t.edits).plainText == t.text.plainText, "\(word)")
    }
    var t = Typist()
    t.type("one ")
    t.backspace()  // B4: across the space too
    #expect(t.edits == [.insert(at: 0, "one "), .delete(at: 3, count: 1)])
    t.key { $0.moveToParagraphStart() }
    t.backspace()  // at the start: nothing recorded
    t.key { $0.moveWordRight() }
    #expect(t.edits.count == 2)  // moves are not journaled
}

@Test func pressAndHoldReplaysMidText() {
    var t = Typist()
    t.type("one")
    t.returnKey()
    t.type("caft")
    t.key { $0.moveLeft() }
    t.type("e")
    t.pressAndHold("é", replacing: 1)  // the accent menu replaces the e just typed, before the t
    #expect(t.text.paragraphs == ["one", "cafét"])
    #expect(Text(replaying: t.edits).plainText == t.text.plainText)
}

@Test func journalRoundTripThroughTheAppsReplay() throws {
    var template = Array((String(cString: getenv("TMPDIR")) + "/flow-app-test-XXXXXX").utf8CString)
    let root = template.withUnsafeMutableBufferPointer { String(cString: mkdtemp($0.baseAddress!)) }
    let sessions = root + "/sessions.noindex", store = MemoryKeyStore()

    var t = Typist()
    do {
        let j = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
        #expect(j.replay.isEmpty)
        t.type("hello  world. i said so")
        t.returnKey()
        t.returnKey()
        t.type("cafe")
        t.pressAndHold("é", replacing: 1)
        t.type(" naïve 🙂 wort")
        t.backspace()
        t.type("d\nlast")  // a newline from the input system ends a paragraph too
        // Back into the middle: a word put in, the paragraph's last word taken by ⌥⌫ and typed anew, a Return and ⌦ in
        // the paragraph after it.
        for _ in 0 ..< 3 { t.key { $0.moveWordLeft() } }
        t.type("very ")
        t.key { $0.moveToParagraphEnd() }
        t.key { $0.deleteWordBackward() }
        t.type("words")
        t.key { $0.moveRight() }
        t.key { $0.moveRight() }
        t.returnKey()
        t.key { $0.deleteForward() }
        for e in t.edits { j.append(e) }
        j.flush(.full)
    }
    // The journal holds its file's lock while it lives, and its 50 ms batch window holds the journal: let both pass,
    // as a relaunch would.
    usleep(200_000)

    let k = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
    let restored = Text(replaying: k.replay)
    #expect(restored.plainText == t.text.plainText)
    #expect(restored.paragraphs == ["hello  world. i said so", "", "café naïve very 🙂 words", "l", "st"])
    #expect(restored.caret == restored.count)
    try k.finish()  // the key gone, the file deleted: the folder is empty again
    #expect(rmdir(sessions) == 0 && rmdir(root) == 0)
}
