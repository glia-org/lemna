import AVFoundation
import Darwin
import Testing
@testable import LemnaClicks

// MARK: The default pack

/// A pack from the source tree: `SoundPack.bundled()` reads an app's Contents/Resources, which a test lacks.
private func pack(_ folder: String) throws -> SoundPack {
    let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()
    return try SoundPack(folder: package.appendingPathComponent("Sources/LemnaClicks/\(folder)"))
}

private func defaultPack() throws -> SoundPack { try pack("DefaultPack") }

/// A bed from the source tree, as a pack: `Bed.bundled` reads an app's Contents/Resources/Beds.
private func bed(_ folder: String) throws -> Bed {
    let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()
    return try Bed(folder: package.appendingPathComponent("Sources/LemnaClicks/Beds/\(folder)"))
}

private func rain() throws -> Bed { try bed("Rain") }

/// A file's channels as floats, as AVAudioFile decodes them.
private func channels(_ url: URL) throws -> [[Float]] {
    let file = try AVAudioFile(forReading: url)
    let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
    try file.read(into: buffer)
    return (0..<Int(buffer.format.channelCount)).map {
        Array(UnsafeBufferPointer(start: buffer.floatChannelData![$0], count: Int(buffer.frameLength)))
    }
}

/// The squares of one 48 kHz channel through ITU-R BS.1770's K-weighting (the head's high shelf, then the RLB
/// high-pass), whose means give loudness as ffmpeg's ebur128 measures it.
private func kWeightedSquares(_ x: [Float]) -> [Double] {
    var out = [Double](repeating: 0, count: x.count)
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0, z1 = 0.0, z2 = 0.0
    for i in x.indices {
        let v = Double(x[i])
        let y = 1.53512485958697 * v - 2.69169618940638 * x1 + 1.19839281085285 * x2 + 1.69065929318241 * y1
            - 0.73248077421585 * y2
        let z = y - 2 * y1 + y2 + 1.99004745483398 * z1 - 0.99007225036621 * z2
        (x2, x1, y2, y1, z2, z1) = (x1, v, y1, y, z1, z)
        out[i] = z * z
    }
    return out
}

/// The loudest 400 ms of a mono 48 kHz file in LUFS (BS.1770 momentary loudness every 10 ms over the file followed by
/// 0.5 s of silence): THIRD_PARTY.md's M max.
private func momentaryMax(_ url: URL) throws -> Double {
    let x = try channels(url)[0] + [Float](repeating: 0, count: 24_000)
    var sums = [0.0]
    for z in kWeightedSquares(x) { sums.append(sums[sums.count - 1] + z) }
    let window = 19_200
    let loudest = stride(from: 480, through: x.count, by: 480).map { (sums[$0] - sums[max($0 - window, 0)]) / Double(window) }.max()!
    return -0.691 + 10 * log10(loudest)
}

/// The loudness of the whole of a 48 kHz file over all its channels, ungated: a steady bed's integrated loudness.
private func loudness(_ url: URL) throws -> Double {
    let power = try channels(url).reduce(0.0) { sum, x in sum + kWeightedSquares(x).reduce(0, +) / Double(x.count) }
    return -0.691 + 10 * log10(power)
}

private func peakDB(_ url: URL) throws -> Double {
    20 * log10(Double(try channels(url).joined().map(abs).max() ?? 0))
}

@Test func bundledThrowsWithoutThePackInTheApp() {
    // The test runner is not an app: no pack in its resources.
    #expect(throws: ClickError.self) { try SoundPack.bundled() }
    #expect(throws: ClickError.self) { try SoundPack.bundled("TypewriterPack") }
}

