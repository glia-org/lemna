//! Spike: the sliding line in GPUI (../SPEC.md). One window, one line, caret fixed at 60 %, the line glides
//! left per keystroke, glyphs fade toward 25 %. Measures key → handled → presented per keystroke.

mod layout;
mod mac;
mod measure;

use std::ops::Range;

use gpui::{
    App, Bounds, ContentMask, Context, ElementInputHandler, Entity, EntityInputHandler, FocusHandle, KeyBinding,
    Pixels, ShapedLine, TextRun, TitlebarOptions, UTF16Selection, Window, WindowBounds, WindowOptions, actions, canvas,
    div, fill, font, point, prelude::*, px, rgb, size,
};

use layout::{CARET_AT, Glide, RETURN_TEXT, fade};
use measure::{now, rec};

actions!(line, [Backspace, Return, Quit]);

const FONT_SIZE: f32 = 28.0;
const BG: u32 = 0x0e1013;
const TEXT: u32 = 0xd8dce3;
const CARET: u32 = 0x7aa7f0;
const RESULTS: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../results");
/// 300 characters typed by --bench at 12 per second; the AppKit half types the same.
const BENCH_TEXT: &str = "The quick brown fox jumps over the lazy dog. A writer sits at the desk and types one line at a \
time, never looking back at the words that slide away to the left. The caret stays where it is, the text moves on, and \
the mind keeps going forward. Twelve keys a second is a calm pace for this short test.";

struct Line {
    focus: FocusHandle,
    text: String,
    /// Dead-key / IME composition, drawn at the line's end (its end at the caret) until committed.
    marked: Option<String>,
    shaped: Option<ShapedLine>,
    /// Width of `shaped` (`text` and `marked`), the x of the line's end.
    width: f64,
    glide: Glide,
    reduce_motion: bool,
    bench: bool,
}

fn utf16_to_byte(s: &str, u: usize) -> usize {
    let mut n = 0;
    s.char_indices().find(|(_, c)| { n += c.len_utf16(); n > u }).map_or(s.len(), |(i, _)| i)
}

fn utf16_len(s: &str) -> usize {
    s.encode_utf16().count()
}

impl Line {
    fn full(&self) -> String {
        format!("{}{}", self.text, self.marked.as_deref().unwrap_or(""))
    }

    /// Applies one keystroke's edit, reshapes, starts the glide and records the key's timestamps.
    fn edit(&mut self, window: &mut Window, cx: &mut Context<Self>, f: impl FnOnce(&mut Self) -> bool) {
        let entered = now();
        let key_ts = mac::current_key_ts();
        let changed = f(self);
        if changed {
            let full = self.full();
            let run = TextRun {
                len: full.len(), font: font("Menlo"), color: rgb(TEXT).into(),
                background_color: None, underline: None, strikethrough: None,
            };
            let shaped = window.text_system().shape_line(full.into(), px(FONT_SIZE), &[run], None);
            let width = f64::from(f32::from(shaped.width));
            self.reduce_motion = mac::reduce_motion(); // read per edit, as the AppKit half does
            self.glide.add(width - self.width, now(), self.reduce_motion);
            (self.shaped, self.width) = (Some(shaped), width);
            cx.notify();
        }
        rec().key(key_ts, entered, now(), changed);
    }

    fn backspace(&mut self, _: &Backspace, window: &mut Window, cx: &mut Context<Self>) {
        self.edit(window, cx, |l| layout::backspace(&mut l.text));
    }

    fn ret(&mut self, _: &Return, window: &mut Window, cx: &mut Context<Self>) {
        self.edit(window, cx, |l| {
            l.text.push_str(RETURN_TEXT);
            true
        });
    }

    fn quit(&mut self, _: &Quit, _: &mut Window, cx: &mut Context<Self>) {
        self.finish(cx);
    }

    fn finish(&self, cx: &mut App) {
        let intact = match (self.bench, self.text == BENCH_TEXT) {
            (false, _) => "n/a (not --bench)".to_string(),
            (true, true) => "yes".to_string(),
            (true, false) => format!("NO ({} characters)", self.text.chars().count()),
        };
        finish(&intact, self.reduce_motion, cx);
    }

    /// The range an IME edit replaces, in bytes of `full()`: the given UTF-16 range, else the marked text,
    /// else the end.
    fn edit_range(&self, range: Option<Range<usize>>) -> Range<usize> {
        let full = self.full();
        range.map(|r| utf16_to_byte(&full, r.start)..utf16_to_byte(&full, r.end))
            .unwrap_or(self.marked.as_ref().map_or(full.len(), |_| self.text.len())..full.len())
    }
}

