// Flow (working name): the writing surface (DESIGN.md S1 V2 B4 P0) in a small floating box over whatever the user is
// doing, or in an ordinary window for long sessions (W2), kept in the journal (E2), with key clicks (K1), summoning
// (hotkey, menu-bar item), and the end of a session: Done pastes into the app behind the box, or Copy, Save… or
// Discard…, with R1 applied silently and the session finished at once (O1 O2 O3 R1).
import AppKit
import Carbon.HIToolbox
import FlowClicks
import FlowCore
import FlowJournal
import UniformTypeIdentifiers

final class App: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation {
    private var window: NSWindow!
    private var box: Box!
    private var view: LineView!
    /// Which container holds the line, and whether it is on screen; `apply()` makes the screen match.
    private var surface = Surface()
    /// The app in front when the box was last summoned from it: where Paste goes (O3).
    private var target: NSRunningApplication?
    private let keeper = Keeper()
    private var session = Session()
    private var asking = false  // a question is up: Discard
    /// The journal could not open: said on the first container to come on screen (at launch nothing shows).
    private var notKept = false
    /// ⌃⌘F or the close button in full screen: back to the box once the window has left full screen.
    private var boxAfterFullScreen = false
    private let edge = EdgeView()
    private var clicks: ClickPlayer?
    private var notice = BluetoothNotice()
    private var hotkey: Hotkey?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [Self.soundKey: true])
        choice = SoundChoice(pack: UserDefaults.standard.string(forKey: Self.packKey),
                             on: UserDefaults.standard.bool(forKey: Self.soundKey))
        let font = (NSFont(name: "Menlo", size: 28) ?? .monospacedSystemFont(ofSize: 28, weight: .regular)) as CTFont
        let style = Style(font: font)
        view = LineView(style: style)
        view.load(keeper.open())  // the silent restore: the last session's text, or an empty one
        view.onEdit = { [unowned self] in self.keeper.append($0) }
        view.onEscape = { [unowned self] in self.escape() }
        view.onKey = { [unowned self] in self.edge.clearNote() }  // the next key, Esc included
        view.addSubview(edge)  // at the view's zero size, so the edge's autoresizing keeps it across the bottom
        box = Box(lineHeight: BoxFrame.height(fontSize: style.size))
        // Window mode (W2 keeps v1's window for long sessions): titled, with its standard buttons, so tiling window
        // managers (AeroSpace, yabai) treat it as a normal window.
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
        window.contentView = NSView()  // the line goes in when the window comes on screen (`apply`)
        // On launch nothing shows: the hotkey and the menu-bar item summon the box.
        warnIfNotKept()  // waits for the first container on screen
        startClicks()
        hotkey = Hotkey { [unowned self] in self.hotkeyPressed() }
        if hotkey == nil { NSLog("Flow: the hotkey could not be registered; the menu-bar item shows Flow") }
        statusItem = makeStatusItem(target: self)
        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: box.panel,
                                               queue: .main) { [unowned self] _ in self.boxLostKeys() }
    }

    // MARK: Clicks (K1)

    /// `sound`: on or off, as before the submenu; `soundPack`: the chosen pack's folder.
    private static let soundKey = "sound", packKey = "soundPack"
    /// Session › Sound: the pack and whether it plays, kept across launches (read at launch).
    private var choice = SoundChoice(pack: nil, on: true)
    private var sound: Bool { choice.on }

    /// The player is made once, with every pack loaded, so choosing another is an index and never a load on the key
    /// path; if it cannot start (no output device, a pack missing) Flow is silent and says so once, in the system log.
    private func startClicks() {
        do {
            let c = try ClickPlayer(packs: SoundChoice.packs.map { try SoundPack.bundled($0.folder) })
            c.pack = choice.index
            c.enabled = sound
            c.onOutputChanged = { [unowned self] in
                self.notice.outputChanged()
                self.warnIfBluetooth()
            }
            clicks = c
            view.clicks = c
            warnIfBluetooth()
        } catch {
            NSLog("Flow: no key clicks: %@", String(describing: error))
        }
    }

    /// Bluetooth output plays every click late: the surface's bottom edge says so once per output, while sound is on,
    /// and only while a container is on screen (else the notice would fade unseen and count as told); each summon
    /// checks again.
    private func warnIfBluetooth() {
        guard surface.onScreen != nil, let clicks, notice.check(bluetooth: clicks.isBluetoothOutput, sound: sound)
        else { return }
        edge.showNotice()
    }

    /// Session › Sound › Off (⌘K), also in the menu-bar item: clicks off, or, while off, back on with the last pack.
    @objc func toggleSound(_ sender: Any?) {
        choice.toggle()
        keepSound()
    }

    /// A pack from Session › Sound (the item's tag is its place in `SoundChoice.packs`): the next key plays it, and the
    /// sound is on.
    @objc func chooseSound(_ sender: NSMenuItem) {
        choice.choose(SoundChoice.packs[sender.tag].folder)
        keepSound()
    }

    /// The choice kept across launches and given to the player: a pack is an index there, on or off.
    private func keepSound() {
        UserDefaults.standard.set(choice.on, forKey: Self.soundKey)
        UserDefaults.standard.set(choice.pack, forKey: Self.packKey)
        clicks?.pack = choice.index
        clicks?.enabled = sound
        warnIfBluetooth()  // turned on over Bluetooth: said once for this output
    }

    // MARK: Summoning (W2)

    /// The hotkey and Show Flow toggle: the container on screen with the keys goes away, else it comes (the box, or in
    /// window mode the window, wherever it went: hidden, minimised).
    @objc func summon(_ sender: Any?) { hotkeyPressed() }

    private func hotkeyPressed() {
        let focused: Bool
        switch surface.onScreen {
        case .box?: focused = box.panel.isKeyWindow || hasKeys(box.panel)  // key without Flow being active
        case .window?: focused = NSApp.isActive && hasKeys(window)
        case nil: focused = false
        }
        surface.toggle(focused: focused)
        apply()
        if surface.onScreen == nil { handBack() }
    }

    /// `w`, or a sheet on it (a question, the save panel), has the keys.
    private func hasKeys(_ w: NSWindow) -> Bool {
        var key = NSApp.keyWindow
        while let k = key, k !== w { key = k.sheetParent }
        return key != nil
    }

    /// The container on screen, for Done from the menu-bar item, a question, a reopen.
    private func showSurface() {
        surface.show()
        apply()
    }

    /// Esc while writing in the box: it hides; the session stays and the journal keeps everything. In the window Esc
    /// does nothing, as in v1.
    private func escape() {
        guard surface.onScreen == .box else { return }
        surface.hide()
        apply()
        handBack()
    }

    /// The box stopped being the key window. A click outside it (into another app, through the dim) hides it as Esc
    /// does; the session stays. The guard (`ClickOutside`) exists because the box also loses the keys to Flow itself,
    /// and hiding then would pull the box from under its own sheet or question: a sheet on the box (Save…, Discard…, an
    /// alert) takes the keys as it opens, and the box is going anyway on Esc, the hotkey, a paste and Open Window.
    /// Decided a turn later, once AppKit has made the new key window key: `NSApp.keyWindow` then names it when it is
    /// Flow's, and is nil when another app has the keys.
    private func boxLostKeys() {
        DispatchQueue.main.async { [self] in
            guard !box.panel.isKeyWindow else { return }  // it has them back already
            guard ClickOutside.hides(boxOnScreen: surface.onScreen == .box, asking: asking,
                                     sheet: box.panel.attachedSheet != nil, flowHasKeys: NSApp.keyWindow != nil)
            else { return }
            surface.hide()
            apply()
            handBack()
        }
    }

    /// Open Window (⌃⌘F, also from the box) and back: the line moves to the other container. Only while writing, so
    /// a hand-off and the questions stay with the container they opened on.
    @objc func toggleWindow(_ sender: Any?) {
        guard session.phase == .writing, !asking, container.attachedSheet == nil else { return }
        if surface.mode == .window, window.styleMask.contains(.fullScreen) { return leaveFullScreen() }
        surface.use(surface.mode == .box ? .window : .box)
        apply()
    }

    /// Ordering out a full-screen window would leave its Space behind: out of full screen first, then to the box.
    private func leaveFullScreen() {
        boxAfterFullScreen = true
        window.toggleFullScreen(nil)
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        guard boxAfterFullScreen else { return }
        boxAfterFullScreen = false
        surface.use(.box)
        apply()
    }

    /// Where the line lives now: the box's panel or the window. Questions are sheets on it.
    private var container: NSWindow { surface.mode == .box ? box.panel : window }

    /// Makes the screen match `surface`: at most one container on screen, the line in it. Off screen, a hand-off's note
    /// goes: the next summon shows the line alone.
    private func apply() {
        let on = surface.onScreen
        if on != .box, box.isVisible {
            box.hide()
            keeper.flushSoon()  // leaving the box is leaving Flow: the full flush deactivating did in v1's window
        }
        // The line moved to the box: the window goes. In window mode hiding is the app's (`handBack`), which also keeps
        // a full-screen window in its Space.
        if surface.mode == .box, window.isVisible { window.orderOut(nil) }
        switch on {
        case .box?:
            if let front = NSWorkspace.shared.frontmostApplication, front != NSRunningApplication.current {
                target = front  // after the window or a question Flow is in front itself: the target stays
            }
            if NSApp.isHidden { NSApp.unhideWithoutActivation() }
            box.show(view)
        case .window?:
            if NSApp.isHidden { NSApp.unhide(nil) }
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
            // The line goes in once the window is on screen, so the strip's first frames are presented to a layer
            // that is shown: only then is a drawable sure to come back to the layer's pool of two.
            if let holder = window.contentView, view.superview !== holder {
                view.autoresizingMask = [.width, .height]
                view.frame = holder.bounds
                holder.addSubview(view)
            }
            if window.attachedSheet == nil { window.makeFirstResponder(view) }
            activateFlow()
        case nil:
            return edge.clearNote()
        }
        warnIfBluetooth()
        if notKept {
            notKept = false
            warnIfNotKept()
        }
    }

    /// Flow comes forward: the window, and a question on the box (a sheet takes keys only in the active app; the box
    /// itself needs no activation). macOS 14's `activate()` does not promise it (cooperative activation); if Flow is
    /// still not active a moment later, the older call, to be deprecated but still working, forces it.
    private func activateFlow() {
        NSApp.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self, !NSApp.isActive, self.surface.onScreen != nil else { return }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// After a container went away. The box never took activation, so the app behind has the keys again by itself;
    /// Flow is active only after the window or a question, and then hiding it brings back the app before it (as v1's
    /// hotkey did).
    private func handBack() {
        if NSApp.isActive { NSApp.hide(nil) }
    }

    // MARK: Keeping (E2): the session outlives a close, ⌘Q and a crash; only a hand-off and Discard end it.

    /// The close button returns to the box, as ⌃⌘F does; with a question or the save panel up it only hides the window
    /// (they stay with it, and the hotkey brings it back). Quitting is ⌘Q, which keeps the session.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if asking || window.attachedSheet != nil {
            surface.hide()
            apply()
            handBack()
        } else if window.styleMask.contains(.fullScreen) {
            leaveFullScreen()
        } else {
            surface.use(.box)
            apply()
        }
        return false
    }

    /// Opening Flow again (Finder, Spotlight) while it runs: the container comes on screen.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSurface()
        return true
    }

    func applicationDidResignActive(_ notification: Notification) { keeper.flushSoon() }

    /// Everything typed reaches the drive before the process ends.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        keeper.flushNow()
        return .terminateNow
    }

    /// One plain alert when the journal could not be opened, on the container on screen (or the first to come); the
    /// surface stays quiet.
    private func warnIfNotKept() {
        guard let problem = keeper.problem else { return }
        guard surface.onScreen != nil else { return notKept = true }
        let a = NSAlert()
        a.messageText = "This session is not kept"
        a.informativeText = "Flow could not open its journal: \(problem). You can write, but if Flow quits or crashes "
            + "before you copy or save, the text is lost."
        a.beginSheetModal(for: questionHost())
    }

    /// Where a question goes: a sheet on the container, which comes on screen first. On the box Flow comes forward for
    /// it: a sheet is no non-activating panel, so it would not get the keys.
    private func questionHost() -> NSWindow {
        if surface.onScreen == nil { showSurface() }
        if surface.mode == .box { activateFlow() }
        return container
    }

    // MARK: The end of a session (O1 O2 O3 R1): R1 applied silently, finished at once (no review, no grace)

    private var blank: Bool { view.text.plainText.allSatisfy(\.isWhitespace) }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
        case #selector(done(_:)), #selector(copyText(_:)), #selector(saveText(_:)):
            return session.phase == .writing && !asking && !blank
        case #selector(discard(_:)): return !asking && session.phase == .writing && !blank
        case #selector(toggleWindow(_:)):
            item.title = surface.mode == .window ? "Close Window" : "Open Window"
            return session.phase == .writing && !asking && container.attachedSheet == nil
        case #selector(toggleSound(_:)):
            item.state = sound ? .off : .on  // Off is ticked while the sound is off
            return true
        case #selector(chooseSound(_:)):
            item.state = sound && item.tag == choice.index ? .on : .off
            return true
        default: return true
        }
    }

    /// Done, Copy and Save… begin alike: the keys stop (a pending dead key joins the text, as the line shows it) and the
    /// text to hand off is R1's, applied silently (no toggle, no undo). Nil when there is nothing to hand off, or a
    /// hand-off or a question is already up.
    private func handOff() -> String? {
        guard !asking, !blank, session.handOff() else { return nil }
        view.stop()
        keeper.flushSoon()
        return Mechanical.apply(view.text.plainText).text
    }

    /// Done (⌘⏎): into the app that was in front when the box was summoned (O3). Decided first (`Paste.decide`); when
    /// it cannot paste, and always in the window (no app behind it), it copies and the bottom edge says why. Either way
    /// the session is finished at once.
    @objc func done(_ sender: Any?) {
        guard let text = handOff() else { return }
        showSurface()  // the hotkey may have hidden it; the menu-bar item's Done comes from another app
        guard surface.mode == .box else { return copyOut(text, note: Paste.noTargetNote) }
        let app = target.flatMap { $0.isTerminated ? nil : $0 }
        switch Paste.decide(secureInput: IsSecureEventInputEnabled(), mayPost: CGPreflightPostEventAccess(),
                            hasTarget: app != nil) {
        case .copy(let note, let ask):
            // macOS's Accessibility prompt, once (seen 2026-10-28: CGRequestPostEventAccess brought none, this does; the
            // Accessibility grant covers posting events too)
            if ask { _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary) }
            copyOut(text, note: note)
        case .paste:
            afterReturnIsUp { [unowned self] in self.paste(text, into: app!) }  // `decide` pastes only with a target
        }
    }

    /// Copy (⌘⇧⏎, O1): R1's text on the clipboard; the session is finished and the box (or the window) goes, as after a
    /// paste.
    @objc func copyText(_ sender: Any?) {
        guard let text = handOff() else { return }
        afterReturnIsUp { [unowned self] in self.copyOut(text, note: nil) }  // ⌘⇧⏎ held, as with ⌘⏎
    }

    /// The pasteboard as Copy writes it, then the session is finished. `note`: ⌘⏎ copied instead of pasting, and why;
    /// the container then stays with the note at its bottom edge, until the next key or Esc. Without one the container
    /// goes, as after a paste.
    private func copyOut(_ text: String, note: String?) {
        guard Clipboard.write(text) else { return notHandedOff("Not copied.") }
        guard finished() else { return }
        if let note { return edge.showNote(note) }
        surface.hide()
        apply()
        handBack()
    }

    // MARK: Paste (O3)

    /// The pasteboard as Copy writes it, the session finished, the box and the dim gone, the app behind in front, and ⌘V
    /// posted 120 ms later. The text stays on the clipboard: a ⌘V that did not land is one more ⌘V away, and Flow
    /// never reads the clipboard. The next summon shows an empty line.
    private func paste(_ text: String, into app: NSRunningApplication) {
        guard let keys = CommandV() else { return copyOut(text, note: "Copied · ⌘V could not be made") }
        guard Clipboard.write(text) else { return notHandedOff("Not pasted.") }
        guard finished() else { return }
        surface.hide()
        apply()
        bringForward(app)
        DispatchQueue.main.asyncAfter(deadline: .now() + Paste.settle) { [weak self] in
            guard let self else { return }
            // Again, now that the app has its keys back: a password field turns Secure Input on only while its window
            // is key, and the box had taken that. The text stays on the pasteboard, as a copy, and the box comes back
            // saying so.
            if IsSecureEventInputEnabled() {
                self.showSurface()
                return self.edge.showNote(Paste.secureNote)
            }
            keys.post()
        }
    }

    /// The app to paste into, in front. Usually it already is: the box never activated Flow. After the window or a
    /// question Flow is the active app and yields to it first, as macOS 14's cooperative activation asks; if the system
    /// does not allow that request, a plain one (`activateIgnoringOtherApps` has no effect since macOS 14).
    private func bringForward(_ app: NSRunningApplication) {
        guard NSWorkspace.shared.frontmostApplication != app else { return }
        NSApp.yieldActivation(to: app)
        if !app.activate(from: NSRunningApplication.current, options: []) { app.activate(options: []) }
    }

    /// Runs `then` once Return (or Enter) is up again, at most a second on: ⌘⏎ held into the app behind would reach it
    /// as auto-repeated ⌘⏎ (which sends a message in many apps) once the box is gone. While the box waits, the repeats
    /// find Done off (the hand-off is under way) and the line not taking keys. Done from the menu-bar item runs `then`
    /// at once.
    private func afterReturnIsUp(_ then: @escaping () -> Void) {
        guard let e = NSApp.currentEvent, e.type == .keyDown, [36, 76].contains(e.keyCode) else { return then() }
        var ran = false
        let once = { [unowned self] in
            guard !ran else { return }
            ran = true
            self.box.panel.onKeyUp = { _ in }
            then()
        }
        box.panel.onKeyUp = { if [36, 76].contains($0) { once() } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { once() }
    }

    /// Save… (⌘S, O2): R1's text as Markdown, written atomically, to a folder the panel remembers; the session is then
    /// finished and the box (or the window) goes, as after a paste. Cancel: writing goes on.
    @objc func saveText(_ sender: Any?) {
        guard let text = handOff() else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = "flow-\(stamp.string(from: Date())).md"
        if let folder = UserDefaults.standard.string(forKey: Self.folderKey) {
            panel.directoryURL = URL(fileURLWithPath: folder, isDirectory: true)
        }
        // A sheet on the container; on the box Flow comes forward first, since a sheet takes keys only in the active app.
        panel.beginSheetModal(for: questionHost()) { [unowned self] response in
            guard response == .OK, let url = panel.url else { return self.notHandedOff(nil) }
            do {
                try Data((text + "\n").utf8).write(to: url, options: .atomic)
            } catch {
                return self.notHandedOff("Not saved: \(describe(error)).")
            }
            UserDefaults.standard.set(url.deletingLastPathComponent().path, forKey: Self.folderKey)
            guard self.finished() else { return }
            self.surface.hide()
            self.apply()
            self.handBack()
        }
    }

    private static let folderKey = "SaveFolder"
    private let stamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f
    }()

    /// Pasted, copied or saved: the session is finished at once. False when the key store refused (`end` says so).
    private func finished() -> Bool {
        guard session.handedOff() else { return false }
        return end(discard: false)
    }

    /// The hand-off did not happen: writing goes on with the text as it was. `why`: the pasteboard refused or the file
    /// could not be written, said at the bottom edge; nil: the save panel was cancelled.
    private func notHandedOff(_ why: String?) {
        session.back()
        view.resume()
        guard let why else { return }
        showSurface()
        edge.showNote(why)
    }

    /// Discard… (the menu-bar item): asks once, then destroys the key and clears.
    @objc func discard(_ sender: Any?) {
        guard !asking, session.phase == .writing else { return }
        let a = NSAlert()
        a.messageText = "Discard this session's text?"
        a.informativeText = "It cannot be recovered."
        a.addButton(withTitle: "Discard").hasDestructiveAction = true
        a.addButton(withTitle: "Cancel")
        asking = true
        a.beginSheetModal(for: questionHost()) { [unowned self] response in
            self.asking = false
            guard response == .alertFirstButtonReturn, self.session.discard() else { return }
            self.end(discard: true)
        }
    }

    /// The session is over: key destroyed, file deleted, the surface cleared, a new session begun. If the key store
    /// refuses, the session stays, writing goes on and an alert says why; false then.
    @discardableResult private func end(discard: Bool) -> Bool {
        do {
            try keeper.end(discard: discard)
        } catch {
            session.kept()
            view.resume()
            let a = NSAlert()
            a.messageText = "Not finished: \(describe(error)). The session stays."
            a.beginSheetModal(for: questionHost())
            return false
        }
        view.load(keeper.open())
        session.started()
        warnIfNotKept()
        return true
    }
}

