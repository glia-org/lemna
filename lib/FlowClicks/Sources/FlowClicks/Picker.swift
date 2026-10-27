/// Chooses the sample and the playback rate of each click. Kept apart from the audio code so its
/// rules can be tested without a sound card. Fixed-size arrays mutated in place: no allocation.
struct Picker {
    /// ±3 %: about half a semitone either way, enough that repeats do not sound machine-made.
    static let rateSpread: Float = 0.03

    private let first: [Int]  // index of each kind's first sample in the player's table
    private let count: [Int]
    private var last: [Int]   // the last sample played per kind, -1 before the first
    private var rng: SplitMix64

    /// `counts[kind.rawValue]` samples per kind, laid out kind after kind.
    init(counts: [Int], seed: UInt64) {
        var first: [Int] = []
        var next = 0
        for n in counts {
            first.append(next)
            next += n
        }
        self.first = first
        self.count = counts
        self.last = Array(repeating: -1, count: counts.count)
        self.rng = SplitMix64(state: seed)
    }

    /// A random sample of the kind other than the one before it, so neither an exact repeat nor a
    /// fixed a-b-c cycle can be heard; with two samples this alternates.
    mutating func next(_ kind: KeyKind) -> (sample: Int, rate: Float) {
        let k = kind.rawValue
        let n = count[k]
        var pick: Int
        if n == 1 {
            pick = 0
        } else if last[k] < 0 {
            pick = Int(rng.next() % UInt64(n))
        } else {
            pick = Int(rng.next() % UInt64(n - 1))
            if pick >= last[k] { pick += 1 }
        }
        last[k] = pick
        let unit = Float(rng.next() >> 40) / Float(1 << 24)  // [0, 1)
        return (first[k] + pick, 1 + (2 * unit - 1) * Self.rateSpread)
    }
}

/// A tiny fast generator with no allocation or locks, seeded once.
struct SplitMix64 {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
