//! Per-key timestamps, frames and the CSV/summary writer (SPEC "Measurements").
//! All times are seconds of mach_absolute_time uptime, the clock of NSEvent.timestamp and presentedTime.

use std::fmt::Write as _;
use std::sync::{Mutex, OnceLock};

use crate::layout::percentile;

unsafe extern "C" {
    fn mach_absolute_time() -> u64;
    fn mach_timebase_info(info: *mut [u32; 2]) -> i32;
}

pub fn now() -> f64 {
    static TB: OnceLock<f64> = OnceLock::new();
    let tb = *TB.get_or_init(|| {
        let mut i = [0u32; 2];
        unsafe { mach_timebase_info(&mut i) };
        i[0] as f64 / i[1] as f64 / 1e9
    });
    (unsafe { mach_absolute_time() }) as f64 * tb
}

pub struct Key {
    key_ts: f64,
    /// key_ts is NSEvent.timestamp (else: when the handler was entered).
    exact: bool,
    handled_ts: f64,
    painted: Option<f64>,
    frame: Option<usize>,
}

pub struct Frame {
    drawable_at: f64,
    /// presentedTime; 0 when the drawable was dropped, None when the handler never ran.
    presented: Option<f64>,
    glide: bool,
}

pub struct Rec {
    pub main_ts: f64,
    keys: Vec<Key>,
    unpainted: Vec<usize>,
    in_frame: Vec<usize>,
    frame_glide: bool,
    frames: Vec<Frame>,
    done: bool,
}

pub static REC: Mutex<Rec> = Mutex::new(Rec::new());

pub fn rec() -> std::sync::MutexGuard<'static, Rec> {
    REC.lock().unwrap_or_else(|e| e.into_inner())
}

impl Rec {
    const fn new() -> Self {
        Rec {
            main_ts: 0.0, keys: Vec::new(), unpainted: Vec::new(), in_frame: Vec::new(), frame_glide: false,
            frames: Vec::new(), done: false,
        }
    }

    /// One handled keystroke; `changed`: it changed what is drawn, so a frame will show it.
    pub fn key(&mut self, key_ts: Option<f64>, entered: f64, handled_ts: f64, changed: bool) {
        if changed {
            self.unpainted.push(self.keys.len());
        }
        let (key_ts, exact) = key_ts.map_or((entered, false), |t| (t, true));
        self.keys.push(Key { key_ts, exact, handled_ts, painted: None, frame: None });
    }

    /// The line was painted into the next frame's scene.
    pub fn painted(&mut self, t: f64, glide: bool) {
        for i in self.unpainted.drain(..) {
            self.keys[i].painted = Some(t);
            self.in_frame.push(i);
        }
        self.frame_glide |= glide;
    }

    /// The renderer took a drawable for the frame just painted; returns the frame's index.
    pub fn drawable(&mut self, t: f64) -> usize {
        let id = self.frames.len();
        self.frames.push(Frame { drawable_at: t, presented: None, glide: std::mem::take(&mut self.frame_glide) });
        for i in self.in_frame.drain(..) {
            self.keys[i].frame = Some(id);
        }
        id
    }

    #[cfg(test)]
    pub fn frame_count(&self) -> usize {
        self.frames.len()
    }

    pub fn presented(&mut self, id: usize, t: f64) {
        self.frames[id].presented = Some(t);
    }

    fn present_of(&self, k: &Key) -> (Option<f64>, &'static str) {
        match k.frame.map(|f| &self.frames[f]) {
            Some(Frame { presented: Some(t), .. }) if *t > 0.0 => (Some(*t), "presentedTime"),
            Some(f) => (Some(f.drawable_at), "nextDrawable"),
            None => (k.painted, if k.painted.is_some() { "paint" } else { "none" }),
        }
    }