/// Session › Sound and the menu-bar item's Sound (K1): the packs as radio items, then Off ⌘K, which turns the sound off
/// and, while it is off, back on with the last pack. `target` nil in the main menu (the App gets the actions as the
/// delegate); the menu-bar item's menu names it, as Flow may not be active.
func soundMenu(target: AnyObject?) -> NSMenu {
    let menu = NSMenu(title: "Sound")
    for (i, pack) in SoundChoice.packs.enumerated() {
        let item = menu.addItem(withTitle: pack.title, action: #selector(App.chooseSound(_:)), keyEquivalent: "")
        item.tag = i
        item.target = target
    }
    menu.addItem(.separator())
    menu.addItem(withTitle: "Off", action: #selector(App.toggleSound(_:)), keyEquivalent: "k").target = target  // ⌘K
    return menu
}

/// Flow: About, Quit; Session: Done, Copy, Save…, Discard…, Sound ▸; View: Open Window. As an accessory
/// app Flow shows no menu bar, so this is where the key equivalents live (the menu-bar item's menu shows the items).
/// No Edit menu yet, so no ⌘ shortcut but these reaches the text. Full screen: the window's green button.
func mainMenu() -> NSMenu {
    let bar = NSMenu(), app = NSMenu(title: "Flow"), session = NSMenu(title: "Session"), view = NSMenu(title: "View")
    app.addItem(withTitle: "About Flow", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: "")  // a placeholder until the name is chosen
    app.addItem(.separator())
    app.addItem(withTitle: "Quit Flow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    session.addItem(withTitle: "Done", action: #selector(App.done(_:)), keyEquivalent: "\r")  // ⌘⏎
    session.addItem(withTitle: "Copy", action: #selector(App.copyText(_:)), keyEquivalent: "\r")
        .keyEquivalentModifierMask = [.command, .shift]  // ⌘⇧⏎
    session.addItem(withTitle: "Save…", action: #selector(App.saveText(_:)), keyEquivalent: "s")  // ⌘S
    session.addItem(withTitle: "Discard…", action: #selector(App.discard(_:)), keyEquivalent: "")
    session.addItem(.separator())
    session.addItem(withTitle: "Sound", action: nil, keyEquivalent: "").submenu = soundMenu(target: nil)  // Off ⌘K
    view.addItem(withTitle: "Open Window", action: #selector(App.toggleWindow(_:)), keyEquivalent: "f")
        .keyEquivalentModifierMask = [.control, .command]
    for menu in [app, session, view] { bar.addItem(withTitle: menu.title, action: nil, keyEquivalent: "").submenu = menu }
    return bar
}

let app = NSApplication.shared
NSWindow.allowsAutomaticWindowTabbing = false  // keeps the tab items out of the View menu
// An accessory app (no Dock icon, no menu bar; LSUIElement in Info.plist says the same before launch): a box-first app,
// like Spotlight, summoned over whatever the user is doing (W2). The menu-bar item is its menu.
app.setActivationPolicy(.accessory)
app.mainMenu = mainMenu()
let delegate = App()
app.delegate = delegate
app.run()
