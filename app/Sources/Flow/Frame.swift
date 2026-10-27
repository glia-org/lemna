// The session frame on screen (DESIGN.md M1): the surface's bottom edge, with the time box's line and the Bluetooth
// notice (K1), and the two small sheets, Time box… and Intent….
import AppKit
import FlowCore

/// The bottom edge of the surface: the time box's 1 pt line along the very bottom (`#262b32` track, `#5c646f` fill,
/// no numbers) and, above it, the Bluetooth notice. Both stay off the line: the window is at least 300 pt tall, so the
/// line's band starts 122 pt up, and this strip is 40 pt. Clicks go through to the surface.
final class EdgeView: NSView {
    static let height: CGFloat = 40
    /// How far the time box's line has filled, 0…1; nil: no time box, no line.
    var progress: Double? {
        didSet { if progress != oldValue { setNeedsDisplay(NSRect(x: 0, y: 0, width: bounds.width, height: 1)) } }
    }
    private let notice = NSTextField(labelWithString: BluetoothNotice.text)
    private var shown = 0  // the latest notice; an earlier one's fade finds it moved on

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: Self.height))
        autoresizingMask = [.width, .maxYMargin]  // across the bottom as the window resizes
        notice.font = .systemFont(ofSize: 12)
        notice.textColor = color(0x5c646f)
        notice.alignment = .center
        notice.lineBreakMode = .byTruncatingTail
        notice.isHidden = true
        notice.frame = NSRect(x: 0, y: 12, width: 0, height: notice.fittingSize.height)
        notice.autoresizingMask = [.width]
        addSubview(notice)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirty: NSRect) {
        guard let progress else { return }
        let scale = window?.backingScaleFactor ?? 2
        color(0x262b32).setFill()
        NSRect(x: 0, y: 0, width: bounds.width, height: 1).fill()
        color(0x5c646f).setFill()
        NSRect(x: 0, y: 0, width: (bounds.width * progress * scale).rounded() / scale, height: 1).fill()
    }

    /// The Bluetooth notice: at once, then after 5 s it fades out over a second.
    func showNotice() {
        shown += 1
        let mine = shown
        NSAnimationContext.runAnimationGroup { $0.duration = 0; notice.animator().alphaValue = 1 }  // ends a fade
        notice.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, self.shown == mine else { return }
            NSAnimationContext.runAnimationGroup { $0.duration = 1; self.notice.animator().alphaValue = 0 }
        }
    }
}

/// Session › Time box…: Off, 10, 15 or 25 minutes. `done` gets whether the user chose (Set) and the minutes, nil for
/// Off.
func askTimeBox(current: Int?, for window: NSWindow, done: @escaping (_ set: Bool, _ minutes: Int?) -> Void) {
    let a = NSAlert()
    a.messageText = "Time box"
    a.informativeText = "A line along the bottom edge fills over the box, and a soft tone ends it. Writing goes on."
    let choices: [Int?] = [nil] + TimeBox.choices
    // Radio buttons with one superview and one action form a group; the action itself does nothing.
    let radios = choices.map { m in
        NSButton(radioButtonWithTitle: m.map { "\($0) minutes" } ?? "Off", target: Radio.group,
                 action: #selector(Radio.picked(_:)))
    }
    for (r, m) in zip(radios, choices) { r.state = m == current ? .on : .off }
    let stack = NSStackView(views: radios)
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 6
    stack.setFrameSize(stack.fittingSize)
    a.accessoryView = stack
    a.addButton(withTitle: "Set")
    a.addButton(withTitle: "Cancel")
    a.beginSheetModal(for: window) { response in
        let picked = zip(radios, choices).first { $0.0.state == .on }?.1
        done(response == .alertFirstButtonReturn, picked)
    }
}

private final class Radio: NSObject {
    static let group = Radio()
    @objc func picked(_ sender: Any?) {}
}

/// Session › Intent…: one line, at most 120 characters, for the review's header only. `done` gets whether the user
/// chose (Set) and the line, nil when empty.
func askIntent(current: String?, for window: NSWindow, done: @escaping (_ set: Bool, _ intent: String?) -> Void) {
    let a = NSAlert()
    a.messageText = "Intent"
    a.informativeText = "One line for this session. Not shown while you write; the review shows it. Kept in memory only."
    let field = NSTextField(string: current ?? "")
    field.placeholderString = "What this session is for"
    field.frame = NSRect(x: 0, y: 0, width: 320, height: field.fittingSize.height)
    let limit = Limit()
    field.delegate = limit
    a.accessoryView = field
    a.addButton(withTitle: "Set")
    a.addButton(withTitle: "Cancel")
    a.window.initialFirstResponder = field
    a.beginSheetModal(for: window) { response in
        withExtendedLifetime(limit) {}  // the field holds its delegate weakly
        let line = field.stringValue.split(whereSeparator: \.isNewline).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        done(response == .alertFirstButtonReturn, line.isEmpty ? nil : String(line.prefix(Limit.characters)))
    }
}

/// Keeps the intent's field to 120 characters as it is typed or pasted.
private final class Limit: NSObject, NSTextFieldDelegate {
    static let characters = 120
    func controlTextDidChange(_ n: Notification) {
        guard let f = n.object as? NSTextField, f.stringValue.count > Self.characters else { return }
        f.stringValue = String(f.stringValue.prefix(Self.characters))
    }
}
