// Other sound (DK1, pass 40, 40b): the shade's response at 1, 2, 4 and 16 kHz against two one-poles' own, its glide, the watch
// that tells a tap macOS gives no sound from one that hears, and the states with what each event asks of the tap. No
// audio hardware: the tap itself is the app target's. No Foundation here.
import Darwin
import Testing
@testable import LemnaCore

private typealias T = OtherSound.Tuning

/// The steady level, in dB, of a sine of `hz` through `shade` held at `target`: its RMS over the second half (the glide
/// done by then) against a full-scale sine's (a sample peak would miss the crest at 16 kHz, three samples a cycle).
private func level(_ shade: OtherSound.Shade, _ hz: Double, target: Float = 1, rate: Double = 48000) -> Double {
    let n = Int(0.6 * rate)  // the glide's 0.25 s, then 0.3 s measured: whole cycles of 1, 2, 4 and 16 kHz at 48 kHz
    let x = (0..<n).map { Float(sin(2 * Double.pi * hz * Double($0) / rate)) }
    var y = [Float](repeating: 0, count: n)
    x.withUnsafeBufferPointer { xp in
        y.withUnsafeMutableBufferPointer { yp in
            shade.render(frames: n, target: target, step: OtherSound.step(over: T.duckGlide, sampleRate: rate),
                         inLeft: xp.baseAddress!, inRight: xp.baseAddress!, inStride: 1,
                         outLeft: yp.baseAddress!, outRight: nil, outStride: 1)
        }
    }
    let tail = y[(n / 2)...]
    return 20 * log10(sqrt(2 * tail.reduce(0) { $0 + Double($1) * Double($1) } / Double(tail.count)))
}

/// The one-pole's magnitude at `hz` in dB, from its transfer function a / (1 − (1 − a) e^−jω).
private func onePole(_ hz: Double, rate: Double = 48000) -> Double {
    let a = Double(OtherSound.coefficient(cutoff: T.duckCutoff, sampleRate: rate)), b = 1 - a
    let w = 2 * Double.pi * hz / rate
    return 20 * log10(a / sqrt(1 - 2 * b * cos(w) + b * b))
}

@Test func theShadeIsSixDecibelsDownAndTwelveAnOctaveSofterAboveTwoKilohertz() {
    #expect(T.duckGain == -6 && T.duckCutoff == 2000 && T.duckGlide == 0.25)
    var shaded: [Double] = []
    for hz in [1000.0, 2000, 4000, 16000] {
        let got = level(OtherSound.Shade(sampleRate: 48000), hz)
        #expect(abs(got - (T.duckGain + 2 * onePole(hz))) < 0.3, "\(hz) Hz: \(got) dB")
        shaded.append(got)
    }
    // About −7.9, −12.0, −19.8 and −39 dB: the lows a little touched, the cutoff 6 dB under the gain, an octave up
    // 12 dB further, the top gone (pass 40b: one pole at 4 kHz, −8.9 and −16.7 dB at 4 and 16 kHz, left music bright).
    #expect(abs(shaded[0] + 7.9) < 0.3 && abs(shaded[1] + 12.0) < 0.3 && abs(shaded[2] + 19.8) < 0.3
            && abs(shaded[3] + 39) < 1)
    #expect(shaded[0] > shaded[1] && shaded[1] > shaded[2] && shaded[2] > shaded[3])
    // Open, the input passes as it is at every frequency.
    for hz in [1000.0, 16000] { #expect(abs(level(OtherSound.Shade(sampleRate: 48000), hz, target: 0)) < 0.01) }
    // At 44.1 kHz the cutoff stays at 2 kHz.
    let cd = level(OtherSound.Shade(sampleRate: 44100), 2000, rate: 44100)
    #expect(abs(cd - (T.duckGain + 2 * onePole(2000, rate: 44100))) < 0.3)
}

@Test func theGlideTakesAQuarterSecondEachWayAndTurnsBackMidway() {
    let rate = 48000.0, step = OtherSound.step(over: T.duckGlide, sampleRate: rate)
    let shade = OtherSound.Shade(sampleRate: rate)
    let x = [Float](repeating: 0.5, count: 600)  // 12.5 ms a call
    var y = x
    func run(_ calls: Int, to target: Float) {
        for _ in 0..<calls {
            x.withUnsafeBufferPointer { xp in
                y.withUnsafeMutableBufferPointer { yp in
                    shade.render(frames: 600, target: target, step: step, inLeft: xp.baseAddress!,
                                 inRight: xp.baseAddress!, inStride: 1, outLeft: yp.baseAddress!, outRight: nil,
                                 outStride: 1)
                }
            }
        }
    }
    run(10, to: 1)  // 125 ms: halfway
    #expect(abs(shade.amount - 0.5) < 0.01)
    run(11, to: 1)  // 262.5 ms: there (the float steps add up a hair short of 250 ms)
    #expect(shade.amount == 1)
    #expect(abs(Double(y[599]) - 0.5 * pow(10, T.duckGain / 20)) < 1e-3)  // DC through the shade: the gain alone
    run(4, to: 0)  // turned back: from where it is, at the same pace
    #expect(abs(shade.amount - 0.8) < 0.01)
    run(17, to: 0)
    #expect(shade.amount == 0 && y[599] == 0.5)  // open again: the input as it is
}

