// appkit-line: the sliding line in AppKit (spikes/SPEC.md), a throwaway spike. Keys arrive through
// NSTextInputClient; Core Text glyphs are drawn by Core Graphics into a shared Metal buffer, blitted into a
// CAMetalLayer drawable and presented; MTLDrawable.addPresentedHandler gives each frame's on-screen time.
import AppKit
import CoreText
import LineCore
import Metal
import QuartzCore

let mainTs = CACurrentMediaTime()  // host time: mach_absolute_time in seconds, as NSEvent.timestamp and presentedTime
let uptimeSkew = ProcessInfo.processInfo.systemUptime - CACurrentMediaTime()  // clock check, expected ~0
let bench = CommandLine.arguments.contains("--bench")
let quitAfterFirstFrame = CommandLine.arguments.contains("--quit-after-first-frame")
let results = URL(fileURLWithPath: #filePath)  // spikes/appkit-line/Sources/appkit-line/main.swift → spikes/results
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("results")
let presentMethod = "metal-presentedTime"
let benchText = "The quick brown fox jumps over the lazy dog. A writer sits at the desk and types one line at a time, "
    + "never looking back at the words that slide away to the left. The caret stays where it is, the text moves on, "
    + "and the mind keeps going forward. Twelve keys a second is a calm pace for this short test."  // 300 characters
let ansiKeyCodes = Dictionary(uniqueKeysWithValues: Array("asdfhgzxcv\0bqweryt123465=97-80]ou[ip\0lj'k;\\,/nm.\0 ")
    .enumerated().filter { $0.element != "\0" }.map { ($0.element, UInt16($0.offset)) })  // US ANSI virtual key codes

let fontSize: CGFloat = 28
let font = (NSFont(name: "Menlo", size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)) as CTFont
let baselineDrop = (CTFontGetAscent(font) - CTFontGetDescent(font)) / 2  // centres the line box on the middle
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
func color(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 255) / 255, green: CGFloat(hex >> 8 & 255) / 255, blue: CGFloat(hex & 255) / 255,
            alpha: 1)
}
let background = color(0x0e1013), caretColor = color(0x7aa7f0), textColor = color(0xd8dce3)

struct Key { var key: Double; var handled = 0.0; var present = 0.0; var changed = false }