    /// Writes `<dir>/gpui-keys.csv` and `<dir>/gpui-summary.txt` once, and returns the summary.
    pub fn finish(&mut self, dir: &str, intact: &str, reduce_motion: bool) -> Option<String> {
        if std::mem::replace(&mut self.done, true) {
            return None;
        }
        let mut csv = String::from("seq,key_ts,handled_ts,present_ts,method\n");
        let (mut lat, mut hand, mut methods) = (vec![], vec![], std::collections::BTreeMap::new());
        for (i, k) in self.keys.iter().enumerate() {
            let (p, m) = self.present_of(k);
            let ps = p.map_or(String::new(), |p| format!("{p:.6}"));
            writeln!(csv, "{},{:.6},{:.6},{ps},{m}", i + 1, k.key_ts, k.handled_ts).ok();
            *methods.entry(m).or_insert(0) += 1;
            if let Some(p) = p {
                lat.push((p - k.key_ts) * 1e3);
                hand.push((k.handled_ts - k.key_ts) * 1e3);
            }
        }
        // Frame rate while a glide ran: consecutive presented frames that were both painted mid-glide.
        let ts: Vec<(bool, f64)> = self.frames.iter().map(|f| (f.glide, f.presented.unwrap_or(0.0))).collect();
        let iv: Vec<f64> = ts.windows(2).filter(|w| w[0].0 && w[1].0 && w[0].1 > 0.0 && w[1].1 > 0.0)
            .map(|w| w[1].1 - w[0].1).collect();
        let (fps, p50) = (iv.len() as f64 / iv.iter().sum::<f64>(), percentile(&iv, 0.5));
        let slow = iv.iter().filter(|d| **d > 1.5 * p50).count();
        let first = self.frames.iter().find_map(|f| f.presented.filter(|t| *t > 0.0)).map(|t| (t - self.main_ts) * 1e3);
        let exact_keys = self.keys.iter().filter(|k| k.exact).count();
        let env = |k: &str| std::env::var(k).unwrap_or_else(|_| "n/a (run ../run-bench.sh)".into());
        let st = |xs: &[f64]| format!("{:.2} / {:.2} / {:.2}", percentile(xs, 0.5), percentile(xs, 0.95), percentile(xs, 1.0));
        let mut s = String::new();
        writeln!(s, "stack: GPUI (gpui-pre 0.3.8), Rust").ok();
        let rest = format!(" (of {} key events; the rest changed nothing)", self.keys.len());
        writeln!(s, "n: {}{}", lat.len(), if lat.len() == self.keys.len() { "" } else { &rest }).ok();
        writeln!(s, "present-key ms p50/p95/max: {}", st(&lat)).ok();
        writeln!(s, "handled-key ms p50/p95/max: {}", st(&hand)).ok();
        writeln!(s, "glide fps: {fps:.1} ({} intervals, p50 {:.2} ms, {slow} over 1.5x p50; display max {} Hz)",
            iv.len(), p50 * 1e3, crate::mac::display_max_fps()).ok();
        writeln!(s, "main-to-first-frame ms: {}", first.map_or("n/a".into(), |f| format!("{f:.1}"))).ok();
        writeln!(s, "binary bytes (stripped): {}", env("GPUI_LINE_STRIPPED_BYTES")).ok();
        writeln!(s, "dependencies: {}", env("GPUI_LINE_DEPS")).ok();
        writeln!(s, "cold release build s: {}", env("GPUI_LINE_COLD_BUILD_S")).ok();
        writeln!(s, "present_ts methods: {methods:?}").ok();
        writeln!(s, "key_ts: NSEvent.timestamp (NSApp.currentEvent in the handler) for {exact_keys} of {}; others: handler entry", self.keys.len()).ok();
        writeln!(s, "exact: key_ts, handled_ts, present_ts where method=presentedTime (MTLDrawable presented handler, \
            hooked on -[CAMetalLayer nextDrawable]), glide fps (from presentedTime), all on the mach host clock").ok();
        writeln!(s, "approximate: present_ts where method=nextDrawable or paint (earlier than the real present); \
            main-to-first-frame starts at main(), not at exec (time --quit-after-first-frame for the whole launch); \
            under --bench key_ts is when the event was posted to the app's queue, without the keyboard and \
            WindowServer part of a real keystroke").ok();
        let presented = self.frames.iter().filter(|f| f.presented.is_some_and(|t| t > 0.)).count();
        writeln!(s, "frames rendered/presented: {}/{presented}", self.frames.len()).ok();
        writeln!(s, "bench text intact: {intact}").ok();
        writeln!(s, "reduce motion: {}", if reduce_motion { "on (jumps)" } else { "off" }).ok();
        std::fs::create_dir_all(dir).ok();
        std::fs::write(format!("{dir}/gpui-keys.csv"), csv).ok();
        std::fs::write(format!("{dir}/gpui-summary.txt"), &s).ok();
        Some(s)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Three keys 100 ms apart, each painted 2 ms later and presented 9 ms after that, with a 120 Hz glide
    /// frame train after each: the summary's numbers come out as constructed.
    #[test]
    fn summary_from_synthetic_frames() {
        let mut r = Rec::new();
        r.main_ts = 0.5;
        let frame = 1.0 / 120.0;
        for k in 0..3 {
            let t = 1.0 + k as f64 * 0.1;
            r.key(Some(t), t, t + 0.001, true);
            for f in 0..12 {
                let at = t + 0.002 + f as f64 * frame;
                r.painted(at, true);
                let id = r.drawable(at + 0.001);
                r.presented(id, at + 0.009);
            }
        }
        r.key(None, 2.0, 2.0005, false); // a backspace with nothing to delete: no frame
        let dir = std::env::temp_dir().join(format!("gpui-line-test-{}", std::process::id()));
        let s = r.finish(dir.to_str().unwrap(), "n/a (not --bench)", false).unwrap();
        println!("{s}");
        assert!(r.finish(dir.to_str().unwrap(), "n/a", false).is_none());
        let csv = std::fs::read_to_string(dir.join("gpui-keys.csv")).unwrap();
        std::fs::remove_dir_all(&dir).ok();
        assert_eq!(csv.lines().count(), 5);
        assert!(csv.lines().nth(1).unwrap().ends_with(",1.011000,presentedTime"), "{csv}");
        assert!(csv.lines().nth(4).unwrap().ends_with(",,none"), "{csv}");
        assert!(s.contains("n: 3 (of 4 key events; the rest changed nothing)\n"), "{s}");
        assert!(s.contains("frames rendered/presented: 36/36\n"), "{s}");
        assert!(s.contains("present-key ms p50/p95/max: 11.00 / 11.00 / 11.00"), "{s}");
        assert!(s.contains("handled-key ms p50/p95/max: 1.00 / 1.00 / 1.00"), "{s}");
        assert!(s.contains("glide fps: 120.0 (35 intervals"), "{s}");
        assert!(s.contains("main-to-first-frame ms: 511.0"), "{s}");
    }
}
