// The end of a session as a state machine: writing → handing off → cleared (finished at once) → writing.
import Testing
@testable import FlowCore

@Test func handOffFinishesAtOnce() {
    var s = Session()
    #expect(s.phase == .writing)
    #expect(s.handOff() && s.phase == .handingOff)
    let twice = s.handOff()
    #expect(!twice)  // ⌘⏎'s auto-repeat while Paste waits for Return to come up
    #expect(s.handedOff() && s.phase == .cleared)  // no grace: the key goes, the surface clears
    let again = s.handedOff()
    #expect(!again)  // once only
    #expect(s.started() && s.phase == .writing)  // a new session
}

@Test func aHandOffThatDidNotHappenDestroysNothing() {
    var s = Session()
    s.handOff()
    #expect(s.back() && s.phase == .writing)  // the save panel cancelled, the pasteboard refused
    let backTwice = s.back()
    #expect(!backTwice)
}

@Test func discardOnlyWhileWriting() {
    var s = Session()
    #expect(s.discard() && s.phase == .cleared)
    let twice = s.discard()
    #expect(!twice)
    var saving = Session()
    saving.handOff()
    let underThePanel = saving.discard()
    #expect(!underThePanel && saving.phase == .handingOff)  // the save panel is up: Discard is off
}

@Test func eventsOutOfPlaceDoNothing() {
    var s = Session()
    #expect(!s.back() && !s.handedOff() && !s.kept() && !s.started())
    s.handOff()
    #expect(!s.handOff() && !s.kept() && !s.started())
    #expect(s.phase == .handingOff)
}

@Test func keyStoreRefusalKeepsTheSession() {
    var s = Session()
    s.handOff()
    s.handedOff()
    #expect(s.kept() && s.phase == .writing)  // the text stays on the line, an alert says why
}