final class LineView: NSView, NSTextInputClient {
    let device = MTLCreateSystemDefaultDevice()!
    lazy var queue = device.makeCommandQueue()!
    var metal: CAMetalLayer { layer as! CAMetalLayer }
    var ring: [(buffer: MTLBuffer, context: CGContext)] = []  // one CPU bitmap per drawable in flight
    var pixels = (w: 0, h: 0, row: 0)
    var committed = "", marked = ""
    var glyphs: [Glyph] = [], lineWidth: CGFloat = 0
    var glide = Glide()
    var link: CADisplayLink?
    var gliding = false, glideRun = 0, keyFrame = 0.0  // keyFrame: when a key last drew its own frame
    var keys: [Key] = [], current: Int?, nextUnpresented = 0
    var rendered = 0, presented = 0, glideFrames: [(run: Int, t: Double)] = [], firstFrame = 0.0
    var onFirstFrame: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func makeBackingLayer() -> CALayer {
        let l = CAMetalLayer()
        l.device = device
        l.pixelFormat = .bgra8Unorm
        l.framebufferOnly = false  // the drawable's texture is a blit destination
        l.colorspace = sRGB
        l.isOpaque = true
        return l
    }
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {}  // every frame comes from render(at:)
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, link == nil else { return }
        let l = displayLink(target: self, selector: #selector(tick(_:)))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
        l.isPaused = true  // runs only while a glide does
        l.add(to: .main, forMode: .common)
        link = l
        resizeDrawable()
    }
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        resizeDrawable()
    }

    func resizeDrawable() {
        let scale = window?.backingScaleFactor ?? 2
        let w = Int((bounds.width * scale).rounded()), h = Int((bounds.height * scale).rounded())
        metal.contentsScale = scale
        metal.drawableSize = CGSize(width: w, height: h)
        pixels = (w, h, (w * 4 + 255) & ~255)
        ring = (0..<3).map { _ in
            let buffer = device.makeBuffer(length: pixels.row * h, options: .storageModeShared)!
            let c = CGContext(data: buffer.contents(), width: w, height: h, bitsPerComponent: 8, bytesPerRow: pixels.row,
                              space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                  | CGBitmapInfo.byteOrder32Little.rawValue)!  // BGRA in memory, as .bgra8Unorm
            c.scaleBy(x: scale, y: scale)
            c.setAllowsFontSubpixelPositioning(true)
            c.setShouldSubpixelPositionFonts(true)
            c.setAllowsFontSubpixelQuantization(false)
            c.setShouldSubpixelQuantizeFonts(false)
            return (buffer, c)
        }
    }

    // MARK: Frames

    /// Draws the line as it stands at host time `t` and presents it.
    func render(at t: Double) {
        guard !ring.isEmpty, let drawable = metal.nextDrawable() else { return }
        rendered += 1
        let (buffer, c) = ring[rendered % ring.count]  // free: its drawable has left the screen
        let w = bounds.width, mid = bounds.height / 2, caretX = 0.6 * w
        c.setAlpha(1)
        c.setFillColor(background)
        c.fill(bounds)
        c.setFillColor(textColor)
        Line.draw(glyphs, in: c, x0: caretX - lineWidth + CGFloat(glide.offset(at: t)), baseline: mid - baselineDrop,
                  caretX: caretX, width: w)  // clipped at the caret, which is drawn on top
        c.setAlpha(1)
        c.setFillColor(caretColor)
        c.fill(CGRect(x: caretX, y: mid - 0.6 * fontSize, width: 2, height: 1.2 * fontSize))
        let commands = queue.makeCommandBuffer()!, blit = commands.makeBlitCommandEncoder()!
        blit.copy(from: buffer, sourceOffset: 0, sourceBytesPerRow: pixels.row, sourceBytesPerImage: pixels.row * pixels.h,
                  sourceSize: MTLSize(width: pixels.w, height: pixels.h, depth: 1), to: drawable.texture,
                  destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blit.endEncoding()
        let upTo = keys.count - 1, run = gliding ? glideRun : -1
        drawable.addPresentedHandler { [weak self] d in
            let shown = d.presentedTime
            DispatchQueue.main.async { self?.didPresent(shown, upTo: upTo, run: run) }
        }
        commands.present(drawable)
        commands.commit()
    }

    func didPresent(_ t: Double, upTo: Int, run: Int) {
        guard t > 0 else { return }  // skipped frame
        presented += 1
        while nextUnpresented <= upTo {  // the first presented frame that holds a key's glyph
            if keys[nextUnpresented].changed { keys[nextUnpresented].present = t }
            nextUnpresented += 1
        }
        if run >= 0 { glideFrames.append((run, t)) }
        if firstFrame == 0 {
            firstFrame = t
            onFirstFrame?()
        }
    }

    @objc func tick(_ l: CADisplayLink) {
        if keyFrame <= l.timestamp { render(at: l.targetTimestamp) }  // else that key's frame already targets this one
        if !glide.active(at: l.targetTimestamp) {
            gliding = false
            l.isPaused = true
        }
    }

    // MARK: Text

    /// Lays the line out again after an edit that turned `old` into `committed + marked`, and shows it.
    func edited(from old: String) {
        let now = CACurrentMediaTime(), new = committed + marked
        guard new != old else { return }
        let start = max(0, new.count - 120)  // only the tail can be on screen
        let line = shape(String(new.dropFirst(start)))
        let oldWidth = CTLineGetTypographicBounds(shape(String(old.dropFirst(start))), nil, nil, nil)
        lineWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        glyphs = []
        for run in CTLineGetGlyphRuns(line) as! [CTRun] {
            let n = CTRunGetGlyphCount(run)
            let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
            var ids = [CGGlyph](repeating: 0, count: n), pos = [CGPoint](repeating: .zero, count: n)
            var adv = [CGSize](repeating: .zero, count: n)
            CTRunGetGlyphs(run, CFRange(), &ids)
            CTRunGetPositions(run, CFRange(), &pos)
            CTRunGetAdvances(run, CFRange(), &adv)
            for i in 0..<n { glyphs.append(Glyph(font: runFont, id: ids[i], x: pos[i].x, advance: adv[i].width)) }
        }
        glide.add(Double(lineWidth) - oldWidth, at: now,
                  reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        if let k = current { keys[k].changed = true }
        guard !gliding else { return }  // the running display link draws it on its next tick
        if glide.active(at: now) {
            gliding = true
            glideRun += 1
            link?.isPaused = false
        }
        keyFrame = now
        render(at: now)  // the glyph shows in the next frame
    }

    func shape(_ s: String) -> CTLine {
        CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: [.font: font]))
    }

    override func keyDown(with event: NSEvent) {
        keys.append(Key(key: event.timestamp))
        current = keys.count - 1
        interpretKeyEvents([event])
        keys[keys.count - 1].handled = CACurrentMediaTime()
        current = nil
    }

    override func doCommand(by selector: Selector) {
        let old = committed + marked
        switch selector {
        case #selector(NSStandardKeyBindingResponding.deleteBackward(_:)):
            guard let s = Line.backspace(committed) else { return }
            committed = s
        case #selector(NSStandardKeyBindingResponding.insertNewline(_:)):
            committed = Line.newline(committed)
        case #selector(NSStandardKeyBindingResponding.cancelOperation(_:)):
            DispatchQueue.main.async { NSApp.terminate(nil) }
            return
        default:
            return
        }
        edited(from: old)
    }

    func insertText(_ string: Any, replacementRange: NSRange) {
        let old = committed + marked, s = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        if marked.isEmpty, replacementRange.location != NSNotFound, NSMaxRange(replacementRange) <= committed.utf16.count {
            committed = (committed as NSString).replacingCharacters(in: replacementRange, with: s)  // press-and-hold
        } else {
            committed += s
        }
        marked = ""
        edited(from: old)
    }
    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        let old = committed + marked
        marked = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        edited(from: old)
    }
    func unmarkText() {
        committed += marked
        marked = ""
    }
    func hasMarkedText() -> Bool { !marked.isEmpty }
    func markedRange() -> NSRange {
        marked.isEmpty ? NSRange(location: NSNotFound, length: 0)
            : NSRange(location: committed.utf16.count, length: marked.utf16.count)
    }
    func selectedRange() -> NSRange { NSRange(location: committed.utf16.count + marked.utf16.count, length: 0) }
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        let all = (committed + marked) as NSString, r = NSIntersectionRange(range, NSRange(location: 0, length: all.length))
        actualRange?.pointee = r
        return NSAttributedString(string: all.substring(with: r), attributes: [.font: font])
    }
    func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        let caret = NSRect(x: 0.6 * bounds.width, y: bounds.height / 2 - 0.6 * fontSize, width: 2, height: 1.2 * fontSize)
        return window?.convertToScreen(convert(caret, to: nil)) ?? .zero
    }
    func characterIndex(for point: NSPoint) -> Int { NSNotFound }

    // MARK: Results

    func writeResults() {
        var csv = "seq,key_ts,handled_ts,present_ts,method\n"
        for (i, k) in keys.enumerated() {
            csv += String(format: "%d,%.6f,%.6f,", i + 1, k.key, k.handled)
                + (k.present > 0 ? String(format: "%.6f,", k.present) + presentMethod : ",none") + "\n"
        }
        let summary = report()
        print(summary)
        try? FileManager.default.createDirectory(at: results, withIntermediateDirectories: true)
        try? csv.write(to: results.appendingPathComponent("appkit-keys.csv"), atomically: true, encoding: .utf8)
        try? summary.write(to: results.appendingPathComponent("appkit-summary.txt"), atomically: true, encoding: .utf8)
    }

    func report() -> String {
        let shown = keys.filter { $0.present > 0 }
        func ms(_ xs: [Double]) -> String {
            xs.isEmpty ? "n/a" : String(format: "%.2f / %.2f / %.2f", Line.percentile(xs, 0.5), Line.percentile(xs, 0.95),
                                        xs.max()!)
        }
        var gaps: [Double] = []  // between consecutive presented frames of one glide
        for i in glideFrames.indices.dropFirst() where glideFrames[i].run == glideFrames[i - 1].run {
            gaps.append(glideFrames[i].t - glideFrames[i - 1].t)
        }
        let p50 = Line.percentile(gaps, 0.5), hz = window?.screen?.maximumFramesPerSecond ?? 0
        let fps = gaps.isEmpty ? "n/a" : String(format: "%.1f (%d intervals, p50 %.2f ms, %d over 1.5x p50; display max %d Hz)",
                                                Double(gaps.count) / gaps.reduce(0, +), gaps.count, p50 * 1000,
                                                gaps.filter { $0 > 1.5 * p50 }.count, hz)
        var build: [String: String] = [:]
        for line in ((try? String(contentsOf: results.appendingPathComponent("appkit-build.txt"), encoding: .utf8)) ?? "")
            .split(separator: "\n") {
            let kv = line.split(separator: "=", maxSplits: 1).map(String.init)
            if kv.count == 2 { build[kv[0]] = kv[1] }
        }
        return """
            stack: AppKit (NSTextInputClient, Core Text, CAMetalLayer), \(build["swift"] ?? "Swift")
            n: \(shown.count)\(shown.count == keys.count ? "" : " (of \(keys.count) key events; the rest changed nothing)")
            present-key ms p50/p95/max: \(ms(shown.map { ($0.present - $0.key) * 1000 }))
            handled-key ms p50/p95/max: \(ms(shown.map { ($0.handled - $0.key) * 1000 }))
            glide fps: \(fps)
            main-to-first-frame ms: \(firstFrame > 0 ? String(format: "%.1f", (firstFrame - mainTs) * 1000) : "n/a")
            binary bytes (stripped): \(build["stripped_binary_bytes"] ?? "n/a (run build.sh)")
            dependencies: 0 (system frameworks only: AppKit, Metal, QuartzCore, CoreText)
            cold release build s: \(build["cold_release_build_s"] ?? "n/a (run build.sh)")
            present_ts methods: \(presentMethod) for all \(shown.count)
            key_ts: NSEvent.timestamp\(bench ? " (synthetic: the time the event was posted to the app's queue)" : "")
            exact: present-key, handled-key and glide fps (NSEvent.timestamp, CACurrentMediaTime, MTLDrawable.presentedTime, \
            all host time); under --bench key_ts leaves out the keyboard and WindowServer part of a real keystroke
            approximate: main-to-first-frame starts at main(), not at exec (time --quit-after-first-frame for the whole \
            launch); binary size and build time are from build.sh
            frames rendered/presented: \(rendered)/\(presented)
            bench text intact: \(!bench ? "n/a (not --bench)" : committed == benchText ? "yes" : "NO (\(committed.count) characters)")
            reduce motion: \(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? "on (jumps)" : "off")
            clock check: systemUptime - CACurrentMediaTime = \(String(format: "%.6f", uptimeSkew)) s

            """
    }
}

