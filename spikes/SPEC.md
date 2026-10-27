# Spike: the sliding line in GPUI and in AppKit

Two throwaway programs, same behaviour, same measurements, so the stack decision (DESIGN.md T1 vs T2) rests on
numbers from this Mac instead of guesses. Keep each under ~400 lines. No persistence, no sound, no settings.

Folders: `spikes/gpui-line` (cargo project, own `target/` inside it, `CARGO_INCREMENTAL=0`, dependencies without
debug info) and `spikes/appkit-line` (SwiftPM executable, `swift build -c release`; Command Line Tools only, no
Xcode). Results go to `spikes/results/<name>-keys.csv` and `spikes/results/<name>-summary.txt`.

## Behaviour (identical in both)

- One window, 1200×700 pt, background `#0e1013`, no title text needed. Not full screen (the console must stay visible).
- One line of text in a monospaced font (Menlo, 28 pt; the system's if Menlo is missing), colour `#d8dce3`,
  vertically centred.
- The caret is fixed at 60 % of the window width: a 2 pt bar, 1.2 em tall, colour `#7aa7f0`.
- Typed text is laid out so that its end sits at the caret. Each keystroke appends, and the whole line, the new
  glyph included, is drawn with one x offset that starts at +advance in the key's frame and eases to 0 over 140 ms
  (ease-out, 1 − (1 − t)³). Keystrokes during a glide add their advance to the remaining offset; a leftover offset
  in the same direction is capped at one advance, so the glide never lags more than one keystroke behind.
- Nothing is ever drawn right of the caret (DESIGN.md S1): the text is clipped at the caret's x, so the new glyph
  emerges from under the caret as the line glides left, and the caret is drawn on top of the text. Backspace's
  glide back and marked text (a pending dead key, drawn as the line's end) are under the same clip.
- Fade (V2): per glyph, opacity 1 right of 45 % of the width, falling linearly to 0 at 25 % of the width, nothing
  drawn left of that.
- Backspace deletes within the current word only (back to the last space); before that it does nothing. The
  deleted glyph goes at once and the line glides back (offset −advance to 0).
- Return inserts a space followed by `¶` (so paragraphs stay visible in one line).
- Text input goes through `NSTextInputClient` / `interpretKeyEvents:` (GPUI: its input handler), so dead keys work:
  ⌥E then E must give `é`, ⌥U then O must give `ö`. Not testable without a hand on the keyboard; say so.
- Frames: present a frame on every display-link tick while a glide runs (hold 120 Hz on ProMotion), none when idle.
  Honour Reduce Motion (`NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`): jump instead of gliding.
- `Esc` quits.

## Measurements

Per keystroke, one CSV row `seq,key_ts,handled_ts,present_ts,method` in seconds of `mach_absolute_time`-based
uptime (the same clock as `NSEvent.timestamp`):

- `key_ts`: the OS event's timestamp (`NSEvent.timestamp`; GPUI: the platform event's timestamp if it exposes it,
  else the time its key handler is entered, and say which).
- `handled_ts`: when the app's key handler finished.
- `present_ts`: when the first frame containing the new glyph was presented. AppKit: draw into a `CAMetalLayer`
  and use the drawable's `addPresentedHandler` / `presentedTime`; if the drawing uses Core Text into a CALayer
  instead, use the display link's `targetTimestamp` of the frame after the draw and label the method `displaylink`.
  GPUI: the closest hook available (the time after the frame's present call is the fallback); label it.
- `method`: the string naming how `present_ts` was obtained.

At quit print and write a summary: n, p50 / p95 / max of `present_ts − key_ts` and of `handled_ts − key_ts`, the
frame rate held during glides (frames per second from the frame timestamps while a glide was active), time from
`main()` entry to the first presented frame, the release binary's size in bytes (stripped), the dependency count,
and the cold release-build wall time. The summary says which measurement is exact and which is approximate.

`--bench`: after the first frame, type a fixed 300-character English text at 12 characters per second through the
same key path the OS uses (AppKit: `NSApp.postEvent(NSEvent.keyEvent(...), atStart: false)`; GPUI: the nearest
in-process way to deliver a key event to the window, and if none reaches the OS event path, call the key handler
directly and label `handled_ts − key_ts` as in-process only), then quit and write the summary.
`--quit-after-first-frame`: for launch timing from a shell `time`.

## Hand-over

`spikes/run-bench.sh` builds both in release and runs each with `--bench`, then prints the two summaries side by
side as one table. The builders do not run the window-showing binaries themselves (a visible window takes the
user's focus); they build, run any windowless self-test they wrote, and hand the script over.

Note (2026-10-27): with the clip, `present_ts` is the first frame drawn after the key; its first visible pixels come one refresh later. Left as is; the spike is done.
