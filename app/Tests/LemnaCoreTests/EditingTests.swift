// Editing anywhere on the line (DESIGN.md B4): the caret's moves, the deletes, the word rules, Characters as the one
// unit, and the edits each key hands the journal; since pass 29 the selection: every move with ⇧, ⌘A, the collapse of
// a plain move, typing and pending text over a selection, the four deletes of one, and what ⌘C and ⌘X take. No
// Foundation here (see RenderTests.swift).
import LemnaJournal
import Testing
@testable import LemnaCore

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

/// `t` with the caret shown as `|` and the selection's anchor as `^`.
func selecting(_ t: Text) -> String {
    var s = t.plainText
    for (n, mark) in ([(t.caret, "|")] + (t.anchor.map { [($0, "^")] } ?? [])).sorted(by: { $0.0 > $1.0 }) {
        s.insert(contentsOf: mark, at: s.index(s.startIndex, offsetBy: n))
    }
    return s
}

@Test func shiftArrowsSelectACharacterAtATime() {
    var t = Text("ab\ncd", caret: 3)  // just after the paragraph end
    #expect(t.moveLeft(extending: true) == Change(motion: .caret(passed: "\n", leftward: true)))
    #expect(selecting(t) == "ab|\n^cd" && t.selection == 2..<3 && t.selectedText == "\n")  // the paragraph end
    t.moveLeft(extending: true)
    t.moveLeft(extending: true)
    #expect(selecting(t) == "|ab\n^cd" && t.moveLeft(extending: true) == Change())  // at the text's start: nothing
    for _ in 0 ..< 3 { t.moveRight(extending: true) }  // back over the same Characters: at the anchor it is gone
    #expect(t.anchor == nil && selecting(t) == "ab\n|cd" && t.selection == 3..<3 && t.selectedText == "")
    #expect(t.moveRight(extending: true) == Change(motion: .caret(passed: "c", leftward: false)))
    t.moveRight(extending: true)
    #expect(selecting(t) == "ab\n^cd|" && t.selectedText == "cd" && t.moveRight(extending: true) == Change())  // the end
    #expect(t.moveLeft(extending: true).edits.isEmpty)  // never journaled
    var u = Text("ab", caret: 2)
    #expect(u.moveRight(extending: true) == Change() && u.anchor == nil)  // nothing to take: no selection either
}

@Test func shiftOptionArrowsSelectAWordAtATime() {
    var t = Text("the quick brown\nfox", caret: 9)  // after "quick"
    #expect(t.moveWordLeft(extending: true) == Change(motion: .caret(passed: "quick", leftward: true)))
    t.moveWordLeft(extending: true)
    #expect(selecting(t) == "|the quick^ brown\nfox" && t.selectedText == "the quick")
    #expect(t.moveWordLeft(extending: true) == Change())  // at the text's start
    t.moveWordRight(extending: true)
    #expect(selecting(t) == "the| quick^ brown\nfox")  // shrunk from the start
    t.moveWordRight(extending: true)
    #expect(t.anchor == nil && t.caret == 9)  // back at the anchor
    t.moveWordRight(extending: true)
    #expect(t.moveWordRight(extending: true) == Change(motion: .caret(passed: "\nfox", leftward: false)))  // across the ¶
    #expect(selecting(t) == "the quick^ brown\nfox|" && t.selectedText == " brown\nfox")
    #expect(t.moveWordRight(extending: true) == Change())  // at the text's end
}