@Test func theWatchHearsSoundAndTakesSilenceWhileOthersPlayForNoSound() {
    // A tap that hears: the first new sounding buffer is the verdict, once.
    var w = OtherSound.Watch(trial: false)
    #expect(w.feed(at: 0, cycles: 0, sounding: 0, othersPlaying: true) == nil)
    #expect(w.feed(at: 0.25, cycles: 20, sounding: 3, othersPlaying: true) == .heard)
    #expect(w.feed(at: 0.5, cycles: 40, sounding: 9, othersPlaying: true) == nil)
    // Silence counts from the last buffer with sound: a paused app, or a doubt, after the window.
    #expect(w.feed(at: 3.4, cycles: 300, sounding: 9, othersPlaying: true) == nil)
    #expect(w.feed(at: 3.75, cycles: 330, sounding: 9, othersPlaying: true) == .silent)
    // Only zeros while another app plays, for the window: no sound from macOS.
    var d = OtherSound.Watch(trial: false)
    #expect(d.window == T.duckWatch && T.duckWatch == 3)
    _ = d.feed(at: 10, cycles: 0, sounding: 0, othersPlaying: true)
    #expect(d.feed(at: 12.9, cycles: 270, sounding: 0, othersPlaying: true) == nil)
    #expect(d.feed(at: 13, cycles: 280, sounding: 0, othersPlaying: true) == .silent)
    // Nothing else playing: no verdict, however long; the window starts when something does.
    var q = OtherSound.Watch(trial: false)
    _ = q.feed(at: 0, cycles: 0, sounding: 0, othersPlaying: false)
    #expect(q.feed(at: 60, cycles: 5000, sounding: 0, othersPlaying: false) == nil)
    #expect(q.feed(at: 61, cycles: 5100, sounding: 0, othersPlaying: true) == nil)
    #expect(q.feed(at: 63.5, cycles: 5300, sounding: 0, othersPlaying: false) == nil)  // stopped: the window again
    #expect(q.feed(at: 64, cycles: 5350, sounding: 0, othersPlaying: true) == nil)
    #expect(q.feed(at: 67, cycles: 5600, sounding: 0, othersPlaying: true) == .silent)
    // The counts wrap: a change is a change.
    var r = OtherSound.Watch(trial: false)
    _ = r.feed(at: 0, cycles: .max, sounding: .max, othersPlaying: true)
    #expect(r.feed(at: 0.25, cycles: 3, sounding: 1, othersPlaying: true) == .heard)
}

@Test func theWatchCallsAStillTapDeadButNeverTheTrial() {
    var w = OtherSound.Watch(trial: false)
    _ = w.feed(at: 0, cycles: 100, sounding: 50, othersPlaying: false)
    #expect(w.feed(at: 2.9, cycles: 100, sounding: 50, othersPlaying: false) == nil)
    #expect(w.feed(at: 3, cycles: 100, sounding: 50, othersPlaying: false) == .dead)
    // The trial waits longer for silence (the prompt may be up) and its IO may not run until it is answered.
    var t = OtherSound.Watch(trial: true)
    #expect(t.window == T.duckTrial && T.duckTrial == 15)
    _ = t.feed(at: 0, cycles: 0, sounding: 0, othersPlaying: true)
    #expect(t.feed(at: 14, cycles: 0, sounding: 0, othersPlaying: true) == nil)
    #expect(t.feed(at: 15, cycles: 0, sounding: 0, othersPlaying: true) == .silent)
}

