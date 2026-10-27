// The box (W2) and paste at Done (O3): the box's frame on a screen and its clamps, the review growing it upward from
// its bottom edge, which container is on screen, the paste's decision table, when the old clipboard comes back.
import CoreGraphics
import Testing
@testable import FlowCore

/// A laptop's visible frame: 1512 pt wide, the Dock 80 pt below it, the menu bar above.
private let laptop = CGRect(x: 0, y: 80, width: 1512, height: 868)

@Test func boxIsCentredInTheLowerThird() {
    #expect(BoxFrame.height(fontSize: 28) == 112)  // the 2 em band and one em above and below
    let b = BoxFrame.line(in: laptop, height: 112)
    #expect(b.width == 907)  // 60 % of 1512 is 907.2
    #expect(b.height == 112)
    #expect(abs(b.midX - laptop.midX) <= 0.5)
    #expect(abs(b.midY - (laptop.maxY - 2 * laptop.height / 3)) <= 0.5)  // two thirds of the way down
    #expect(laptop.contains(b))
    #expect(b.minX == b.minX.rounded() && b.minY == b.minY.rounded())  // whole points
    // A second screen to the right and lower: the box follows its visible frame, not the main one's.
    let right = CGRect(x: 1512, y: -300, width: 2560, height: 1415)
    let r = BoxFrame.line(in: right, height: 112)
    #expect(r.width == 1536 && abs(r.midX - right.midX) <= 0.5 && right.contains(r))
    #expect(abs(r.midY - (right.minY + right.height / 3)) <= 0.5)
}

@Test func boxClampsToItsScreen() {
    let narrow = BoxFrame.line(in: CGRect(x: 0, y: 0, width: 800, height: 600), height: 112)
    #expect(narrow.width == 600 && narrow.minX == 100)  // 60 % would be 480: not under 600 pt
    let tiny = CGRect(x: 10, y: 20, width: 500, height: 100)
    let t = BoxFrame.line(in: tiny, height: 112)
    #expect(t == tiny)  // never wider or taller than the screen, never outside it
    let low = CGRect(x: 0, y: 0, width: 1000, height: 150)  // a third up is 50 pt: the box would hang below
    let l = BoxFrame.line(in: low, height: 112)
    #expect(l.minY == 0 && low.contains(l))
}

@Test func reviewGrowsUpwardFromTheBottomEdge() {
    let b = BoxFrame.line(in: laptop, height: 112)
    let g = BoxFrame.grown(b, in: laptop)
    #expect(g.minY == b.minY && g.minX == b.minX && g.width == b.width)  // in place: the bottom edge stays
    #expect(g.height == 521)  // 60 % of 868 is 520.8
    #expect(laptop.contains(g))
    #expect(BoxFrame.shrunk(g, height: 112) == b)  // Back: the line's box again
    // Dragged up high: the top stops at the visible frame's top.
    let high = CGRect(x: 100, y: 700, width: 907, height: 112)
    #expect(BoxFrame.grown(high, in: laptop) == CGRect(x: 100, y: 700, width: 907, height: 248))
    // A short screen: at least 240 pt while there is room.
    let short = CGRect(x: 0, y: 0, width: 1024, height: 350)
    let s = BoxFrame.grown(BoxFrame.line(in: short, height: 112), in: short)
    #expect(s.height == 240 && short.contains(s))
    // No room above at all: never shorter than the box.
    let top = CGRect(x: 0, y: 900, width: 907, height: 112)
    #expect(BoxFrame.grown(top, in: laptop).height == 112)
}

@Test func oneContainerOnScreenAtATime() {
    var s = Surface()
    #expect(s.onScreen == nil && s.mode == .box)  // at launch nothing shows
    s.toggle(focused: false)
    #expect(s.onScreen == .box)  // the hotkey: the box
    s.toggle(focused: false)
    #expect(s.onScreen == .box)  // on screen but clicked away from: it takes the keys back, it does not go
    s.toggle(focused: true)
    #expect(s.onScreen == nil)  // on screen with the keys: away
    s.show()
    s.hide()
    #expect(s.onScreen == nil)  // Esc, a paste
    s.use(.window)
    #expect(s.onScreen == .window && s.mode == .window)  // Open Window: the window, the box gone
    s.toggle(focused: true)
    #expect(s.onScreen == nil && s.mode == .window)  // the hotkey hides the window and keeps the mode
    s.toggle(focused: false)
    #expect(s.onScreen == .window)  // and brings the window back, not the box
    s.use(.box)
    #expect(s.onScreen == .box && s.mode == .box)  // ⌃⌘F again or the close button: back to the box
}

@Test func pasteDecidesBeforeAnythingHappens() {
    typealias P = Paste
    #expect(P.decide(secureInput: false, mayPost: true, hasTarget: true) == .paste)
    #expect(P.decide(secureInput: true, mayPost: true, hasTarget: true) == .copy(note: P.secureNote, ask: false))
    #expect(P.decide(secureInput: false, mayPost: false, hasTarget: true) == .copy(note: P.permissionNote, ask: true))
    #expect(P.decide(secureInput: false, mayPost: true, hasTarget: false) == .copy(note: P.noTargetNote, ask: false))
    // In order: Secure Input over a missing permission (no prompt then), the permission over a missing target.
    #expect(P.decide(secureInput: true, mayPost: false, hasTarget: false) == .copy(note: P.secureNote, ask: false))
    #expect(P.decide(secureInput: false, mayPost: false, hasTarget: false) == .copy(note: P.permissionNote, ask: true))
    #expect(P.secureNote == "Secure input is on: copied instead")
    #expect(P.permissionNote == "Copied · allow Flow under Privacy & Security › Accessibility to paste")
    #expect(P.noTargetNote == "Copied · no app to paste into")
    #expect(P.settle == 0.12 && P.restoreAfter == 0.25)
}

@Test func oldClipboardReturnsOnlyOverFlowsOwnItem() {
    #expect(Paste.restores(written: 41, now: 41))  // still Flow's item: the old one comes back
    #expect(!Paste.restores(written: 41, now: 42))  // copied again since (the user, a clipboard manager): it stays
    #expect(!Paste.restores(written: 41, now: 40))
}

@Test func pastedGraceEndsAsCopyDoes() {
    var s = Session()
    s.done()
    let pasted = s.handedOff(.pasted, at: 100)
    #expect(pasted && s.phase == .graced(.pasted, until: 110))
    let copied = s.handedOff(.copied, at: 100.12)  // Secure Input came on before the ⌘V: copied instead
    #expect(copied && s.phase == .graced(.copied, until: 110.12))
    let stale = s.tick(at: 110)
    #expect(!stale)  // the paste's grace end is stale
    #expect(s.undo() && s.phase == .review)  // Undo within the grace keeps the text
}
