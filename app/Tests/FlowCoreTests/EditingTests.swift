// Editing anywhere on the line (DESIGN.md B4): the caret's moves, the deletes, the word rules, Characters as the one
// unit, and the edits each key hands the journal. No Foundation here (see RenderTests.swift).
import FlowJournal
import Testing
@testable import FlowCore

/// `t` with the caret shown as `|`.
func marked(_ t: Text) -> String {
    var s = t.plainText
    s.insert("|", at: s.index(s.startIndex, offsetBy: t.caret))
    return s
}

@Test func arrowsStepOneCharacterAndStopAtTheEnds() {
    var t = Text("a🙂é\n👩‍💻")  // é precomposed; 👩‍💻 one Character of three scalars
    #expect(t.count == 5)
    #expect(t.moveRight() == Change())  // at the end: nothing
    #expect(t.moveLeft() == Change(motion: .caret(passed: "👩‍💻", leftward: true)))
    #expect(t.moveLeft() == Change(motion: .caret(passed: "\n", leftward: true)))  // ← past the ¶ lands before it
    #expect(marked(t) == "a🙂é|\n👩‍💻" && t.utf16Caret == 4)  // 🙂 is two UTF-16 units
    t.moveLeft()
    t.moveLeft()
    #expect(t.moveLeft() == Change(motion: .caret(passed: "a", leftward: true)))
    #expect(t.moveLeft() == Change() && t.caret == 0 && t.utf16Caret == 0)
    #expect(t.moveRight() == Change(motion: .caret(passed: "a", leftward: false)))
    #expect(t.moveRight().edits.isEmpty)  // moves are never journaled
}

@Test func wordMovesSkipWhiteSpaceThenTheWord() {
    var t = Text("the quick  brown\u{A0}fox\nend")  // ⌥Space's no-break space and the paragraph end are white space
    t.moveWordLeft()
    #expect(marked(t) == "the quick  brown\u{A0}fox\n|end")
    t.moveWordLeft()
    #expect(marked(t) == "the quick  brown\u{A0}|fox\nend")
    #expect(t.moveWordLeft() == Change(motion: .caret(passed: "brown\u{A0}", leftward: true)))
    t.moveWordLeft()
    #expect(marked(t) == "the |quick  brown\u{A0}fox\nend")
    t.moveWordLeft()
    #expect(t.moveWordLeft() == Change() && t.caret == 0)
    #expect(t.moveWordRight() == Change(motion: .caret(passed: "the", leftward: false)))
    t.moveWordRight()
    #expect(marked(t) == "the quick|  brown\u{A0}fox\nend")
    #expect(t.moveWordRight() == Change(motion: .caret(passed: "  brown", leftward: false)))
    t = Text("  café 🙂", caret: 0)
    t.moveWordRight()
    #expect(marked(t) == "  café| 🙂")
    t.moveWordRight()
    #expect(t.caret == t.count && t.moveWordRight() == Change())
}

@Test func paragraphMovesGoToItsEnds() {
    var t = Text("one\ntwo three\nfour", caret: 7)
    #expect(t.moveToParagraphStart() == Change(motion: .caret(passed: "two", leftward: true)))
    #expect(t.caret == 4 && t.moveToParagraphStart() == Change())  // already there
    #expect(t.moveToParagraphEnd() == Change(motion: .caret(passed: "two three", leftward: false)))
    #expect(marked(t) == "one\ntwo three|\nfour" && t.moveToParagraphEnd() == Change())
    t = Text("ab\n", caret: 3)  // an empty last paragraph: start and end are one place
    #expect(t.moveToParagraphStart() == Change() && t.moveToParagraphEnd() == Change())
}

@Test func deleteBackwardCrossesSpacesAndParagraphEnds() {
    var t = Text("the cat\n")
    #expect(t.deleteBackward() == Change(edits: [.delete(at: 7, count: 1)], motion: .before(added: "", removed: "\n")))
    #expect(t.plainText == "the cat")
    for _ in 0 ..< 3 { t.deleteBackward() }
    #expect(t.plainText == "the " && t.deleteBackward().edits == [.delete(at: 3, count: 1)])  // across the space
    t = Text("ab", caret: 0)
    #expect(t.deleteBackward() == Change() && t.plainText == "ab")  // at the start: nothing, no edit
    t = Text("x👩‍💻é", caret: 2)
    #expect(t.deleteBackward() == Change(edits: [.delete(at: 1, count: 1)], motion: .before(added: "", removed: "👩‍💻")))
    #expect(marked(t) == "x|é")
}

@Test func wordDeletesTakeWhatTheWordMovesPass() {
    var t = Text("one\ntwo three  ", caret: 15)
    #expect(t.deleteWordBackward() == Change(edits: [.delete(at: 8, count: 7)],
                                             motion: .before(added: "", removed: "three  ")))
    #expect(t.deleteWordBackward().edits == [.delete(at: 4, count: 4)] && marked(t) == "one\n|")
    #expect(t.deleteWordBackward().edits == [.delete(at: 0, count: 4)] && t.plainText == "")  // the ¶ and the word
    #expect(t.deleteWordBackward() == Change())
    t = Text("go  naïve 🙂 end", caret: 2)
    #expect(t.deleteWordForward() == Change(edits: [.delete(at: 2, count: 7)], motion: .after(removed: "  naïve")))
    #expect(marked(t) == "go| 🙂 end")
    t.deleteWordForward()
    #expect(marked(t) == "go| end")
}

@Test func deleteForwardTakesTheCharacterAfterTheCaret() {
    var t = Text("ab🙂\nc", caret: 2)
    #expect(t.deleteForward() == Change(edits: [.delete(at: 2, count: 1)], motion: .after(removed: "🙂")))
    #expect(t.deleteForward().edits == [.delete(at: 2, count: 1)] && marked(t) == "ab|c")  // the paragraph end
    t.deleteForward()
    #expect(t.deleteForward() == Change() && t.plainText == "ab")  // at the end: nothing
}

@Test func typingInTheMiddleInsertsAtTheCaret() {
    var t = Text("helo world", caret: 3)
    #expect(t.insert("l") == Change(edits: [.insert(at: 3, "l")], motion: .before(added: "l", removed: "")))
    #expect(marked(t) == "hell|o world")
    t.insert("\n")  // Return in the middle splits the paragraph
    #expect(t.paragraphs == ["hell", "o world"] && t.caret == 5)
    t.moveToParagraphStart()
    t.deleteBackward()  // ⌫ across the ¶ joins them again
    #expect(marked(t) == "hell|o world")
    t = Text("e", caret: 1)
    t.insert("\u{301}")  // a combining accent joins the e: one Character, the caret after it
    #expect(t.count == 1 && t.caret == 1)
}

@Test func everyKeysEditsReplayToTheSameText() {
    var t = Text(), edits: [Edit] = []
    func key(_ change: Change) { edits += change.edits }
    key(t.insert("Thé quick brown fox 🙂"))
    for _ in 0 ..< 3 { key(t.moveWordLeft()) }
    key(t.insert("very "))
    key(t.deleteWordForward())
    key(t.insert("\n"))
    key(t.moveLeft())
    key(t.deleteBackward())
    key(t.insert("é", replacing: 1))
    key(t.moveToParagraphEnd())
    key(t.deleteForward())
    key(t.moveRight())
    key(t.deleteWordBackward())
    let replayed = Text(replaying: edits)
    #expect(replayed.plainText == t.plainText)
    #expect(replayed.caret == replayed.count)  // the replay puts the caret at the end
}
