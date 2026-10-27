//! The sliding line's rules (SPEC "Behaviour"), free of GPUI so `cargo test` checks them without a window.
//! Same choices as the AppKit half's `LineCore`, so the two programs behave alike.

pub const GLIDE_S: f64 = 0.140;
/// Caret, full opacity and zero opacity, as fractions of the window width.
pub const CARET_AT: f32 = 0.60;
pub const FULL_AT: f32 = 0.45;
pub const ZERO_AT: f32 = 0.25;
pub const RETURN_TEXT: &str = " ¶";

/// Ease-out cubic, 1 − (1 − u)³, with u clamped to 0..=1.
pub fn ease(u: f64) -> f64 {
    let v = 1.0 - u.clamp(0.0, 1.0);
    1.0 - v * v * v
}

/// A glyph's opacity by its x in a window `w` wide: 1 right of 45 %, 0 at 25 % and left of it, linear between.
/// None where nothing is drawn.
pub fn fade(x: f32, w: f32) -> Option<f32> {
    let a = ((x - ZERO_AT * w) / ((FULL_AT - ZERO_AT) * w)).min(1.0);
    (a > 0.0).then_some(a)
}

/// Backspace within the current word only: drops the last character unless the text is empty or ends in the
/// space that starts the current word. Returns whether anything was deleted.
pub fn backspace(s: &mut String) -> bool {
    match s.chars().last() {
        Some(c) if c != ' ' => {
            s.pop();
            true
        }
        _ => false,
    }
}

/// The line's x offset from its resting place (its end at the caret): starts at +advance, eases to 0 in 140 ms.
#[derive(Clone, Copy, Debug, Default)]
pub struct Glide {
    from: f64,
    start: f64,
}

impl Glide {
    pub fn offset(&self, t: f64) -> f64 {
        self.from * (1.0 - ease((t - self.start) / GLIDE_S))
    }

    /// Whether the line is still away from its resting place (`t < start + GLIDE_S` misjudges the last
    /// instant in floating point: 1.0 + 0.14 > 1.14).
    pub fn active(&self, t: f64) -> bool {
        self.offset(t) != 0.0
    }

    /// The line's end moved left by `dw` (an append; negative for a deletion). The glide restarts from the
    /// offset still remaining plus `dw`, so nothing on screen jumps; a remainder in the same direction is
    /// capped at one such step, so the line never trails more than one keystroke. Reduce Motion jumps.
    pub fn add(&mut self, dw: f64, t: f64, reduce_motion: bool) {
        if dw == 0.0 {
            return;
        }
        if reduce_motion {
            self.from = 0.0;
            return;
        }
        let mut r = self.offset(t);
        if r * dw > 0.0 {
            r = if dw > 0.0 { r.min(dw) } else { r.max(dw) };
        }
        self.from = r + dw;
        self.start = t;
    }
}

/// Nearest-rank percentile (p in 0..=1); NaN for an empty sample.
pub fn percentile(xs: &[f64], p: f64) -> f64 {
    if xs.is_empty() {
        return f64::NAN;
    }
    let mut s = xs.to_vec();
    s.sort_by(f64::total_cmp);
    s[((p * s.len() as f64).ceil() as usize).clamp(1, s.len()) - 1]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ease_out_cubic() {
        assert_eq!(ease(0.0), 0.0);
        assert_eq!(ease(1.0), 1.0);
        assert_eq!(ease(0.5), 0.875);
        assert!(ease(-1.0) == 0.0 && ease(2.0) == 1.0);
        assert!(ease(0.2) < ease(0.3));
    }

    #[test]
    fn glide_starts_at_advance_and_eases_to_zero() {
        let mut g = Glide::default();
        g.add(10.0, 1.0, false);
        assert_eq!(g.offset(1.0), 10.0);
        assert!((g.offset(1.07) - 1.25).abs() < 1e-9);
        assert!(g.offset(1.14) == 0.0 && !g.active(1.14));
        assert!(g.active(1.1));
    }

    #[test]
    fn keystroke_during_glide_adds_to_remainder() {
        let mut g = Glide::default();
        g.add(10.0, 0.0, false);
        let before = g.offset(0.05);
        g.add(10.0, 0.05, false);
        assert!((g.offset(0.05) - (before + 10.0)).abs() < 1e-9); // nothing jumps
        g.add(10.0, 0.05, false);
        assert_eq!(g.offset(0.05), 20.0); // capped: never more than one keystroke behind
        g.add(-10.0, 0.05, false);
        assert_eq!(g.offset(0.05), 10.0); // a deletion moves the target back, no jump
        let mut d = Glide::default();
        d.add(-10.0, 0.0, false);
        assert_eq!(d.offset(0.0), -10.0); // from idle, a deletion glides right
    }

    #[test]
    fn reduce_motion_jumps() {
        let mut g = Glide::default();
        g.add(10.0, 0.0, true);
        assert!(g.offset(0.0) == 0.0 && !g.active(0.0));
    }

    #[test]
    fn fade_per_x() {
        let w = 1200.0;
        assert_eq!(fade(ZERO_AT * w, w), None);
        assert_eq!(fade(0.10 * w, w), None);
        assert!((fade(0.35 * w, w).unwrap() - 0.5).abs() < 1e-5);
        assert_eq!(fade(FULL_AT * w, w), Some(1.0));
        assert_eq!(fade(CARET_AT * w, w), Some(1.0));
    }

    #[test]
    fn backspace_within_word() {
        let bs = |s: &str| {
            let mut s = s.to_string();
            backspace(&mut s).then_some(s)
        };
        assert_eq!(bs("the cat").as_deref(), Some("the ca"));
        assert_eq!(bs("the c").as_deref(), Some("the "));
        assert_eq!(bs("the "), None);
        assert_eq!(bs(""), None);
        assert_eq!(bs("café").as_deref(), Some("caf"));
    }

    #[test]
    fn return_inserts_pilcrow() {
        let mut s = String::from("end");
        s.push_str(RETURN_TEXT);
        assert_eq!(s, "end ¶");
        // ¶ sits after the last space, so it is the current word: one backspace removes it, the next does nothing.
        assert!(backspace(&mut s) && s == "end ");
        assert!(!backspace(&mut s));
    }

    #[test]
    fn percentile_nearest_rank() {
        let xs: Vec<f64> = (1..=100).rev().map(f64::from).collect();
        assert_eq!(percentile(&xs, 0.5), 50.0);
        assert_eq!(percentile(&xs, 0.95), 95.0);
        assert_eq!(percentile(&xs, 1.0), 100.0);
        assert!(percentile(&[], 0.5).is_nan());
    }
}
