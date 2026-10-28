// Where a key sits on the keyboard (DESIGN.md A1, pass 16): the ambience's scenes follow it ("some of them could also
// be more reactive depending on where the key is on the keyboard"). NSEvent's keyCode is the physical key, whatever the
// layout, so a German ´ and a US = come from the same place. The main block of a Mac keyboard, 15 key units wide and 5
// rows tall (the number row 0 to the space bar's row 4), as a MacBook's: ANSI, or ISO, which has the extra key left of
// Z, the key left of 1 (kVK_ISO_Section; on ISO the code kVK_ANSI_Grave is the key left of Z), the tall Return and the
// key left of it (kVK_ANSI_Backslash, # on a German keyboard). The function row, the arrows and the keypad have no
// position here; the scenes take the caret's x for them. Free of AppKit.

public enum Keyboard {
    /// The physical layout, from KBGetLayoutType (the app reads it at each show); JIS takes ANSI's table, its own keys
    /// have no position.
    public enum Kind: Equatable { case ansi, iso, jis }

    /// A key: the middle of its row (0 the number row, 4 the space bar's; ISO's Return 1.5) and of its column in key
    /// units from the block's left edge (0 to 15), its width and height in key units.
    public struct Position: Equatable {
        public var row: Double, column: Double, width: Double, height: Double
        public init(row: Double, column: Double, width: Double = 1, height: Double = 1) {
            (self.row, self.column, self.width, self.height) = (row, column, width, height)
        }

        /// Across the block, 0 at its left edge and 1 at its right, at the key's middle.
        public var across: Double { column / Keyboard.columns }
        /// Down the block, 0 at the number row and 1 at the space bar's.
        public var down: Double { row / Double(Keyboard.rows - 1) }

        /// The rows and columns of a 5 × 15 grid (row 0 at the top) whose cells' middles the key covers: one cell for
        /// a letter, five for the space bar, two rows for ISO's Return. Ranges, so nothing is allocated per key.
        public var rows: Range<Int> { span(row - height / 2, row + height / 2, 0, Keyboard.rows) }
        public var columns: Range<Int> { span(column - width / 2 - 0.5, column + width / 2 - 0.5, 0, Int(Keyboard.columns)) }
        /// The cells, as pairs.
        public var cells: [(row: Int, column: Int)] { rows.flatMap { r in columns.map { (r, $0) } } }

        /// The whole numbers n with lo ≤ n < hi, within first..<end.
        private func span(_ lo: Double, _ hi: Double, _ first: Int, _ end: Int) -> Range<Int> {
            let a = min(max(Int(lo.rounded(.up)), first), end), b = min(max(Int(hi.rounded(.up)), a), end)
            return a..<b
        }
    }

    public static let columns = 15.0, rows = 5

    /// The kind from KBGetLayoutType's answer: 'ISO ' and 'JIS ', else ANSI (also when it could not be read).
    public static func kind(layoutType: UInt32?) -> Kind {
        switch layoutType {
        case 0x4953_4F20?: .iso  // 'ISO '
        case 0x4A49_5320?: .jis  // 'JIS '
        default: .ansi
        }
    }

    /// The key with the virtual key code `code` (kVK_…) on a `kind` keyboard; nil off the main block.
    public static func position(of code: UInt16, on kind: Kind = .ansi) -> Position? {
        if kind == .iso, let p = iso[code] { return p }
        return ansi[code]
    }

    private static func row(_ r: Double, _ keys: [(UInt16, Double)]) -> [UInt16: Position] {
        Dictionary(uniqueKeysWithValues: keys.map { ($0.0, Position(row: r, column: $0.1)) })
    }

    /// ANSI, a MacBook's main block (the code names are Events.h's kVK_ANSI_… and kVK_…).
    static let ansi: [UInt16: Position] = {
        var t: [UInt16: Position] = [:]
        // Row 0: ` 1 2 3 4 5 6 7 8 9 0 - =, Delete (2 wide; fn-Delete's forward delete comes from the same key).
        t.merge(row(0, [(0x32, 0.5), (0x12, 1.5), (0x13, 2.5), (0x14, 3.5), (0x15, 4.5), (0x17, 5.5), (0x16, 6.5),
                        (0x1A, 7.5), (0x1C, 8.5), (0x19, 9.5), (0x1D, 10.5), (0x1B, 11.5), (0x18, 12.5)])) { $1 }
        t[0x33] = Position(row: 0, column: 14, width: 2)
        t[0x75] = t[0x33]
        // Row 1: Tab, Q W E R T Y U I O P [ ], \ (1.5 wide).
        t[0x30] = Position(row: 1, column: 0.75, width: 1.5)
        t.merge(row(1, [(0x0C, 2), (0x0D, 3), (0x0E, 4), (0x0F, 5), (0x11, 6), (0x10, 7), (0x20, 8), (0x22, 9),
                        (0x1F, 10), (0x23, 11), (0x21, 12), (0x1E, 13)])) { $1 }
        t[0x2A] = Position(row: 1, column: 14.25, width: 1.5)
        // Row 2: Caps Lock, A S D F G H J K L ; ', Return (2.25 wide).
        t[0x39] = Position(row: 2, column: 0.875, width: 1.75)
        t.merge(row(2, [(0x00, 2.25), (0x01, 3.25), (0x02, 4.25), (0x03, 5.25), (0x05, 6.25), (0x04, 7.25),
                        (0x26, 8.25), (0x28, 9.25), (0x25, 10.25), (0x29, 11.25), (0x27, 12.25)])) { $1 }
        t[0x24] = Position(row: 2, column: 13.875, width: 2.25)
        // Row 3: Shift, Z X C V B N M , . /, right Shift.
        t[0x38] = Position(row: 3, column: 1.125, width: 2.25)
        t.merge(row(3, [(0x06, 2.75), (0x07, 3.75), (0x08, 4.75), (0x09, 5.75), (0x0B, 6.75), (0x2D, 7.75),
                        (0x2E, 8.75), (0x2B, 9.75), (0x2F, 10.75), (0x2C, 11.75)])) { $1 }
        t[0x3C] = Position(row: 3, column: 13.625, width: 2.75)
        // Row 4: fn, Control, Option, Command, the space bar (5 wide), right Command, right Option, right Control
        // (an external keyboard's, where a MacBook has its arrows).
        t.merge(row(4, [(0x3F, 0.5), (0x3B, 1.5), (0x3A, 2.5), (0x3D, 11), (0x3E, 12)])) { $1 }
        t[0x37] = Position(row: 4, column: 3.625, width: 1.25)
        t[0x31] = Position(row: 4, column: 6.75, width: 5)
        t[0x36] = Position(row: 4, column: 9.875, width: 1.25)
        return t
    }()

    /// What differs on ISO: the key left of 1 (kVK_ISO_Section), the tall Return over rows 1 and 2 with the key left
    /// of it in row 2 (kVK_ANSI_Backslash), a short left Shift and the extra key right of it (kVK_ANSI_Grave).
    static let iso: [UInt16: Position] = [
        0x0A: Position(row: 0, column: 0.5),
        0x24: Position(row: 1.5, column: 14.375, width: 1.25, height: 2),
        0x2A: Position(row: 2, column: 13.25),
        0x38: Position(row: 3, column: 0.625, width: 1.25),
        0x32: Position(row: 3, column: 1.75),
    ]
}