@Test func defaultPackMeetsTheFormat() throws {
    let pack = try defaultPack()
    #expect(pack.licence == "CC0-1.0")
    #expect((3...6).contains(pack.files[.letter]?.count ?? 0))
    for kind in [KeyKind.space, .paragraph, .backspace] {
        #expect(pack.files[kind]?.count == 2, "\(kind)")
    }
    var bytes = 0
    for url in pack.files.values.joined() {
        let file = try AVAudioFile(forReading: url)
        let name = url.lastPathComponent
        #expect(file.fileFormat.sampleRate == 48_000, "\(name)")
        #expect(file.fileFormat.channelCount == 1, "\(name)")
        #expect(file.fileFormat.commonFormat == .pcmFormatInt16, "\(name)")
        #expect(Double(file.length) / 48_000 <= (name.hasPrefix("send-") ? 0.45 : 0.150), "\(name)")  // the send: below
        bytes += try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }
    #expect(bytes <= 600_000)
}

// MARK: The packs beside it (DESIGN.md K1: Typewriter, Soft, Electric)

@Test(arguments: ["TypewriterPack", "SoftPack", "ElectricPack", "StonePack"])
func packLoadsAndMapsEachKeyToItsOwnCuts(_ folder: String) throws {
    let p = try pack(folder)
    let letters = folder == "StonePack" ? 8 : 6  // Stone: four takes, each also 6 % slower
    #expect(p.licence == (folder == "ElectricPack" ? "CC-BY-4.0" : "CC0-1.0"))
    #expect(p.files[.letter]?.count == letters)
    for kind in [KeyKind.space, .paragraph, .backspace] {
        #expect(p.files[kind]?.count == 2, "\(kind)")
    }
    var bytes = 0, count = 0
    for (kind, urls) in p.files {
        for url in urls {
            let file = try AVAudioFile(forReading: url)
            let name = url.lastPathComponent
            #expect(name.hasPrefix("\(kind)-"), "\(name)")  // Return plays the carriage return, ⌫ its own cuts
            #expect(file.fileFormat.sampleRate == 48_000, "\(name)")
            #expect(file.fileFormat.channelCount == 1, "\(name)")
            #expect(file.fileFormat.commonFormat == .pcmFormatInt16, "\(name)")
            // A carriage return may run long, as paragraphs are rare, and so may the send; every other key stays a click.
            let send = folder == "StonePack" ? 1.0 : 0.45
            #expect(Double(file.length) / 48_000 <= (kind == .paragraph ? 1.0 : kind == .send ? send : 0.150), "\(name)")
            bytes += try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            count += 1
        }
    }
    #expect(count == letters + 7)
    #expect(bytes <= 1_000_000)
}

