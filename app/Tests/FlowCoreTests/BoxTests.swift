// The box (W2) and paste at Done (O3): the box's frame on a screen and its clamps, which container is on screen, the
// paste's decision table, when the old clipboard comes back, and when a click outside hides the box.
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
    #expect(P.settle == 0.12)
}

@Test func clickOutsideHidesOnlyAnUnguardedBox() {
    // Every combination: only a box on screen with no question, no sheet, and the keys gone to another app.
    for bits in 0..<16 {
        let (onScreen, asking, sheet, flow) = (bits & 1 != 0, bits & 2 != 0, bits & 4 != 0, bits & 8 != 0)
        let hides = ClickOutside.hides(boxOnScreen: onScreen, asking: asking, sheet: sheet, flowHasKeys: flow)
        #expect(hides == (bits == 1), "\(bits)")
    }
    #expect(ClickOutside.hides(boxOnScreen: true, asking: false, sheet: false, flowHasKeys: false))
    // The save panel or a question opened on the box: its sheet has the keys.
    #expect(!ClickOutside.hides(boxOnScreen: true, asking: false, sheet: true, flowHasKeys: true))
    // Esc, the hotkey, a paste, Open Window: the box is already going.
    #expect(!ClickOutside.hides(boxOnScreen: false, asking: false, sheet: false, flowHasKeys: false))
}
