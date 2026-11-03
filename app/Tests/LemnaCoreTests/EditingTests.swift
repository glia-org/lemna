// Editing anywhere on the line (DESIGN.md B4): the caret's moves, the deletes, the word rules, Characters as the one
// unit, and the edits each key hands the journal; since pass 29 the selection: every move with ⇧, ⌘A, the collapse of
// a plain move, typing and pending text over a selection, the four deletes of one, and what ⌘C and ⌘X take; since
// pass 29b the line break (⇧⏎), one Character inside its paragraph for every key; since pass 30 ⌘V's text, an emoji
// pasted, and ⌘Z's and ⌘⇧Z's groups, through a `Writer` that records as the line does. No Foundation here (see
// RenderTests.swift).
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

// MARK: The line break (pass 29b)

/// ⇧⏎'s line break, U+2028 in the text.
let br = String(Text.lineBreak)

/// A line break (B4, pass 29b; the user, 2026-11-03: "make shift+enter newline and keep enter the old behaviour"): one
/// Character inside its paragraph, so ← and → step over it, ⌫ and ⌦ take it alone, and it is journaled as typed.
@Test func aLineBreakIsOneCharacterInsideItsParagraph() {
    var t = Text("first line")
    #expect(t.insert(br) == Change(edits: [.insert(at: 10, br)], motion: .before(added: br, removed: "")))
    t.insert("second")
    #expect(t.paragraphs == ["first line\u{2028}second"] && t.count == 17 && t.utf16Caret == 17)
    for _ in 0 ..< 6 { t.moveLeft() }
    #expect(t.moveLeft() == Change(motion: .caret(passed: br, leftward: true)))  // ← past the ↵ lands before it
    #expect(marked(t) == "first line|\u{2028}second" && t.utf16Caret == 10)
    #expect(t.moveRight() == Change(motion: .caret(passed: br, leftward: false)))
    #expect(t.deleteBackward() == Change(edits: [.delete(at: 10, count: 1)], motion: .before(added: "", removed: br)))
    #expect(marked(t) == "first line|second")
    t.insert(br)
    t.moveLeft()
    #expect(t.deleteForward() == Change(edits: [.delete(at: 10, count: 1)], motion: .after(removed: br)))
    #expect(t.paragraphs == ["first linesecond"])
    t = Text("one")
    t.insert(br)
    t.insert(br)  // ⇧⏎ twice: two line breaks, kept as typed
    t.insert("two")
    t.insert("\n")  // and Return still ends the paragraph
    #expect(t.paragraphs == ["one\u{2028}\u{2028}two", ""] && t.count == 9)
}

/// ⌥← and ⌥→ take a line break as white space, a word's end; ⌘← and ⌘→ go to the paragraph's ends past it; ⌥⌫ takes
/// what ⌥← passes.
@Test func wordMovesStopAtALineBreakAndParagraphMovesPassIt() {
    var t = Text("zero\nthe reeds\u{2028}the boats\nend", caret: 24)  // after "boats"
    t.moveWordLeft()
    #expect(marked(t) == "zero\nthe reeds\u{2028}the |boats\nend")
    t.moveWordLeft()
    #expect(marked(t) == "zero\nthe reeds\u{2028}|the boats\nend")
    #expect(t.moveWordLeft() == Change(motion: .caret(passed: "reeds\u{2028}", leftward: true)))
    t.moveWordRight()
    #expect(marked(t) == "zero\nthe reeds|\u{2028}the boats\nend")
    #expect(t.moveWordRight() == Change(motion: .caret(passed: "\u{2028}the", leftward: false)))
    #expect(t.moveToParagraphStart() == Change(motion: .caret(passed: "the reeds\u{2028}the", leftward: true)))
    #expect(marked(t) == "zero\n|the reeds\u{2028}the boats\nend")
    #expect(t.moveToParagraphEnd() == Change(motion: .caret(passed: "the reeds\u{2028}the boats", leftward: false)))
    #expect(marked(t) == "zero\nthe reeds\u{2028}the boats|\nend")
    t = Text("one\u{2028}two", caret: 4)
    #expect(t.deleteWordBackward() == Change(edits: [.delete(at: 0, count: 4)],
                                             motion: .before(added: "", removed: "one\u{2028}")))
    t = Text("one\u{2028}two", caret: 3)
    #expect(t.deleteWordForward() == Change(edits: [.delete(at: 3, count: 4)], motion: .after(removed: "\u{2028}two")))
}

