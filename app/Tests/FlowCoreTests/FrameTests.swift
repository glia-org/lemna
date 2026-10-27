// The session frame (M1) and what surrounds the surface (W1 K1 O1): the time box's fill and its one end, the tone,
// the log's line and file, the menu-bar mark, the Bluetooth notice, the review's keys. No Foundation here (see
// RenderTests.swift): files through Darwin.
import CoreGraphics
import Darwin
import Testing
@testable import FlowCore

@Test func timeBoxFillsOverItsLengthClamped() {
    let b = TimeBox(minutes: 10, start: 100)
    #expect(b.seconds == 600)
    #expect(b.fraction(at: 100) == 0)
    #expect(b.fraction(at: 400) == 0.5)
    #expect(b.fraction(at: 700) == 1)
    #expect(b.fraction(at: 5000) == 1)  // after the end: full, no further
    #expect(b.fraction(at: 50) == 0)  // a clock read before the start
    #expect(b.fraction(at: 250) < b.fraction(at: 251))
    #expect(TimeBox.choices == [10, 15, 25])
}

@Test func timeBoxEndsOnce() {
    var b = TimeBox(minutes: 25, start: 0)
    let early = b.ends(at: 25 * 60 - 0.1)
    #expect(!early && !b.over)
    let end = b.ends(at: 25 * 60 + 0.4), again = b.ends(at: 25 * 60 + 1)
    #expect(end && !again && b.over)  // one tone, then the line stays full
}

@Test func softEndToneIsA440HzSineAtMinus18dBFSWithFades() {
    let wav = Tone.wav()
    #expect(Array(wav[0..<4]) == Array("RIFF".utf8) && Array(wav[8..<16]) == Array("WAVEfmt ".utf8))
    func u32(_ i: Int) -> Int { Int(wav[i]) | Int(wav[i + 1]) << 8 | Int(wav[i + 2]) << 16 | Int(wav[i + 3]) << 24 }
    #expect(u32(24) == 48_000)  // the rate
    #expect(u32(40) == 2 * 14_400 && wav.count == 44 + 2 * 14_400)  // 300 ms of 16-bit mono
    let samples = stride(from: 44, to: wav.count, by: 2).map { (i: Int) -> Double in
        Double(Int16(bitPattern: UInt16(wav[i]) | UInt16(wav[i + 1]) << 8))
    }
    let full = 32767 * pow(10, -18.0 / 20)  // ≈ 4125
    #expect(abs((samples.map(abs).max() ?? 0) - full) < 2)
    #expect(abs(samples.first!) < 1 && abs(samples.last!) < 30)  // faded in and out: no click at either end
    let firstFade = samples[0..<2400].map(abs).max()!, middle = samples[6000..<8400].map(abs).max()!
    #expect(firstFade < full - 1 && abs(middle - full) < 2)
    // 440 Hz: 132 cycles in 300 ms, so 264 sign changes, give or take the ends.
    let crossings = zip(samples, samples.dropFirst()).filter { (a: Double, b: Double) in (a < 0) != (b < 0) }.count
    #expect(abs(crossings - 264) <= 2)
}

@Test func logLineHoldsTotalsOnly() {
    // 2026-10-27 21:30 UTC is 1_793_136_600 s; at UTC+1 it was 22:30 there.
    #expect(PrivateLog.line(start: 1_793_136_600, offset: 0, seconds: 754, words: 834) == "2026-10-27\t21:30\t12\t834\n")
    #expect(PrivateLog.line(start: 1_793_136_600.9, offset: 3600, seconds: 59, words: 3) == "2026-10-27\t22:30\t0\t3\n")
    #expect(PrivateLog.line(start: 1_793_136_600, offset: 3 * 3600, seconds: 3 * 3600 + 5, words: 0)
        == "2026-10-28\t00:30\t180\t0\n")  // past midnight there: the next day
    #expect(PrivateLog.line(start: 0, offset: 0, seconds: -1, words: 1) == "1970-01-01\t00:00\t0\t1\n")
}

@Test func logFileIsAppendedAndPrivate() {
    var template = Array((String(cString: getenv("TMPDIR")) + "/flow-log-test-XXXXXX").utf8CString)
    let root = template.withUnsafeMutableBufferPointer { String(cString: mkdtemp($0.baseAddress!)) }
    let path = root + "/log.tsv"
    #expect(PrivateLog.append("a\t1\n", to: path) && PrivateLog.append("b\t2\n", to: path))
    var st = stat()
    #expect(stat(path, &st) == 0 && st.st_mode & 0o777 == 0o600)
    let fd = open(path, O_RDONLY)
    var buffer = [UInt8](repeating: 0, count: 64)
    let n = read(fd, &buffer, buffer.count)
    close(fd)
    #expect(String(decoding: buffer[0..<max(n, 0)], as: UTF8.self) == "a\t1\nb\t2\n")
    #expect(!PrivateLog.append("c\n", to: root + "/missing/log.tsv"))
    #expect(unlink(path) == 0 && rmdir(root) == 0)
}

