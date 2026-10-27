// Flow (working name): the writing surface in an ordinary window (DESIGN.md S1 V2 B1 P0 W1), kept in the journal (E2),
// and the end of a session: Done → review → copy, save or discard (O1 O2 R1).
import AppKit
import FlowCore
import FlowJournal
import QuartzCore
import UniformTypeIdentifiers

final class App: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation {
    private var window: NSWindow!
    private var view: LineView!
    private let keeper = Keeper()
    private var session = Session()
    private var review: ReviewSheet?
    private var asking = false  // the Discard question is up

    func applicationDidFinishLaunching(_ notification: Notification) {
        let font = (NSFont(name: "Menlo", size: 28) ?? .monospacedSystemFont(ofSize: 28, weight: .regular)) as CTFont
        let style = Style(font: font)
        view = LineView(style: style)
        view.load(keeper.open())  // the silent restore: the last session's text, or an empty one
        view.onEdit = { [unowned self] in self.keeper.append($0) }
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
        window.isReleasedWhenClosed = false
        window.delegate = self
        if !window.setFrameUsingName("Flow") { window.center() }
        window.setFrameAutosaveName("Flow")
        window.makeKeyAndOrderFront(nil)
        // The view goes in once the window is on screen, so the strip's first frames are presented to a layer that is
        // shown: only then is a drawable sure to come back to the layer's pool of two.
        window.contentView = view
        window.makeFirstResponder(view)
        NSApp.activate()
        warnIfNotKept()
    }

    // MARK: Keeping (E2): the session outlives a close, ⌘Q and a crash; only a hand-off's grace and Discard end it.

