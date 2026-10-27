import ClickRing

/// The audio-thread half of the player: a fixed table of voices mixing preloaded mono samples.
/// Everything `render` touches is allocated in `init`; it takes no locks, allocates nothing and
/// calls nothing that could block, as a render thread requires.
final class Mixer {
    /// Clicks of up to 150 ms at 12–20 keys/s overlap two or three deep; 16 covers key mashing.
    static let voiceCount = 16

    private struct Voice {
        var sample: Int  // -1 when idle
        var position: Double
        var rate: Double
    }

    let sampleCount: Int
    private let ring: OpaquePointer
    private let data: UnsafeMutablePointer<Float>  // all samples back to back
    private let starts: UnsafeMutablePointer<Int>
    private let lengths: UnsafeMutablePointer<Int>
    private let voices: UnsafeMutablePointer<Voice>

    init(samples: [[Float]]) {
        sampleCount = samples.count
        ring = click_ring_create()!
        let data = UnsafeMutablePointer<Float>.allocate(capacity: max(samples.reduce(0) { $0 + $1.count }, 1))
        let starts = UnsafeMutablePointer<Int>.allocate(capacity: max(samples.count, 1))
        let lengths = UnsafeMutablePointer<Int>.allocate(capacity: max(samples.count, 1))
        var offset = 0
        for (i, sample) in samples.enumerated() {
            starts[i] = offset
            lengths[i] = sample.count
            sample.withUnsafeBufferPointer { if let base = $0.baseAddress { (data + offset).update(from: base, count: $0.count) } }
            offset += sample.count
        }
        self.data = data
        self.starts = starts
        self.lengths = lengths
        voices = .allocate(capacity: Self.voiceCount)
        voices.initialize(repeating: Voice(sample: -1, position: 0, rate: 1), count: Self.voiceCount)
    }

    deinit {
        click_ring_destroy(ring)
        data.deallocate()
        starts.deallocate()
        lengths.deallocate()
        voices.deallocate()
    }

    /// Producer side (the key handler's thread). False when the ring is full: the click is dropped.
    @discardableResult
    func trigger(sample: Int, rate: Float) -> Bool {
        click_ring_push(ring, click_trigger(sample: UInt32(sample), rate: rate))
    }

    /// Clicks the render thread has taken from the ring so far.
    var consumed: Int { Int(click_ring_popped(ring)) }

    /// Consumer side (the render thread). Fills `out` with the sum of the voices; false when
    /// nothing sounded and `out` is all zeros.
    func render(frames: Int, into out: UnsafeMutablePointer<Float>) -> Bool {
        out.update(repeating: 0, count: frames)
        // Every pending click starts at the head of this buffer: the soonest it can be heard.
        var trigger = click_trigger()
        while click_ring_pop(ring, &trigger) {
            start(Int(trigger.sample), rate: Double(trigger.rate))
        }
        var sounded = false
        for v in 0..<Self.voiceCount where voices[v].sample >= 0 {
            sounded = true
            let s = voices[v].sample
            let base = data + starts[s]
            let end = Double(lengths[s] - 1)
            let rate = voices[v].rate
            var position = voices[v].position
            var i = 0
            // Linear interpolation is enough for a short click at a rate within a few percent of 1.
            while i < frames && position < end {
                let j = Int(position)
                let f = Float(position - Double(j))
                out[i] += base[j] + (base[j + 1] - base[j]) * f
                position += rate
                i += 1
            }
            voices[v].position = position
            if position >= end { voices[v].sample = -1 }
        }
        return sounded
    }

    private func start(_ sample: Int, rate: Double) {
        guard sample >= 0, sample < sampleCount else { return }
        var slot = 0
        var furthest = -1.0
        for v in 0..<Self.voiceCount {
            if voices[v].sample < 0 {
                slot = v
                break
            }
            // No idle voice: take the one furthest through its sample, the quietest by now.
            let progress = voices[v].position / Double(lengths[voices[v].sample])
            if progress > furthest {
                furthest = progress
                slot = v
            }
        }
        voices[slot] = Voice(sample: sample, position: 0, rate: rate)
    }

    /// Voices sounding now. Tests only: it reads the render thread's table without a barrier.
    var activeVoices: Int { (0..<Self.voiceCount).reduce(0) { $0 + (voices[$1].sample >= 0 ? 1 : 0) } }
}
