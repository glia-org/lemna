// Where a key is (DESIGN.md A1, pass 16): the physical key codes of a Mac's main block on ANSI and ISO, the cells a key
// covers, and the layout type. No Foundation here.
import Testing
@testable import LemnaCore

private func at(_ code: UInt16, _ kind: Keyboard.Kind = .ansi) -> Keyboard.Position? { Keyboard.position(of: code, on: kind) }

/// The cells a key covers, as "row,column".
private func cells(_ code: UInt16, _ kind: Keyboard.Kind = .ansi) -> [String] {
    (at(code, kind)?.cells ?? []).map { "\($0.row),\($0.column)" }
}

@Test func theKeymapPlacesKnownKeysWhereAMacBookHasThem() {
    #expect(at(0x00) == Keyboard.Position(row: 2, column: 2.25))  // kVK_ANSI_A, the home row's first letter
    #expect(at(0x0C) == Keyboard.Position(row: 1, column: 2))  // kVK_ANSI_Q
    #expect(at(0x06) == Keyboard.Position(row: 3, column: 2.75))  // kVK_ANSI_Z
    #expect(at(0x12) == Keyboard.Position(row: 0, column: 1.5))  // kVK_ANSI_1
    #expect(at(0x31) == Keyboard.Position(row: 4, column: 6.75, width: 5))  // kVK_Space
    #expect(cells(0x31) == ["4,4", "4,5", "4,6", "4,7", "4,8"])  // the space bar: a bar of five
    #expect(at(0x33) == Keyboard.Position(row: 0, column: 14, width: 2) && at(0x75) == at(0x33))  // Delete, fn-Delete
    #expect(at(0x24) == Keyboard.Position(row: 2, column: 13.875, width: 2.25) && cells(0x24) == ["2,13", "2,14"])
    #expect(at(0x32) == Keyboard.Position(row: 0, column: 0.5))  // kVK_ANSI_Grave: ` left of 1 on ANSI
    #expect(at(0x2A) == Keyboard.Position(row: 1, column: 14.25, width: 1.5))  // kVK_ANSI_Backslash above Return
    #expect(at(0x0A) == nil)  // kVK_ISO_Section: no such key on ANSI
    // ISO (a German MacBook): ^ left of 1, the tall Return, # left of it, < left of Z.
    #expect(at(0x0A, .iso) == Keyboard.Position(row: 0, column: 0.5))
    #expect(cells(0x24, .iso) == ["1,14", "2,14"])
    #expect(at(0x2A, .iso) == Keyboard.Position(row: 2, column: 13.25))
    #expect(at(0x32, .iso) == Keyboard.Position(row: 3, column: 1.75) && cells(0x32, .iso) == ["3,1"])
    #expect(at(0x00, .iso) == at(0x00) && at(0x06, .iso) == at(0x06))  // the letters stay where they are
    // No position: the arrows, Esc, the keypad, the function row; JIS's own keys.
    for code: UInt16 in [0x7B, 0x7C, 0x7D, 0x7E, 0x35, 0x52, 0x7A, 0x5D, 0x66] { #expect(at(code) == nil, "\(code)") }
    #expect(at(0x00, .jis) == at(0x00))
}

@Test func everyCharacterKeyHasACellOfItsOwn() {
    // The 47 keys that type (letters, digits, punctuation, the ISO extras) each cover cells of their own (one, or two
    // for ANSI's 1.5-wide \), no two the same.
    let typing: [UInt16] = Array(0x00...0x09) + Array(0x0B...0x23) + [0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C,
                                                                      0x2D, 0x2E, 0x2F, 0x32]
    #expect(typing.count == 47)
    for kind in [Keyboard.Kind.ansi, .iso] {
        let keys = typing + (kind == .iso ? [0x0A] : []), all = keys.flatMap { cells($0, kind) }
        #expect(keys.allSatisfy { !cells($0, kind).isEmpty }, "\(kind)")
        #expect(Set(all).count == all.count, "\(kind): two keys on one cell")
        #expect(all.allSatisfy { !$0.hasPrefix("4,") }, "\(kind): nothing typing in the space bar's row")
    }
    let a = at(0x00)!, del = at(0x33)!
    #expect(a.across > 0.1 && a.across < 0.2 && del.across > 0.9 && a.down == 0.5 && at(0x31)!.down == 1)
}

@Test func theLayoutTypeIsReadFromItsCode() {
    #expect(Keyboard.kind(layoutType: 0x4953_4F20) == .iso)  // 'ISO '
    #expect(Keyboard.kind(layoutType: 0x4A49_5320) == .jis)  // 'JIS '
    #expect(Keyboard.kind(layoutType: 0x414E_5349) == .ansi && Keyboard.kind(layoutType: nil) == .ansi)
}
