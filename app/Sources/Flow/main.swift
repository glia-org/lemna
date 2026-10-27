// Flow (working name): the writing surface (DESIGN.md S1 V2 B4 P0) in a small floating box over whatever the user is
// doing, or in an ordinary window for long sessions (W2), kept in the journal (E2), with key clicks (K1), the session
// frame (M1: time box, intent, private log), summoning (hotkey, menu-bar item), and the end of a session: Done → review
// with Harper's suggestions → paste into the app behind the box, copy, save or discard (O1 O2 O3 R1 R2).
import AppKit
import Carbon.HIToolbox
import FlowClicks
import FlowCore
import FlowJournal
import QuartzCore
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
    /// Harper (R2), on its own serial queue from launch on.
    private let lint = Lint()
    private var session = Session()
    private var review: Review?
    /// The review's host in window mode; in the box the box holds the review itself.
    private var sheet: ReviewPanel?
    private var asking = false  // a question is up: Discard, Time box, Intent
    /// The journal could not open: said on the first container to come on screen (at launch nothing shows).
    private var notKept = false
    /// ⌃⌘F or the close button in full screen: back to the box once the window has left full screen.
    private var boxAfterFullScreen = false
    private let edge = EdgeView()
    private var clicks: ClickPlayer?
    private var notice = BluetoothNotice()
    private var hotkey: Hotkey?
    private var statusItem: NSStatusItem?
    // The session frame (M1), this session's only: in memory, gone when it ends or Flow quits; never journaled or
    // logged.
    private var timeBox: TimeBox?, boxTimer: Timer?, intent: String?
    /// What the review showed at Done, for the log line when the session is finished.
    private var totals: (start: Date, seconds: Double, words: Int)?
    private let tone = NSSound(data: Data(Tone.wav()))

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [Self.soundKey: true])
        let font = (NSFont(name: "Menlo", size: 28) ?? .monospacedSystemFont(ofSize: 28, weight: .regular)) as CTFont
        let style = Style(font: font)
        view = LineView(style: style)
        view.load(keeper.open())  // the silent restore: the last session's text, or an empty one
        view.onEdit = { [unowned self] in self.keeper.append($0) }
        view.onEscape = { [unowned self] in self.escape() }
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
        lint.warmUp()
    }

    // MARK: Clicks (K1)

    private static let soundKey = "sound"
    private var sound: Bool { UserDefaults.standard.bool(forKey: Self.soundKey) }

    /// The player is made once; if it cannot start (no output device, the pack missing) Flow is silent and says so
    /// once, in the system log.
    private func startClicks() {
        do {
            let c = try ClickPlayer(pack: .bundled())
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

    /// Session › Sound (⌘K), also in the menu-bar item: clicks and the soft end's tone on or off, kept across launches.
    @objc func toggleSound(_ sender: Any?) {
        UserDefaults.standard.set(!sound, forKey: Self.soundKey)
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

    /// `w`, or a sheet on it (a question, the review, the save panel on the review), has the keys.
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
    /// does, the review included; the session stays. The guard (`ClickOutside`) exists because the box also loses the
    /// keys to Flow itself, and hiding then would pull the box from under its own sheet or question: a sheet on the box
    /// (Save…, Discard…, Time box…, Intent…, an alert) takes the keys as it opens, and the box is going anyway on Esc,
    /// the hotkey, a paste and Open Window. In a hand-off's grace the review stays, so its Undo stays in reach. Decided
    /// a turn later, once AppKit has made the new key window key: `NSApp.keyWindow` then names it when it is Flow's,
    /// and is nil when another app has the keys.
    private func boxLostKeys() {
        DispatchQueue.main.async { [self] in
            guard !box.panel.isKeyWindow else { return }  // it has them back already
            var graced = false
            if case .graced = session.phase { graced = true }
            guard ClickOutside.hides(boxOnScreen: surface.onScreen == .box, asking: asking,
                                     sheet: box.panel.attachedSheet != nil, graced: graced,
                                     flowHasKeys: NSApp.keyWindow != nil)
            else { return }
            surface.hide()
            apply()
            handBack()
        }
    }

    /// Open Window (⌃⌘F, also from the box) and back: the line moves to the other container. Only while writing, so
    /// the review and the questions stay with the container they opened on.
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

    /// Makes the screen match `surface`: at most one container on screen, the line (or the box's review) in it.
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
            box.show(view, review: review)
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
            return
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

    // MARK: The session frame (M1)

    /// Session › Time box…: the box starts when it is set; setting the running box again leaves it running, setting
    /// an ended one again starts it afresh.
    @objc func setTimeBox(_ sender: Any?) {
        guard session.phase == .writing, !asking, container.attachedSheet == nil else { return }
        asking = true
        askTimeBox(current: timeBox?.minutes, for: questionHost()) { [unowned self] set, minutes in
            self.asking = false
            if set { self.startBox(minutes) }
        }
    }

    private func startBox(_ minutes: Int?) {
        if let minutes, let timeBox, timeBox.minutes == minutes, !timeBox.over { return }
        boxTimer?.invalidate()
        boxTimer = nil
        timeBox = minutes.map { TimeBox(minutes: $0, start: CACurrentMediaTime()) }
        edge.progress = timeBox == nil ? nil : 0
        guard timeBox != nil else { return }
        // Twice a second: the fill moves a point or two at a time at most, and nothing else wakes for it.
        let t = Timer(timeInterval: 0.5, repeats: true) { [unowned self] _ in self.tickBox() }
        t.tolerance = 0.1
        RunLoop.main.add(t, forMode: .common)  // fills during a live resize and with a menu open too
        boxTimer = t
    }

    /// The soft end: once, the tone (unless the sound is off, or the review is already up), and the line stays full.
    /// Typing goes on (P0).
    private func tickBox() {
        guard var b = timeBox else { return }
        let now = CACurrentMediaTime()
        edge.progress = b.fraction(at: now)
        if b.ends(at: now) {
            boxTimer?.invalidate()
            boxTimer = nil
            if sound && session.phase == .writing { tone?.play() }
        }
        timeBox = b
    }

    /// Session › Intent…: one line, shown only in the review's header.
    @objc func setIntent(_ sender: Any?) {
        guard session.phase == .writing, !asking, container.attachedSheet == nil else { return }
        asking = true
        askIntent(current: intent, for: questionHost()) { [unowned self] set, line in
            self.asking = false
            if set { self.intent = line }
        }
    }

    /// The private log: one line of totals per finished session, beside the sessions' folder.
    private static let log = Keeper.directory.deletingLastPathComponent().appendingPathComponent("log.tsv")

    private func logFinished() {
        guard let t = totals else { return }
        let folder = Self.log.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
                                                 attributes: [.posixPermissions: 0o700])
        let line = PrivateLog.line(start: t.start.timeIntervalSince1970, offset: TimeZone.current.secondsFromGMT(for: t.start),
                                   seconds: t.seconds, words: t.words)
        if !PrivateLog.append(line, to: Self.log.path) { NSLog("Flow: the log could not be written") }
    }

    /// Session › Show Log: the file in Finder.
    @objc func showLog(_ sender: Any?) { NSWorkspace.shared.activateFileViewerSelecting([Self.log]) }

    // MARK: Keeping (E2): the session outlives a close, ⌘Q and a crash; only a hand-off's grace and Discard end it.

    /// The close button returns to the box, as ⌃⌘F does; with the review or a question up it only hides the window
    /// (they stay with it, and the hotkey brings it back). Quitting is ⌘Q, which keeps the session.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if review != nil || asking || window.attachedSheet != nil {
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
    /// surface stays quiet, the review's footer repeats it.
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

    // MARK: The end of a session (O1 O2 R1)

    private var blank: Bool { view.text.plainText.allSatisfy(\.isWhitespace) }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
        case #selector(done(_:)): return session.phase == .writing && !asking && !blank
        case #selector(discard(_:)): return !asking && session.phase != .cleared && !(session.phase == .writing && blank)
        case #selector(setTimeBox(_:)), #selector(setIntent(_:)):
            return session.phase == .writing && !asking && container.attachedSheet == nil
        case #selector(toggleWindow(_:)):
            item.title = surface.mode == .window ? "Close Window" : "Open Window"
            return session.phase == .writing && !asking && container.attachedSheet == nil
        case #selector(toggleSound(_:)):
            item.state = sound ? .on : .off
            return true
        case #selector(showLog(_:)): return FileManager.default.fileExists(atPath: Self.log.path)
        default: return true
        }
    }

    /// Done (⌘⏎): the surface stops with its last frame, and the review opens: in the box, which grows upward in place;
    /// in the window, as a sheet.
    @objc func done(_ sender: Any?) {
        guard !asking, !blank, session.done() else { return }
        view.stop()
        keeper.flushSoon()
        let raw = view.text.plainText, words = Mechanical.words(raw)
        let seconds = keeper.started.map { Date().timeIntervalSince($0) } ?? 0
        totals = (keeper.started ?? Date(), seconds, words)
        let r = Review(raw: raw, stats: "\(Session.duration(seconds)) · \(words) \(words == 1 ? "word" : "words")",
                       note: keeper.problem.map { "Not kept on disk: \($0)." }, intent: intent,
                       paste: surface.mode == .box,  // the window has no app behind it to paste into
                       lint: lint.lint)
        r.onCopy = { [unowned self] in self.copyOut() }
        r.onPaste = { [unowned self] in self.pasteOut() }
        r.onSave = { [unowned self] in self.saveOut() }
        r.onBack = { [unowned self] in self.back() }
        r.onDiscard = { [unowned self] in self.discard(nil) }
        r.onUndoHandoff = { [unowned self] in
            if self.session.undo() { self.review?.showHandoff(nil, undoable: false) }
        }
        // A suggestion accepted (or R1 toggled) after a hand-off: what was copied, saved or pasted is no longer the
        // text shown, so the grace stops, as under the save panel, and the session is not finished with the older text.
        r.onTextChange = { [unowned self] in
            if self.session.undo() { self.review?.showHandoff(nil, undoable: false) }
        }
        showSurface()  // the hotkey may have hidden it; the menu-bar item's Done comes from another app
        review = r
        switch surface.mode {
        case .box:
            box.hold(view, review: r)
        case .window:
            let s = ReviewPanel(review: r, room: window.contentLayoutRect.size)
            sheet = s
            window.beginSheet(s)
        }
    }

    /// The review goes: the box shrinks back to the line, or the sheet ends; the line has the keys again.
    private func closeReview() {
        review = nil
        if let s = sheet {
            window.endSheet(s)
            sheet = nil
            window.makeFirstResponder(view)
        } else {
            box.hold(view, review: nil)
        }
    }

    /// Back: the sheet closes and writing goes on; nothing is destroyed, a running grace included.
    private func back() {
        guard review != nil, session.back() else { return }
        closeReview()
        view.resume()
    }

    /// Copy (O1), and Paste's fallback with `note` saying why it copied instead.
    private func copyOut(note: String? = nil) {
        guard let r = review else { return }
        guard Clipboard.write(r.text) != nil else { return r.showHandoff("Not copied.", undoable: false) }
        handedOff(.copied, note: note)
    }

    // MARK: Paste (O3)

    /// ⌘⏎ in the box's review, and its Paste button: into the app that was in front when the box was summoned. Decided
    /// first (`Paste.decide`); when it cannot paste it copies and the footer says why.
    private func pasteOut() {
        guard let r = review else { return }
        let app = target.flatMap { $0.isTerminated ? nil : $0 }
        switch Paste.decide(secureInput: IsSecureEventInputEnabled(), mayPost: CGPreflightPostEventAccess(),
                            hasTarget: app != nil) {
        case .copy(let note, let ask):
            if ask { _ = CGRequestPostEventAccess() }  // macOS shows its Accessibility prompt, once
            copyOut(note: note)
        case .paste:
            afterReturnIsUp { [unowned self] in
                guard self.review === r, let app else { return }
                self.paste(r.text, into: app)
            }
        }
    }

    /// The pasteboard as Copy writes it, the box and the dim gone, the app behind in front, ⌘V posted 120 ms later, and
    /// 250 ms after that the old clipboard back if the pasteboard still holds Flow's item. The grace runs while the box
    /// is hidden: a summon within it shows the review with `Pasted · Undo (10 s)` (Undo keeps the text in Flow); after
    /// it the session is finished as after Copy and the next summon shows an empty line.
    private func paste(_ text: String, into app: NSRunningApplication) {
        guard let keys = CommandV() else { return copyOut(note: "Copied · ⌘V could not be made") }
        let old = Clipboard.save()  // before Flow's write replaces it
        guard let mine = Clipboard.write(text) else {
            review?.showHandoff("Not pasted.", undoable: false)
            return
        }
        handedOff(.pasted)
        surface.hide()
        apply()
        bringForward(app)
        DispatchQueue.main.asyncAfter(deadline: .now() + Paste.settle) { [weak self] in
            guard let self else { return }
            // Again, now that the app has its keys back: a password field turns Secure Input on only while its window
            // is key, and the box had taken that. The text stays on the pasteboard, as a copy.
            if IsSecureEventInputEnabled() {
                self.handedOff(.copied, note: Paste.secureNote)
                return self.showSurface()
            }
            keys.post()
            DispatchQueue.main.asyncAfter(deadline: .now() + Paste.restoreAfter) {
                if let old, Paste.restores(written: mine, now: NSPasteboard.general.changeCount) { Clipboard.restore(old) }
            }
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
    /// as auto-repeated ⌘⏎ (which sends a message in many apps) once the box is gone. While the box waits, its review
    /// swallows the repeats. A click on Paste runs `then` at once.
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
        if surface.mode == .box { activateFlow() }  // the save panel is a sheet: it takes keys only in the active app
        panel.beginSheetModal(for: sheet ?? box.panel) { [unowned self] response in
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

    /// A hand-off happened: the session is finished after the grace unless Undo or Back comes first. `note`: a copy
    /// made in Paste's place says why.
    private func handedOff(_ how: Handoff, note: String? = nil) {
        let now = CACurrentMediaTime(), until = now + Session.grace
        guard session.handedOff(how, at: now) else { return }
        switch how {
        case .copied: review?.showHandoff((note ?? "Copied") + " ·", undoable: true)
        case .saved(let name): review?.showHandoff("Saved \(name) ·", undoable: true)
        case .pasted: review?.showHandoff("Pasted ·", undoable: true)
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
        let host = questionHost()
        a.beginSheetModal(for: sheet ?? host) { [unowned self] response in
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
            return a.beginSheetModal(for: questionHost())
        }
        if !discard { logFinished() }
        if review != nil { closeReview() }
        startBox(nil)
        intent = nil
        view.load(keeper.open())
        session.started()
        warnIfNotKept()
    }
}

/// Flow: About, Quit; Session: Done, Discard…, Time box…, Intent…, Sound, Show Log; View: Open Window. As an accessory
/// app Flow shows no menu bar, so this is where the key equivalents live (the menu-bar item's menu shows the items).
/// No Edit menu yet, so no ⌘ shortcut but these reaches the text. Full screen: the window's green button.
func mainMenu() -> NSMenu {
    let bar = NSMenu(), app = NSMenu(title: "Flow"), session = NSMenu(title: "Session"), view = NSMenu(title: "View")
    app.addItem(withTitle: "About Flow", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: "")  // a placeholder until the name is chosen
    app.addItem(.separator())
    app.addItem(withTitle: "Quit Flow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    session.addItem(withTitle: "Done", action: #selector(App.done(_:)), keyEquivalent: "\r")  // ⌘⏎
    session.addItem(withTitle: "Discard…", action: #selector(App.discard(_:)), keyEquivalent: "")
    session.addItem(.separator())
    session.addItem(withTitle: "Time box…", action: #selector(App.setTimeBox(_:)), keyEquivalent: "")
    session.addItem(withTitle: "Intent…", action: #selector(App.setIntent(_:)), keyEquivalent: "")
    session.addItem(.separator())
    session.addItem(withTitle: "Sound", action: #selector(App.toggleSound(_:)), keyEquivalent: "k")  // ⌘K
    session.addItem(withTitle: "Show Log", action: #selector(App.showLog(_:)), keyEquivalent: "")
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
