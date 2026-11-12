// Other sound (DESIGN.md DK1, pass 40): while the box is up, every other app's sound a little quieter and softer,
// through a Core Audio process tap the app makes (app/Sources/Lemna/OtherSound.swift). Here, free of Core Audio so the
// tests check it: the shade over float buffers, the watch that tells a tap macOS gives no sound from one that hears,
// and the states with what each event asks of the tap.
import Darwin

public enum OtherSound {
    /// Every magnitude of DK1 in one place. Times in seconds.
    public enum Tuning {
        /// The shade: `duckGain` dB and two one-pole low-passes in series at `duckCutoff` Hz, each matched to the
        /// analog pole (−2.9 dB at the cutoff at 48 kHz, so −5.8 dB there and 12 dB an octave above it; pass 40b, the
        /// one pole at 4 kHz left music bright), reached and left in a straight glide over `duckGlide`.
        public static let duckGain = -6.0, duckCutoff = 2000.0, duckGlide = 0.25
        /// The watch over a tap that shades: only silence for `duckWatch` while another app plays to the same output
        /// takes the tap down at once, so no app stays muted longer: with nothing heard since launch it is macOS
        /// giving no sound (every call succeeds then and the tap hears zeros), and the setting goes off; after sound
        /// was heard it may be the apps' own, and the tap goes for that summon alone. No IO cycle for `duckWatch` is a
        /// failure.
        public static let duckWatch = 3.0
        /// The trial at the tick mutes nothing, so it may wait longer (the system's prompt may be up meanwhile):
        /// silence for `duckTrial` while another app plays is the same verdict, and it ends without one after
        /// `duckTrial`.
        public static let duckTrial = 15.0
        /// After the box goes, the shade glides out and the tap stops `duckRelease` later: when the bed's fade-out (K1,
        /// 0.6 s) is over, so the switch back is heard once the bed has gone.
        public static let duckRelease = 0.6
        /// A buffer whose peak is under this is silence (−120 dBFS): the tap macOS gives no sound hears exact zeros.
        public static let silence: Float = 1e-6
    }

    /// The gain of `decibels`.
    public static func gain(decibels: Double) -> Float { Float(pow(10, decibels / 20)) }

    /// The one-pole low-pass's coefficient a in y += a (x − y): 1 passes the input through, smaller is duller.
    public static func coefficient(cutoff: Double, sampleRate: Double) -> Float {
        Float(1 - exp(-2 * Double.pi * cutoff / sampleRate))
    }

    /// The glide's step per frame: 0 to 1 in `seconds`.
    public static func step(over seconds: Double, sampleRate: Double) -> Float {
        Float(1 / max(seconds * sampleRate, 1))
    }

    /// The shade on a stereo pair, the render thread's: a gain and the low-pass (two poles in series) gliding together
    /// between open (gain 1, no filter: the input as it is) and shaded, toward the target each call is given (0 open, 1 shaded) by the step
    /// it is given, so a new target never meets an old step. Allocates nothing and takes no lock after `init`.
    public final class Shade {
        public let shadedGain: Float, shadedCoefficient: Float
        /// 0 open, 1 shaded; where the glide is now.
        public private(set) var amount: Float = 0
        private var left: Float = 0, right: Float = 0, left2: Float = 0, right2: Float = 0

        public init(sampleRate: Double, decibels: Double = Tuning.duckGain, cutoff: Double = Tuning.duckCutoff) {
            shadedGain = OtherSound.gain(decibels: decibels)
            shadedCoefficient = OtherSound.coefficient(cutoff: cutoff, sampleRate: sampleRate)
        }