    /// The close button hides the window; the Dock icon brings it back. Quitting is ⌘Q, which keeps the session.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !window.isVisible { window.makeKeyAndOrderFront(nil) }
        return true
    }

    func applicationDidResignActive(_ notification: Notification) { keeper.flushSoon() }

    /// Everything typed reaches the drive before the process ends.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        keeper.flushNow()
        return .terminateNow
    }

    /// One plain alert when the journal could not be opened; the surface stays quiet, the review's footer repeats it.
    private func warnIfNotKept() {
        guard let problem = keeper.problem else { return }
        let a = NSAlert()
        a.messageText = "This session is not kept"
        a.informativeText = "Flow could not open its journal: \(problem). You can write, but if Flow quits or crashes "
            + "before you copy or save, the text is lost."
        a.beginSheetModal(for: window)
    }

    // MARK: The end of a session (O1 O2 R1)

    private var blank: Bool { view.text.plainText.allSatisfy(\.isWhitespace) }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
        case #selector(done(_:)): return session.phase == .writing && !asking && !blank
        case #selector(discard(_:)): return !asking && session.phase != .cleared && !(session.phase == .writing && blank)
        default: return true
        }
    }

    /// Done (⌘⏎): the surface stops with its last frame, and the review opens over it.
    @objc func done(_ sender: Any?) {
        guard !asking, !blank, session.done() else { return }
        view.stop()
        keeper.flushSoon()
        let raw = view.text.plainText, words = Mechanical.words(raw)
        let seconds = keeper.started.map { Date().timeIntervalSince($0) } ?? 0
        let r = ReviewSheet(raw: raw, stats: "\(Session.duration(seconds)) · \(words) \(words == 1 ? "word" : "words")",
                            note: keeper.problem.map { "Not kept on disk: \($0)." }, room: window.contentLayoutRect.size)
        r.onCopy = { [unowned self] in self.copyOut() }
        r.onSave = { [unowned self] in self.saveOut() }
        r.onBack = { [unowned self] in self.back() }
        r.onDiscard = { [unowned self] in self.discard(nil) }
        r.onUndoHandoff = { [unowned self] in
            if self.session.undo() { self.review?.showHandoff(nil, undoable: false) }
        }
        review = r
        window.makeKeyAndOrderFront(nil)  // the close button may have hidden it
        window.beginSheet(r.panel)
    }

    /// Back: the sheet closes and writing goes on; nothing is destroyed, a running grace included.
    private func back() {
        guard let r = review, session.back() else { return }
        window.endSheet(r.panel)
        review = nil
        view.resume()
        window.makeFirstResponder(view)
    }

    /// Copy (O1): plain text, marked for clipboard managers as concealed and transient (nspasteboard.org), kept off
    /// other devices. `prepareForNewContents(with:)` clears the pasteboard itself; `declareTypes` would clear it again
    /// and drop the host-only option (NSPasteboard.h), so the types go in as one item.
    private func copyOut() {
        guard let r = review else { return }
        let pasteboard = NSPasteboard.general
        _ = pasteboard.prepareForNewContents(with: .currentHostOnly)
        let item = NSPasteboardItem()
        item.setString(r.text, forType: .string)
        for marker in ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType"] {
            item.setData(Data(), forType: NSPasteboard.PasteboardType(marker))
        }
        guard pasteboard.writeObjects([item]) else { return r.showHandoff("Not copied.", undoable: false) }
        handedOff(.copied)
    }

    /// Save… (O2): Markdown, written atomically, to a folder the panel remembers. A grace already running stops while
    /// the panel is up, so the session is never finished under it; the save starts a new one.
    private func saveOut() {
        guard let r = review else { return }
        if session.undo() { r.showHandoff(nil, undoable: false) }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = "flow-\(stamp.string(from: Date())).md"
        if let folder = UserDefaults.standard.string(forKey: Self.folderKey) {
            panel.directoryURL = URL(fileURLWithPath: folder, isDirectory: true)
        }
        panel.beginSheetModal(for: r.panel) { [unowned self] response in
            guard response == .OK, let url = panel.url, let r = self.review else { return }
            do {
                try Data((r.text + "\n").utf8).write(to: url, options: .atomic)
            } catch {
                return r.showHandoff("Not saved: \(describe(error)).", undoable: false)
            }
            UserDefaults.standard.set(url.deletingLastPathComponent().path, forKey: Self.folderKey)
            self.handedOff(.saved(name: url.lastPathComponent))
        }
    }

    private static let folderKey = "SaveFolder"
    private let stamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f
    }()

    /// A hand-off happened: the session is finished after the grace unless Undo or Back comes first.
    private func handedOff(_ how: Handoff) {
        let now = CACurrentMediaTime(), until = now + Session.grace
        guard session.handedOff(how, at: now) else { return }
        switch how {
        case .copied: review?.showHandoff("Copied ·", undoable: true)
        case .saved(let name): review?.showHandoff("Saved \(name) ·", undoable: true)
        }
        // Ticks at the grace's own end rather than the clock's reading when the timer fires, so rounding cannot make
        // it early; a stale timer (undone, or a later hand-off that started the grace again) finds the phase moved on.
        DispatchQueue.main.asyncAfter(deadline: .now() + Session.grace) { [weak self] in
            guard let self, self.session.tick(at: until) else { return }
            self.end(discard: false)
        }
    }

    /// Discard… (the menu, or the review's button): asks once, then destroys the key and clears.
    @objc func discard(_ sender: Any?) {
        guard !asking, session.phase != .cleared else { return }
        if session.undo() { review?.showHandoff(nil, undoable: false) }  // no grace runs out under the question
        let a = NSAlert()
        a.messageText = "Discard this session's text?"
        a.informativeText = "It cannot be recovered."
        a.addButton(withTitle: "Discard").hasDestructiveAction = true
        a.addButton(withTitle: "Cancel")
        asking = true
        window.makeKeyAndOrderFront(nil)
        a.beginSheetModal(for: review?.panel ?? window) { [unowned self] response in
            self.asking = false
            guard response == .alertFirstButtonReturn, self.session.discard() else { return }
            self.end(discard: true)
        }
    }

    /// The session is over: key destroyed, file deleted, the surface cleared, a new session begun. If the key store
    /// refuses, the session stays and the review (or an alert, from the surface) says why.
    private func end(discard: Bool) {
        do {
            try keeper.end(discard: discard)
        } catch {
            session.kept()
            let why = "Not finished: \(describe(error)). The session stays."
            if let r = review { return r.showHandoff(why, undoable: false) }
            session.back()
            let a = NSAlert()
            a.messageText = why
            return a.beginSheetModal(for: window)
        }
        if let r = review { window.endSheet(r.panel) }
        review = nil
        view.load(keeper.open())
        session.started()
        window.makeFirstResponder(view)
        warnIfNotKept()
    }
}

/// Flow: About, Quit; Session: Done, Discard…; View: Enter Full Screen. No Edit menu yet, so no ⌘ shortcut but these
/// reaches the text.
func mainMenu() -> NSMenu {
    let bar = NSMenu(), app = NSMenu(title: "Flow"), session = NSMenu(title: "Session"), view = NSMenu(title: "View")
    app.addItem(withTitle: "About Flow", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: "")  // a placeholder until the name is chosen
    app.addItem(.separator())
    app.addItem(withTitle: "Quit Flow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    session.addItem(withTitle: "Done", action: #selector(App.done(_:)), keyEquivalent: "\r")  // ⌘⏎
    session.addItem(withTitle: "Discard…", action: #selector(App.discard(_:)), keyEquivalent: "")
    view.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        .keyEquivalentModifierMask = [.control, .command]
    for menu in [app, session, view] { bar.addItem(withTitle: menu.title, action: nil, keyEquivalent: "").submenu = menu }
    return bar
}

let app = NSApplication.shared
NSWindow.allowsAutomaticWindowTabbing = false  // keeps the tab items out of the View menu
app.setActivationPolicy(.regular)
app.mainMenu = mainMenu()
let delegate = App()
app.delegate = delegate
app.run()