/// A selection runs across a line break as across any Character: ⇧← and ⇧⌥→ take it, ⇧⌘← goes past it to the
/// paragraph's start; ⌘C and ⌘X copy it as "\n", as the output has it; typing replaces it, ⌫ takes it.
@Test func aSelectionRunsAcrossALineBreak() {
    var t = Text("ab\u{2028}cd", caret: 3)  // just after the line break
    #expect(t.moveLeft(extending: true) == Change(motion: .caret(passed: br, leftward: true)))
    #expect(selecting(t) == "ab|\u{2028}^cd" && t.selection == 2..<3 && t.selectedText == "\n")
    t.moveWordRight(extending: true)  // turned round: from the anchor on to the end of "cd"
    #expect(selecting(t) == "ab\u{2028}^cd|" && t.selectedText == "cd")
    t.moveToParagraphStart(extending: true)  // ⇧⌘←: past the line break to the paragraph's start
    #expect(selecting(t) == "|ab\u{2028}^cd" && t.selectedText == "ab\n" && t.utf16Selection == 0..<3)
    #expect(t.insert("x") == Change(edits: [.delete(at: 0, count: 3), .insert(at: 0, "x")],
                                    motion: .before(added: "x", removed: "")))  // the caret at its start, as ⌦'s cut
    #expect(selecting(t) == "x|cd")
    t = Text("one\u{2028}two\nthree")
    t.selectAll()
    #expect(t.selectedText == "one\ntwo\nthree")  // a line break and a paragraph end alike: "\n" for ⌘C
    #expect(t.deleteBackward().edits == [.delete(at: 0, count: 13)] && t.plainText == "")
}

// MARK: Paste, undo and redo (pass 30)

/// Writes as the line does (LineView): each key's edit kept for ⌘Z with its kind at its time (`History.record`; keys
/// 0.1 s apart unless a pause is given), a move closing the group, ⌘V as one edit of `Text.pasted`'s text, ⌘Z and
/// ⌘⇧Z; and the edits the journal gets, every key's in order.
struct Writer {
    var text = Text(), history = History(), edits: [Edit] = [], t = 0.0

    mutating func key(_ kind: History.Kind, after pause: Double = 0.1, _ k: (inout Text) -> Change) {
        t += pause
        let before = text, change = k(&text)
        history.record(change, from: before, to: text, kind: kind, at: t)
        edits += change.edits
    }
    /// Each Character a key; the first after `pause`.
    mutating func type(_ s: String, after pause: Double = 0.1) {
        for (i, c) in s.enumerated() { key(.typing, after: i == 0 ? pause : 0.1) { $0.insert(String(c)) } }
    }
    mutating func backspace(after pause: Double = 0.1) { key(.deleting, after: pause) { $0.deleteBackward() } }
    mutating func returnKey() { key(.alone) { $0.insert("\n") } }
    mutating func lineBreak() { key(.alone) { $0.insert(br) } }
    mutating func paste(_ s: String) { key(.alone) { $0.insert(Text.pasted(s)) } }
    mutating func move(_ k: (inout Text) -> Change) {
        let change = k(&text)
        if change.edits.isEmpty, change.motion != .none { history.close() }
    }
    @discardableResult mutating func undo() -> Change { revisit(history.undo(&text)) }
    @discardableResult mutating func redo() -> Change { revisit(history.redo(&text)) }
    private mutating func revisit(_ change: Change) -> Change {
        t += 0.1
        edits += change.edits
        return change
    }
    /// The journal's replay of every edit so far gives the text on screen.
    var replays: Bool { Text(replaying: edits).plainText == text.plainText }
}

