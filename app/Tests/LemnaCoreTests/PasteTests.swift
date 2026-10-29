// Paste at Done (O3), pass 17a: what waits for what between ⌘⏎ and the posted ⌘V. Until then every paste with ⌘ still
// held as Return came up waited a whole second (AppKit gives such a key-up to no window, so the box never saw it) and
// finished the session (the keychain, 30 ms here) before the box went.
import Testing
@testable import LemnaCore

private typealias R = ReturnUp

@Test func onlyAReturnKeyDownWaits() {
    #expect(R.waits(keyDown: true, code: 36))  // ⌘⏎, ⌘⇧⏎: Return
    #expect(R.waits(keyDown: true, code: 76))  // the keypad's Enter
    #expect(!R.waits(keyDown: false, code: 36))  // the menu-bar item's Done: a click, not a key
    #expect(!R.waits(keyDown: true, code: 1))  // ⌘S's S: the save panel comes, nothing to wait for
}

@Test func theKeyUpEndsTheWaitWhateverModifiersItCarries() {
    // The monitor sees the key-up before AppKit drops it, ⌘ down or not; the codes are all the wait reads.
    let w = R(at: 10)
    #expect(w.take(.keyUp(36), at: 10.09) == .keyUp)
    #expect(w.take(.keyUp(76), at: 10.09) == .keyUp)
    #expect(w.take(.keyUp(0), at: 10.09) == nil)  // another key coming up (A): still waiting
}

@Test func aKeyDownWithNoKeyUpWaitsOnlyUntilTheNextRead() {
    // The key-up went elsewhere (or never came): the first read that finds the key up ends it, not the cap.
    let w = R(at: 10)
    #expect(w.take(.check(down: true), at: 10) == nil)  // read at once: still held
    #expect(w.take(.check(down: false), at: 10 + R.poll) == .released)
    #expect(R.poll == 0.05)
    // Already up when the key-down's turn comes (the main thread was busy): at once.
    #expect(R(at: 10).take(.check(down: false), at: 10.002) == .released)
}

@Test func aHeldKeyKeepsTheBoxUpToTheCap() {
    let w = R(at: 10)
    var t = 10.0, end: R.End?
    while end == nil {
        t += R.poll
        end = w.take(.check(down: true), at: t)
    }
    #expect(end == .cap)
    #expect(abs(t - 10 - R.cap) < 1e-9 && R.cap == 1)  // as before pass 17a, for a key really held
    #expect(w.take(.keyUp(1), at: 11.2) == .cap)  // any signal past the cap ends it
}

@Test func pasteStepsPutNothingSlowBeforeTheCommandV() {
    typealias P = Paste
    // The box never activated Lemna: the app behind is in front, only the keys' way back is waited for.
    #expect(P.acts(targetInFront: true)
            == [.write, .hide, .settle(P.settleInFront), .checkSecureInput, .post, .finish])
    // After the window or a question Lemna is active: the app is brought forward and given its activation's time.
    #expect(P.acts(targetInFront: false)
            == [.write, .hide, .bringForward, .settle(P.settle), .checkSecureInput, .post, .finish])
    #expect(P.settleInFront == 0.03 && P.settle == 0.12)
    for inFront in [true, false] {
        let acts = P.acts(targetInFront: inFront)
        let post = acts.firstIndex(of: .post)!
        #expect(acts.last == .finish && post == acts.count - 2)  // the journal's finish only after the ⌘V
        #expect(acts.firstIndex(of: .hide)! < acts.firstIndex { if case .settle = $0 { true } else { false } }!)
        #expect(acts.firstIndex(of: .checkSecureInput)! == post - 1)  // read once the keys are back, just before
    }
}