        /// `frames` frames of a pair, each side read and written with its stride (an interleaved buffer's channel
        /// count, a planar one's 1). `inRight` may be `inLeft` (one channel); `outRight` nil writes the left alone.
        public func render(frames: Int, target: Float, step: Float,
                           inLeft: UnsafePointer<Float>, inRight: UnsafePointer<Float>, inStride: Int,
                           outLeft: UnsafeMutablePointer<Float>, outRight: UnsafeMutablePointer<Float>?,
                           outStride: Int) {
            var (l, r, l2, r2, amount) = (left, right, left2, right2, self.amount)
            for i in 0..<frames {
                if amount < target { amount = min(amount + step, target) } else if amount > target {
                    amount = max(amount - step, target)
                }
                let g = 1 + (shadedGain - 1) * amount, a = 1 + (shadedCoefficient - 1) * amount
                l += a * (inLeft[i * inStride] - l)
                r += a * (inRight[i * inStride] - r)
                l2 += a * (l - l2)
                r2 += a * (r - r2)
                outLeft[i * outStride] = l2 * g
                outRight?[i * outStride] = r2 * g
            }
            (left, right, left2, right2, self.amount) = (l, r, l2, r2, amount)
        }
    }

    /// The watch over one tap, fed a few times a second with what its IO block counted (buffers in all, buffers with
    /// sound) and whether another app plays to the same output now.
    public struct Watch: Equatable, Sendable {
        public enum Verdict: Equatable, Sendable {
            /// The tap gave sound: macOS allows it.
            case heard
            /// Only silence for the watch's window while another app played: taken for macOS giving no sound.
            case silent
            /// No IO cycle for the window: the tap does not run.
            case dead
        }

        /// The window: `Tuning.duckWatch` for a tap that shades, `Tuning.duckTrial` for the trial.
        public let window: Double
        private let trial: Bool
        private var heard = false
        private var cycles: UInt32?, sounding: UInt32?
        private var idleSince = 0.0, silentSince: Double?

        public init(trial: Bool) {
            self.trial = trial
            window = trial ? Tuning.duckTrial : Tuning.duckWatch
        }

        /// The counts as the IO block published them at `t`, wrapping as they will. `heard` comes once, at the first
        /// buffer with sound; `silent` and `dead` on each feed while they hold, and the app takes the tap down at the
        /// first. Silence counts from the last buffer with sound, and only while another app plays. The trial is
        /// never `dead`: its IO may wait for the prompt's answer.
        public mutating func feed(at t: Double, cycles c: UInt32, sounding s: UInt32, othersPlaying: Bool) -> Verdict? {
            defer { (cycles, sounding) = (c, s) }
            guard let cycles, let sounding else {
                idleSince = t
                silentSince = othersPlaying ? t : nil
                return nil
            }
            if c != cycles { idleSince = t } else if !trial, t - idleSince >= window { return .dead }
            if s != sounding {
                silentSince = othersPlaying ? t : nil
                if heard { return nil }
                heard = true
                return .heard
            }
            guard othersPlaying else {
                silentSince = nil
                return nil
            }
            let since = silentSince ?? t
            silentSince = since
            return t - since >= window ? .silent : nil
        }
    }

    /// Where DK1 stands, and what each event asks of the tap. The setting `duck` is on in every phase but `off` and
    /// `denied`.
    public enum Phase: Equatable, Sendable {
        /// The setting is off.
        case off
        /// Just ticked in Settings: a tap that mutes nothing, so macOS's prompt comes up there and not over the box,
        /// listening for whether sound comes.
        case trial
        /// On, and no tap: the box is not up.
        case armed
        /// The box is up: other apps shaded.
        case running
        /// The output changed, its rate did, or the Mac slept: the tap is being made again.
        case rebuilding
        /// The tap heard only silence while another app played, and no tap had heard sound since launch: the setting
        /// is off again, and the line says what to allow.
        case denied
    }

    /// What the app's tap is asked to do.
    public enum Command: Equatable, Sendable {
        case none
        /// Make a tap that mutes nothing and listen (the trial).
        case trial
        /// Make the tap and shade, or shade again with the one still gliding out.
        case start
        /// Glide out, and stop `Tuning.duckRelease` later unless a `start` comes first.
        case release
        /// Take the tap down and make it again as it was.
        case rebuild
        /// Take the tap down now.
        case stop
    }

