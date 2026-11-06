// The other-sound tap (DESIGN.md DK1, pass 40): while the box is up and the setting is on, what every other app sends to
// the default output goes through a Core Audio process tap and comes out shaded (LemnaCore's `OtherSound.Shade`); the
// states and the watch's rules are LemnaCore's too (`OtherSound.State`, `Watch`). Here the Core Audio of it, ported
// from the pass 40 spike, every call from the headers of the macOS 26.1 SDK: a tap of every process but Lemna on the
// default output's first stream, muted only while it is read; a private aggregate device with that output as its
// clock and only sub-device and the tap as its sub-tap; an IO block on the aggregate that reads the tap and writes it
// shaded to the output. Lemna's own clicks and bed play from its own engine, outside the tap, as before. Every Core
// Audio call runs on one serial queue, never on the main thread, so a summon never waits for it.
import CoreAudio
import Foundation
import LemnaClicks
import LemnaCore

@available(macOS 14.2, *)
final class OtherSoundTap {
    /// On the main queue: the tap is up; it could not be made (why); the watch's verdict; the default output or its
    /// sample rate changed.
    var onStarted: () -> Void = {}
    var onFailed: (String) -> Void = { _ in }
    var onVerdict: (OtherSound.Watch.Verdict) -> Void = { _ in }
    var onOutputChanged: () -> Void = {}

    /// The aggregate's IO buffer: 5.3 ms at 48 kHz, the delay the tap adds about twice that (in and out).
    static let bufferFrames: UInt32 = 256

    private let queue = DispatchQueue(label: "dev.lemna.other-sound", qos: .userInitiated)
    /// The queue → the IO block: the shade's target (0 open, 1 shaded) and its step per frame.
    private let target = AtomicPair()
    /// The IO block → the watch: buffers in all and buffers with sound, as floats wrapping under 2^24.
    private let counts = AtomicPair()
    /// Main: a release's stop goes only if nothing came since.
    private var generation = 0

