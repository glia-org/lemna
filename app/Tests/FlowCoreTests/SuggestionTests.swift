// Harper's suggestions in the review (R2) as plain values: accepting one, the ones after it moved, offsets past
// characters of more than one unit, accept all in order, a stale list, the selection, the footer's wording, the
// kind's label, and where the list goes for a width.
import CoreGraphics
import Testing
@testable import FlowCore

/// A suggestion for the first `wrong` in `text`, as the app makes one from Harper's range.
private func suggest(_ wrong: String, in text: String, _ replacement: String?, number: Int = 1,
                     kind: String = "Spelling") -> Suggestion {
    let range = text.firstRange(of: wrong)!
    return Suggestion(number: number, in: text, range: range, replacements: replacement.map { [$0] } ?? [],
                      kind: kind, message: "")
}

@Test func acceptOne() {
    let text = "I saw teh cat."
    let s = suggest("teh", in: text, "the")
    #expect(s.start == 6 && s.length == 3 && s.end == 9)
    #expect(Suggestion.apply(s, to: text) == "I saw the cat.")
    var list = SuggestionList(text: text, items: [s])
    #expect(list.current == s)
    #expect(list.accept() && list.text == "I saw the cat." && list.items.isEmpty && list.selected == nil)
    #expect(list.accepted == 1)
}

@Test func acceptMovesTheLaterOnes() {
    let text = "It was a idea, the the end, teh."
    let a = suggest("a idea", in: text, "an idea", number: 1), twice = suggest("the the", in: text, "the", number: 2)
    let teh = suggest("teh", in: text, "the", number: 3)
    // One character longer: the two after it move one unit right; one before stays.
    let moved = Suggestion.shift([twice, teh], after: a)
    #expect(moved.map(\.start) == [twice.start + 1, teh.start + 1])
    #expect(Suggestion.shift([a], after: teh) == [a])
    // Four characters shorter ("the the" → "the"): the one after moves four units left.
    #expect(Suggestion.shift([teh], after: twice).map(\.start) == [teh.start - 4])
    var list = SuggestionList(text: text, items: [a, twice, teh])
    list.accept()  // the first: "an idea"
    #expect(list.text == "It was an idea, the the end, teh." && list.items.map(\.number) == [2, 3])
    list.move(1)
    list.accept()  // the last: "teh", at its moved place
    #expect(list.text == "It was an idea, the the end, the.")
    list.accept()  // the one left
    #expect(list.text == "It was an idea, the end, the." && list.accepted == 3)
}

@Test func offsetsCountUTF16PastWideCharacters() {
    // é is one UTF-16 unit, 🙂 two, the ZWJ sequence 👩‍💻 five, all single Characters: the offsets are the text view's.
    let text = "Café 🙂 👩‍💻 teh end, a idea."
    let teh = suggest("teh", in: text, "the"), a = suggest("a idea", in: text, "an idea", number: 2)
    #expect(teh.start == 14)  // C a f é, space, 🙂 (2), space, 👩‍💻 (5), space
    #expect(Array(Array(text.utf16)[teh.start..<teh.end]) == Array("teh".utf16))
    var list = SuggestionList(text: text, items: [teh, a])
    list.acceptAll()
    #expect(list.text == "Café 🙂 👩‍💻 the end, an idea.")
    // Accepted from the far end first, the near one still fits: each is applied to the text as it stands.
    var back = SuggestionList(text: text, items: [teh, a])
    back.move(1)
    back.accept()
    back.accept()
    #expect(back.text == list.text)
}

@Test func acceptAllInOrderLeavesTheFlaggedOnes() {
    let text = "teh boats sat low, a idea, Köln, the the"
    let items = [suggest("teh", in: text, "the", number: 1), suggest("a idea", in: text, "an idea", number: 2),
                 suggest("Köln", in: text, nil, number: 3), suggest("the the", in: text, "the", number: 4)]
    var list = SuggestionList(text: text, items: items)
    #expect(list.acceptAll() == 3)
    #expect(list.text == "the boats sat low, an idea, Köln, the")
    #expect(list.items.map(\.number) == [3] && list.selected == 0)  // only pointed at: skip only
    #expect(list.items[0].start == items[2].start + 1)  // moved by "an"
    let none = list.accept()
    #expect(!none && list.accepted == 3)  // nothing to accept with
    #expect(list.skip() && list.items.isEmpty && list.selected == nil)
    #expect(list.text == "the boats sat low, an idea, Köln, the")  // skipping changes no text
}

