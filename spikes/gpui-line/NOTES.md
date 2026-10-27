# gpui-line: notes

The GPUI half of the sliding-line spike (`../SPEC.md`). Rust 1.99, `gpui-pre =0.3.8` (the GPUI the the terminal app app
resolves through gpui-kit 0.7.1), one binary crate with its own `target/`.

## Run

```sh
cd spikes/gpui-line
export PATH="$HOME/.rustup/toolchains/stable-aarch64-apple-darwin/bin:$PATH" CARGO_INCREMENTAL=0
cargo build --release                                   # binary: target/release/gpui-line
target/release/gpui-line --bench                        # types 300 characters at 12/s, quits, writes ../results/gpui-{keys.csv,summary.txt}
time target/release/gpui-line --quit-after-first-frame  # launch timing; prints main-to-first-frame, writes nothing
target/release/gpui-line                                # by hand: type; Esc, ⌘Q or closing the window quits and writes the two files
cargo test --release                                    # 12 tests, no window (reuses the release dependencies)
../run-bench.sh                                         # both halves: build, --bench each, one table
```

Plain `cargo test` passes too, but builds every dependency a second time in the debug profile (≈ +1 GB in
`target/debug`). I ran it once in a scratch target directory, where objc2's debug checks verify every message's
argument and return encodings (the presented-handler block, `nextDrawable`, the key event): all 12 pass.

The bench binary's summary reads three numbers it cannot know from the environment, which `../run-bench.sh` sets:
`GPUI_LINE_STRIPPED_BYTES` (strips a copy), `GPUI_LINE_DEPS` (`cargo tree`), `GPUI_LINE_COLD_BUILD_S` (from
`cold-build-seconds.txt`, written by a build that started without `target/release`). Run by hand they print `n/a`.

## Numbers measured here (2026-10-27, 10 cores)

| | |
|---|---|
| cold release build (wall, `rm -rf target/release`, crates already in `~/.cargo/registry`, `--offline`) | 59.9 s (an earlier run: 59.0 s); the root crate alone ≈ 2 s |
| `target/` after the release build and `cargo test --release` | 1.4 GB |
| binary, stripped (`strip -o`) | 6,730,832 bytes (unstripped, with line tables: 9,889,928) |
| dependencies | 360 crates compiled on this Mac (`cargo tree -e normal,build`, unique); 671 packages in `Cargo.lock` (all platforms) |
| linked system libraries | 19 (AppKit, Metal, QuartzCore, CoreText, CoreVideo, OpenGL, Carbon, CoreLocation, UserNotifications, …) |
| source | 849 lines in 4 files, ≈ 570 without tests, comments and blank lines (SPEC: ~400; the excess is the IME input handler, the presented-time hook and the bench poster, none of which GPUI provides) |

`Cargo.lock` was seeded from the the terminal app checkout's, so the build resolves the same versions offline (no Little
Snitch prompt, no download).

## Where GPUI 0.3.8 forced a deviation, and what I did instead

1. **`gpui-pre` alone has no platform.** `gpui::Application` must be given a `Platform` (`Application::with_platform`); `gpui-pre-platform`
   (`gpui_platform::application()`, which builds `MacPlatform`) is a second dependency, with `font-kit` (the macOS
   text system is behind it) and `runtime_shaders` (the default build compiles the Metal shaders with `xcrun metal`,
   which the Command Line Tools lack; the terminal app enables the same through gpui-kit).
2. **Key events carry no timestamp** (`KeyDownEvent { keystroke, is_held, prefer_character_input }`). The handler
   reads `NSApp.currentEvent.timestamp`: while AppKit dispatches the key-down (GPUI's `keyDown:` →
   `NSTextInputContext` → `insertText:` → our `EntityInputHandler`), the current event is that key-down, so `key_ts`
   is the OS event's own timestamp, not the handler entry. If the current event is not a key-down, the handler
   entry time is used; the summary says how many rows had which.
3. **No presented-time callback.** `MetalRenderer::draw` (gpui-pre-apple `metal_renderer.rs`) calls
   `layer.next_drawable()`, renders, then `command_buffer.present_drawable(drawable)` + `commit` (or `commit`,
   `wait_until_scheduled`, `drawable.present()` while presenting with a transaction); its only handler is a
   completed handler that recycles instance buffers. Nothing reaches the app. So the spike swizzles
   `-[CAMetalLayer nextDrawable]` process-wide, before the window opens: the hook calls the original, attaches
   `addPresentedHandler:` to the drawable it returns, and the handler records `presentedTime`. That is the same
   measurement as the AppKit half (`method` = `presentedTime`). It relies on GPUI taking exactly one drawable per
   frame, on the main thread, after the frame was painted (`Window::present` → `MacWindow::draw` →
   `MetalRenderer::draw`), which holds in 0.3.8. Fallbacks, labelled in the CSV: `nextDrawable` (when the drawable
   was taken; before encoding, so earlier than the present) and `paint` (when the line was painted). A windowless
   test checks that the hook runs and tags a drawable of an offscreen layer.