@Test func statusMarkIsALineWithTheCaretAt60Percent() {
    #expect(StatusMark.size == CGSize(width: 16, height: 16))
    let (w, h) = (32, 32)  // 16 × 16 pt at 2×
    let c = Line.context(width: w, height: h, rowBytes: 4 * w, scale: 2, data: nil)
    StatusMark.draw(in: c)
    let px = c.data!.assumingMemoryBound(to: UInt8.self)
    /// The alpha at a point in points (the bitmap's first row is its top).
    func ink(_ x: CGFloat, _ y: CGFloat) -> UInt8 { px[4 * ((h - 1 - Int(y * 2)) * w + Int(x * 2)) + 3] }
    #expect(ink(4, 8.25) == 255 && ink(12.5, 8.25) == 255)  // the line, on both sides of the caret
    #expect(ink(9.25, 11) == 255 && ink(9.25, 5) == 255)  // the caret's bar, above and below the line
    #expect(ink(4, 11) == 0 && ink(12.5, 11) == 0 && ink(9.25, 14) == 0 && ink(9.25, 1) == 0)
    // Above the line only the caret is inked, its middle at 60 % of the line.
    let columns = (0..<w).filter { px[4 * ((h - 1 - 22) * w + $0) + 3] > 0 }
    let middle = (CGFloat(columns.min()!) + CGFloat(columns.max()!) + 1) / 4  // in points
    #expect(abs((middle - StatusMark.line.minX) / StatusMark.line.width - 0.6) < 0.01)
    #expect(columns.count == 3)  // 1.5 pt
}

@Test func bluetoothNoticeShowsOncePerOutput() {
    var n = BluetoothNotice()
    // Mutating calls stay outside #expect, which takes its operands as constants.
    let launch = n.check(bluetooth: true, sound: true), twice = n.check(bluetooth: true, sound: true)
    #expect(launch && !twice)  // once: not again for the same output (⌘K off and on again included)
    n.outputChanged()
    let wired = n.check(bluetooth: false, sound: true)
    #expect(!wired)  // to wired headphones: nothing to say
    n.outputChanged()
    let back = n.check(bluetooth: true, sound: true)
    #expect(back)  // back to Bluetooth: once more
    var muted = BluetoothNotice()
    let off = muted.check(bluetooth: true, sound: false), on = muted.check(bluetooth: true, sound: true)
    #expect(!off && on)  // muted at launch: nothing to warn about, until the sound is turned on
}

@Test func reviewKeysReturnDoesNothingCommandReturnCopies() {
    func route(_ k: UInt16, cmd: Bool = false, others: Bool = false, rep: Bool = false) -> ReviewKey {
        ReviewKey.route(keyCode: k, command: cmd, others: others, isRepeat: rep)
    }
    #expect(route(36) == .nothing && route(76) == .nothing)  // plain Return, Enter: no copy
    #expect(route(36, cmd: true) == .copy && route(76, cmd: true) == .copy)
    #expect(route(36, cmd: true, rep: true) == .nothing)  // ⌘⏎ held past Done
    #expect(route(36, cmd: true, others: true) == .pass && route(36, others: true) == .pass)
    #expect(route(53) == .back && route(53, cmd: true) == .pass)
    #expect(route(1, cmd: true) == .pass && route(0) == .pass)  // ⌘S, letters: the panel's
}

@Test func reviewKeysWithHarpersList() {
    func route(_ k: UInt16, cmd: Bool = false, others: Bool = false, rep: Bool = false,
               listed: Bool = true) -> ReviewKey {
        ReviewKey.route(keyCode: k, command: cmd, others: others, isRepeat: rep, listed: listed)
    }
    #expect(route(36) == .accept && route(76) == .accept)  // Return accepts the selected suggestion
    #expect(route(36, rep: true) == .nothing)  // held (⌘⏎ at Done, ⌘ let go first): not down the list
    #expect(route(36, cmd: true) == .copy && route(36, cmd: true, rep: true) == .nothing)  // ⌘⏎ stays Copy/Paste
    #expect(route(51) == .skip && route(51, rep: true) == .nothing)  // ⌫ skips, once per press
    #expect(route(126) == .up && route(125) == .down && route(125, rep: true) == .down)  // arrows repeat
    #expect(route(126, others: true) == .pass && route(125, cmd: true) == .pass && route(51, cmd: true) == .pass)
    #expect(route(53) == .back)  // Esc is Back still
    // Without a selected suggestion (checking, none, unavailable): as before.
    #expect(route(36, listed: false) == .nothing && route(51, listed: false) == .pass)
    #expect(route(126, listed: false) == .pass && route(125, listed: false) == .pass)
}