@Test func shiftCommandArrowsSelectToTheParagraphsEnds() {
    var t = Text("one\ntwo three\nfour", caret: 7)  // after "two"
    #expect(t.moveToParagraphEnd(extending: true) == Change(motion: .caret(passed: " three", leftward: false)))
    #expect(selecting(t) == "one\ntwo^ three|\nfour" && t.moveToParagraphEnd(extending: true) == Change())  // there
    #expect(t.moveToParagraphStart(extending: true) == Change(motion: .caret(passed: "two three", leftward: true)))
    #expect(selecting(t) == "one\n|two^ three\nfour" && t.selectedText == "two")  // past the anchor: turned round
    t.moveLeft(extending: true)  // ⇧← over the paragraph end, then ⇧⌘←: the paragraph before
    t.moveToParagraphStart(extending: true)
    #expect(selecting(t) == "|one\ntwo^ three\nfour" && t.moveToParagraphStart(extending: true) == Change())
    t = Text("one\ntwo", caret: 1)
    t.moveToParagraphEnd(extending: true)
    t.moveRight(extending: true)
    t.moveToParagraphEnd(extending: true)
    #expect(selecting(t) == "o^ne\ntwo|" && t.selectedText == "ne\ntwo")
}

@Test func commandASelectsEverythingWithTheCaretAtTheEnd() {
    var t = Text("one\ntwo", caret: 2)
    #expect(t.selectAll() == Change(motion: .caret(passed: "e\ntwo", leftward: false)))  // glides as ⌘→ to the end
    #expect(selecting(t) == "^one\ntwo|" && t.selectedText == "one\ntwo" && t.selection == 0..<7)
    #expect(t.selectAll() == Change())  // again: nothing changes
    t.moveLeft(extending: true)
    #expect(selecting(t) == "^one\ntw|o")  // ⇧← shrinks it from the end
    t = Text("abc")  // the caret at the end already: only the selection changes, and the line draws it
    #expect(t.selectAll() == Change(motion: .selected) && t.selection == 0..<3)
    var empty = Text()
    #expect(empty.selectAll() == Change() && empty.anchor == nil)
    var one = Text("abc", caret: 0)
    one.moveRight(extending: true)
    #expect(one.selectAll() == Change(motion: .caret(passed: "bc", leftward: false)) && selecting(one) == "^abc|")
}

@Test func aPlainMoveCollapsesTheSelectionToItsSide() {
    var t = Text("one two three", caret: 4)
    t.moveWordRight(extending: true)  // "two", the caret at its end
    var u = t
    #expect(u.moveLeft() == Change(motion: .caret(passed: "two", leftward: true)) && selecting(u) == "one |two three")
    u = t
    #expect(u.moveRight() == Change(motion: .selected) && selecting(u) == "one two| three")  // the caret's own side
    u = t
    u.moveWordLeft()  // from the selection's start, the word before it
    #expect(selecting(u) == "|one two three")
    u = t
    u.moveWordRight()  // from its end, the next word
    #expect(selecting(u) == "one two three|")
    u = t
    #expect(u.moveToParagraphStart() == Change(motion: .caret(passed: "one two", leftward: true)))
    #expect(selecting(u) == "|one two three")
    u = t
    u.moveToParagraphEnd()
    #expect(selecting(u) == "one two three|")
    t = Text("one two three", caret: 7)
    t.moveWordLeft(extending: true)  // "two", the caret at its start
    u = t
    #expect(u.moveLeft() == Change(motion: .selected) && selecting(u) == "one |two three")
    u = t
    #expect(u.moveRight() == Change(motion: .caret(passed: "two", leftward: false)) && selecting(u) == "one two| three")
    u = t
    u.moveWordLeft()
    #expect(selecting(u) == "|one two three")
    t = Text("ab\ncd", caret: 1)  // across a paragraph end: ⌘← from the start's paragraph, ⌘→ to the end's
    t.moveToParagraphEnd(extending: true)
    t.moveRight(extending: true)
    t.moveRight(extending: true)
    u = t
    u.moveToParagraphStart()
    #expect(selecting(u) == "|ab\ncd")
    u = t
    u.moveToParagraphEnd()
    #expect(selecting(u) == "ab\ncd|")
}