/// Writes the CSV and the summary and quits, once (Esc, ⌘Q, closing the window, or the bench's end).
fn finish(intact: &str, reduce_motion: bool, cx: &mut App) {
    let summary = rec().finish(RESULTS, intact, reduce_motion);
    if let Some(summary) = summary {
        print!("{summary}");
        cx.quit();
    }
}

impl EntityInputHandler for Line {
    fn text_for_range(&mut self, r: Range<usize>, adjusted: &mut Option<Range<usize>>, _: &mut Window,
        _: &mut Context<Self>) -> Option<String> {
        let full = self.full();
        let b = utf16_to_byte(&full, r.start)..utf16_to_byte(&full, r.end);
        *adjusted = Some(utf16_len(&full[..b.start])..utf16_len(&full[..b.end]));
        Some(full[b].to_string())
    }

    fn selected_text_range(&mut self, _: bool, _: &mut Window, _: &mut Context<Self>) -> Option<UTF16Selection> {
        let end = utf16_len(&self.full());
        Some(UTF16Selection { range: end..end, reversed: false })
    }

    fn marked_text_range(&self, _: &mut Window, _: &mut Context<Self>) -> Option<Range<usize>> {
        let start = utf16_len(&self.text);
        self.marked.as_ref().map(|m| start..start + utf16_len(m))
    }

    fn unmark_text(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.marked.is_some() {
            self.edit(window, cx, |l| l.marked.take().map(|m| l.text.push_str(&m)).is_some());
        }
    }

    fn replace_text_in_range(&mut self, range: Option<Range<usize>>, new: &str, window: &mut Window,
        cx: &mut Context<Self>) {
        let r = self.edit_range(range);
        self.edit(window, cx, |l| {
            let full = l.full();
            l.text = format!("{}{new}{}", &full[..r.start], &full[r.end..]);
            l.marked = None;
            true
        });
    }

    fn replace_and_mark_text_in_range(&mut self, range: Option<Range<usize>>, new: &str, _: Option<Range<usize>>,
        window: &mut Window, cx: &mut Context<Self>) {
        let r = self.edit_range(range);
        self.edit(window, cx, |l| {
            let full = l.full();
            l.text = format!("{}{}", &full[..r.start], &full[r.end..]);
            l.marked = (!new.is_empty()).then(|| new.to_string());
            true
        });
    }

    fn bounds_for_range(&mut self, _: Range<usize>, b: Bounds<Pixels>, _: &mut Window, _: &mut Context<Self>)
        -> Option<Bounds<Pixels>> {
        let x = b.origin.x + b.size.width * CARET_AT;
        let y = b.origin.y + b.size.height / 2. - px(0.6 * FONT_SIZE);
        Some(Bounds::new(point(x, y), size(px(2.), px(1.2 * FONT_SIZE))))
    }

    fn character_index_for_point(&mut self, _: gpui::Point<Pixels>, _: &mut Window, _: &mut Context<Self>)
        -> Option<usize> {
        None
    }
}

/// Paints the line glyph by glyph (per-glyph opacity by x), then the caret; asks for the next frame mid-glide.
fn paint_line(entity: &Entity<Line>, bounds: Bounds<Pixels>, window: &mut Window, cx: &mut App) {
    let focus = entity.read(cx).focus.clone();
    window.handle_input(&focus, ElementInputHandler::new(bounds, entity.clone()), cx);
    let t = now();
    let line = entity.read(cx);
    let (left, w) = (f32::from(bounds.origin.x), f32::from(bounds.size.width));
    let cy = f32::from(bounds.origin.y) + f32::from(bounds.size.height) / 2.;
    let caret_x = left + CARET_AT * w;
    let gliding = line.glide.active(t);
    // Nothing is drawn right of the caret (DESIGN.md S1): the text, marked text included, is clipped at the
    // caret's x, so a new glyph emerges from under the caret as the line glides; the caret is painted on top.
    let mask = ContentMask { bounds: Bounds::from_corners(bounds.origin, point(px(caret_x), bounds.bottom())) };
    window.with_content_mask(Some(mask), |window| {
        if let Some(shaped) = &line.shaped {
            let x0 = caret_x - line.width as f32 + if gliding { line.glide.offset(t) as f32 } else { 0. };
            let baseline = cy + (f32::from(shaped.ascent) - f32::from(shaped.descent)) / 2.;
            let glyphs: Vec<_> = shaped.runs.iter().flat_map(|r| r.glyphs.iter().map(move |g| (r.font_id, g))).collect();
            for (i, (font_id, g)) in glyphs.iter().enumerate() {
                let x = x0 + f32::from(g.position.x);
                let next = glyphs.get(i + 1).map_or(shaped.width, |(_, n)| n.position.x);
                let marked = g.index >= line.text.len();
                let Some(a) = (if marked { Some(1.) } else { fade((x + x0 + f32::from(next)) / 2. - left, w) }) else {
                    continue;
                };
                let color = if marked { rgb(CARET).into() } else { gpui::Hsla::from(rgb(TEXT)).opacity(a) };
                let origin = point(px(x), px(baseline) + g.position.y);
                if g.is_emoji {
                    window.paint_emoji(origin, *font_id, g.id, shaped.font_size).ok();
                } else {
                    window.paint_glyph(origin, *font_id, g.id, shaped.font_size, color).ok();
                }
            }
        }
    });
    let caret = Bounds::new(point(px(caret_x), px(cy - 0.6 * FONT_SIZE)), size(px(2.), px(1.2 * FONT_SIZE)));
    window.paint_quad(fill(caret, rgb(CARET)));
    rec().painted(t, gliding);
    if gliding {
        window.request_animation_frame();
    }
}