@Test func staleSuggestionChangesNothing() {
    let s = suggest("teh", in: "I saw teh cat.", "the")
    #expect(Suggestion.apply(s, to: "I saw the cat.") == nil)  // the text no longer holds "teh" there
    #expect(Suggestion.apply(s, to: "I saw") == nil)  // past the end
    var list = SuggestionList(text: "I saw ten cats.", items: [s])
    let applied = list.accept()
    #expect(!applied && list.text == "I saw ten cats." && list.accepted == 0)
    // A deletion: struck out, nothing put in.
    let comma = suggest(",", in: "Yes, , no", "")
    #expect(Suggestion.apply(comma, to: "Yes, , no") == "Yes , no")
}

@Test func rowsAreInTextOrderWhateverOrderTheyCameIn() {
    let text = "teh boats, a idea, the the"
    let a = suggest("teh", in: text, "the", number: 1), b = suggest("a idea", in: text, "an idea", number: 2)
    let c = suggest("the the", in: text, "the", number: 3)
    var list = SuggestionList(text: text, items: [c, a, b])
    #expect(list.items == [a, b, c] && list.current == a)  // row 1 is the first in the text
    list.select(1)
    list.skip()
    #expect(list.items == [a, c])  // c is row 2 now: the rows are numbered by place, 1 to N
}

@Test func selectionMovesSkipsAndClamps() {
    let text = "a teh b teh c teh"
    var items: [Suggestion] = []
    var from = text.startIndex
    for n in 1...3 {
        let r = text[from...].firstRange(of: "teh")!
        items.append(Suggestion(number: n, in: text, range: r, replacements: ["the"], kind: "Spelling", message: ""))
        from = r.upperBound
    }
    var list = SuggestionList(text: text, items: items)
    list.move(-1)
    #expect(list.selected == 0)  // ↑ at the first: stays
    list.move(1)
    list.move(1)
    list.move(1)
    #expect(list.selected == 2)  // ↓ at the last: stays
    list.select(1)
    #expect(list.skip() && list.items.map(\.number) == [1, 3] && list.selected == 1 && list.text == text)
    #expect(list.accept() && list.selected == 0)  // the last one went: the one before it
    list.select(5)
    #expect(list.selected == 0)
    #expect(SuggestionList(text: "x").selected == nil && SuggestionList(text: "x").current == nil)
}

@Test func footerSaysHowManyWereAccepted() {
    let text = "teh a idea"
    var list = SuggestionList(text: text,
                              items: [suggest("teh", in: text, "the"), suggest("a idea", in: text, "an idea")])
    #expect(list.note == nil)  // nothing accepted: the R1 line as before
    list.accept()
    #expect(list.note == "· Harper: 1 accepted")
    list.accept()
    #expect(list.note == "· Harper: 2 accepted")
}

@Test func kindLabels() {
    func label(_ kind: String) -> String {
        Suggestion(number: 1, start: 0, wrong: "x", replacement: nil, kind: kind, message: "").label
    }
    #expect(label("Spelling") == "spelling")
    #expect(label("WordChoice") == "word choice")
    #expect(label("Repetition") == "repetition")
}

@Test func listBesideTheTextFrom820Points() {
    let column: CGFloat = 564, margin: CGFloat = 20  // 72 characters of the 15 pt system font, insets, scroller
    typealias L = ReviewLayout
    // The box's review on a 1512 pt laptop: 907 pt less the border.
    let box = L.columns(width: 905, column: column, margin: margin)
    #expect(box == .init(beside: true, textX: 20, textWidth: 564, listX: 600, listWidth: 285))
    // The window's sheet as wide as the review asks: the list at its widest.
    let sheet = L.columns(width: column + L.gap + L.listWidest + 2 * margin, column: column, margin: margin)
    #expect(sheet.beside && sheet.listWidth == 330 && sheet.textX == 20 && sheet.textWidth == 564)
    // The edge: 820 beside (200 pt of list), one point less below.
    let edge = L.columns(width: 820, column: column, margin: margin)
    #expect(edge.beside && edge.listWidth == 200 && edge.listX + edge.listWidth == 800)
    let narrow = L.columns(width: 819, column: column, margin: margin)
    #expect(narrow == .init(beside: false, textX: 127, textWidth: 564, listX: 127, listWidth: 564))
    // The narrowest box (600 pt) and a narrow sheet: the column narrows to the room, the list under it as wide.
    #expect(L.columns(width: 600, column: column, margin: margin)
        == .init(beside: false, textX: 20, textWidth: 560, listX: 20, listWidth: 560))
    // A wide window's sheet never gets the list wider than the mock-up's.
    #expect(L.columns(width: 1400, column: column, margin: margin).listWidth == 330)
}
