// The session frame (DESIGN.md M1): an optional time box with its peripheral line and soft end, the soft end's tone,
// and the private log of totals. Free of AppKit and of clocks, so the tests drive it.
import Foundation

/// A time box: the line along the surface's bottom edge fills over it, and it ends once, softly. Nothing stops: typing
/// goes on after the end (P0).
public struct TimeBox: Equatable {
    /// What the sheet offers, in minutes; Off is no box.
    public static let choices = [10, 15, 25]
    public let minutes: Int
    /// When the box began, on the clock the app ticks it with.
    public let start: Double
    /// The end has come (and was told once).
    public private(set) var over = false

    public init(minutes: Int, start: Double) {
        self.minutes = max(minutes, 1)
        self.start = start
    }

    public var seconds: Double { Double(minutes) * 60 }

    /// How far the line has filled at `t`: 0 at the start, 1 at the end and after it, never outside 0…1.
    public func fraction(at t: Double) -> Double { min(max((t - start) / seconds, 0), 1) }

    /// True once, at the first tick at or past the end: the tone plays and the line stays full.
    public mutating func ends(at t: Double) -> Bool {
        guard !over, t >= start + seconds else { return false }
        over = true
        return true
    }
}

/// The soft end's tone as a 16-bit mono WAV file in memory, for NSSound: the click player plays only its pack's
/// samples, so it cannot take an ad-hoc buffer. A sine with raised-cosine fades, so it starts and stops without a
/// click.
public enum Tone {
    public static func wav(hertz: Double = 440, seconds: Double = 0.3, dBFS: Double = -18, fade: Double = 0.05,
                           rate: Int = 48_000) -> [UInt8] {
        let n = Int((seconds * Double(rate)).rounded()), f = max(Int((fade * Double(rate)).rounded()), 1)
        let peak = pow(10, dBFS / 20) * Double(Int16.max)
        var out: [UInt8] = []
        out.reserveCapacity(44 + 2 * n)
        func u32(_ v: Int) { withUnsafeBytes(of: UInt32(v).littleEndian) { out.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
        out += Array("RIFF".utf8)
        u32(36 + 2 * n)
        out += Array("WAVEfmt ".utf8)
        u32(16)
        u16(1)  // PCM
        u16(1)  // mono
        u32(rate)
        u32(2 * rate)  // bytes per second
        u16(2)  // bytes per frame
        u16(16)  // bits per sample
        out += Array("data".utf8)
        u32(2 * n)
        for i in 0..<n {
            let edge = min(i, n - 1 - i)
            let gain = edge >= f ? 1 : 0.5 - 0.5 * cos(Double.pi * Double(edge) / Double(f))
            let v = peak * gain * sin(2 * Double.pi * hertz * Double(i) / Double(rate))
            u16(UInt16(bitPattern: Int16(v.rounded())))
        }
        return out
    }
}

/// The private log (M1): one line of totals per finished session. Never text, never timing per key.
public enum PrivateLog {
    /// `YYYY-MM-DD\tHH:MM\tminutes\twords\n`: when the session began, in local time (`offset`: seconds east of UTC),
    /// its whole minutes (rounded down, as the review shows them) and its words. `start`: seconds since 1970.
    public static func line(start: Double, offset: Int, seconds: Double, words: Int) -> String {
        var t = time_t(start.rounded(.down)) + time_t(offset), c = tm()
        gmtime_r(&t, &c)
        return String(format: "%04d-%02d-%02d\t%02d:%02d\t%d\t%d\n", c.tm_year + 1900, c.tm_mon + 1, c.tm_mday, c.tm_hour,
                      c.tm_min, Int(max(seconds, 0) / 60), words)
    }

    /// Appends `line` to the file at `path` in one write(2) with O_APPEND, so lines never interleave; the file is
    /// made 0600, and kept so. False when it cannot be opened or written.
    @discardableResult
    public static func append(_ line: String, to path: String) -> Bool {
        let fd = open(path, O_WRONLY | O_APPEND | O_CREAT | O_CLOEXEC, 0o600)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        fchmod(fd, 0o600)
        let bytes = Array(line.utf8)
        return write(fd, bytes, bytes.count) == bytes.count
    }
}