4. **Reduce Motion is not read from the OS.** `App::reduce_motion()` exists but defaults to false and GPUI never
   sets it; the spike reads `NSWorkspace.accessibilityDisplayShouldReduceMotion` on every edit, as the AppKit half.
5. **Per-glyph opacity.** `ShapedLine::paint` colours per text run. Reshaping with one run per glyph each frame
   would work through the layout cache, but the spike instead shapes once per edit and paints the `ShapedLine`'s
   glyphs itself with `Window::paint_glyph` (per-glyph colour; glyphs whose centre is left of 25 % are skipped).
   GPUI snaps glyph origins to a quarter of a device pixel (`SUBPIXEL_VARIANTS_X = 4`), so the line moves in
   0.25 px steps (0.125 pt on Retina).
6. **Frame pacing is GPUI's.** GPUI draws from a `CVDisplayLink` per display (not `CADisplayLink` with a preferred
   frame-rate range); the link ticks while the window is visible and GPUI draws only when the window is dirty. While
   a glide runs the paint calls `window.request_animation_frame()`, so every tick draws; when it ends nothing is drawn.
   Two GPUI throttles: inactive windows are capped at 30 fps by default (turned off: `inactive_frame_interval:
   None`, since AppKit has no such cap), and under Serious/Critical thermal state frames are capped at 60 fps (left
   on). GPUI also re-presents for 1 s after input arriving at ≥ 60 events/s; 12 keys/s does not trigger it.
7. **No GPUI way to inject an OS key event.** `Window::dispatch_keystroke` exists but skips AppKit and the input
   context. Since GPUI runs `[NSApp run]`, `--bench` uses the AppKit half's method: `NSEvent.keyEvent(...)`
   (timestamp = now, US ANSI key code, Shift for capitals) posted with `NSApp.postEvent(_:atStart: false)` from a
   GPUI foreground task, at 12 characters a second on an absolute schedule, 0.5 s after the first presented frame
   once the window is key (it prints "waiting for the window to become key; click it" otherwise), quitting 0.5 s
   after the last one. The event goes the OS's way from the queue on: `sendEvent:` → GPUI's `keyDown:` → GPUI's
   key-binding dispatch (no binding) → `NSTextInputContext handleEvent:` → `insertText:`. So `handled_ts − key_ts`
   is not in-process only; like the AppKit half it leaves out the keyboard, HID and WindowServer part.
8. **Backspace, Return and Esc are GPUI actions** bound to `backspace`, `enter`, `escape` (and `cmd-q`): GPUI
   routes ⌫ and Esc through the input context's `doCommandBySelector:` back into its key bindings, and matches
   Return against the bindings before the input context, so these never reach `insertText:`.
9. **Dead keys and marked text** use GPUI's `EntityInputHandler` (`replace_and_mark_text_in_range` for ⌥E's `´`,
   `replace_text_in_range` for the following `e`, which replaces the marked text with `é`). Marked text is drawn in
   the caret colour as the line's end, its end at the caret (as the AppKit half places it); the IME's candidate and
   accent windows are placed at the caret (`bounds_for_range`). Not testable without a hand on the keyboard: ⌥E then
   E should give `é`, ⌥U then O `ö`.

## Behaviour choices (the same as the AppKit half; coordinator's amendment)

- One offset for the whole line, the new glyph included: a keystroke adds +advance (the new glyph starts just
  right of the caret, under the clip below) and the offset eases to 0 over 140 ms with 1 − (1 − t)³. A leftover
  offset in the same direction is capped at one step, so the line never trails more than one keystroke. Backspace
  glides back the other way; the deleted glyph goes at once. Reduce Motion: no glide.
- Nothing is drawn right of the caret (DESIGN.md S1): the glyphs, marked text included, are painted inside
  `window.with_content_mask` with its right edge at the caret's x, so the new glyph emerges from under the caret.
- Text colour `#d8dce3` (the SPEC gives none); the fade uses each glyph's centre x.
- Backspace "back to the last space" is taken literally: after Return (` ¶`) one backspace removes the `¶`, the next
  does nothing. Whether `¶` should count as a word boundary is open.
- Menlo 28 pt through GPUI's font lookup; if Menlo were missing, GPUI's own fallback stack applies (not the
  system monospaced font).
- `Glide::active` is "offset ≠ 0", not "t < start + 140 ms": in floating point 1.0 + 0.14 > 1.14, so the time test
  calls the glide active at its last instant (the AppKit `LineCore` uses the time test).

## Not tested here

- Nothing with the window shown (by instruction): presented times, the frame rate, activation from a terminal,
  focus, dead keys. The windowless tests cover the layout math, the summary writer on synthetic frames, the
  presented-time hook on an offscreen layer and the bench's key events.