    // The queue's alone.
    private var pipe: Pipe?
    private var watch: OtherSound.Watch?
    private var timer: DispatchSourceTimer?
    private var listeners: [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []

    private struct Pipe {
        var tap = AudioObjectID(kAudioObjectUnknown), aggregate = AudioObjectID(kAudioObjectUnknown)
        var proc: AudioDeviceIOProcID?
        var output = AudioObjectID(kAudioObjectUnknown), me = AudioObjectID(kAudioObjectUnknown)
        var trial = false, step: Float = 1
    }

    private struct Failure: Error {
        let why: String
    }

    /// A tap that mutes nothing and shades nothing (the trial at the tick): it brings up macOS's prompt and hears
    /// whether sound comes.
    func trial() {
        generation += 1
        queue.async { [self] in
            takeDown()
            make(trial: true)
        }
    }

    /// Shade: the tap still gliding out after a release shades again; else a new one.
    func start() {
        generation += 1
        queue.async { [self] in
            if let p = pipe, !p.trial { return target.set(1, p.step) }
            takeDown()
            make(trial: false)
        }
    }

    /// Glide out, and take the tap down `duckRelease` later (the bed's fade-out) unless something came first.
    func release() {
        generation += 1
        let g = generation
        queue.async { [self] in if let p = pipe { target.set(0, p.step) } }
        DispatchQueue.main.asyncAfter(deadline: .now() + OtherSound.Tuning.duckRelease) { [weak self] in
            if let self, self.generation == g { self.stop() }
        }
    }

    /// The tap down and made again: the output changed, its rate did, or the Mac woke.
    func rebuild(trial: Bool) {
        generation += 1
        queue.async { [self] in
            takeDown()
            make(trial: trial)
        }
    }

    func stop() {
        generation += 1
        queue.async { [self] in takeDown() }
    }

    /// At quit: down before the process goes (a private tap and aggregate would go with it anyway).
    func stopNow() { queue.sync { takeDown() } }

    // MARK: The queue

    private func make(trial: Bool) {
        do {
            try build(trial: trial)
            watch = OtherSound.Watch(trial: trial)
            let t = DispatchSource.makeTimerSource(queue: queue)
            t.schedule(deadline: .now() + 0.25, repeating: 0.25)
            t.setEventHandler { [weak self] in self?.look() }
            t.resume()
            timer = t
            DispatchQueue.main.async { self.onStarted() }
        } catch {
            takeDown()  // whatever was made goes: no app is left muted
            let why = (error as? Failure)?.why ?? String(describing: error)
            DispatchQueue.main.async { self.onFailed(why) }
        }
    }

    private func build(trial: Bool) throws {
        let me = HAL.value(HAL.system, HAL.address(kAudioHardwarePropertyTranslatePIDToProcessObject),
                           qualifier: getpid(), AudioObjectID(kAudioObjectUnknown)) ?? AudioObjectID(kAudioObjectUnknown)
        // Lemna outside the tap: its own sound stays as it is, and the shaded sound it plays is not tapped again.
        guard me != kAudioObjectUnknown else { throw Failure(why: "Core Audio does not know Lemna yet") }
        guard let output = HAL.defaultOutput, let uid = HAL.string(output, HAL.address(kAudioDevicePropertyDeviceUID))
        else { throw Failure(why: "no output device") }
        // What every other process sends to this output's first stream, in that stream's format; what an app sends to
        // another device stays there. Muted only while read, so a stop or a crash gives it back at once.
        let description = CATapDescription(excludingProcesses: [me], deviceUID: uid, stream: 0)
        description.name = "Lemna other sound"
        description.isPrivate = true
        description.muteBehavior = trial ? .unmuted : .mutedWhenTapped
        var p = Pipe(output: output, me: me, trial: trial)
        try check("the tap was refused", AudioHardwareCreateProcessTap(description, &p.tap))
        pipe = p
        guard let f = HAL.value(p.tap, HAL.address(kAudioTapPropertyFormat), AudioStreamBasicDescription()),
              f.mFormatID == kAudioFormatLinearPCM, f.mFormatFlags & kAudioFormatFlagIsFloat != 0, f.mBitsPerChannel == 32
        else { throw Failure(why: "the output's format is not float") }
        let composition: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Lemna other sound",
            kAudioAggregateDeviceUIDKey: UUID().uuidString,
            kAudioAggregateDeviceMainSubDeviceKey: uid,
            kAudioAggregateDeviceIsPrivateKey: true,  // this process's alone, gone with it, never in Sound settings
            kAudioAggregateDeviceIsStackedKey: false,
            kAudioAggregateDeviceSubDeviceListKey: [[kAudioSubDeviceUIDKey: uid]],
            kAudioAggregateDeviceTapListKey: [[kAudioSubTapUIDKey: description.uuid.uuidString,
                                               kAudioSubTapDriftCompensationKey: true]],
        ]
        try check("the output could not be joined",
                  AudioHardwareCreateAggregateDevice(composition as CFDictionary, &p.aggregate))
        pipe = p
        HAL.set(p.aggregate, HAL.address(kAudioDevicePropertyBufferFrameSize), Self.bufferFrames)
        let rate = HAL.value(p.aggregate, HAL.address(kAudioDevicePropertyNominalSampleRate), Float64(0)) ?? 0
        guard rate > 0 else { throw Failure(why: "the output has no sample rate") }
        p.step = OtherSound.step(over: OtherSound.Tuning.duckGlide, sampleRate: rate)
        // The output's own inputs (a headset's, an audio interface's) come into the aggregate before the tap's: the IO
        // block reads the tap's alone, and they are switched off below.
        let deviceInputs = HAL.streams(output, kAudioObjectPropertyScopeInput)
        let tapStreams = max(HAL.streams(p.aggregate, kAudioObjectPropertyScopeInput) - deviceInputs, 1)
        let io = IO(shade: OtherSound.Shade(sampleRate: rate), target: target, counts: counts, trial: trial,
                    tapStreams: tapStreams)
        try check("the output could not be joined",
                  AudioDeviceCreateIOProcIDWithBlock(&p.proc, p.aggregate, nil) { _, input, _, output, _ in
                      io.cycle(input: input, output: output)
                  })
        pipe = p
        if deviceInputs > 0 { try inputsOff(p, first: deviceInputs) }
        target.set(trial ? 0 : 1, p.step)  // a new tap glides in from open
        try check("the output did not start", AudioDeviceStart(p.aggregate, p.proc))
        listen(output)
    }

