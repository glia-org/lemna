# Flow (working name): design decisions

A separate macOS app, not part of the terminal app. Research and the option panel: `docs/design-panel-flow-writer.html`,
backed by `reports/Flow writing tool design options.md` and `research_notes/`. The stack spike: `spikes/`.

## Decisions (the user's picks, 2026-10-27: the panel's recommended bundle)

| ID | Decision | Pick |
|---|---|---|
| S1 | Surface | One horizontal line, caret fixed at ~60 % of the width, text glides left per keystroke (one offset for the whole line, +advance easing out over 140 ms, leftover capped at one advance); nothing is ever drawn right of the caret: the new glyph emerges from under the caret as the line glides (clipped at the caret; the user, 2026-10-27, after seeing it overlap the caret in the spike); Reduce Motion jumps |
| V2 | Visible span | Last words at full strength, the clause before fades out toward ~25 % of the width |
| B1 | Backspace | Within the current word only |
| P0 | Pressure | None; text is never destroyed |
| K1 | Key sound | Clicks from the app's own window only (key-down, preloaded samples, pitch variation, one audio stream); default on, one toggle; warn once on Bluetooth output |
| W1 | Window | Own quiet surface, global hotkey + menu-bar item; panel-over-app (W2) is v2. The surface is an ordinary window that fills whatever rect it is given, so tiling window managers (AeroSpace, yabai) can place it; full screen is the default, not a requirement (the user, 2026-10-27) |
| O1+O2 | Output | Copy with Concealed/Transient markers, this host only; save as Markdown to a chosen folder |
| E2 | Never lose, privacy | Encrypted append-only journal (`lib/FlowJournal`); per-session key in the keychain, destroyed on Done/Discard; edits batched into 50 ms records (no keystroke timing on disk), each record write()n at once and followed by F_BARRIERFSYNC, F_FULLFSYNC on ~1 s idle, deactivate, quit (an app crash loses at most the last 50 ms); ⌘Q never discards, silent restore; a flock per journal so two builds never share a file. "This device only" holds only once the data-protection keychain is used (Apple allows kSecAttrAccessible on macOS only with it). **Signing:** the user has no Developer ID (2026-10-27), so dev builds are ad-hoc signed and the key lives in the login keychain; the key store is one type, swapped for the data-protection keychain when an identity exists |
| R1+R2+R3 | Review | Deterministic pass always; Harper review per change (offline, English; v1.5, via a Rust static library); AI only as hand-off to Apple Writing Tools / Shortcuts. No in-tool LLM, no silent background fixes |
| T2 | Stack | **Swift + AppKit** (the user, 2026-10-27, after the spike): custom NSView with NSTextInputClient, Core Text into a CAMetalLayer, AVAudioEngine, SwiftPM with the Command Line Tools (no Xcode), a script assembles and ad-hoc signs the bundle. Why not T1 (GPUI): the spike showed equal latency (p50 42 vs 50 ms at 60 Hz, both ~2.5–3 frames), and GPUI 0.3.8 needed five workarounds (no key timestamps, no presented-time hook, Reduce Motion unread, no event injection, 30 fps inactive cap) for 139 KB vs 6.7 MB, 0 vs 360 dependencies. Other OSes later mean a UI rewrite; accepted |
| M1 | Session | Free start; optional time box and hidden intent line; peripheral progress line; no live counts; soft end; summary; private log (totals only, never keystroke timing) |
| X1 | Distribution | Developer ID, notarized, outside the App Store, when the user has an identity; until then personal use only |

## Spike results (2026-10-27, this Mac, 60 Hz display, 300 synthetic keys at 12/s)

| | GPUI (gpui-pre 0.3.8) | AppKit (Swift 6.2) |
|---|---|---|
| key → presented p50 / p90 | 50 / 56 ms (mostly 3 frames) | 42 / 60 ms (mostly 2.5 frames) |
| handler p50 | 0.9 ms | 11.7 ms (draws in the handler) |
| glide fps | 60.0 | 59.9 |
| stripped binary / dependencies / cold build | 6.7 MB / 360 crates / 60 s | 139 KB / 0 / 35 s |

Both wait for the display-link tick and then for vsync. Known cuts for the app: draw on the key event instead of the next tick (about half a frame), `maximumDrawableCount = 2` (one frame). ProMotion was not exercised. Dead keys not yet tried by hand.

## Plan (v1), one milestone at a time, each with tests and a try by the user

1. **Surface** (S1 V2 B1 P0, W1's window): the app bundle skeleton (`app/`, SwiftPM, `make-app.sh` assembles `Flow.app` and ad-hoc signs it), an ordinary resizable window, the line from the spike with clip, fade and glide, real paragraphs in the model (shown as `¶` on the line), dead keys, Reduce Motion, 120 Hz hold, draw-on-key. Tests: layout core, offscreen render to PNG.
2. **Journal** (E2): AES-GCM append-only journal, key store (login keychain now), write/barrier/flush policy, silent restore, Done/Discard destroys the key. Tests: round trip, kill -9 mid-session then restore, discard leaves noise.
3. **Output and the mechanical pass** (O1 O2 R1): Done → summary → copy (markers, host only) / save Markdown (atomic, chosen folder) / discard; R1 with one-line undo; shred after a confirmed hand-off with an undo grace.
4. **Sound** (K1): AVAudioEngine, preloaded buffers, round-robin and pitch variation, a CC0 pack with its licence recorded in `THIRD_PARTY.md`, toggle, Bluetooth warning.
5. **Session frame and summoning** (M1, W1): hotkey (Carbon), menu-bar item, optional time box / intent line, peripheral progress line, soft end, summary, private log.

Later: R2 Harper (v1.5), W2 panel + O3 paste (v2), the name, Developer ID.

## Open

1. Typewriter samples: no permissively licensed pack found; record or buy. v1 ships a CC0 mechanical pack (Keychron K10 linear, Freesound, cut from the lossy previews; `lib/FlowClicks/THIRD_PARTY.md`).
6. AirPods: AVAudioEngine created an aggregate device on this Mac; an old report says that switches AirPods to call quality when they are the default input. Untested (no AirPods here). Fallback if it shows: an output-only DefaultOutput audio unit driving the same mixer (changes the audio choice in T2; the user decides).
2. The 5–10 draft post-processing test before any AI.
3. The name.
4. Tiling window managers: verify under AeroSpace that the window is tiled and keeps focus (the spike's AppKit bench waited for activation under it, 2026-10-27).
5. Dead keys by hand (´ then e → é on the German layout, ⌥U then o → ö).
