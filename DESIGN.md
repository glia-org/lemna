# Flow (working name): design decisions

A separate macOS app, not part of the terminal app. Research and the option panel: `docs/design-panel-flow-writer.html`,
backed by `reports/Flow writing tool design options.md` and `research_notes/`. The stack spike: `spikes/`.

## Decisions (the user's picks, 2026-10-27: the panel's recommended bundle)

| ID | Decision | Pick |
|---|---|---|
| S1 | Surface | One horizontal line, caret fixed at ~60 % of the width, text glides left per keystroke (one offset for the whole line, +advance easing out over 140 ms, leftover capped at one advance); nothing is ever drawn right of the caret: the new glyph emerges from under the caret as the line glides (clipped at the caret; the user, 2026-10-27, after seeing it overlap the caret in the spike); Reduce Motion jumps |
| V2 | Visible span | Last words at full strength, the clause before fades out toward ~25 % of the width |
| B4 | Editing | **Amended 2026-10-27 after the user tried the box** ("I would like to be able to also edit words that I already typed before"): the caret moves through the text (←/→ by character, ⌥←/→ by word, ⌘←/→ to the paragraph's start/end); typing inserts at the caret; ⌫ deletes backwards without limit within the text (across spaces and paragraph ends), ⌥⌫ a word back, ⌦ / ⌥⌦ forwards; no selection, no mouse placement, no undo on the line (the review has them). The line keeps the caret fixed and glides the text so that the caret never moves: text before the caret as before (V2 fade to the left), text after the caret drawn too, at full strength up to 80 % of the width and fading to nothing at 95 %; an insertion pushes only the text before the caret (which keeps emerging from under it), the text after stays put; a deletion glides back. The rule "nothing right of the caret" now applies to the text before the caret only. Concern raised and overruled: hidden history is what cut corrections from 42 % to 9 % with no quality loss (Pinet & Nozari 2020), and the earlier pick B1 followed from it; the user chose full editing with that in view. Replaces B1
| P0 | Pressure | None; text is never destroyed |
| K1 | Key sound | Clicks from the app's own window only (key-down, preloaded samples, pitch variation, one audio stream); default on, one toggle; warn once on Bluetooth output |
| W2 | Window | **Amended 2026-10-27 after the user tried v1** ("it doesn't open like a small box where you can type, it's treated as a full class separate window"): the surface is a small floating box, summoned by the hotkey or the menu-bar item over whatever the user is doing: a non-activating panel (the app behind stays active), about 60 % of the screen's width, one line tall plus margins, in the lower third of the active screen, rounded, with the rest of the screen dimmed by per-screen overlays; Esc hides it, and so does a click outside it while none of Flow's own sheets is up (the session stays; pass 7b, 2026-10-27); the review expands the box in place; the app is an accessory (menu-bar item, no Dock icon). The full window of v1 stays reachable (Flow › Open Window, ⌃⌘F) as an ordinary window for long sessions; tiling window managers see only that one. Replaces the W1 pick
| O1+O2+O3 | Output | Copy with Concealed/Transient markers, this host only; save as Markdown to a chosen folder; **O3 added 2026-10-27 with the box:** ⌘⏎ in the review pastes into the app that was active when the box was summoned (hide the box, reactivate that app, pasteboard + a posted ⌘V, the old clipboard restored after 250 ms if the pasteboard still holds Flow's item); needs the Accessibility (PostEvent) permission, asked once; with no permission or Secure Input on, it copies instead and says so; after a paste the 10 s grace keeps the text in Flow (Undo = keep), then finish()
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

All five built on 2026-10-27 (`app/`, `lib/FlowJournal`, `lib/FlowClicks`); none tried by the user yet. `HANDOFF.md` lists what to try.

1. **Surface** (S1 V2 B1 P0, W1's window): the app bundle skeleton (`app/`, SwiftPM, `make-app.sh` assembles `Flow.app` and ad-hoc signs it), an ordinary resizable window, the line from the spike with clip, fade and glide, real paragraphs in the model (shown as `¶` on the line), dead keys, Reduce Motion, 120 Hz hold, draw-on-key. Tests: layout core, offscreen render to PNG.
2. **Journal** (E2): AES-GCM append-only journal, key store (login keychain now), write/barrier/flush policy, silent restore, Done/Discard destroys the key. Tests: round trip, kill -9 mid-session then restore, discard leaves noise.
3. **Output and the mechanical pass** (O1 O2 R1): Done → summary → copy (markers, host only) / save Markdown (atomic, chosen folder) / discard; R1 with one-line undo; shred after a confirmed hand-off with an undo grace.
4. **Sound** (K1): AVAudioEngine, preloaded buffers, round-robin and pitch variation, a CC0 pack with its licence recorded in `THIRD_PARTY.md`, toggle, Bluetooth warning.
5. **Session frame and summoning** (M1, W1): hotkey (Carbon), menu-bar item, optional time box / intent line, peripheral progress line, soft end, summary, private log.

6. **The box and paste** (W2, O3; 2026-10-27): the floating panel, dim overlays, accessory policy, paste at Done, window mode kept.
8. **Editing on the line** (B4; 2026-10-27): caret movement, insert and delete anywhere, journal edits carry positions (format v2, v1 journals still replay).
7. **Harper review** (R2): `lib/FlowHarper`, a Rust static library (harper-core, Apache-2.0) with a C ABI, wrapped by a Swift package; suggestions in the review, per-change accept.

Later: the name, Developer ID.

## Open

1. Typewriter samples: no permissively licensed pack found; record or buy. v1 ships a CC0 mechanical pack (Keychron K10 linear, Freesound, cut from the lossy previews; `lib/FlowClicks/THIRD_PARTY.md`).
6. AirPods: AVAudioEngine created an aggregate device on this Mac; an old report says that switches AirPods to call quality when they are the default input. Untested (no AirPods here). Fallback if it shows: an output-only DefaultOutput audio unit driving the same mixer (changes the audio choice in T2; the user decides).
2. The 5–10 draft post-processing test before any AI.
3. The name.
4. Tiling window managers: verify under AeroSpace that the window is tiled and keeps focus (the spike's AppKit bench waited for activation under it, 2026-10-27).
5. Dead keys by hand (´ then e → é on the German layout, ⌥U then o → ö).
7. Hotkey: the user keeps ⌃⌥Space (2026-10-27; it also collides with macOS's input-source chord, off here, and with OmniFocus's quick entry). Reconsider only before a build goes to others; the constant is in `app/Sources/Flow/Summon.swift`.
8. Soft-end tone is silent while Sound is off; decide whether it should play regardless.
10. Harper is English only: a German session gets most words flagged. Decide: a language guess that skips Harper when the text is not English, or a per-session toggle.
9. Harper (R2): dialect is American (one constant in `lib/FlowHarper/rust/src/lib.rs`; British spellings get flagged); harper-core 3.0.0 pulls ~200 crates and adds ~9.5 MB to the binary, accepted for R2 on 2026-10-27; SCOWL's notice must ship with any distributed build (`lib/FlowHarper/THIRD_PARTY.md`).