final class App: NSObject, NSApplicationDelegate {
    var window: NSWindow!, view: LineView!, benchIndex = 0, waited = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let size = NSSize(width: 1200, height: 700), band = 2 * fontSize
        window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled, .closable, .miniaturizable],
                          backing: .buffered, defer: false)
        window.backgroundColor = NSColor(cgColor: background)
        window.appearance = NSAppearance(named: .darkAqua)
        view = LineView(frame: NSRect(x: 0, y: (size.height - band) / 2, width: size.width, height: band))
        window.contentView?.addSubview(view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        NSApp.activate()
        view.onFirstFrame = { [unowned self] in
            print(String(format: "main-to-first-frame ms: %.1f (presentedTime)", (view.firstFrame - mainTs) * 1000))
            if quitAfterFirstFrame { exit(0) }
            if bench { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.startBench() } }
        }
        view.render(at: CACurrentMediaTime())
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationWillTerminate(_ notification: Notification) { view.writeResults() }

    /// Types benchText at 12 characters a second through the app's event queue, then quits.
    func startBench() {
        guard window.isKeyWindow else {  // an app started from a terminal is not always activated
            if !waited { print("appkit-line: waiting for the window to become key; click it") }
            waited = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.startBench() }
            return
        }
        let chars = Array(benchText)
        Timer.scheduledTimer(withTimeInterval: 1.0 / 12, repeats: true) { [unowned self] timer in
            guard benchIndex < chars.count else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
                return
            }
            let c = chars[benchIndex], s = String(c)
            benchIndex += 1
            let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: c.isUppercase ? .shift : [],
                                         timestamp: CACurrentMediaTime(), windowNumber: window.windowNumber, context: nil,
                                         characters: s, charactersIgnoringModifiers: s, isARepeat: false,
                                         keyCode: ansiKeyCodes[Character(s.lowercased())] ?? 0)!
            NSApp.postEvent(event, atStart: false)
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = App()
app.delegate = delegate
app.run()