/// ⌘V (B4, pass 30; the user, 2026-11-03: "It should be possible to paste text as well."): the newlines of the pasted
/// text as the line has them, a single one a line break and a run of them a paragraph end, "\r\n" and "\r" as one
/// newline each, those at the very end dropped, a tab one space, the rest as it is.
@Test func aPastesNewlinesBecomeLineBreaksAndParagraphEnds() {
    #expect(Text.pasted("one\ntwo") == "one\u{2028}two")  // a single newline: a line break, as ⇧⏎
    #expect(Text.pasted("one\n\ntwo") == "one\ntwo" && Text.pasted("one\n\n\n\ntwo") == "one\ntwo")  // a paragraph end
    #expect(Text.pasted("one\r\ntwo\r\n\r\nthree") == "one\u{2028}two\nthree")  // "\r\n" one newline
    #expect(Text.pasted("one\rtwo\r\rthree") == "one\u{2028}two\nthree")  // and "\r"
    #expect(Text.pasted("a\u{2028}b\u{2029}\u{2029}c") == "a\u{2028}b\nc")  // a newline of any kind counts
    #expect(Text.pasted("Note name\n") == "Note name" && Text.pasted("end\r\n\r\n") == "end")  // the end's dropped
    #expect(Text.pasted("\n\nstart") == "\nstart")  // at the start kept
    #expect(Text.pasted("col\tumn\t") == "col umn ")  // a tab one space
    #expect(Text.pasted("  two  spaces, i. e. as is ") == "  two  spaces, i. e. as is ")  // no R1 here
    #expect(Text.pasted("\n\r\n") == "" && Text.pasted("") == "")  // nothing left: ⌘V does nothing
}

/// ⌘V types its text at the caret in one insert, over the selection as typing does (⌫'s or ⌦'s cut of it first).
@Test func aPasteReplacesTheSelection() {
    var t = Text("the slow fox", caret: 4)
    t.moveWordRight(extending: true)  // "slow", the caret at its end
    let pasted = Text.pasted("quick\nbrown")
    #expect(t.insert(pasted) == Change(edits: [.delete(at: 4, count: 4), .insert(at: 4, "quick\u{2028}brown")],
                                       motion: .before(added: "quick\u{2028}brown", removed: "slow")))
    #expect(selecting(t) == "the quick\u{2028}brown| fox" && t.paragraphs.count == 1)
    t = Text("a b", caret: 1)
    #expect(t.insert(Text.pasted(" new\n\npara")).edits == [.insert(at: 1, " new\npara")])
    #expect(marked(t) == "a new\npara| b")
}

/// An emoji pasted (the user's case: an Obsidian note's name with one in it) is one Character as typed ones are: one
/// step of ← and one ⌫, a flag, a ZWJ sequence with a skin tone and a letter with a combining accent alike.
@Test func anEmojiPastedIsOneCharacter() {
    var t = Text("Notes: ")
    t.insert(Text.pasted("🦆 Ducks 🇩🇪 👩🏽‍💻 cafe\u{301}"))
    #expect(t.count == 7 + 16 && t.plainText.unicodeScalars.count == 7 + 21)  // 👩🏽‍💻 four scalars, 🇩🇪 two
    #expect(t.deleteBackward() == Change(edits: [.delete(at: 22, count: 1)],
                                         motion: .before(added: "", removed: "e\u{301}")))
    for _ in 0 ..< 4 { t.deleteBackward() }  // "caf" and the space
    #expect(t.deleteBackward() == Change(edits: [.delete(at: 17, count: 1)],
                                         motion: .before(added: "", removed: "👩🏽‍💻")))
    t.deleteBackward()
    #expect(t.moveLeft() == Change(motion: .caret(passed: "🇩🇪", leftward: true)))  // the flag, one step
    #expect(t.moveLeft(extending: true) == Change(motion: .caret(passed: " ", leftward: true)))
    t.moveWordLeft(extending: true)
    t.moveWordLeft(extending: true)
    #expect(t.selectedText == "🦆 Ducks " && t.utf16Selection == 7..<16)  // 🦆 is two UTF-16 units
}