@Test func theStatesTrialAtTheTickRunWhileTheBoxIsUpAndGoAtTheHide() {
    var s = OtherSound.State(on: false)
    #expect(s.phase == .off && !s.on && s.line == "")
    #expect(s.want(true) == .none && s.want(false) == .none)  // off: the box comes and goes, no tap
    #expect(s.tick(true) == .trial)
    #expect(s.phase == .trial && s.on && s.line == "Asking macOS for permission…")
    #expect(s.tick(true) == .none)
    #expect(s.watched(.heard) == .stop)  // sound came: allowed; the trial's tap goes
    #expect(s.phase == .armed && s.heard && s.line == "")
    #expect(s.want(true) == .start && s.phase == .running)
    #expect(s.want(true) == .none)  // called again at the same state: nothing new
    #expect(s.watched(.heard) == .none && s.phase == .running)
    #expect(s.want(false) == .release && s.phase == .armed)
    #expect(s.want(true) == .start)  // a summon during the glide out: shaded again
    #expect(s.tick(false) == .stop && s.phase == .off && s.line == "")
    #expect(s.want(false) == .none && s.want(true) == .none)
    // Kept on at launch: armed, nothing made until the box is up.
    var k = OtherSound.State(on: true)
    #expect(k.phase == .armed && k.on && !k.heard && k.line == "")
    #expect(k.want(true) == .start)
    // A summon right after the tick, before the trial decided: the shading tap instead.
    var t = OtherSound.State(on: false)
    _ = t.tick(true)
    #expect(t.want(true) == .start && t.phase == .running)
}

@Test func theStatesRebuildOnAnOutputChangeAndAcrossSleep() {
    var s = OtherSound.State(on: true)
    #expect(s.outputChanged() == .none && s.sleep() == .none && s.wake() == .none)  // no tap: nothing to make again
    _ = s.want(true)
    #expect(s.outputChanged() == .rebuild && s.phase == .rebuilding)
    #expect(s.started() == .none && s.phase == .running)
    #expect(s.sleep() == .stop && s.phase == .rebuilding)
    #expect(s.wake() == .rebuild && s.phase == .rebuilding)
    _ = s.started()
    #expect(s.phase == .running)
    // Asleep with the box up, and the box gone before the wake: nothing at the wake.
    _ = s.sleep()
    #expect(s.want(false) == .stop && s.phase == .armed)
    #expect(s.wake() == .none && s.phase == .armed)
    // Rebuilding when the box goes: down at once.
    _ = s.want(true)
    _ = s.outputChanged()
    #expect(s.want(false) == .stop && s.phase == .armed)
    // The trial follows the output too, and a sleep ends it.
    var t = OtherSound.State(on: false)
    _ = t.tick(true)
    #expect(t.outputChanged() == .rebuild && t.phase == .trial)
    #expect(t.sleep() == .stop && t.phase == .armed)
}

@Test func silenceWhileOthersPlayUnticksAndFailuresKeepTheSettingOn() {
    var s = OtherSound.State(on: false)
    _ = s.tick(true)
    #expect(s.watched(.silent) == .stop)
    #expect(s.phase == .denied && !s.on)
    #expect(s.line.hasPrefix("Allow Lemna in System Settings › Privacy & Security › Screen & System Audio Recording"))
    #expect(s.want(true) == .none)  // the box comes: no tap
    #expect(s.tick(false) == .none && s.phase == .denied)  // already unticked
    #expect(s.tick(true) == .trial)  // ticked again, after allowing it
    // Kept on at launch, the permission taken back since: the first summon's watch finds it, the tap goes at once.
    var k = OtherSound.State(on: true)
    _ = k.want(true)
    #expect(k.watched(.silent) == .stop && k.phase == .denied)
    #expect(k.want(false) == .none)
    // Heard since launch, then silence while another app plays (paused with its stream open, or a doubt): the tap goes
    // for this summon, the setting stays, the next summon shades again.
    var h = OtherSound.State(on: false)
    _ = h.tick(true)
    _ = h.watched(.heard)
    _ = h.want(true)
    #expect(h.watched(.silent) == .stop && h.phase == .armed && h.on && h.line == "")
    #expect(h.want(false) == .none && h.want(true) == .start)
    // A tap that will not start, or stops running: down at once, still on, the line says why; the next summon tries.
    var f = OtherSound.State(on: true)
    _ = f.want(true)
    #expect(f.failed("no output device") == .stop && f.phase == .armed && f.on)
    #expect(f.line == "Could not start last time (no output device). Lemna tries again when the box shows.")
    #expect(f.want(false) == .none && f.want(true) == .start)
    #expect(f.started() == .none && f.line == "")
    #expect(f.watched(.dead) == .stop && f.line
        == "Could not start last time (the output did not run). Lemna tries again when the box shows.")
    // The trial over with nothing else playing: on, not checked yet; the first sound heard checks it.
    var q = OtherSound.State(on: false)
    _ = q.tick(true)
    #expect(q.trialEnded() == .stop && q.phase == .armed)
    #expect(q.line == "Not checked yet: Lemna checks it the next time another app plays sound while the box is up.")
    _ = q.want(true)
    _ = q.watched(.heard)
    #expect(q.line == "" && q.trialEnded() == .none)
    #expect(OtherSound.State.unavailable == "Needs macOS 14.2 or later.")
}