impl Render for Line {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let entity = cx.entity();
        div()
            .size_full()
            .bg(rgb(BG))
            .track_focus(&self.focus)
            .key_context("Line")
            .on_action(cx.listener(Self::backspace))
            .on_action(cx.listener(Self::ret))
            .on_action(cx.listener(Self::quit))
            .child(canvas(|_, _, _| (), move |b, (), window, cx| paint_line(&entity, b, window, cx)).size_full())
    }
}

fn main() {
    let main_ts = now();
    let args: Vec<String> = std::env::args().skip(1).collect();
    let bench = args.iter().any(|a| a == "--bench");
    rec().main_ts = main_ts;
    let hooked = mac::install_present_hook(args.iter().any(|a| a == "--quit-after-first-frame"));
    gpui_platform::application().run(move |cx: &mut App| {
        cx.bind_keys([
            KeyBinding::new("backspace", Backspace, None),
            KeyBinding::new("enter", Return, None),
            KeyBinding::new("escape", Quit, None),
            KeyBinding::new("cmd-q", Quit, None),
        ]);
        cx.on_window_closed(|cx, _| finish("n/a (window closed)", mac::reduce_motion(), cx)).detach();
        let options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(None, size(px(1200.), px(700.)), cx))),
            titlebar: Some(TitlebarOptions { title: Some("gpui-line".into()), ..Default::default() }),
            // GPUI caps an inactive window's animation to 30 fps by default; AppKit has no such cap.
            inactive_frame_interval: None,
            ..Default::default()
        };
        let window = cx
            .open_window(options, |_, cx| {
                cx.new(|cx| Line {
                    focus: cx.focus_handle(), text: String::new(), marked: None, shaped: None, width: 0.,
                    glide: Glide::default(), reduce_motion: mac::reduce_motion(), bench,
                })
            })
            .expect("open window");
        window.update(cx, |line, window, cx| window.focus(&line.focus, cx)).ok();
        cx.activate(true);
        if !hooked {
            eprintln!("present hook not installed: present_ts falls back to paint time");
        }
        if bench {
            cx.spawn(async move |cx| bench_typist(window, cx).await).detach();
        }
    });
}

/// --bench: once the first frame is presented and the window is key, posts BENCH_TEXT into the app's event queue
/// at 12 characters a second (absolute schedule), then quits 0.5 s after the last one, like the AppKit half.
async fn bench_typist(window: gpui::WindowHandle<Line>, cx: &mut gpui::AsyncApp) {
    let sleep = |s: f64| cx.background_executor().timer(std::time::Duration::from_secs_f64(s.max(0.)));
    let (start, mut waited) = (now(), false);
    loop {
        // If presented handlers never run, start after 5 s anyway.
        let shown = mac::FIRST_PRESENTED.load(std::sync::atomic::Ordering::SeqCst) || now() - start > 5.;
        if shown && mac::window_is_key() {
            break;
        }
        if shown && !std::mem::replace(&mut waited, true) {
            eprintln!("gpui-line: waiting for the window to become key; click it");
        }
        sleep(0.01).await;
    }
    sleep(0.5).await;
    let t0 = now();
    for (i, c) in BENCH_TEXT.chars().enumerate() {
        sleep(t0 + i as f64 / 12. - now()).await;
        mac::post_key(c);
    }
    sleep(0.5).await;
    window.update(cx, |line, _, cx| line.finish(cx)).ok();
}

#[cfg(test)]
mod tests {
    #[test]
    fn bench_text_is_300_characters() {
        assert_eq!(super::BENCH_TEXT.chars().count(), 300);
    }
}