/// Typed keys are one group of ⌘Z's while they come less than `History.pause` apart and nothing else comes between:
/// a pause of 1 s, a move, a delete, starts the next. ⌘Z gives back the text and the caret before the group, ⌘⇧Z the
/// text and the caret after it; the edits of both are the journal's ordinary ones, and its replay is the text.
@Test func typedRunsUndoAsOneGroupUntilAPauseOrAMove() {
    var w = Writer()
    w.type("the quick")
    w.type(" brown", after: History.pause)  // a pause of 1 s: a group of its own
    w.type(" fox", after: History.pause - 0.01)  // under it: the same group
    #expect(w.undo() == Change(edits: [.delete(at: 9, count: 10)], motion: .before(added: "", removed: " brown fox")))
    #expect(marked(w.text) == "the quick|" && w.replays)
    #expect(w.undo().edits == [.delete(at: 0, count: 9)] && w.text.plainText == "" && w.undo() == Change())  // no more
    #expect(w.redo() == Change(edits: [.insert(at: 0, "the quick")], motion: .before(added: "the quick", removed: "")))
    #expect(w.redo().edits == [.insert(at: 9, " brown fox")] && marked(w.text) == "the quick brown fox|")
    #expect(w.redo() == Change() && w.replays)  // nothing left to redo
    w.move { $0.moveWordLeft() }  // a move: the next key starts a group, even back where it was
    w.move { $0.moveWordRight() }
    w.type("es")
    w.move { $0.moveLeft() }
    w.move { $0.moveLeft() }
    w.type("x")
    #expect(marked(w.text) == "the quick brown foxx|es")
    w.undo()
    #expect(marked(w.text) == "the quick brown fox|es")  // the caret where the move left it
    w.undo()
    #expect(marked(w.text) == "the quick brown fox|" && w.replays)
}

/// Deletes are a group of their own kind, as typing is: a run of ⌫ with ⌥⌫ in it is one ⌘Z, which puts the text back
/// before the caret (it glides out as typing would); a run of ⌦ after a move another, put back after the caret, which
/// shows at once. Typing after a delete starts a group, and a pause of 1 s does too.
@Test func deleteRunsUndoAsOneGroup() {
    var w = Writer()
    w.type("one two three four")
    w.backspace(after: History.pause)
    w.backspace()
    w.key(.deleting) { $0.deleteWordBackward() }  // ⌥⌫: "fo", the run goes on
    #expect(marked(w.text) == "one two three |")
    w.type("4")  // typing: a group of its own
    w.backspace(after: History.pause)  // a pause: another
    w.move { $0.moveToParagraphStart() }
    for _ in 0 ..< 4 { w.key(.deleting) { $0.deleteForward() } }  // ⌦ ×4: "one "
    #expect(marked(w.text) == "|two three " && w.replays)
    #expect(w.undo() == Change(edits: [.insert(at: 0, "one ")], motion: .after(removed: "")))  // after the caret
    #expect(marked(w.text) == "|one two three ")
    #expect(w.undo().edits == [.insert(at: 14, "4")] && marked(w.text) == "one two three 4|")  // the caret back with it
    w.undo()
    #expect(w.undo() == Change(edits: [.insert(at: 14, "four")], motion: .before(added: "four", removed: "")))
    #expect(marked(w.text) == "one two three four|" && w.replays)
}

/// ⌘V, Return, ⇧⏎ and ⌘X are each a group of their own, however fast the keys come: nothing joins them and they
/// join nothing. ⌘Z takes them back one by one, ⌘⇧Z brings them back the same way.
@Test func aPasteReturnAndALineBreakAreEachAGroup() {
    var w = Writer()
    w.type("ab")
    w.returnKey()
    w.type("cd")
    w.lineBreak()
    w.type("e")
    w.paste("🦆 X\nY\n")
    w.type("f")
    #expect(w.text.plainText == "ab\ncd\u{2028}e🦆 X\u{2028}Yf" && w.replays)
    let steps = ["ab\ncd\u{2028}e🦆 X\u{2028}Y", "ab\ncd\u{2028}e", "ab\ncd\u{2028}", "ab\ncd", "ab\n", "ab", ""]
    for text in steps {
        w.undo()
        #expect(w.text.plainText == text && w.text.caret == w.text.count)
    }
    #expect(w.undo() == Change() && w.replays)
    for text in steps.reversed().dropFirst() + ["ab\ncd\u{2028}e🦆 X\u{2028}Yf"] {
        w.redo()
        #expect(w.text.plainText == text && w.text.caret == w.text.count)
    }
    #expect(w.redo() == Change() && w.replays)
    var u = Writer()  // a cut (⌘X) is a group of its own: ⌘Z gives the text back, selected as it was
    u.type("one two")
    u.move { $0.moveWordLeft(extending: true) }
    u.key(.alone) { $0.deleteBackward() }
    u.backspace()
    #expect(u.text.plainText == "one" && u.undo().edits == [.insert(at: 3, " ")])
    u.undo()
    #expect(selecting(u.text) == "one |two^" && u.replays)
}

