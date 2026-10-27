// Flow (working name), milestone 1: the writing surface in an ordinary window (DESIGN.md S1 V2 B1 P0 W1).
import AppKit
import FlowCore

final class App: NSObject, NSApplicationDelegate {
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let font = (NSFont(name: "Menlo", size: 28) ?? .monospacedSystemFont(ofSize: 28, weight: .regular)) as CTFont
        let style = Style(font: font), view = LineView(style: style)
        // Titled, with its standard buttons, so tiling window managers (AeroSpace, yabai) treat it as a normal window.
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 700),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.appearance = NSAppearance(named: .darkAqua)  // buttons drawn for the dark background
        window.backgroundColor = NSColor(cgColor: style.background)
        window.collectionBehavior = .fullScreenPrimary  // toggleFullScreen: may do nothing without it
        window.contentMinSize = NSSize(width: 600, height: 300)
        if !window.setFrameUsingName("Flow") { window.center() }
        window.setFrameAutosaveName("Flow")
        window.makeKeyAndOrderFront(nil)
        // The view goes in once the window is on screen, so the strip's first frames are presented to a layer that is
        // shown: only then is a drawable sure to come back to the layer's pool of two.
        window.contentView = view
        window.makeFirstResponder(view)
        NSApp.activate()
    }

    // Milestone 1 keeps nothing (no journal yet), so closing the window ends the app. Milestone 2 changes this: the
    // journal (DESIGN.md E2) keeps the text across a close and ⌘Q.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// Flow: Quit; View: Enter Full Screen. No Edit menu yet, so no ⌘ shortcut but these two reaches the text.
func mainMenu() -> NSMenu {
    let bar = NSMenu(), app = NSMenu(title: "Flow"), view = NSMenu(title: "View")
    app.addItem(withTitle: "Quit Flow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    view.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        .keyEquivalentModifierMask = [.control, .command]
    for menu in [app, view] { bar.addItem(withTitle: menu.title, action: nil, keyEquivalent: "").submenu = menu }
    return bar
}

let app = NSApplication.shared
NSWindow.allowsAutomaticWindowTabbing = false  // keeps the tab items out of the View menu
app.setActivationPolicy(.regular)
app.mainMenu = mainMenu()
let delegate = App()
app.delegate = delegate
app.run()
