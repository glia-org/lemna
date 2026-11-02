import AVFoundation
import ClickRing

/// An ambient bed (sound.md): a folder with one loop, stereo, its seam crossfaded when it was made, and a `bed.json`:
///
///     {"name": "…", "licence": "CC0-1.0", "source": "https://…", "attribution": "…", "file": "rain.caf", "lufs": -26.0}
///
/// `lufs` is the loop's integrated loudness over both channels (EBU R 128, as ffmpeg's ebur128 measures the file as
/// Core Audio decodes it); the player sets the bed's gain from it. `attribution` is optional, as for a pack.
public struct Bed: Sendable, Equatable {
    public let name: String
    public let licence: String
    public let source: String
    public let attribution: String?
    public let file: URL
    public let lufs: Double

    /// Where every bed plays when `ClickPlayer.bedVolume` is 0.6, its default: −43 LUFS over the two channels, which is
    /// −46 LUFS on each. sound.md §2.3 set the bed at −46 LUFS, 12 LU under the clicks' −34 LUFS at 5 keys a second,
    /// both measured as one channel; the main mixer plays the mono clicks on both channels at full level, so over the
    /// two the clicks make −31 LUFS, and the bed at −43 keeps the 12 LU.
    public static let level = -43.0

    private struct Manifest: Decodable {
        let name: String
        let licence: String
        let source: String
        let attribution: String?
        let file: String
        let lufs: Double
    }

    public init(folder: URL) throws {
        let data = try Data(contentsOf: folder.appendingPathComponent("bed.json"))
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)
        let file = folder.appendingPathComponent(manifest.file)
        if !FileManager.default.fileExists(atPath: file.path) {
            throw ClickError("bed.json: \(manifest.file) not found in the bed")
        }
        name = manifest.name
        licence = manifest.licence
        source = manifest.source
        attribution = manifest.attribution
        self.file = file
        lufs = manifest.lufs
    }

    /// A bed an app carries in `Contents/Resources/Beds/<name>`: `Rain`, `Ship`, `Lab`, `Space`, `Synth` (see
    /// THIRD_PARTY.md).
    public static func bundled(_ name: String) throws -> Bed {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Beds/\(name)"),
              FileManager.default.fileExists(atPath: url.path) else {
            throw ClickError("the bed \(name) is missing from the app's Contents/Resources/Beds")
        }
        return try Bed(folder: url)
    }

    /// The gain that puts the loop at `level` under a `bedVolume` of 0.6.
    var gain: Float { Float(pow(10, (Self.level - lufs) / 20) / 0.6) }
}

/// The audio-thread half of a bed: the loop played round and round, its level ramped toward a target the main thread
/// sets. As in `Mixer`, everything `render` touches exists before the first call; it takes no lock, allocates nothing.
final class BedLoop {
    let frames: Int
    let sampleRate: Double
    private let buffer: AVAudioPCMBuffer  // owns the samples
    private let left: UnsafeMutablePointer<Float>
    private let right: UnsafeMutablePointer<Float>
    private let gain: Float
    private let fade: OpaquePointer

    /// Render thread only; tests read them.
    private(set) var position = 0
    private(set) var level: Float = 0

    /// A float buffer of one or two channels (one plays on both), at its own rate; silent until `fade`.
    init(_ buffer: AVAudioPCMBuffer, gain: Float) {
        self.buffer = buffer
        frames = Int(buffer.frameLength)
        sampleRate = buffer.format.sampleRate
        left = buffer.floatChannelData![0]
        right = buffer.format.channelCount > 1 ? buffer.floatChannelData![1] : left
        self.gain = gain
        fade = click_fade_create()!
    }

    deinit { click_fade_destroy(fade) }

    /// The bed's whole loop, decoded (90 s of stereo AAC: 35 MB as floats, some 40 ms).
    static func load(_ bed: Bed) throws -> BedLoop {
        let file = try AVAudioFile(forReading: bed.file)
        guard file.length > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
        else { throw ClickError("\(bed.file.lastPathComponent): empty") }
        try file.read(into: buffer)
        guard buffer.frameLength > 0, buffer.floatChannelData != nil else {
            throw ClickError("\(bed.file.lastPathComponent): no samples")
        }
        return BedLoop(buffer, gain: bed.gain)
    }

    /// Any thread: move to `target` (0 silent, 1 full) over `seconds` of a whole fade, from the level it has now, so a
    /// fade turned back midway leaves no gap; 0 s jumps there at the next buffer.
    func fade(to target: Float, over seconds: Double) {
        click_fade_set(fade, target, seconds > 0 ? Float(1 / (seconds * sampleRate)) : 1)
    }

    /// Render thread: the next `n` frames into `l` and `r`; false when silent, both then zeros, and the loop stays where
    /// it is. The level runs straight; the gain follows a quarter sine of it, equal power: a sine in, a cosine out.
    func render(frames n: Int, left l: UnsafeMutablePointer<Float>, right r: UnsafeMutablePointer<Float>) -> Bool {
        var target: Float = 0, step: Float = 0
        click_fade_get(fade, &target, &step)
        if level == 0 && target == 0 {
            l.update(repeating: 0, count: n)
            r.update(repeating: 0, count: n)
            return false
        }
        var g = gain * sin(.pi / 2 * level)
        for i in 0..<n {
            if level != target {
                level = level < target ? min(level + step, target) : max(level - step, target)
                g = gain * sin(.pi / 2 * level)
            }
            l[i] = left[position] * g
            r[i] = right[position] * g
            position += 1
            if position == frames { position = 0 }
        }
        return true
    }
}
