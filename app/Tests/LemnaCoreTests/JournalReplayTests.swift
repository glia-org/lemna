// The journal in the app's terms: the edits the surface records, written through a real Journal (with a key store in
// memory) and read back by the app's replay, give the text that was typed, edits in the middle included (B4). No
// Foundation here (see RenderTests.swift): the journal's URL comes from its own parameter type, the temporary folder
// from Darwin.
import Darwin
import LemnaJournal
import Testing
@testable import LemnaCore

/// Types as the surface (LineView) does and keeps the edits it hands the journal: each key's `Change.edits`.
struct Typist {
    var text = Text(), edits: [Edit] = []

    mutating func key(_ k: (inout Text) -> Change) { edits += k(&text).edits }
    mutating func type(_ s: String) { key { $0.insert(s) } }
    mutating func returnKey() { key { $0.insert("\n") } }
    mutating func lineBreak() { key { $0.insert(String(Text.lineBreak)) } }  // ⇧⏎ (pass 29b)
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
    var template = Array((String(cString: getenv("TMPDIR")) + "/lemna-app-test-XXXXXX").utf8CString)
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

/// A selection's delete and its replacement in the middle (B4, pass 29) are the journal's two edits, a delete and an
/// insert, so the replay is the one it was: "two" selected by ⇧⌥← (the caret at its start) and typed over; from there
/// to the next paragraph's first word by ⇧⌘→, ⇧→ and ⇧⌥→ (the caret at its end), taken by ⌫; a word selected by ⇧⌥→
/// and replaced by the accent menu's pick (its replacement range not used), the next by Return; then ⌘A and ⌦. Written
/// through a real journal and read back, as a relaunch would.
@Test func selectionDeletesAndReplacementsReplayMidText() throws {
    var t = Typist()
    t.type("one two three")
    t.returnKey()
    t.type("four five six")
    t.key { $0.moveToParagraphStart() }
    t.key { $0.moveLeft() }  // the first paragraph's end
    t.key { $0.moveWordLeft() }
    t.key { $0.moveLeft() }  // after "two"
    t.key { $0.moveWordLeft(extending: true) }
    t.type("2")
    #expect(t.text.paragraphs == ["one 2 three", "four five six"])
    t.key { $0.moveToParagraphEnd(extending: true) }
    t.key { $0.moveRight(extending: true) }
    t.key { $0.moveWordRight(extending: true) }
    #expect(t.text.selectedText == " three\nfour")
    t.backspace()
    #expect(t.text.paragraphs == ["one 2 five six"])
    t.key { $0.moveWordRight(extending: true) }  // " five"
    t.pressAndHold("V", replacing: 1)
    t.key { $0.moveWordRight(extending: true) }
    t.returnKey()
    #expect(t.text.paragraphs == ["one 2V", ""])
    let start = t.edits.count
    t.key { $0.selectAll() }
    t.key { $0.deleteForward() }
    #expect(t.edits.count == start + 1 && t.text.plainText == "")
    #expect(Text(replaying: Array(t.edits[..<start])).paragraphs == ["one 2V", ""])
    #expect(t.edits.allSatisfy { if case .delete(_, let n) = $0 { n > 0 } else { true } })

    var template = Array((String(cString: getenv("TMPDIR")) + "/lemna-app-test-XXXXXX").utf8CString)
    let root = template.withUnsafeMutableBufferPointer { String(cString: mkdtemp($0.baseAddress!)) }
    let sessions = root + "/sessions.noindex", store = MemoryKeyStore()
    do {
        let j = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
        for e in t.edits[..<start] { j.append(e) }
        j.flush(.full)
    }
    usleep(200_000)  // the lock and the batch window pass, as in journalRoundTripThroughTheAppsReplay
    let k = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
    #expect(k.replay == Array(t.edits[..<start]))
    #expect(Text(replaying: k.replay).paragraphs == ["one 2V", ""])
    try k.finish()
    #expect(rmdir(sessions) == 0 && rmdir(root) == 0)
}

/// ⇧⏎'s line break (pass 29b) is journaled as the Character it is, U+2028, in the existing `insert(at:)`, and deleted
/// as one by `delete(at:count:)`, so the replay is unchanged: two line breaks, one taken by ⌫ from the middle and typed
/// again, a Return after them; written through a real journal and read back, then handed off by R1 as a relaunch's
/// Done would.
@Test func lineBreaksReplayThroughTheJournal() throws {
    var t = Typist()
    t.type("the reeds")
    t.lineBreak()
    t.type("the boats")
    t.lineBreak()
    t.lineBreak()
    t.type("so")
    t.key { $0.moveWordLeft() }
    t.backspace()  // the second line break, from before "so"
    t.key { $0.moveToParagraphEnd() }
    t.returnKey()
    t.type("the water")
    t.key { $0.moveToParagraphStart() }
    t.key { $0.moveLeft() }
    t.key { $0.moveWordLeft() }
    t.lineBreak()  // before "so"
    #expect(t.text.paragraphs == ["the reeds\u{2028}the boats\u{2028}\u{2028}so", "the water"])
    #expect(t.edits.contains(.insert(at: 9, "\u{2028}")) && t.edits.contains(.delete(at: 20, count: 1)))

    var template = Array((String(cString: getenv("TMPDIR")) + "/lemna-app-test-XXXXXX").utf8CString)
    let root = template.withUnsafeMutableBufferPointer { String(cString: mkdtemp($0.baseAddress!)) }
    let sessions = root + "/sessions.noindex", store = MemoryKeyStore()
    do {
        let j = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
        for e in t.edits { j.append(e) }
        j.flush(.full)
    }
    usleep(200_000)  // the lock and the batch window pass, as in journalRoundTripThroughTheAppsReplay
    let k = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
    #expect(k.replay == t.edits)
    let restored = Text(replaying: k.replay)
    #expect(restored.plainText == t.text.plainText)
    #expect(Mechanical.apply(restored.plainText).text == "The reeds\nthe boats\n\nso\n\nThe water")
    try k.finish()
    #expect(rmdir(sessions) == 0 && rmdir(root) == 0)
}

/// ⌘V, ⌘Z and ⌘⇧Z (pass 30) are the journal's ordinary edits, no new kind: a paste with an emoji, a flag and a line
/// break typed over a selection is one insert after its cut; ⌘Z takes it back by a delete and an insert, ⌘⇧Z puts it in
/// again; a typed run undone and typed anew in its place; written through a real journal and read back as a relaunch
/// would, the replay is the text the screen showed, and the line it restores has nothing to undo.
@Test func pasteUndoAndRedoReplayThroughTheJournal() throws {
    var w = Writer()
    w.type("A note: TITLE here")
    w.move { $0.moveWordLeft() }
    w.move { $0.moveLeft() }
    w.move { $0.moveWordLeft(extending: true) }  // "TITLE"
    w.paste("🦆 Ducks of 🇩🇪\r\nand 👩🏽‍💻\n")
    #expect(w.text.plainText == "A note: 🦆 Ducks of 🇩🇪\u{2028}and 👩🏽‍💻 here")
    let pasted = w.edits.count
    #expect(Array(w.edits[pasted - 2..<pasted])
        == [.delete(at: 8, count: 5), .insert(at: 8, "🦆 Ducks of 🇩🇪\u{2028}and 👩🏽‍💻")])  // one insert, after the cut
    w.undo()
    #expect(selecting(w.text) == "A note: |TITLE^ here")
    w.redo()
    w.undo()
    w.redo()
    w.move { $0.moveToParagraphEnd() }
    w.returnKey()
    w.type("more", after: History.pause)
    w.undo()
    w.type("less")
    #expect(w.text.plainText == "A note: 🦆 Ducks of 🇩🇪\u{2028}and 👩🏽‍💻 here\nless" && w.replays)

    var template = Array((String(cString: getenv("TMPDIR")) + "/lemna-app-test-XXXXXX").utf8CString)
    let root = template.withUnsafeMutableBufferPointer { String(cString: mkdtemp($0.baseAddress!)) }
    let sessions = root + "/sessions.noindex", store = MemoryKeyStore()
    do {
        let j = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
        for e in w.edits { j.append(e) }
        j.flush(.full)
    }
    usleep(200_000)  // the lock and the batch window pass, as in journalRoundTripThroughTheAppsReplay
    let k = try Journal.open(directory: .init(fileURLWithPath: sessions), keyStore: store)
    #expect(k.replay == w.edits)
    var restored = Writer(text: Text(replaying: k.replay))
    #expect(restored.text.plainText == w.text.plainText)
    #expect(restored.undo() == Change() && restored.redo() == Change())  // a restored session starts with no undo
    #expect(Mechanical.apply(restored.text.plainText).text == "A note: 🦆 Ducks of 🇩🇪\nand 👩🏽‍💻 here\n\nLess")
    try k.finish()
    #expect(rmdir(sessions) == 0 && rmdir(root) == 0)
}