    public struct State: Equatable, Sendable {
        public private(set) var phase: Phase
        /// The box is up and writing goes on (`want`).
        public private(set) var wanted = false
        /// A tap has given sound since launch.
        public private(set) var heard = false
        /// Why the last tap did not start or stopped running, for the line; nil when nothing failed.
        public private(set) var failure: String?
        /// The trial ended with nothing else playing, and no tap has heard sound since: whether macOS allows it is not
        /// known yet.
        public private(set) var unchecked = false

        /// As the setting is kept (`duck`, off unless ticked).
        public init(on: Bool) { phase = on ? .armed : .off }

        /// The setting as the checkbox shows it.
        public var on: Bool { phase != .off && phase != .denied }

        /// The checkbox in Settings. On: the trial (the box is never up with the window, SP2). Off: the tap goes.
        public mutating func tick(_ on: Bool) -> Command {
            (failure, unchecked) = (nil, false)
            guard on else {
                if phase == .off || phase == .denied { return .none }
                phase = .off
                return .stop
            }
            if self.on { return .none }
            phase = .trial
            return .trial
        }

        /// Whether the box is up and writing goes on, called wherever the bed's is decided.
        public mutating func want(_ up: Bool) -> Command {
            guard up != wanted else { return .none }
            wanted = up
            switch (phase, up) {
            case (.trial, true), (.armed, true):
                phase = .running
                return .start
            case (.running, false):
                phase = .armed
                return .release
            case (.rebuilding, false):
                phase = .armed
                return .stop
            default: return .none
            }
        }

        /// The default output changed, or its sample rate.
        public mutating func outputChanged() -> Command {
            switch phase {
            case .running:
                phase = .rebuilding
                return .rebuild
            case .trial: return .rebuild
            default: return .none
            }
        }

        /// The Mac goes to sleep: the tap goes, to be made again at the wake if the box is still up.
        public mutating func sleep() -> Command {
            switch phase {
            case .running:
                phase = .rebuilding
                return .stop
            case .trial:
                phase = .armed
                return .stop
            default: return .none
            }
        }

        public mutating func wake() -> Command {
            guard phase == .rebuilding else { return .none }
            guard wanted else {
                phase = .armed
                return .none
            }
            return .rebuild
        }

        /// The tap is up.
        public mutating func started() -> Command {
            failure = nil
            if phase == .rebuilding { phase = .running }
            return .none
        }

        /// The tap could not be made, or stopped running: down at once, the setting kept; the next summon tries again.
        public mutating func failed(_ why: String) -> Command {
            failure = why
            switch phase {
            case .trial, .running, .rebuilding:
                phase = .armed
                return .stop
            default: return .none
            }
        }

        /// The watch's verdict on the tap running now.
        public mutating func watched(_ verdict: Watch.Verdict) -> Command {
            switch verdict {
            case .heard:
                (heard, unchecked) = (true, false)
                guard phase == .trial else { return .none }
                phase = .armed
                return .stop
            case .silent:
                guard phase == .trial || phase == .running || phase == .rebuilding else { return .none }
                phase = heard ? .armed : .denied  // heard since launch: allowed, so the apps' own silence or a doubt
                return .stop
            case .dead:
                return failed("the output did not run")
            }
        }

        /// The trial ended without a verdict: nothing played to tell. On; the watch decides at the first summon.
        public mutating func trialEnded() -> Command {
            guard phase == .trial else { return .none }
            (phase, unchecked) = (.armed, !heard)
            return .stop
        }

        /// The Settings window's line under the checkbox; empty when the tick alone says it (off, or on and checked).
        public var line: String {
            if let failure, on {
                return "Could not start last time (\(failure)). Lemna tries again when the box shows."
            }
            switch phase {
            case .off: return ""  // the tick says off and on (pass 40b)
            case .trial: return "Asking macOS for permission…"
            case .armed, .running, .rebuilding:
                return unchecked
                    ? "Not checked yet: Lemna checks it the next time another app plays sound while the box is up." : ""
            case .denied:
                return "Allow Lemna in System Settings › Privacy & Security › Screen & System Audio Recording, then "
                    + "tick it again."
            }
        }

        /// The line before macOS 14.2, which has no process taps.
        public static let unavailable = "Needs macOS 14.2 or later."
    }
}