/// Stone's kinds sit where the Keychron's do by loudness (each kind's mean M max within 0.3 LU; THIRD_PARTY.md). Its
/// send, a hand chime, gets there at a peak near -20 dBFS: a ringing tone holds far more energy per peak than a click.
@Test func stoneIsLevelledToTheKeychronByLoudness() throws {
    let stone = try pack("StonePack"), keychron = try defaultPack()
    func mean(_ urls: [URL]) throws -> Double { try urls.map(momentaryMax).reduce(0, +) / Double(urls.count) }
    for kind in KeyKind.allCases {
        let s = try mean(stone.files[kind] ?? []), k = try mean(keychron.files[kind] ?? [])
        #expect(abs(s - k) < 0.3, "\(kind): Stone \(s), Keychron \(k) LUFS")
    }
    let peak = try peakDB(try #require(stone.files[.send]?.first))
    #expect(abs(peak + 20) < 0.5, "send peak \(peak) dBFS")
}

// MARK: The send (DESIGN.md K1, pass 19a; pass 23a)

/// ⌘⏎'s sound in every pack: one sample cut from the pack's own recordings, longer than a click (a key's release or a
/// carriage's stop in it; Stone's hand chime rings to 0.9 s), and as loud as the pack's Returns: its M max within 3 LU
/// of theirs. Pass 19a asked for a peak of -6 dBFS, as the clicks; the four sends cut so land 0.2–1.7 LU from their
/// Returns, but a ringing tone at that peak would stand 14 LU over them (pass 23a), so the rule is now one of loudness.
@Test(arguments: ["DefaultPack", "TypewriterPack", "SoftPack", "ElectricPack", "StonePack"])
func everyPackHasItsSend(_ folder: String) throws {
    let p = try pack(folder)
    let urls = p.files[.send] ?? []
    #expect(urls.map(\.lastPathComponent) == ["send-1.wav"])
    let returns = try (p.files[.paragraph] ?? []).map(momentaryMax)
    for url in urls {
        let file = try AVAudioFile(forReading: url)
        #expect(file.fileFormat.sampleRate == 48_000 && file.fileFormat.channelCount == 1)
        #expect(file.fileFormat.commonFormat == .pcmFormatInt16)
        let seconds = Double(file.length) / 48_000
        #expect(seconds > 0.2 && seconds <= (folder == "StonePack" ? 1.0 : 0.45), "\(seconds) s")
        let loudness = try momentaryMax(url)
        #expect(abs(loudness - returns.reduce(0, +) / Double(returns.count)) <= 3, "M max \(loudness), Returns \(returns)")
    }
}

@Test func theCCBYPackCarriesItsCreditLine() throws {
    let credit = try pack("ElectricPack").attribution ?? ""
    #expect(credit.contains("by magedu") && credit.contains("CC BY 4.0"))
    #expect(credit.contains("https://creativecommons.org/licenses/by/4.0/"))
    #expect(credit.contains("https://freesound.org/people/magedu/packs/17107/"))
    #expect(credit.contains("spliced"))  // the send, made shorter than the return was recorded (pass 19a)
    for id in [277721, 277724, 319944, 319945] {
        #expect(credit.contains("https://freesound.org/people/magedu/sounds/\(id)/"), "\(id)")
    }
    #expect(try defaultPack().attribution == nil && pack("TypewriterPack").attribution == nil)  // CC0: none owed
}

@Test func packJSONMustNameEveryKindAndNoOther() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("lemnaclicks-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    try Data().write(to: folder.appendingPathComponent("a.wav"))
    func write(_ files: String, _ more: String = "") throws {
        let json = #"{"name": "t", "licence": "CC0-1.0", "source": "-", \#(more) "files": {\#(files)}}"#
        try json.write(to: folder.appendingPathComponent("pack.json"), atomically: true, encoding: .utf8)
    }
    try write(#""letter": ["a.wav"], "space": ["a.wav"], "paragraph": ["a.wav"], "backspace": ["a.wav"], "send": ["a.wav"]"#)
    #expect(try SoundPack(folder: folder).files.count == 5)
    try write(#""letter": ["a.wav"], "space": ["a.wav"], "paragraph": ["a.wav"], "backspace": ["a.wav"]"#)  // no send
    #expect(throws: ClickError.self) { try SoundPack(folder: folder) }
    try write(#""letter": ["a.wav"], "space": ["a.wav"], "paragraph": ["a.wav"], "backspace": ["a.wav"], "send": ["a.wav"], "enter": ["a.wav"]"#)
    #expect(throws: ClickError.self) { try SoundPack(folder: folder) }
    try write(#""letter": ["b.wav"], "space": ["a.wav"], "paragraph": ["a.wav"], "backspace": ["a.wav"], "send": ["a.wav"]"#)
    #expect(throws: ClickError.self) { try SoundPack(folder: folder) }
    let all = #""letter": ["a.wav"], "space": ["a.wav"], "paragraph": ["a.wav"], "backspace": ["a.wav"], "send": ["a.wav"]"#
    try write(all)
    #expect(try SoundPack(folder: folder).pitched.isEmpty)  // unpitched unless named
    try write(all, #""pitched": ["send"],"#)
    #expect(try SoundPack(folder: folder).pitched == [.send])
    try write(all, #""pitched": ["chime"],"#)
    #expect(throws: ClickError.self) { try SoundPack(folder: folder) }
}

@Test func aFileAtAnotherRateAndInStereoIsConvertedOnLoad() throws {
    // A device at 44.1 kHz gets the 48 kHz pack through this path; here the other way round.
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("lemnaclicks-\(UUID().uuidString).caf")
    defer { try? FileManager.default.removeItem(at: url) }
    let stereo = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    let tone = AVAudioPCMBuffer(pcmFormat: stereo, frameCapacity: 4410)!
    tone.frameLength = 4410
    for i in 0..<4410 {
        tone.floatChannelData![0][i] = 0.5 * sin(Float(i) * 0.05)
        tone.floatChannelData![1][i] = 0.5 * sin(Float(i) * 0.05)
    }
    try AVAudioFile(forWriting: url, settings: stereo.settings).write(from: tone)
    let mono48 = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    let samples = try ClickPlayer.load(url, as: mono48)
    #expect(abs(samples.count - 4800) <= 2)
    let peak = samples.map(abs).max() ?? 0
    #expect(peak > 0.4 && peak < 0.6)  // the two channels mixed, not summed or dropped
}

// MARK: Picking

@Test func roundRobinNeverRepeatsAndUsesEverySample() {
    let counts = [6, 2, 2, 2, 2]
    var picker = Picker(counts: counts, seed: 1)
    var first = 0
    for kind in KeyKind.allCases {
        var last = -1
        var repeats = 0
        var seen = Set<Int>()
        for _ in 0..<10_000 {
            let sample = picker.next(kind).sample
            if sample == last { repeats += 1 }
            last = sample
            seen.insert(sample)
        }
        #expect(repeats == 0, "\(kind)")
        #expect(seen == Set(first..<first + counts[kind.rawValue]), "\(kind)")
        first += counts[kind.rawValue]
    }
}

@Test func eachPacksPickerStaysInItsPartOfTheTable() {
    // The player lays the packs out one after the other: the second pack's 13 samples follow the first's 13.
    var picker = Picker(counts: [6, 2, 2, 2, 1], seed: 3, base: 13)
    var seen: [KeyKind: Set<Int>] = [:]
    for i in 0..<10_000 {
        let kind = KeyKind.allCases[i % 5]
        seen[kind, default: []].insert(picker.next(kind).sample)
    }
    #expect(seen[.letter] == Set(13..<19) && seen[.space] == [19, 20])
    #expect(seen[.paragraph] == [21, 22] && seen[.backspace] == [23, 24] && seen[.send] == [25])
}

@Test func sendPlaysThePacksOneSendSample() {
    // A pack's one send, after its 12 clicks, every time (pass 19a): no other sample stands in for it.
    var picker = Picker(counts: [6, 2, 2, 2, 1], seed: 5)
    for _ in 0..<100 { #expect(picker.next(.send).sample == 12) }
}

@Test func rateStaysWithinThreePercent() {
    var picker = Picker(counts: [6, 2, 2, 2, 1], seed: 7)
    var low: Float = 2
    var high: Float = 0
    for i in 0..<10_000 {
        let rate = picker.next(KeyKind.allCases[i % 5]).rate
        low = min(low, rate)
        high = max(high, rate)
    }
    #expect(low >= 0.97 - 1e-6 && high <= 1.03 + 1e-6)
    #expect(low < 0.975 && high > 1.025)  // and the whole spread is used
}

/// A pitched kind keeps its recorded rate, so its repeats are one note, not a tune within a semitone (sound.md §4.2);
/// the others keep the ±3 %. Only the Stone pack names any: its slit drum (Return) and its chime (the send).
@Test func pitchedKindsPlayAtTheirRecordedRate() throws {
    var picker = Picker(counts: [8, 2, 2, 2, 1], seed: 11, pitched: [.paragraph, .send])
    var low: [KeyKind: Float] = [:], high: [KeyKind: Float] = [:]
    for i in 0..<10_000 {
        let kind = KeyKind.allCases[i % 5]
        let rate = picker.next(kind).rate
        low[kind] = min(low[kind] ?? 2, rate)
        high[kind] = max(high[kind] ?? 0, rate)
    }
    for kind in [KeyKind.paragraph, .send] { #expect(low[kind] == 1 && high[kind] == 1, "\(kind)") }
    for kind in [KeyKind.letter, .space, .backspace] { #expect(low[kind]! < 0.975 && high[kind]! > 1.025, "\(kind)") }
    #expect(try pack("StonePack").pitched == [.paragraph, .send])
    for folder in ["DefaultPack", "TypewriterPack", "SoftPack", "ElectricPack"] { #expect(try pack(folder).pitched.isEmpty) }
}

// MARK: Mixing

private func render(_ mixer: Mixer, _ frames: Int) -> (sounded: Bool, out: [Float]) {
    var out = [Float](repeating: 1, count: frames)
    let sounded = out.withUnsafeMutableBufferPointer { mixer.render(frames: frames, into: $0.baseAddress!) }
    return (sounded, out)
}

@Test func aClickStartsAtTheHeadOfTheNextBufferAndEnds() {
    let mixer = Mixer(samples: [Array(repeating: 0.5, count: 100)])
    var r = render(mixer, 64)
    #expect(!r.sounded && r.out.allSatisfy { $0 == 0 })
    mixer.trigger(sample: 0, rate: 1)
    r = render(mixer, 64)
    #expect(r.sounded && r.out.allSatisfy { $0 == 0.5 })
    r = render(mixer, 64)  // frames 64...98 of the sample, then silence
    #expect(r.out.prefix(35).allSatisfy { $0 == 0.5 } && r.out.dropFirst(35).allSatisfy { $0 == 0 })
    #expect(!render(mixer, 64).sounded)
    #expect(mixer.consumed == 1)
}

@Test func aFasterRateShortensTheClick() {
    let mixer = Mixer(samples: [Array(repeating: 1, count: 1000)])
    mixer.trigger(sample: 0, rate: 1.03)
    let r = render(mixer, 2048)
    #expect(r.out.filter { $0 != 0 }.count == 970)  // positions 0, 1.03, … below 999
}

@Test func voicesBeyondTheTableAreStolen() {
    let mixer = Mixer(samples: [Array(repeating: 0.01, count: 48_000)])
    for _ in 0..<(Mixer.voiceCount + 4) { mixer.trigger(sample: 0, rate: 1) }
    let r = render(mixer, 32)
    #expect(mixer.consumed == Mixer.voiceCount + 4)
    #expect(mixer.activeVoices == Mixer.voiceCount)
    #expect(abs(r.out[0] - Float(Mixer.voiceCount) * 0.01) < 1e-5)
}

// MARK: The bed (sound.md §2, pass 23a)

@Test func bedJSONNamesItsLoop() throws {
    let bed = try rain()
    #expect(bed.licence == "CC0-1.0" && bed.attribution == nil)  // CC0: no credit owed
    #expect(bed.source == "https://freesound.org/people/felix.blume/sounds/585845/")
    #expect(bed.file.lastPathComponent == "rain.caf")
    #expect(throws: ClickError.self) { try Bed.bundled("Rain") }  // the test runner is not an app
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("lemnaclicks-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let json = #"{"name": "t", "licence": "CC0-1.0", "source": "-", "file": "loop.caf", "lufs": -30}"#
    try json.write(to: folder.appendingPathComponent("bed.json"), atomically: true, encoding: .utf8)
    #expect(throws: ClickError.self) { try Bed(folder: folder) }  // no loop.caf
    try Data().write(to: folder.appendingPathComponent("loop.caf"))
    #expect(try Bed(folder: folder).lufs == -30)
}

/// The four beds of pass 28, the user's picks FB2, FB6, FB7 and FB8 of docs/design-panel-lemna-future-bed.html: each
/// names its loop and its page; the one under CC BY carries its credit line (THIRD_PARTY.md), the CC0 ones none.
@Test func theFutureBedsNameTheirLoopsAndTheirCredit() throws {
    for (folder, file, page) in [("Ship", "ship.caf", "jaava73/sounds/45347"),
                                 ("Lab", "lab.caf", "qubodup/sounds/212025"),
                                 ("Space", "space.caf", "Sonicfreak/sounds/174450"),
                                 ("Synth", "synth.caf", "PhonZz/sounds/242773")] {
        let b = try bed(folder)
        #expect(b.file.lastPathComponent == file && b.source == "https://freesound.org/people/\(page)/", "\(folder)")
        #expect(b.licence == (folder == "Lab" ? "CC-BY-4.0" : "CC0-1.0"), "\(folder)")
        #expect((b.attribution == nil) == (folder != "Lab"), "\(folder)")  // CC0: no credit owed
    }
    // The author's own form (title, name, "with sounds by"), the page's licence field (4.0) and the description's
    // (3.0), each with its link, and what was changed (CC BY 4.0 §3(a), 3.0 §4(a) and (b)).
    let credit = try bed("Lab").attribution ?? ""
    #expect(credit.contains("Sci-fi Laboratory Ambience (https://freesound.org/people/qubodup/sounds/212025/)"))
    #expect(credit.contains("by Iwan ‘qubodup’ Gabovitch (https://freesound.org/people/qubodup/)"))
    #expect(credit.contains("with sounds by wolick, swiftoid, Diboz"))
    #expect(credit.contains("CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)"))
    #expect(credit.contains("CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/legalcode)"))
    #expect(credit.contains("high-pass filtered at 80 and 120 Hz"))
}

/// Every bed as it ships: 90 s of 48 kHz stereo AAC, exact to the frame (the seam is in the samples, so a frame of
/// padding would put a gap in it), about 1.5 MB, and no step at the wrap bigger than the loop's own: in its samples,
/// and in its level, the half second either side of the wrap differing no more than nine in ten of the loop's own
/// adjacent half seconds do. Pass 23a held the level to 1 dB; a half second of Ship's hum or the Synth's pad differs
/// from the next by 0.6–0.8 dB in the median and 1.3–2.0 dB in one of ten, so 1 dB failed Ship's wrap (1.29 dB, at
/// its 74th percentile: no seam, the take's own change). The rain's wrap is 0.15–0.20 dB, at its 10th–14th.
@Test(arguments: ["Rain", "Ship", "Lab", "Space", "Synth"])
func everyBedIsANinetySecondStereoLoopWithoutASeam(_ folder: String) throws {
    let url = try bed(folder).file
    let file = try AVAudioFile(forReading: url)
    #expect(file.fileFormat.sampleRate == 48_000 && file.fileFormat.channelCount == 2)
    #expect(file.length == 90 * 48_000)
    #expect(try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0 <= 1_600_000)
    for x in try channels(url) {
        let wrap = abs(x[0] - x[x.count - 1])
        var larger = 0
        for i in 1..<x.count where abs(x[i] - x[i - 1]) > wrap { larger += 1 }
        #expect(larger > x.count / 1000, "\(folder): the wrap's step \(wrap) is in the loop's largest 0.1 %")
        let half = 24_000
        var sums = [0.0]
        sums.reserveCapacity(x.count + 1)
        for v in x { sums.append(sums[sums.count - 1] + Double(v) * Double(v)) }
        func level(_ from: Int, _ to: Int) -> Double { 10 * log10((sums[to] - sums[from]) / Double(to - from)) }
        let atWrap = abs(level(x.count - half, x.count) - level(0, half))
        let steps = stride(from: half, through: x.count - half, by: 4_800)
            .map { abs(level($0 - half, $0) - level($0, $0 + half)) }.sorted()
        #expect(atWrap <= steps[steps.count * 9 / 10], "\(folder): level either side of the wrap \(atWrap) dB")
    }
}

/// bed.json's lufs is the loop's loudness, and the gain from it puts every bed at `Bed.level` under a bedVolume of 0.6.
@Test(arguments: ["Rain", "Ship", "Lab", "Space", "Synth"])
func everyBedPlaysAtTheBedLevel(_ folder: String) throws {
    let b = try bed(folder)
    let measured = try loudness(b.file)
    #expect(abs(measured - b.lufs) < 0.3, "\(folder): the loop measures \(measured) LUFS")
    #expect(Bed.level == -43)
    #expect(abs(measured + 20 * log10(Double(b.gain) * 0.6) - Bed.level) < 0.3)
}

private func loopBuffer(_ left: [Float], _ right: [Float]) -> AVAudioPCMBuffer {
    let buffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!,
                                  frameCapacity: AVAudioFrameCount(left.count))!
    buffer.frameLength = AVAudioFrameCount(left.count)
    for i in left.indices {
        buffer.floatChannelData![0][i] = left[i]
        buffer.floatChannelData![1][i] = right[i]
    }
    return buffer
}

private func render(_ loop: BedLoop, _ frames: Int) -> (sounded: Bool, left: [Float], right: [Float]) {
    var l = [Float](repeating: 1, count: frames), r = [Float](repeating: 1, count: frames)
    let sounded = l.withUnsafeMutableBufferPointer { lp in
        r.withUnsafeMutableBufferPointer { rp in loop.render(frames: frames, left: lp.baseAddress!, right: rp.baseAddress!) }
    }
    return (sounded, l, r)
}

@Test func theBedLoopsRoundByIndex() {
    let loop = BedLoop(loopBuffer((0..<10).map(Float.init), (0..<10).map { -Float($0) }), gain: 0.5)
    #expect(!render(loop, 8).sounded && loop.position == 0)  // silent, and the loop waits, until a fade
    loop.fade(to: 1, over: 0)
    let r = render(loop, 25)
    let expected = (Array(0..<10) + Array(0..<10) + Array(0..<5)).map { 0.5 * Float($0) }
    #expect(r.sounded && zip(r.left, expected).allSatisfy { abs($0 - $1) < 1e-6 })
    #expect(zip(r.right, expected).allSatisfy { abs($0 + $1) < 1e-6 })
    #expect(loop.position == 5)
}

@Test func theBedFadesAlongASineFromWhereItIs() {
    let loop = BedLoop(loopBuffer(Array(repeating: 1, count: 4800), Array(repeating: 1, count: 4800)), gain: 0.5)
    loop.fade(to: 1, over: 0.01)  // 480 frames at 48 kHz
    var r = render(loop, 600)
    for i in [0, 119, 239, 359, 479, 599] {
        let expected = 0.5 * sin(Float.pi / 2 * min(Float(i + 1) / 480, 1))
        #expect(abs(r.left[i] - expected) < 1e-3 && r.right[i] == r.left[i], "frame \(i)")
    }
    #expect(loop.level == 1)
    loop.fade(to: 0, over: 0.01)
    r = render(loop, 240)  // half way out: the cosine at a quarter turn
    let midway = r.left[239]
    #expect(abs(midway - 0.5 * sin(Float.pi / 4)) < 1e-3)
    loop.fade(to: 1, over: 0.01)  // a summon during the fade-out
    r = render(loop, 240)
    #expect(abs(r.left[0] - midway) < 0.01)  // on from where it was, no jump
    #expect(abs(r.left[239] - 0.5) < 1e-3)  // full again after the rest of the way
    loop.fade(to: 0, over: 0)
    #expect(render(loop, 64).left.allSatisfy { $0 == 0 })
    #expect(!render(loop, 64).sounded)
}

// MARK: The engine (needs an output device; the clicks are audible)

private var hasOutput: Bool { OutputDevice.defaultID() != nil }

@Suite(.serialized) struct Engine {
    @Test(.enabled(if: hasOutput, "no audio output device: engine test skipped"))
    func playReturnsInMicroseconds() throws {
        let player = try ClickPlayer(pack: defaultPack())
        player.volume = 0.3
        // What the main mixer sends out: proof the clicks are not only taken but heard.
        let lock = NSLock()
        var outputPeak: Float = 0
        let mixer = player.engine.mainMixerNode
        mixer.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            var peak: Float = 0
            for i in 0..<Int(buffer.frameLength) { peak = max(peak, abs(channel[i])) }
            lock.withLock { outputPeak = max(outputPeak, peak) }
        }
        defer { mixer.removeTap(onBus: 0) }
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        var micros: [Double] = []
        micros.reserveCapacity(10)
        for i in 0..<10 {  // 12 keys/s, a space every fifth
            let t0 = mach_absolute_time()
            player.play(i % 5 == 4 ? .space : .letter)
            let t1 = mach_absolute_time()
            micros.append(Double(t1 - t0) * Double(timebase.numer) / Double(timebase.denom) / 1000)
            Thread.sleep(forTimeInterval: 1.0 / 12)
        }
        Thread.sleep(forTimeInterval: 0.2)
        print("LemnaClicks play() µs:", micros.map { String(format: "%.1f", $0) }.joined(separator: " "),
              String(format: "(max %.1f)", micros.max() ?? 0))
        print("LemnaClicks IO buffer: asked \(ClickPlayer.wantedIOBufferFrames), accepted \(player.ioBufferFrames) frames;",
              "Bluetooth output: \(player.isBluetoothOutput)")
        #expect(micros.allSatisfy { $0 < 2000 })  // the aim is < 200 µs; machines vary
        #expect(player.mixer.consumed == 10)  // the render thread took every click
        #expect(player.ioBufferFrames > 0)
        let peak = lock.withLock { outputPeak }
        print(String(format: "LemnaClicks output peak %.3f (samples at 0.5, volume 0.3)", peak))
        #expect(peak > 0.05)

        player.enabled = false
        player.play(.letter)
        Thread.sleep(forTimeInterval: 0.1)
        #expect(player.mixer.consumed == 10)
        player.enabled = true
        player.play(.paragraph)
        Thread.sleep(forTimeInterval: 0.2)
        #expect(player.mixer.consumed == 11)  // the engine runs again
    }

    /// Silent: loads every pack into one player and switches between them; nothing is played.
    @Test(.enabled(if: hasOutput, "no audio output device: engine test skipped"))
    func allPacksLoadIntoOnePlayer() throws {
        let folders = ["DefaultPack", "TypewriterPack", "SoftPack", "ElectricPack", "StonePack"]
        let player = try ClickPlayer(packs: folders.map(pack))
        #expect(player.packs.map(\.name) == (try folders.map { try pack($0).name }))
        #expect(player.mixer.sampleCount == 67)  // 13 per pack and Stone's 15, all in one table
        #expect(player.pack == 0)
        player.pack = 3
        #expect(player.pack == 3)
        #expect(player.mixer.consumed == 0)
    }

    /// Plays the rain for about half a second, quietly: decoded off the main thread, faded in and out on the engine,
    /// silenced by `enabled`, taken off by `bed = nil`.
    @Test(.enabled(if: hasOutput, "no audio output device: engine test skipped")) @MainActor
    func theBedFadesInAndOutOnTheEngine() async throws {
        let player = try ClickPlayer(pack: defaultPack())
        player.bedVolume = 0.3
        player.startBed(fadeIn: 0.05)  // asked for before the loop is ready: it starts once it is
        player.bed = try rain()
        for _ in 0..<300 where player.bedLoop == nil { try await Task.sleep(nanoseconds: 10_000_000) }
        let loop = try #require(player.bedLoop)
        let lock = NSLock()
        var outputPeak: Float = 0
        let mixer = player.engine.mainMixerNode
        mixer.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
            guard let channel = buffer.floatChannelData?[1] else { return }
            var peak: Float = 0
            for i in 0..<Int(buffer.frameLength) { peak = max(peak, abs(channel[i])) }
            lock.withLock { outputPeak = max(outputPeak, peak) }
        }
        defer { mixer.removeTap(onBus: 0) }
        try await Task.sleep(nanoseconds: 400_000_000)
        #expect(loop.level == 1 && loop.position > 0)
        let heard = lock.withLock { outputPeak }
        print(String(format: "LemnaClicks bed output peak %.4f (bedVolume 0.3)", heard))
        #expect(heard > 0.001)

        player.stopBed(fadeOut: 0.05)
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(loop.level == 0)
        let stopped = loop.position
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(loop.position == stopped)  // silent: the loop waits where it was

        player.startBed(fadeIn: 0.05)
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(loop.level == 1)
        player.enabled = false  // ⌘K: the bed with the clicks
        player.startBed()
        player.enabled = true
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(loop.level == 0)  // off until asked again

        let attached = player.engine.attachedNodes.count
        player.bed = nil
        #expect(player.bedLoop == nil && player.engine.attachedNodes.count == attached - 1)
    }

    @Test func bluetoothFlagReads() throws {
        let bluetooth = OutputDevice.defaultIsBluetooth()
        print("LemnaClicks default output is Bluetooth: \(bluetooth)")
        if hasOutput {
            #expect(try ClickPlayer(pack: defaultPack()).isBluetoothOutput == bluetooth)
        }
    }
}