    /// An output with inputs of its own: running them would ask for the microphone, and may turn Bluetooth headphones
    /// to their call profile. Only the tap's streams stay on for the IO block.
    private func inputsOff(_ p: Pipe, first n: Int) throws {
        let total = HAL.streams(p.aggregate, kAudioObjectPropertyScopeInput)
        let size = MemoryLayout<UnsafeMutableRawPointer>.size + 4 + 4 * total  // mIOProc, mNumberStreams, mStreamIsOn[]
        let raw = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 8)
        defer { raw.deallocate() }
        raw.storeBytes(of: unsafeBitCast(p.proc, to: UnsafeMutableRawPointer.self), as: UnsafeMutableRawPointer.self)
        raw.storeBytes(of: UInt32(total), toByteOffset: 8, as: UInt32.self)
        for s in 0..<total { raw.storeBytes(of: UInt32(s < n ? 0 : 1), toByteOffset: 12 + 4 * s, as: UInt32.self) }
        var a = HAL.address(kAudioDevicePropertyIOProcStreamUsage, kAudioObjectPropertyScopeInput)
        try check("the output's inputs could not be left off",
                  AudioObjectSetPropertyData(p.aggregate, &a, 0, nil, UInt32(size), raw))
    }

    /// The default output and this one's sample rate: a change asks for a new tap (the app decides, on the main queue).
    private func listen(_ output: AudioObjectID) {
        for (object, address) in [(HAL.system, HAL.address(kAudioHardwarePropertyDefaultOutputDevice)),
                                  (output, HAL.address(kAudioDevicePropertyNominalSampleRate))] {
            var a = address
            let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.onOutputChanged() }
            if AudioObjectAddPropertyListenerBlock(object, &a, .main, block) == noErr {
                listeners.append((object, a, block))
            }
        }
    }

    private func takeDown() {
        timer?.cancel()
        (timer, watch) = (nil, nil)
        for (object, address, block) in listeners {
            var a = address
            AudioObjectRemovePropertyListenerBlock(object, &a, .main, block)
        }
        listeners = []
        guard let p = pipe else { return }
        pipe = nil
        if let proc = p.proc {
            AudioDeviceStop(p.aggregate, proc)
            AudioDeviceDestroyIOProcID(p.aggregate, proc)
        }
        if p.aggregate != kAudioObjectUnknown { AudioHardwareDestroyAggregateDevice(p.aggregate) }
        if p.tap != kAudioObjectUnknown { AudioHardwareDestroyProcessTap(p.tap) }
        target.set(0, 0)
        counts.set(0, 0)
    }

    /// Four times a second: the IO block's counts and whether another app plays to the output, to the watch.
    private func look() {
        guard let p = pipe, var w = watch else { return }
        let (c, s) = counts.get()
        let verdict = w.feed(at: ProcessInfo.processInfo.systemUptime, cycles: UInt32(c), sounding: UInt32(s),
                             othersPlaying: othersPlaying(on: p.output, besides: p.me))
        watch = w
        guard let verdict else { return }
        if verdict != .heard {
            timer?.cancel()
            timer = nil
        }
        DispatchQueue.main.async { self.onVerdict(verdict) }
    }

    /// Whether a process other than `me`, Lemna's, runs output on `output` now (the HAL's process objects: running
    /// output, and the output among its devices). A paused app that keeps its stream open counts too.
    private func othersPlaying(on output: AudioObjectID, besides me: AudioObjectID) -> Bool {
        for process in HAL.ids(HAL.system, HAL.address(kAudioHardwarePropertyProcessObjectList)) where process != me {
            guard HAL.value(process, HAL.address(kAudioProcessPropertyIsRunningOutput), UInt32(0)) == 1 else { continue }
            let devices = HAL.ids(process, HAL.address(kAudioProcessPropertyDevices, kAudioObjectPropertyScopeOutput))
            if devices.contains(output) { return true }
        }
        return false
    }

    private func check(_ why: String, _ status: OSStatus) throws {
        if status != noErr { throw Failure(why: "\(why) (\(status))") }
    }
}

/// The IO block's half: everything it touches made before the first cycle; no lock, no allocation, no Objective-C.
private final class IO {
    let shade: OtherSound.Shade, target: AtomicPair, counts: AtomicPair, trial: Bool, tapStreams: Int
    private var cycles: UInt32 = 0, sounding: UInt32 = 0

    init(shade: OtherSound.Shade, target: AtomicPair, counts: AtomicPair, trial: Bool, tapStreams: Int) {
        (self.shade, self.target, self.counts, self.trial, self.tapStreams) = (shade, target, counts, trial, tapStreams)
    }