/// A new edit after ⌘Z ends what ⌘⇧Z could bring back; a move or a selection does not.
@Test func aNewEditClearsRedo() {
    var w = Writer()
    w.type("first")
    w.type(" second", after: History.pause)
    w.undo()
    w.move { $0.moveLeft() }
    w.move { $0.moveRight(extending: true) }
    #expect(w.redo().edits == [.insert(at: 5, " second")] && w.text.plainText == "first second")
    w.undo()
    w.type(" third")
    #expect(w.redo() == Change() && w.text.plainText == "first third")
    w.undo()  // the typing after ⌘Z is a group of its own, even where it began at the group's end
    #expect(w.text.plainText == "first" && w.replays)
}

/// ⌘Z across a selection's replacement gives back the text with the selection as it was, the caret at the end it
/// was at; the typing after the replacement joins its group, as in a Mac text field; ⌘⇧Z types it again.
@Test func undoAcrossASelectionReplacementRestoresTheSelection() {
    var w = Writer()
    w.type("the slow fox")
    w.move { $0.moveWordLeft() }
    w.move { $0.moveLeft() }
    w.move { $0.moveWordLeft(extending: true) }  // "slow", the caret at its start
    w.type("quick", after: History.pause)
    #expect(marked(w.text) == "the quick| fox")
    #expect(w.undo() == Change(edits: [.delete(at: 4, count: 5), .insert(at: 4, "slow")],
                               motion: .before(added: "", removed: "quick")))
    #expect(selecting(w.text) == "the |slow^ fox" && w.text.selectedText == "slow")
    #expect(w.redo().edits == [.delete(at: 4, count: 4), .insert(at: 4, "quick")])
    #expect(selecting(w.text) == "the quick| fox")
    w.undo()
    w.move { $0.moveToParagraphEnd() }
    w.move { $0.moveWordLeft(extending: true) }  // "fox", the caret at its start
    w.paste("🦆")  // ⌘V over it
    #expect(marked(w.text) == "the slow 🦆|")
    #expect(w.undo() == Change(edits: [.delete(at: 9, count: 1), .insert(at: 9, "fox")],
                               motion: .before(added: "", removed: "🦆")))
    #expect(selecting(w.text) == "the slow |fox^" && w.replays)
    var all = Writer()  // ⌘A and a letter: everything back, selected, the caret at the end
    all.type("a\u{2028}b\nc")
    all.move { $0.selectAll() }
    all.type("x", after: History.pause)
    #expect(all.undo() == Change(edits: [.delete(at: 0, count: 1), .insert(at: 0, "a\u{2028}b\nc")],
                                 motion: .before(added: "a\u{2028}b\nc", removed: "x")))
    #expect(selecting(all.text) == "^a\u{2028}b\nc|" && all.replays)
}

/// ⌘Z after the caret moved on: the text and the caret as before the group, wherever the caret is now; what the two
/// texts share before the caret stays still, the rest glides. Should the cut's two ends join into one Character (a
/// lone regional indicator each), the whole text is put in, so the text is still exactly what it was.
@Test func undoGivesBackTheTextWhereverTheCaretIs() {
    var w = Writer()
    w.type("ab ")
    w.type("cd", after: History.pause)
    for _ in 0 ..< 4 { w.move { $0.moveLeft() } }
    #expect(marked(w.text) == "a|b cd")
    #expect(w.undo() == Change(edits: [.delete(at: 3, count: 2)], motion: .before(added: "b ", removed: "")))
    #expect(marked(w.text) == "ab |" && w.replays)
    var t = Text("\u{1F1E9}x\u{1F1EA}", caret: 2)  // 🇩, x, 🇪: three Characters; without the x one flag
    let change = t.become(Text("\u{1F1E9}y\u{1F1EA}", caret: 2))
    #expect(t.plainText == "\u{1F1E9}y\u{1F1EA}" && t.count == 3 && t.caret == 2)
    var replayed = Text("\u{1F1E9}x\u{1F1EA}")
    for e in change.edits { replayed.apply(e) }
    #expect(replayed.plainText == t.plainText)
}
