// The journal in the app's terms: the edits the surface records, written through a real Journal (with a key store in
// memory) and read back by the app's replay, give the text that was typed. No Foundation here (see RenderTests.swift):
// the journal's URL comes from its own parameter type, the temporary folder from Darwin.
import Darwin
import FlowJournal
import Testing
@testable import FlowCore

/// Types as the surface (LineView) does and returns the edits it hands the journal: Return, typing, the press-and-hold
/// replacement as a cut and an insert, and backspace (B1) as a cut of the character's UTF-16 units.
struct Typist {
    var text = Text(), edits: [Edit] = []

    mutating func record(_ e: Edit) {
        text.apply(e)
        edits.append(e)
    }
    mutating func type(_ s: String) { record(.insert(s)) }
    mutating func returnKey() { record(.paragraphEnd) }
    mutating func pressAndHold(_ s: String, replacing n: Int) {
        record(.deleteBackward(n))
        record(.insert(s))
    }
    mutating func backspace() {
        guard let c = text.backspace() else { return }
        edits.append(.deleteBackward(String(c).utf16.count))
    }
}

@Test func backspaceReplaysAsTheSameCut() {
    for word in ["cat", "🙂", "🇩🇪", "e\u{301}", "naïve", "日本"] {
        var t = Typist()
        t.type("x " + word)
        t.backspace()
        #expect(Text(replaying: t.edits) == t.text, "\(word)")
    }
    var t = Typist()
    t.type("one ")
    t.backspace()  // B1: nothing after a space, so nothing recorded
    #expect(t.edits == [.insert("one ")])
}

@Test func pressAndHoldReplaysClampedAtTheParagraphStart() {
    var t = Typist()
    t.type("one")
    t.returnKey()
    t.type("e")
    t.pressAndHold("é", replacing: 3)  // more than the paragraph holds: the cut stops at its start
    #expect(t.text.paragraphs == ["one", "é"])
    #expect(Text(replaying: t.edits) == t.text)
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
        for e in t.edits { j.append(e) }
        j.flush(.full)
    }
    // The journal holds its file's lock while it lives, and its 50 ms batch window holds the journal: let both pass,
    // as a relaunch would.
    usleep(200_000)

    let k = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
    let restored = Text(replaying: k.replay)
    #expect(restored.plainText == t.text.plainText)
    #expect(restored.paragraphs == ["hello  world. i said so", "", "café naïve 🙂 word", "last"])
    try k.finish()  // the key gone, the file deleted: the folder is empty again
    #expect(rmdir(sessions) == 0 && rmdir(root) == 0)
}
