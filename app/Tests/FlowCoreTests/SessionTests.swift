// The end of a session as a state machine: writing → review → graced(finish at t) → cleared → writing.
import Testing
@testable import FlowCore

@Test func doneCopyGraceThenCleared() {
    var s = Session()
    #expect(s.phase == .writing)
    #expect(s.done() && s.phase == .review)
    let copied = s.handedOff(.copied, at: 100)
    #expect(copied)
    #expect(s.phase == .graced(.copied, until: 100 + Session.grace))
    #expect(!s.tick(at: 109.9) && s.phase == .graced(.copied, until: 110))  // still within the grace
    #expect(s.tick(at: 110) && s.phase == .cleared)  // the key goes, the surface clears
    let again = s.tick(at: 111)
    #expect(!again)  // once only
    #expect(s.started() && s.phase == .writing)  // a new session
}

@Test func undoWithinTheGraceKeepsTheSessionAndTheReview() {
    var s = Session()
    s.done()
    s.handedOff(.saved(name: "flow.md"), at: 0)
    #expect(s.undo() && s.phase == .review)
    #expect(!s.tick(at: 10) && s.phase == .review)  // the timer of the undone grace finds nothing to do
    let undoneTwice = s.undo()
    #expect(!undoneTwice)  // nothing left to undo
}

@Test func anotherHandoffStartsTheGraceAgain() {
    var s = Session()
    s.done()
    s.handedOff(.copied, at: 0)
    let saved = s.handedOff(.saved(name: "a.md"), at: 5), stale = s.tick(at: 10)
    #expect(saved && !stale)  // the first grace's end is stale
    #expect(s.tick(at: 15) && s.phase == .cleared)
}

@Test func backDestroysNothing() {
    var s = Session()
    s.done()
    #expect(s.back() && s.phase == .writing)
    s.done()
    s.handedOff(.copied, at: 0)
    #expect(s.back() && s.phase == .writing)  // Back during a grace drops it
    #expect(!s.tick(at: 10) && s.phase == .writing)
    let backTwice = s.back()
    #expect(!backTwice)
}

@Test func discardFromAnyPhaseButCleared() {
    for setup in [{ (s: inout Session) in }, { $0.done() }, { $0.done(); $0.handedOff(.copied, at: 0) }]
        as [(inout Session) -> Void] {
        var s = Session()
        setup(&s)
        #expect(s.discard() && s.phase == .cleared)
        let twice = s.discard()
        #expect(!twice)
    }
}

@Test func eventsOutOfPlaceDoNothing() {
    var s = Session()
    #expect(!s.back() && !s.undo() && !s.handedOff(.copied, at: 0) && !s.tick(at: 99) && !s.kept() && !s.started())
    s.done()
    #expect(!s.done() && !s.undo() && !s.started())
    #expect(s.phase == .review)
}

@Test func keyStoreRefusalKeepsTheSession() {
    var s = Session()
    s.done()
    s.handedOff(.copied, at: 0)
    s.tick(at: 10)
    #expect(s.kept() && s.phase == .review)  // the review stays and says why
}

@Test func durations() {
    #expect(Session.duration(0) == "< 1 min")
    #expect(Session.duration(59.9) == "< 1 min")
    #expect(Session.duration(60) == "1 min")
    #expect(Session.duration(59 * 60 + 59) == "59 min")
    #expect(Session.duration(3600) == "1 h")
    #expect(Session.duration(3900) == "1 h 5 min")
    #expect(Session.duration(-5) == "< 1 min")
}
