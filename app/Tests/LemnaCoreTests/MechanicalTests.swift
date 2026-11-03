// The deterministic pass R1: each rule, what it leaves alone, its counts, and that a second pass changes nothing; since
// pass 29b a line break's one newline.
import Testing
@testable import LemnaCore

private func fix(_ s: String) -> String { Mechanical.apply(s).text }

@Test func capitalAtParagraphStartAndAfterASentenceEnd() {
    #expect(fix("hello. this is it! and more? yes") == "Hello. This is it! And more? Yes")
    #expect(fix("one\ntwo") == "One\n\nTwo")  // each paragraph's start
    #expect(fix(" leading space") == " Leading space")  // the first letter, after the space
    #expect(fix("über. ärger") == "Über. Ärger")
    #expect(Mechanical.apply("go. be. see").capitals == 3)
}

@Test func noCapitalWhereASentenceMayNotEnd() {
    #expect(fix("Use e.g. this") == "Use e.g. this")  // a word with another period in it
    #expect(fix("Das ist z. B. gut") == "Das ist z. B. gut")  // one letter
    #expect(fix("Am 3. und 4. Mai") == "Am 3. und 4. Mai")  // digits alone: an ordinal
    #expect(fix("Wait... then") == "Wait... then")  // an ellipsis
    #expect(fix("End.next") == "End.next")  // no space after the period
    #expect(fix("Said \"so.\" then") == "Said \"so.\" then")  // a quote between: left alone
    #expect(fix("- item") == "- item")  // the paragraph starts with no letter
}

@Test func collapsesRunsOfSpaces() {
    let r = Mechanical.apply("A  b   c d")
    #expect(r.text == "A b c d")
    #expect(r.spaces == 2)  // one per run, however long
    #expect(fix("End.   next") == "End. Next")  // collapsed first, so the capital follows
    #expect(fix("A\u{A0}\u{A0}b") == "A\u{A0}\u{A0}b")  // no-break spaces are typed on purpose
}

@Test func stripsTrailingSpacesPerParagraph() {
    let r = Mechanical.apply("One  \nTwo \nThree")
    #expect(r.text == "One\n\nTwo\n\nThree")
    #expect(r.trailing == 2 && r.spaces == 0)  // a trailing run counts once, as trailing
}

@Test func loneIBecomesCapital() {
    #expect(fix("So i think i'm right, and i.") == "So I think I'm right, and I.")
    #expect(fix("Then (i) did") == "Then (I) did")
    #expect(fix("He and i") == "He and I")
    #expect(Mechanical.apply("so i, i").lone == 2)
}

@Test func loneILeavesWordsAndAbbreviationsAlone() {
    #expect(fix("Ii in pi i.e. this, i-th, Wi-Fi") == "Ii in pi i.e. this, i-th, Wi-Fi")
    #expect(Mechanical.apply("Ii in pi i.e. this").lone == 0)
}

@Test func paragraphsJoinedByABlankLine() {
    #expect(fix("One\n\nTwo\n") == "One\n\nTwo")  // Return twice and a last empty paragraph: no empty ones
    #expect(fix("One\n  \nTwo") == "One\n\nTwo")  // nothing but spaces: empty too
    #expect(fix("") == "")
}

/// ⇧⏎'s line break (pass 29b) comes out as one "\n" inside its paragraph, Return's paragraph end as a blank line: no
/// capital after a line break (neither a paragraph's start nor a sentence end), two line breaks a blank line as typed,
/// a line's trailing spaces stripped as a paragraph's are; never a U+2028 in the output.
@Test func aLineBreakComesOutAsOneNewline() {
    #expect(fix("the reeds\u{2028}the boats\nthe water") == "The reeds\nthe boats\n\nThe water")
    #expect(fix("one.\u{2028}two") == "One.\ntwo")  // a sentence end before it: still no capital
    #expect(fix("a\u{2028}\u{2028}b") == "A\n\nb")  // ⇧⏎ twice: a blank line, kept as typed
    #expect(fix("one\u{2028} two") == "One\n two")  // a line's leading space stays, as a paragraph's does
    #expect(fix("so\u{2028}i think") == "So\nI think")  // a lone i after it: white space before it
    #expect(fix("Dear\u{2028}A. Reed") == "Dear\nA. Reed" && fix("one\u{2028}A. next") == "One\nA. next")  // an initial
    let r = Mechanical.apply("one  \u{2028}two \nthree")
    #expect(r.text == "One\ntwo\n\nThree" && r.trailing == 2 && r.spaces == 0)  // a line's end as a paragraph's
    #expect(fix("one\u{2028}  \u{2028}two") == "One\n\ntwo")  // a line of spaces is empty, the line breaks stay
    #expect(!fix("a\u{2028}b\u{2028}").contains("\u{2028}") && fix("a\u{2028}b\u{2028}") == "A\nb\n")
}

@Test func nothingElse() {
    let s = "Teh cat sat on teh mat and did not stop"  // no full stop added, no spelling
    #expect(Mechanical.apply(s) == Mechanical.Result(text: s))
    #expect(fix("Ok,fine;  done") == "Ok,fine; done")
}

@Test func counts() {
    let r = Mechanical.apply("hello  world, i said so \nnext")
    #expect((r.capitals, r.spaces, r.trailing, r.lone) == (2, 1, 1, 1))  // "Hello", "Next"; one run; one end; "I"
    #expect(r.count == 5)
    #expect(Mechanical.apply("Fine.").count == 0)
}

@Test func secondPassChangesNothing() {
    let samples = ["hello  world. i said so \nnext", "a. b! c? d", "  lead\n\n\ntrail   ", "e.g. this. i.e. that. i",
                   "one\n \ntwo", "über.  ärger i'm", "ßtart. ßo", ""]
    for s in samples {
        let once = Mechanical.apply(s), twice = Mechanical.apply(once.text)
        #expect(twice.text == once.text, "\(s)")
        #expect(twice.count == 0, "\(s)")
    }
}