@Test func typingReplacesTheSelection() {
    var t = Text("the slow fox", caret: 4)
    t.moveWordRight(extending: true)  // "slow", the caret at its end: it goes as ⌫ would take it, back
    #expect(t.insert("quick") == Change(edits: [.delete(at: 4, count: 4), .insert(at: 4, "quick")],
                                        motion: .before(added: "quick", removed: "slow")))
    #expect(selecting(t) == "the quick| fox" && t.anchor == nil)
    t.moveWordLeft(extending: true)  // "quick", the caret at its start: it closes up after the caret, as ⌦'s would
    #expect(t.insert("red") == Change(edits: [.delete(at: 4, count: 5), .insert(at: 4, "red")],
                                      motion: .before(added: "red", removed: "")))
    #expect(selecting(t) == "the red| fox")
    t.moveWordLeft(extending: true)
    t.insert("\n")  // Return over a selection: the paragraph end in its place
    #expect(t.paragraphs == ["the ", " fox"] && t.caret == 5)
    t = Text("xaby", caret: 1)
    t.moveRight(extending: true)
    t.moveRight(extending: true)
    // The accent menu's replacement range is not used over a selection: the selection is what goes.
    #expect(t.insert("é", replacing: 1).edits == [.delete(at: 1, count: 2), .insert(at: 1, "é")] && t.plainText == "xéy")
}

@Test func pendingTextOverASelectionTakesItsPlace() {
    // LineView's setMarkedText: a dead key over a selection takes it first (⌫'s cut of it, one edit), the pending
    // text shows at the caret, and its letter is typed there when the input system commits it.
    var t = Text("naive one", caret: 2)
    t.moveRight(extending: true)  // the i
    #expect(t.deleteBackward() == Change(edits: [.delete(at: 2, count: 1)], motion: .before(added: "", removed: "i")))
    let shaped = Line.shape(t, marked: "¨", font: menlo)
    #expect(shaped.split == 3 && shaped.selected.isEmpty)  // "na¨" before the caret, nothing selected
    #expect(t.insert("ï").edits == [.insert(at: 2, "ï")] && t.plainText == "naïve one")
}

@Test func everyDeleteKeyTakesTheSelectionAndOnlyIt() {
    let keys: [(String, (inout Text) -> Change)] = [("⌫", { $0.deleteBackward() }), ("⌥⌫", { $0.deleteWordBackward() }),
                                                    ("⌦", { $0.deleteForward() }), ("⌥⌦", { $0.deleteWordForward() })]
    for (name, key) in keys {
        var atEnd = Text("one two three", caret: 4)
        atEnd.moveWordRight(extending: true)  // "two", the caret at its end: it glides back, as ⌫'s cut
        #expect(key(&atEnd) == Change(edits: [.delete(at: 4, count: 3)], motion: .before(added: "", removed: "two")),
                "\(name)")
        #expect(selecting(atEnd) == "one | three", "\(name)")
        var atStart = Text("one two three", caret: 7)
        atStart.moveWordLeft(extending: true)  // the caret at its start: the text after it closes up, as ⌦'s cut
        #expect(key(&atStart) == Change(edits: [.delete(at: 4, count: 3)], motion: .after(removed: "two")), "\(name)")
        #expect(selecting(atStart) == "one | three" && atStart.anchor == nil, "\(name)")
        var all = Text("a\nb")
        all.selectAll()
        #expect(key(&all).edits == [.delete(at: 0, count: 3)] && all.plainText == "", "\(name)")
    }
}

@Test func copyAndCutTakeTheSelectedText() {
    var t = Text("a🙂\nb", caret: 1)
    #expect(t.selectedText == "" && t.utf16Selection == 1..<1)  // nothing selected: ⌘C and ⌘X do nothing
    t.moveRight(extending: true)
    t.moveRight(extending: true)
    #expect(t.selectedText == "🙂\n" && t.selection == 1..<3 && t.utf16Selection == 1..<4)  // 🙂 is two units
    let copied = t.selectedText  // ⌘C copies this; ⌘X copies it and then cuts as ⌫ does
    #expect(t.deleteBackward().edits == [.delete(at: 1, count: 2)] && t.plainText == "ab" && copied == "🙂\n")
    t = Text("one two", caret: 7)
    t.moveWordLeft(extending: true)
    #expect(t.selectedText == "two" && t.utf16Selection == 4..<7)  // the caret at the start: the same text
}
