// The box (DESIGN.md W2): a small floating panel over whatever the user is doing, with the rest of every screen dimmed.
// It takes the keys without activating Flow, so the app behind stays the active one (and is where Paste goes, O3). The
// line moves into it from the window and back (one LineView).
import AppKit
import FlowCore

/// A non-activating panel that can be key although it is borderless (AppKit's `canBecomeKey` is true only for titled
/// windows).
final class BoxPanel: NSPanel {
    /// Each key that comes up while the box has the keys: Paste waits for Return's.
    var onKeyUp: (UInt16) -> Void = { _ in }

    override var canBecomeKey: Bool { true }

    override func sendEvent(_ e: NSEvent) {
        if e.type == .keyUp { onKeyUp(e.keyCode) }
        // Flow is not the active app while the box has the keys. Should AppKit then leave out the main menu's key
        // equivalents (Done ⌘⏎, Copy ⌘⇧C, Save… ⌘S, Open Window ⌃⌘F, Sound ⌘K, Quit ⌘Q), the menu gets them here; only
        // a key no menu item took reaches this, so nothing runs twice.
        if e.type == .keyDown, e.modifierFlags.contains(.command), NSApp.mainMenu?.performKeyEquivalent(with: e) == true {
            return
        }
        super.sendEvent(e)
    }
}

final class Box {
    let panel: BoxPanel
    private let content = NSView()
    /// One black overlay per screen, under the box.
    private var dims: [NSWindow] = []
    private let lineHeight: CGFloat

    /// `lineHeight`: the box's height while it holds the line (`BoxFrame.height`).
    init(lineHeight: CGFloat) {
        self.lineHeight = lineHeight
        panel = BoxPanel(contentRect: .zero, styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                         backing: .buffered, defer: true)
        panel.level = .floating
        // On every Space and over a full-screen app (as an auxiliary of its Space), left out of Mission Control.
        panel.collectionBehavior = Self.behavior
        panel.hidesOnDeactivate = false  // NSPanel's default; the box stays until Esc, the hotkey or a paste
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none  // on and off screen at once
        panel.appearance = NSAppearance(named: .darkAqua)  // its sheets' buttons, drawn for the dark background
        // Clear around the rounded content so the corners show what is behind, with the system's shadow along them.
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        // 0.97 on the whole box rather than on its background alone: the line's Metal band is opaque, and a background
        // a touch lighter than it would show the band as a stripe. Text at 97 % looks the same.
        panel.alphaValue = 0.97
        content.wantsLayer = true
        content.layer?.backgroundColor = rgb(0x0e1013)
        content.layer?.cornerRadius = 10
        content.layer?.masksToBounds = true  // the line's square layers end at the rounded edge
        content.layer?.borderWidth = 1  // drawn over the sublayers, so the content sits inside it (`inner`)
        content.layer?.borderColor = rgb(0x262b32)
        panel.contentView = content
    }

    static let behavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

    var isVisible: Bool { panel.isVisible }

    /// On screen with the keys and the dim. From off screen: on the screen with the pointer, centred in its lower third
    /// (`BoxFrame`), with the line. On screen already (clicked away from): only the keys back.
    func show(_ line: LineView) {
        if !panel.isVisible, let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
            ?? NSScreen.main {
            panel.setFrame(BoxFrame.line(in: screen.visibleFrame, height: lineHeight), display: false)
            dim()
            panel.orderFrontRegardless()  // Flow is not active: plain orderFront may leave it behind the active app's
            hold(line)  // once the panel is on screen, so the strip's first frames reach a shown layer
        }
        panel.makeKey()
    }

    func hide() {
        panel.orderOut(nil)
        for d in dims { d.orderOut(nil) }
    }

    /// The line in the box, inside its border.
    private func hold(_ line: LineView) {
        panel.invalidateShadow()  // the shadow follows the outline (the box on another screen has another width)
        let inner = content.bounds.insetBy(dx: 1, dy: 1)  // inside the border, which would cover the bottom edge
        // One frame per show: the strip's pool holds two drawables, and frames presented in the same turn of the run
        // loop come back only after it, so a third would wait. The size is set first, while the line is still where
        // nothing is drawn (off screen); then moving in draws once (`viewDidMoveToWindow`), else `redraw`.
        if line.frame != inner { line.frame = inner }
        if line.superview !== content {
            line.autoresizingMask = [.width, .maxYMargin]  // a fixed height at the bottom
            content.addSubview(line, positioned: .below, relativeTo: nil)
        } else {
            line.redraw()
        }
        panel.makeFirstResponder(line)
    }

    /// Black at 0.35 over every screen, one level under the box, transparent to the mouse; on and off at once. Made
    /// anew for screens that came since the last time, fitted to each screen's frame on each show.
    private func dim() {
        let screens = NSScreen.screens
        while dims.count < screens.count {
            let d = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true)
            d.backgroundColor = .black
            d.alphaValue = 0.35
            d.isOpaque = false
            d.hasShadow = false
            d.ignoresMouseEvents = true
            d.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
            d.collectionBehavior = Self.behavior
            d.isReleasedWhenClosed = false
            d.animationBehavior = .none
            dims.append(d)
        }
        for (d, s) in zip(dims, screens) {
            d.setFrame(s.frame, display: false)
            d.orderFrontRegardless()
        }
        for d in dims.dropFirst(screens.count) { d.orderOut(nil) }
    }
}