    /// One IO cycle: the tap's streams come last in the input, after the output's own; its first two channels are read
    /// and written shaded to the output's first two (more are left silent: stereo only). The trial writes nothing.
    func cycle(input: UnsafePointer<AudioBufferList>, output: UnsafeMutablePointer<AudioBufferList>) {
        let ins = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
        let outs = UnsafeMutableAudioBufferListPointer(output)
        guard ins.count >= tapStreams, let first = outs.first, let out = first.mData?.assumingMemoryBound(to: Float.self)
        else { return }
        let tap = ins[ins.count - tapStreams]
        guard let left = tap.mData?.assumingMemoryBound(to: Float.self) else { return }
        let inChannels = Int(max(tap.mNumberChannels, 1)), outChannels = Int(max(first.mNumberChannels, 1))
        let right: UnsafeMutablePointer<Float> = inChannels > 1 ? left + 1
            : tapStreams > 1 ? ins[ins.count - 1].mData?.assumingMemoryBound(to: Float.self) ?? left : left
        let outRight: UnsafeMutablePointer<Float>? = outChannels > 1 ? out + 1
            : outs.count > 1 ? outs[1].mData?.assumingMemoryBound(to: Float.self) : nil
        let frames = min(Int(tap.mDataByteSize) / (4 * inChannels), Int(first.mDataByteSize) / (4 * outChannels))
        var peak: Float = 0
        for i in 0..<frames { peak = max(peak, abs(left[i * inChannels]), abs(right[i * inChannels])) }
        cycles &+= 1
        if peak > OtherSound.Tuning.silence { sounding &+= 1 }
        counts.set(Float(cycles & 0xFF_FFFF), Float(sounding & 0xFF_FFFF))
        guard !trial else { return }
        let (t, step) = target.get()
        shade.render(frames: frames, target: t, step: step, inLeft: left, inRight: right, inStride: inChannels,
                     outLeft: out, outRight: outRight, outStride: outChannels)
    }
}

/// The few AudioObject reads and writes the tap needs, over the C API (the Swift wrappers need macOS 15).
private enum HAL {
    static let system = AudioObjectID(kAudioObjectSystemObject)

    static func address(_ selector: AudioObjectPropertySelector,
                        _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    static func value<T: BitwiseCopyable>(_ object: AudioObjectID, _ a: AudioObjectPropertyAddress, _ initial: T) -> T? {
        var (a, v) = (a, initial)
        var size = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(object, &a, 0, nil, &size, &v) == noErr ? v : nil
    }

    static func value<T: BitwiseCopyable, Q: BitwiseCopyable>(_ object: AudioObjectID, _ a: AudioObjectPropertyAddress,
                                                              qualifier: Q, _ initial: T) -> T? {
        var (a, q, v) = (a, qualifier, initial)
        var size = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(object, &a, UInt32(MemoryLayout<Q>.size), &q, &size, &v) == noErr ? v : nil
    }

    @discardableResult
    static func set<T: BitwiseCopyable>(_ object: AudioObjectID, _ a: AudioObjectPropertyAddress, _ value: T) -> OSStatus {
        var (a, v) = (a, value)
        return AudioObjectSetPropertyData(object, &a, 0, nil, UInt32(MemoryLayout<T>.size), &v)
    }

    static func ids(_ object: AudioObjectID, _ a: AudioObjectPropertyAddress) -> [AudioObjectID] {
        var a = a
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(object, &a, 0, nil, &size) == noErr, size > 0 else { return [] }
        var out = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        return AudioObjectGetPropertyData(object, &a, 0, nil, &size, &out) == noErr ? out : []
    }

    static func string(_ object: AudioObjectID, _ a: AudioObjectPropertyAddress) -> String? {
        var a = a
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(object, &a, 0, nil, &size, &value) == noErr, let value else { return nil }
        return value.takeRetainedValue() as String
    }

    static var defaultOutput: AudioObjectID? {
        value(system, address(kAudioHardwarePropertyDefaultOutputDevice), AudioObjectID(kAudioObjectUnknown))
            .flatMap { $0 == kAudioObjectUnknown ? nil : $0 }
    }

    /// The device's streams of `scope` (kAudioDevicePropertyStreamConfiguration's buffers).
    static func streams(_ device: AudioObjectID, _ scope: AudioObjectPropertyScope) -> Int {
        var a = address(kAudioDevicePropertyStreamConfiguration, scope)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(device, &a, 0, nil, &size) == noErr, size > 0 else { return 0 }
        let raw = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: 16)
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(device, &a, 0, nil, &size, raw) == noErr else { return 0 }
        return UnsafeMutableAudioBufferListPointer(raw.assumingMemoryBound(to: AudioBufferList.self)).count
    }
}
