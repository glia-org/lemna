import AVFoundation
import Darwin
import Testing
@testable import FlowClicks

// MARK: The default pack

@Test func defaultPackMeetsTheFormat() throws {
    let pack = try SoundPack.bundled()
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
        #expect(Double(file.length) / 48_000 <= 0.150, "\(name)")
        bytes += try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }
    #expect(bytes <= 600_000)
}

@Test func packJSONMustNameEveryKindAndNoOther() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("flowclicks-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    try Data().write(to: folder.appendingPathComponent("a.wav"))
    func write(_ files: String) throws {
        let json = #"{"name": "t", "licence": "CC0-1.0", "source": "-", "files": {\#(files)}}"#
        try json.write(to: folder.appendingPathComponent("pack.json"), atomically: true, encoding: .utf8)
    }
    try write(#""letter": ["a.wav"], "space": ["a.wav"], "paragraph": ["a.wav"], "backspace": ["a.wav"]"#)
    #expect(try SoundPack(folder: folder).files.count == 4)
    try write(#""letter": ["a.wav"], "space": ["a.wav"], "paragraph": ["a.wav"]"#)
    #expect(throws: ClickError.self) { try SoundPack(folder: folder) }
    try write(#""letter": ["a.wav"], "space": ["a.wav"], "paragraph": ["a.wav"], "backspace": ["a.wav"], "enter": ["a.wav"]"#)
    #expect(throws: ClickError.self) { try SoundPack(folder: folder) }
    try write(#""letter": ["b.wav"], "space": ["a.wav"], "paragraph": ["a.wav"], "backspace": ["a.wav"]"#)
    #expect(throws: ClickError.self) { try SoundPack(folder: folder) }
}

@Test func aFileAtAnotherRateAndInStereoIsConvertedOnLoad() throws {
    // A device at 44.1 kHz gets the 48 kHz pack through this path; here the other way round.
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("flowclicks-\(UUID().uuidString).caf")
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
    let counts = [6, 2, 2, 2]
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

@Test func rateStaysWithinThreePercent() {
    var picker = Picker(counts: [6, 2, 2, 2], seed: 7)
    var low: Float = 2
    var high: Float = 0
    for i in 0..<10_000 {
        let rate = picker.next(KeyKind.allCases[i % 4]).rate
        low = min(low, rate)
        high = max(high, rate)
    }
    #expect(low >= 0.97 - 1e-6 && high <= 1.03 + 1e-6)
    #expect(low < 0.975 && high > 1.025)  // and the whole spread is used
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

// MARK: The engine (needs an output device; the clicks are audible)

private var hasOutput: Bool { OutputDevice.defaultID() != nil }

@Suite(.serialized) struct Engine {
    @Test(.enabled(if: hasOutput, "no audio output device: engine test skipped"))
    func playReturnsInMicroseconds() throws {
        let player = try ClickPlayer(pack: .bundled())
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
        print("FlowClicks play() µs:", micros.map { String(format: "%.1f", $0) }.joined(separator: " "),
              String(format: "(max %.1f)", micros.max() ?? 0))
        print("FlowClicks IO buffer: asked \(ClickPlayer.wantedIOBufferFrames), accepted \(player.ioBufferFrames) frames;",
              "Bluetooth output: \(player.isBluetoothOutput)")
        #expect(micros.allSatisfy { $0 < 2000 })  // the aim is < 200 µs; machines vary
        #expect(player.mixer.consumed == 10)  // the render thread took every click
        #expect(player.ioBufferFrames > 0)
        let peak = lock.withLock { outputPeak }
        print(String(format: "FlowClicks output peak %.3f (samples at 0.5, volume 0.3)", peak))
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

    @Test func bluetoothFlagReads() throws {
        let bluetooth = OutputDevice.defaultIsBluetooth()
        print("FlowClicks default output is Bluetooth: \(bluetooth)")
        if hasOutput {
            #expect(try ClickPlayer(pack: .bundled()).isBluetoothOutput == bluetooth)
        }
    }
}
