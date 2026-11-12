// The box's fixed chords as the Settings window lists them (DESIGN.md SP2, pass 37): read-only, each with what it
// does. Free of AppKit, so the tests check it; the window draws it.

public enum Shortcuts {
    public struct Row: Equatable {
        public let chords: [Chord], label: String
    }

    private static let (control, option, shift, command) = (Chord.control, Chord.option, Chord.shift, Chord.command)
    private static func c(_ key: UInt32, _ modifiers: UInt32 = 0) -> Chord { Chord(key: key, modifiers: modifiers) }

    /// The hidden main menu's key equivalents (`mainMenu()`) and the keys LineView takes through AppKit's key bindings
    /// (B4), in the order of a session: the hand-offs and Esc, writing, moving, editing, the rest. ⇧ with any move
    /// selects; its row names the plain ones. ⌘Z has a second row, the second chance on the empty line (pass 41).
    public static let overview: [Row] = [
        Row(chords: [c(0x24, command)], label: "Send into the app"),
        Row(chords: [c(0x24, shift | command)], label: "Copy"),
        Row(chords: [c(0x01, command)], label: "Save…"),
        Row(chords: [c(0x35)], label: "Hide the box"),
        Row(chords: [c(0x24)], label: "Paragraph"),
        Row(chords: [c(0x24, shift)], label: "Line break"),
        Row(chords: [c(0x7B, option), c(0x7C, option)], label: "Word left, right"),
        Row(chords: [c(0x7B, command), c(0x7C, command)], label: "Paragraph start, end"),
        Row(chords: [c(0x7B, shift), c(0x7C, shift)], label: "Select (⇧ with any move)"),
        Row(chords: [c(0x33, option), c(0x75, option)], label: "Delete a word"),
        Row(chords: [c(0x06, command), c(0x06, shift | command)], label: "Undo, redo"),
        Row(chords: [c(0x06, command)], label: "On the empty line: the text that last went out"),
        Row(chords: [c(0x00, command), c(0x08, command), c(0x07, command), c(0x09, command)],
            label: "Select all, copy, cut, paste"),
        Row(chords: [c(0x31, control | command)], label: "Emoji & Symbols"),
        Row(chords: [c(0x28, command)], label: "Sound off, on"),
        Row(chords: [c(0x28, option | command)], label: "Clicks off, on"),  // the bed plays on (pass 42)
        Row(chords: [c(0x03, control | command)], label: "Window mode"),
    ]

    /// A row's chords as the window writes them. Letters are the US layout's: the menus' key equivalents are
    /// characters, so ⌘Z is the key that types z, wherever it sits.
    public static func glyphs(_ row: Row) -> String {
        row.chords.map { $0.glyphs(letter: Chord.usLetter) }.joined(separator: " ")
    }
}
