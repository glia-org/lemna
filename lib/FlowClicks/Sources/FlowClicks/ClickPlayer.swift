import AVFoundation
import AudioToolbox
import CoreAudio

/// Plays a key click on key-down, from one AVAudioEngine that keeps running.
///
/// The path of a click: `play` picks a sample and a rate and pushes them into a lock-free ring (a
/// few atomic operations, no allocation, no lock, no Objective-C call). The engine calls the
/// source node's render block on its audio thread once per IO buffer; the block drains the ring
/// and starts each click at the head of the buffer it fills. So a click reaches the device within
/// one IO buffer (128 frames, 2.7 ms at 48 kHz, when the device accepts that size) plus the
/// device's own output latency and safety offset.
///
/// Why a source node and not `AVAudioPlayerNode.scheduleBuffer`: both are heard at the next
/// render cycle, but `scheduleBuffer` is an Objective-C call into the engine with no promise of
/// being lock- or allocation-free, overlapping clicks would need a pool of player nodes, and the
/// ±3 % rate would need a varispeed unit per node or pre-pitched copies. The source node's mixer
/// does voices and rate itself, in one node.
public final class ClickPlayer {
    /// Off: `play` does nothing and the engine pauses, as AVAudioEngine.h advises for an engine
    /// not in use, so the audio hardware can idle. On again restarts it.
    public var enabled = true {
        didSet {
            guard enabled != oldValue else { return }
            if enabled { try? start() } else { engine.pause() }
        }
    }

    /// 0–1, applied at the main mixer's input.
    public var volume: Float = 0.6 {
        didSet { source.volume = Self.clamp(volume) }
    }

    /// Whether the default output device is Bluetooth; re-read when the default output changes.
    public private(set) var isBluetoothOutput = false

    /// The IO buffer size in frames that the output device accepted (read back after asking for
    /// 128), 0 if it could not be read.
    public private(set) var ioBufferFrames = 0

    /// Called on the main queue after the default output device changed and
    /// `isBluetoothOutput` was re-read, so the app can warn once about Bluetooth delay.
    public var onOutputChanged: (() -> Void)?

    static let wantedIOBufferFrames: UInt32 = 128

    let engine: AVAudioEngine
    private let source: AVAudioSourceNode
    let mixer: Mixer
    private var picker: Picker
    private var listener: AudioObjectPropertyListenerBlock?
    private var observer: NSObjectProtocol?

    /// Loads every sample of `pack`, converted to mono at the output device's sample rate, and
    /// starts the engine. Throws when there is no output device or a file will not load.
    public init(pack: SoundPack) throws {
        let engine = AVAudioEngine()
        let hardware = engine.outputNode.outputFormat(forBus: 0)
        // AVAudioEngine.h: a zero sample rate or channel count on the output node means no output.
        guard hardware.sampleRate > 0, hardware.channelCount > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: hardware.sampleRate, channels: 1)
        else { throw ClickError("no audio output device") }

        // Mono at the device's rate: the main mixer only spreads it over the output channels and
        // converts no rate. Laid out kind after kind, as the picker expects.
        var samples: [[Float]] = []
        var counts: [Int] = []
        for kind in KeyKind.allCases {
            let urls = pack.files[kind] ?? []
            counts.append(urls.count)
            for url in urls { samples.append(try Self.load(url, as: format)) }
        }
        let mixer = Mixer(samples: samples)

        // unowned(unsafe): no reference counting on the render thread. The player owns the mixer
        // and stops the engine in deinit, before the mixer goes.
        let source = AVAudioSourceNode(format: format) { [unowned(unsafe) mixer] isSilence, _, frames, data in
            let buffers = UnsafeMutableAudioBufferListPointer(data)
            guard let out = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            let sounded = mixer.render(frames: Int(frames), into: out)
            for buffer in buffers.dropFirst() {
                buffer.mData?.copyMemory(from: out, byteCount: Int(frames) * MemoryLayout<Float>.size)
            }
            isSilence.pointee = ObjCBool(!sounded)
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)

        self.engine = engine
        self.source = source
        self.mixer = mixer
        self.picker = Picker(counts: counts, seed: mach_absolute_time())
        source.volume = Self.clamp(volume)
        try start()
        isBluetoothOutput = OutputDevice.defaultIsBluetooth()
        watchOutput()
    }

    deinit {
        if let listener {
            var address = OutputDevice.defaultOutputAddress
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, listener)
        }
        if let observer { NotificationCenter.default.removeObserver(observer) }
        engine.stop()
    }

    /// Call on key-down from the key handler, from one thread at a time (the main thread in the
    /// app). Returns in microseconds: no allocation, no lock, no node or engine call.
    public func play(_ kind: KeyKind) {
        guard enabled else { return }
        let (sample, rate) = picker.next(kind)
        mixer.trigger(sample: sample, rate: rate)
    }

    private func start() throws {
        try engine.start()
        ioBufferFrames = Int(OutputDevice.requestIOBuffer(Self.wantedIOBufferFrames, on: engine.outputNode.audioUnit))
    }

    private func watchOutput() {
        var address = OutputDevice.defaultOutputAddress
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.outputChanged() }
        if AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, block) == noErr {
            listener = block
        }
        // The engine stops itself when the device's rate or channel count changes. The source
        // keeps its format (the output chain converts rate), so starting again is enough.
        observer = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            guard let self, self.enabled else { return }
            try? self.start()
        }
    }

    private func outputChanged() {
        isBluetoothOutput = OutputDevice.defaultIsBluetooth()
        // A new device starts at its own default buffer size (512 frames); ask again.
        if enabled, engine.isRunning {
            ioBufferFrames = Int(OutputDevice.requestIOBuffer(Self.wantedIOBufferFrames, on: engine.outputNode.audioUnit))
        }
        onOutputChanged?()
    }

    /// One file as mono float samples at `format`'s rate, through AVAudioConverter when the file's
    /// rate or channel count differ (a 48 kHz mono file on a 48 kHz device is copied as is).
    static func load(_ url: URL, as format: AVAudioFormat) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        guard file.length > 0,
              let input = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
        else { throw ClickError("\(url.lastPathComponent): empty") }
        try file.read(into: input)
        var buffer = input
        let from = file.processingFormat
        if from.sampleRate != format.sampleRate || from.channelCount != format.channelCount {
            guard let converter = AVAudioConverter(from: from, to: format),
                  let output = AVAudioPCMBuffer(
                      pcmFormat: format,
                      frameCapacity: AVAudioFrameCount(Double(input.frameLength) * format.sampleRate / from.sampleRate) + 64)
            else { throw ClickError("\(url.lastPathComponent): cannot convert to \(format)") }
            converter.downmix = true  // a stereo file becomes the mix of its channels, not its left one
            var fed = false
            var error: NSError?
            let status = converter.convert(to: output, error: &error) { _, inputStatus in
                if fed {
                    inputStatus.pointee = .endOfStream
                    return nil
                }
                fed = true
                inputStatus.pointee = .haveData
                return input
            }
            if status == .error { throw error ?? ClickError("\(url.lastPathComponent): conversion failed") }
            buffer = output
        }
        guard let channel = buffer.floatChannelData?[0] else { throw ClickError("\(url.lastPathComponent): no samples") }
        return Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
    }

    private static func clamp(_ volume: Float) -> Float { min(max(volume, 0), 1) }
}
