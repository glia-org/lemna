# A theme layer for Lemna: where the look lives and how to add themes (as of 2026-10-31)

Question (the user, 2026-10-31): "I want to add different themes that really change the way the app looks. I want to
add a new look and sound now that leans a lot more into the mindfulness side of things, so having ambient sounds like
winchimes and light rain drops as ambient animations as well as a user interface theme that is much more minimalism and
also typing sounds that lean more into that theme. ... Keep in mind that we in the future might want to add other themes
and ambients as well."

Read-only analysis of the code at 8d10301 (pass 20). Nothing was built, launched or listened to. File:line references
are to that commit. Tags: **[C]** read in the code, **[D]** DESIGN.md or a research note, **[I]** inference or estimate.

## Takeaway

1. **The look is spread over four places, not one** [C]: `Style` (5 colours and the font, `Line.swift:29-42`), literals
   in the app (corner radius, border, appearance, shadows, the notice's font; about 20), `Effects.Tuning` (the dim's
   alpha and every duration, 29 reads) and `Ambience.Tuning` (97 reads, with its own copy of two `Style` colours,
   `Ambience.swift:80`). Five objects capture the look once at init and would not follow a change at run time.
2. **Two things assume a dark theme and would break a light one silently** [C]: the ambience is drawn with additive
   blending ("light spilling onto the dim", `Particles.swift:98-116`), which adds nothing you can see on a light dim;
   and the box's system shadow is dropped on the hand-off's first frame (`Box.swift:282`), which is acceptable only
   because "under the dim it barely shows" on dark.
3. **Recommendation: A, the preset, over independent axes** (§2). A theme sets the look and also writes the sound pack,
   the bed and the ambience into today's keys. The menus stay and show what is really set. Effects ticks and ⌘K's
   on/off stay the user's. B's per-theme overrides fix a problem nobody has had yet, at about 4× A's extra code.
4. **Declare themes as Swift literals in LemnaCore** (§3), like `Effects.Tuning` and `SoundChoice.packs`. Tests then
   check that every theme names packs, beds and scenes that exist, reaches its contrast ratios, and that every scene can
   be seen on every theme's dim.
5. **The sound bed is the costliest and riskiest part** (§4): a stereo source node of its own on the same engine, about
   200 lines plus tests. **It reverses DESIGN K1's D1** ("no ambient sound bed"), and wind chimes are the textbook
   changing-state sound K1 ruled out. That is the user's call, made with the evidence in view (§0).
6. **Water rings and chimes fit the sprite pipeline** with one new soft-ring shape. True wave interference would need
   a full-screen shader pass; additive overlap already brightens where rings cross. A breathing glow is cheapest on Core
   Animation, without Metal (§5).
7. **Order** (§8): (1) the theme layer, with today's look as the `lemna` theme plus a light stub theme to exercise the
   light-only paths; (2) a design panel, then the mindful look; (3) the click pack and the bed; (4) the scenes and the
   removals. Keep 103 app, 16 journal and 17 clicks tests green throughout.

## 0. Points the user should settle first

| # | Point | Evidence | Why it matters |
|---|---|---|---|
| Q1 | "Ambient sounds like windchimes and light rain drops as ambient animations" can be read two ways: (a) a sound bed (chimes, rain) **and** animations, or (b) chimes and raindrops as **animations** only | the sentence | (a) needs §4, the costliest part; (b) needs only §5 |
| Q2 | An ambient sound bed reverses **K1 D1** | DESIGN.md:14 (D1: "noise slightly harms writers without ADHD, g −0.21, speech in a bed lowers fluency, and macOS's Background Sounds plays rain or noise beside Lemna"); `research_notes/Flow sounds and ambience/sounds.md` §8.1: "for a typical writer an ambient bed is at best neutral" | if built: opt-in, Off unless a theme's preset turns it on, recorded as an amendment of K1 |
| Q3 | Wind chimes are a stream of varying tones; K1 ruled out "notes and water drops (changing pitches disrupt verbal memory)" | DESIGN.md:14; `sounds.md` line 23 (changing-state effect, Jones & Macken 1993; steady noise no disruption, Salamé & Baddeley 1989) and §3.7 (water drops "at 12/s it sounds like boiling") | the evidence favours a **steady** bed (light rain, wind). Chimes are safest as the picture, or as rare soft strikes when no key has come for a while. A mindful click pack should keep K1's "short, dark, low-mid strikes" of one pitch: wood or felt, not water and not notes |
| Q4 | A breathing glow beside a text task | `visuals.md` §4.1: Apple's Breathe "is the *foreground* task ... Nothing in Apple's design suggests running a breathing animation next to a primary task"; §1: clock-driven ambience draws "gets old" complaints | keep it opt-in as an ambience mode, Off under Reduce Motion (A1's WCAG 2.2.2 rule) |
| Q5 | Light or dark for the mindful look | `visuals.md` §2.6: positive polarity (dark on light) gave smaller pupils and better proofreading (Piepenbrock et al. 2014); the dark box over a light app inverts EN 12464-1's ratio (surround ~130× brighter) | light is the evidence-backed choice, but it brings the light-only work of §7 |
| Q6 | Remove Drift, Rings and Grid ("the other ones are not really great") | DESIGN A1, pass 18 (the same kind of removal was recorded there with "Reinstate from 5ed9259") | §5.4 lists what the removals would orphan |

F1 already holds a theme submenu as "Not taken: T3 (a Theme submenu, later)", with the risk "Each scheme needs its muted
checked and every effect tried on it; no need shown yet" (DESIGN.md:23; `docs/design-panel-lemna-effects.html`). The
need is shown now. The risk stays, and §3's tests are its answer.

## 1. Where the look is defined and where it is read

### 1.1 Definitions

| Source | Where | What |
|---|---|---|
| `Style` | `LemnaCore/Line.swift:29-42` | `font`, `background` #0e1013, `text` #d8dce3, `muted` #5c646f (Increase Contrast #8d95a0, a static func), `caret` = static `accent` #7aa7f0; `size` from the font |
| the font | `Lemna/main.swift:43` | `NSFont(name: "Menlo", size: 28)`, else the monospaced system font, made once at launch |
| `Effects.Tuning` | `LemnaCore/Effects.swift:91-117` | `dim` 0.5 (`:96`), open 0.300 from 0.87, close 0.200 (`:94`), glyph fade 0.080 (`:99`), ¶ fade 0.200 (`:101`), hand-off (`:112-114`) |
| the glide | `LemnaCore/Line.swift:51`, `Glide.swift:9-10` | 140 ms on easeOutQuint (S1, G1: "always, not an effect") |
| `Ambience.Tuning` | `LemnaCore/Ambience.swift:64-142` | about 56 constants; `text`/`accent` copied from `Style` as `UInt32` (`:80`); a test keeps the copy equal (`AmbienceTests.swift:98`) |
| box shape | `Lemna/Box.swift:39` | `borderWidth` 1, `cornerRadius` 10 (static on `Face`) |
| box frame | `LemnaCore/Box.swift:8,11` | 60 % of the screen's width, at least 600 pt, height 4 em |
| the mark | `LemnaCore/Summoning.swift:10-34` | black on clear, a template: the menu bar tints it |
| the icon | `app/make-app.sh:10,17-18` | K1's SVG with its own colours, `CFBundleIconFile` |

### 1.2 Reads

| Kind | Count | Sites |
|---|---|---|
| `style.background` | 6 | `LineView.swift:57`, `Line.swift:149`, `Box.swift:173,189,460`, `main.swift:64` |
| `style.text` | 1 | `Line.swift:160` |
| `muted` (instance and static) | 6 | `Line.swift:160`; `main.swift:337,339,340` (Increase Contrast, read at each show); `Frame.swift:22,35` (static) |
| `caret` / `Style.accent` | 1 + 2 | `Line.swift:176`; `Line.swift:32` (the default), `Box.swift:50` (the border, static) |
| `style.font` / `style.size` | 10 + 4 | `LineView.swift:42,129,180,217,228,327`, `Line.swift:127,133,147`, `Ambience.swift:196`, `Handoff.swift:48`, `Box.swift:513`, `main.swift:52` |
| `Effects.Tuning` | 29 | `Box.swift` 15 (`:100,206,234,275,285-288,304,339,412,422-423,437,474`), `Glide.swift:83,88`, `Handoff.swift` 12 (`:39,74,80,86-94,108`) |
| `Ambience.Tuning` | 97 | `Scenes.swift` (51 names), `Ambience.swift`, `Ambient.swift:157,262`, `Particles.swift:38,65,80`; colours at `Scenes.swift:70,156,169,304,352,356,434` |
| look literals in code | ≈ 20 | appearance `.darkAqua` `main.swift:63`, `Box.swift:166`; shadows `Box.swift:170,187,212,282,302,365,390`; border inset 1 `Box.swift:320,519`; the notice in system 12 pt at y 12, 5 s then a 1 s fade `Frame.swift:21,26,60-62`; caret 2 pt × 1.2 em `Line.swift:133`; additive blend `Particles.swift:113-116`; Grid's 0.05 s attack `Scenes.swift:434`; the glyph pad 0.1 em `Handoff.swift:48`; the monospace advance `Scenes.swift:38` |

### 1.3 Looks captured once (they would not follow a theme change)

| Captured | Where | Fix |
|---|---|---|
| `Box.style`, `lineHeight` are `let`; content, card and every shade get their background in `init` / at creation | `Box.swift:134,173,189,460` | a `restyle(_:)` that sets them again, `lineHeight` a `var` |
| `Face` border: colour, width, radius static | `Box.swift:39,48-50` | from the theme, set in `restyle` |
| `LineView.word` is `lazy` (one word's width in the font) | `LineView.swift:42` | recompute when `style` is set |
| the window's background and appearance | `main.swift:63-64` | set in `applyTheme` |
| the ambience's renderer (atlas) is **static**, made once per launch from the first font | `Ambient.swift:87,177-186`, `Particles.swift:26-34` | key it by font (the pipeline is already cached per device, `Particles.swift:103`) |

### 1.4 What a `Theme` carries, and what moves into it

| Field | Today's value (the `lemna` theme) | Moves from |
|---|---|---|
| `id`, `title` | `lemna`, "Lemna" | new |
| `dark` (appearance, blend, shadow policy) | true | `main.swift:63`, `Box.swift:166`, `Particles.swift:113-116` |
| palette: background, text, muted, muted under Increase Contrast, caret, accent | #0e1013, #d8dce3, #5c646f, #8d95a0, #7aa7f0, #7aa7f0 | `Line.swift:31-41`, `Ambience.swift:80` |
| type: font name, size, bundled file (optional), monospaced | Menlo, 28, none, yes | `main.swift:43` |
| shape: corner radius, border width, border role (accent, muted, none), caret width and height, shadow | 10, 1, accent, 2 pt × 1.2 em, on | `Box.swift:39,50`, `Line.swift:133` |
| dim alpha | 0.5 | `Effects.swift:96` |
| ink for the ambience: blend (add, over), primary and secondary colour, an alpha scale | add, text, accent, 1 | `Particles.swift:113-116`, `Ambience.swift:80` |
| motion (optional, later): open, close, glyph and ¶ fades, the hand-off's times | `Effects.Tuning`'s | `Effects.swift:91-117` |
| preset (option A): pack, bed, ambience | `DefaultPack`, none, Off | `Sound.swift:8-10`, `Ambience.swift:14-35` |

**Stays global**: the line's geometry (caret at 60 %, the fades at 25/45 % and 80/95 %), the glide (140 ms on
easeOutQuint: S1 and G1 tie it to latency, so no theme slows it), the box's proportions, the mark (a template, L1) and
the app icon. Lemna is an accessory app with no Dock icon, so a per-theme icon would show almost nowhere.

## 2. Three ways to add themes

The shared part (A, B and C alike): `Theme.swift` in LemnaCore (≈ 120 lines with two themes), `Style` built from a
theme (≈ 20 changed), `Box.restyle` (≈ 50), `applyTheme` with a menu, its validation and a `theme` key in `main.swift`
(≈ 50), the menu-bar item (1), `EdgeView` colours (≈ 6), `LineView` restyle (≈ 10), `Stage` carrying the ink so scenes
read `stage.ink` instead of `T.text`/`T.accent` (≈ 15 + 7 sites), the blend per theme (≈ 15), the renderer per font
(≈ 20). **About 12 files, ≈ 350 lines, ≈ 120 test lines** [I].

| | A. Preset | B. Bundle with overrides | C. Look only |
|---|---|---|---|
| What a theme switch does | look; writes `soundPack`, `bed`, `ambience` | look; the per-axis menus show this theme's stored choice, else the theme's default | look only |
| Existing menus | unchanged; they override until the next theme switch | unchanged in form; storage becomes per theme | unchanged; new packs, beds and scenes are new items there |
| Defaults | + `theme` (+ `bed`) | + `theme`; `soundPack`, `bed`, `ambience` (and `effects`?) become per-theme dictionaries; today's values migrate into `lemna`'s slot | + `theme` (+ `bed`) |
| Extra code beyond the shared part | ≈ 40 lines, 1–2 tests | ≈ 180 lines, 5–6 tests, a "Theme Defaults" item to undo tweaks | 0 |
| Hidden state | none: the menus show the truth | tweaks of other themes, invisible until you switch back | none |
| Getting the mindful set | one choice | one choice | three menus |
| Failure mode | a tweak is lost on a theme switch | which setting holds is hard to tell (is ⌘K per theme? is Reduce Motion?) | a theme that does not "really change" the app; mismatches (the films' Rain on a paper look) |

**Recommendation: A**, with two amendments:
- the preset writes the pack, the bed and the ambience, **not** the Effects ticks. Ticks are per-user motion
  preferences, and their Reduce Motion handling is theirs. A theme's own durations, if any, are part of its look.
- the preset does not touch Sound's on/off (⌘K). `SoundChoice.choose` turns the sound on (`Sound.swift:26-30`), so the
  preset needs a variant that leaves `on` alone.

Why A:
1. "really change the way the app looks" plus "a new look and sound" asks for one choice that brings a coherent
   package. A gives that, C does not.
2. The axes stay independent in storage, so a future ambience or pack is one item in its own menu, usable under any
   theme. That is C's strength, and A keeps it.
3. The overwrite costs little: themes are switched rarely. The evidence so far is a user who settles on a setup ("Rain
   ... the one I'm using the most"). The overwrite is also visible, since the menus show what holds.
4. B solves a problem that has not happened (switching back and forth with tweaks). It does so with hidden state and a
   test matrix of axes × themes, and it raises questions (⌘K, Reduce Motion) that A and C never have.
5. A turns into C if the preset is deleted, and into B if only the storage keys change. Choosing A now keeps both
   doors open.

Every axis can still be set by hand under A and C, so **every scene and pack must work on every theme**. Under
additive blending a dark-theme scene on a light dim is invisible (§7), so the ink has to come from the theme whichever
option is taken.

## 3. Declaring a theme

| | Swift literal in LemnaCore | JSON/plist in Resources |
|---|---|---|
| Checked | at compile time: `Ambience.Mode` cases, the types of every field | at run time: a typo'd mode or colour is a launch-time error path |
| Tests | `Theme.all` straight from `swift test`, no bundle | the test needs the file from the repo; a decoder to test |
| Fits | `Effects.Tuning`, `Ambience.Tuning`, `SoundChoice.packs` are all Swift | `pack.json` is data that ships **with assets** (file lists, licence, credit) |
| Third-party themes | no | possible, but no need shown |

**Swift literals for themes.** Assets keep their own manifests: a bed is a folder with a `bed.json` (name, licence,
source, attribution, files) in the shape of `pack.json` (`SoundPack.swift:16-38`).

```swift
public struct Theme: Equatable {
    public let id: String, title: String, dark: Bool
    public let palette: Palette, type: Typeface, shape: Shape, dim: Float, ink: Ink
    public let pack: String, bed: String?, ambience: Ambience.Mode?   // the preset (A)
    public static let all: [Theme] = [.lemna, .mindful]                // the first is the default
}
```

**Where the names bind.** LemnaCore does not depend on LemnaClicks (`app/Package.swift:14`), so a pack is named by
its folder string, as `SoundChoice.packs` does (`Sound.swift:8-10`). A bed is named by folder in a `BedChoice` list
shaped like `SoundChoice`. The ambience is an `Ambience.Mode` case. A bundled font is a file name in
`Contents/Resources/Fonts` plus its PostScript name. Folders are listed in three places: `SoundChoice.packs`,
`make-app.sh:21` and the exclude list in `lib/LemnaClicks/Package.swift:14`. A new pack or bed can be forgotten in any
of them. `make-app.sh` could copy `*Pack *Bed` by glob.

**What the tests should assert** (a `ThemeTests.swift`):
- ids and titles unique; `Theme.all[0].id == "lemna"`; `Theme(kept:)` with an unknown or missing value is `lemna`.
- **`lemna` equals today's values exactly**: the T2 colours, Menlo 28, radius 10, border 1, dim 0.5. Pass 1 must
  change nothing on screen, and this test proves it.
- every theme's `pack` is in `SoundChoice.packs`, its `bed` in the bed list, its `ambience` a current mode.
- contrast for each theme (reusing `FrameTests.swift:82-103`'s `ratio`): text ≥ 7:1; caret and accent ≥ 3:1 (WCAG
  1.4.11, non-text); muted under Increase Contrast ≥ 4.5:1; plain muted recorded as designed (T2's is 3.2:1).
- **every scene visible on every theme**: one offscreen frame per (theme, mode) over the theme's dim. The test checks
  that enough pixels differ from the dim by a set luminance step. This is the test that catches additive light on a
  light dim.
- the font resolves: `CTFontCopyPostScriptName` of the created font is the one asked for, not a fallback. For a
  bundled font the test registers it from the repo path first.
- under A: the preset applied leaves the Effects ticks and `SoundChoice.on` unchanged.
- if a theme carries motion: every duration on F1's scale, the loop `EffectsTests` already has, run per theme.

## 4. The ambient sound bed

Today: one `AVAudioEngine`, one **mono** `AVAudioSourceNode` (`ClickPlayer.swift:73,95-104`), copied to every output
channel (`:99-101`); a 16-voice mixer of one-shots (`Mixer.swift:9,63-91`) fed by a lock-free ring; the engine paused
while the sound is off (`ClickPlayer.swift:22-27`) and restarted on a configuration change (`:149-154`).

| Way | For | Against |
|---|---|---|
| **a `Bed` source node of its own**, stereo, attached to the same engine's main mixer (recommended) | sample-smooth fades: a gain ramp toward an atomic target, set like the ring; a crossfade between two beds with two slots; `isSilence` when both are at 0; render tested offline, as `Mixer` is; the click node untouched | ≈ 120 lines Swift + ≈ 15 lines C atomics in ClickRing |
| `AVAudioPlayerNode` with `scheduleBuffer(.loops)` (`sounds.md` §8.2) | ≈ 50 lines; a loop sample-exact by Apple | fades only by stepping `volume` from a main-thread timer; two nodes for a crossfade; not testable without a running engine |
| a voice type in the existing `Mixer` | one node | mono (the bed needs stereo width); a bug there would glitch the clicks |
| a second engine | — | two IO units, the device handling and the Bluetooth notice twice: no |

**The loop**: stereo 48 kHz AAC or CAF, 60–120 s, its seam crossfaded **offline** with equal-power ramps, as one web
player does (`sounds.md` §8.2), so the render is a plain wrap-around; no rare events, which "would be recognised on
every loop". Chime strikes, if any, are one-shots at random times over the bed, not part of the loop. Size ≈ 1 MB a
minute at AAC 128k. Memory is 23 MB per minute as Float32 stereo (`sounds.md` §8.4), so only the chosen bed is loaded,
off the main thread.

**Where it starts and stops**: in `App.apply()` (`main.swift:291-331`), the one place that knows both containers.
`on != nil` fades it in; `nil` fades it out, which covers Esc, the hotkey, a click outside and a hand-off. `Box.show`
and `Box.hide` see only the box. The audio may outlast the dim, since nothing waits for it. The fade lengths are open
(nothing in the notes fixes them), and so is the bed's level against the clicks (set by listening).

**Engine state**: today `enabled` pauses the engine. With a bed the engine runs while `enabled` or while the bed is
audible, and pauses once both are silent. ⌘K (Sound ▸ Off) silences both: it is "the sound", muted for a call. The
menu: a second radio group in Session › Sound ▸ (packs | beds, No Bed | Off ⌘K) rather than a new submenu.

**Cost** ≈ 200 lines (Bed, atomics, ClickPlayer wiring, `BedChoice`, menu, `make-app.sh`), + 4–5 LemnaClicks tests (seam
continuity, ramp reaches its target in N samples, equal-power crossfade, silence flag) and 2 LemnaCore tests. **Risk**:
medium. The render thread is shared with the clicks, though on another node. The engine stays awake longer. Memory and
bundle size grow. Sourcing a licensed bed: the CC0 rain recordings are in `sounds.md` §8.3, chimes are not.

## 5. New scenes in the mindful register

The pipeline: CPU scenes behind `Ambience.Scene` (`Ambience.swift:337-356`) write 32-byte sprites; one instanced
pipeline draws three shapes: glyph, rect, bend (`Particles.swift:217-235`; disc, small ring and beam were removed in
pass 18).

| Scene | Sprites enough? | New | Estimate [I] |
|---|---|---|---|
| **Ripples**: drops on still water (light rain at rest as an ambient mode like Rain; each key a drop where the key is, `Stage.screenX`) | yes, with one new shape | `ring`: a quad over the circle's square, coverage a Gaussian of (\|p\| − r)/σ, an inner trough ring a second, dimmer sprite; rings that cross add, so they brighten (reads as interference) | shader +12 lines, `Sprite.Kind` +1, scene ≈ 120, tuning ≈ 10, 2–3 tests, 1 render: ≈ 1 day |
| Ripples with **true interference** | no: a full-screen fragment pass | a signed height field from ≤ 32–64 drops' damped waves, shaded by its gradient; a second pipeline, a uniforms buffer, a "field" output beside sprites in the protocol | +200–300 lines; every pixel every frame while it plays (an ambient mode: power at rest) |
| **Chimes**: rods hanging from the top edge, swaying | yes | rods as `rect` sprites turned about a pivot (centre from pivot and angle), strings as thin rects; a damped pendulum per rod, wind from the typing rate, a key a small impulse | scene ≈ 110, tuning ≈ 10, 2 tests |
| **Breathing glow** | needs a soft disc (removed in pass 18) | either a `glow` shape (+6 shader lines) and a 40-line scene, or **no Metal**: the shade's opacity or a `CAGradientLayer` animated by Core Animation (autoreverse, repeat), ≈ 30 lines in `Box`, nothing on the scene thread | CA ≈ ½ day (cheapest; note F1's "none loops" rule, which Rain already broke for the ambience under I1) |

Sound and picture stay separate. Linking a chime's swing to a chime's sound would need a scene-thread-to-audio path,
which is new. Both can be driven by the same keys and seed if wanted.

### 5.4 What removing Drift, Rings and Grid would orphan

| Removed | Orphaned |
|---|---|
| Drift | `Event.leaving` and `Run.leaving` (`Ambience.swift:167,427-438`); `Key.line`, `Key.pushed` (`:155`) and LineView's `pushed` and the shaped line it hands on (`LineView.swift:36,130,187`); `Stage.band`, `baseline` (`:185,195-196`); `Glyphs.sprite(baselineLeft:)` (`:317`); `pace()` and `Tuning.fastRate` (`Scenes.swift:20`, `Ambience.swift:78`); the drift tunings |
| Rings | `circle()` (`Scenes.swift:312-324`), `Sprite.Kind.bend`, `Sprite.bend` and the shader's case 2; `Stage.boxX`, `Tuning.boxSpan` (`Ambience.swift:86,210-213`) |
| Grid | `Sprite.Kind.rect` and case 1 (unless Chimes use it); `Stage.caretPoint` (`:201`); `Keyboard.Position.rows/columns` (`Keyboard.swift:29-30`; `cells` is read only by `KeyboardTests`) |
| kept by Rain | `Keyboard` positions (via `screenX`), `mix`, `Random`, `Typing`, the glyph atlas |

Ripples would reuse either `circle()` and `bend` or replace them with `ring`. Already without a reader in the sources:
`Glyphs.letters` (`Ambience.swift:280,302`), read only by `AmbienceTests.swift:116`. Tests that would go: the per-mode
couplings and renders in `AmbienceTests`. `AmbienceLinkTests` loops over `Mode.allCases` and adapts by itself.

## 6. Fonts

- **Today**: `NSFont(name: "Menlo", size: 28)` with a monospaced fallback, made once at `main.swift:43`, passed to
  `Style(font:)`, and `BoxFrame.height(fontSize:)` = 4 em sets the box's height (`main.swift:52`, `LemnaCore/Box.swift:11`).
- **A bundled OFL font** works: `CTFontManagerRegisterFontsForURL(url, .process, &error)` before line 43 (or
  `ATSApplicationFontsPath` = `Fonts` in the Info.plist, no code). The call gives an error to log, and the tests can
  use it too. `make-app.sh` needs `mkdir Contents/Resources/Fonts`, a copy of the font and its `OFL.txt` (OFL fonts
  must travel with their licence), and a `THIRD_PARTY.md` line. `codesign --deep` covers it.
- **Monospace assumptions** a proportional face would hit: Drift's speed is "one cell of the monospaced line" (the
  atlas's widest advance, `Scenes.swift:38`, `Ambience.swift:297`), wrong for a proportional face. `Line.tail` = 200
  characters was sized from Menlo's cells (`Line.swift:58-60`), and a narrower face spans about a quarter less: check
  it against the widest window. `CoreTests.swift:8` assumes "every Menlo glyph" has one advance (fine if those tests
  pin the `lemna` theme). `Line.wordCells` measures "n" and works for any face.
- **The size**: the bottom-edge note sits at a fixed y of 12 pt with a 40 pt view (`Frame.swift:12,26`). Its comment
  places it against the band's lower quarter at 28 pt (`Frame.swift:6-9`). A theme with another size must check that
  the note still clears the glyphs, or the y must be derived in em.
- **The ambience's atlas follows the font only at its birth**: the renderer is static and made once
  (`Ambient.swift:87,177-186`). After a font change the glyph scenes would draw the old face. Drift would quietly stop,
  because `Glyphs.slot(glyph:font:)` checks `CFEqual` against the atlas's font (`Ambience.swift:314`). Key the renderer
  by font (≈ 20 lines). A theme may also give the ambience its own face (Rain in a mono face under a serif line).

## 7. The dim and the box under a light theme

| Assumes dark | Where | Under a light theme |
|---|---|---|
| additive blend: "the colours added (the scenes are light spilling onto the dim)" | `Particles.swift:98-116` | light added to light shows nothing → `ink.blend = .over` (src one, dst one-minus-src-alpha), a second pipeline in the cache keyed by blend (`:103`); dark ink colours |
| scene alphas tuned "plainly visible over a dark app" (pass 16) | `Ambience.Tuning` | an alpha scale per theme's ink, checked by §3's visibility test |
| C1's note "over a light app it nearly vanishes" | DESIGN.md:24 | the same problem inside Lemna itself once the dim is light |
| `.darkAqua` on the window and the panel (their sheets: Discard…, Save…, the journal's alert; the traffic lights) | `main.swift:63`, `Box.swift:166` | `.aqua` |
| the box's shadow dropped on the hand-off's first frame and restored on the next show | `Box.swift:212,282,302,365,390` | visible as a pop on a light dim → light themes with `shadow: false` (a flat card with a hairline), which suits a minimal look anyway |
| the dim is the background at 0.5 | `Box.swift:460,474`, `Effects.swift:96` | a paper-coloured wash; fine, its alpha per theme |
| Increase Contrast: one static muted pair | `Line.swift:39-41`, `main.swift:335-342`, `Frame.swift:22,35` | the theme's pair |
| Reduce Transparency | no path (Q1 made the box opaque always) | none needed; the dim's 0.5 is a dim, not a translucent surface |
| hand-off layers | cut from the band's last frame, which fills the theme's background (`Line.swift:149`, `Box.swift:83-106`) | follow the theme by themselves once content and card are restyled |
| `StatusMark` | a template, black on clear (`Summoning.swift:22`, `Summon.swift:53`) | nothing: the menu bar tints it |
| the strip's layer `isOpaque` | `Strip.swift:32` | fine: the band paints the theme's background |
| the contrast test's comment "HIG Dark Mode's minimum" | `FrameTests.swift:102` | the same 4.5:1 per theme |

## 8. Risks and order of work

| Pass | What | Verify | Tests |
|---|---|---|---|
| 1 | Theme layer: `Theme` with `lemna` = today and a **light stub** (`paper`: a light palette, Menlo, no shadow, `.over` ink) to exercise appearance, blend, shadow and contrast; Session › Theme ▸ and the menu-bar item's; live restyle (§1.3); the ink through `Stage`; the renderer per font; the preset (A) with the stub naming existing packs and Off | renders per theme (`idle-<theme>.png`, `ambience-<mode>-<theme>.png` in `app/renders`); `lemna`'s renders byte-equal to today's | 103 + ≈ 8 (§3) |
| 2 | The mindful look, after a design panel in the existing style (palette light or dark Q5, face, radius, border role, dim, any motion values) | renders; contrast tests | + 2–3 |
| 3 | Sound: a mindful click pack (5 kinds, `pack.json`, CC0 sourcing still to do), the bed (§4) if Q1/Q2 say yes; K1 amended | offline render tests; listening by the user | clicks 17 + 4–5, app + 2 |
| 4 | Scenes: Ripples, Chimes, Breathing (§5); removals if Q6 says yes; A1 amended | renders per (theme, mode); the visibility test | per scene 2–3; removed modes' tests go |
| 5 | The mindful theme's preset filled in with the new pack, bed and scene | the "names exist" test | + 0 |

The journal's 16 tests are untouched throughout.

**Risks**
- **The key path**: resolve the theme into a `Style` once, at the switch. `Line.draw` already takes a `Style` by value
  (`Line.swift:144-178`), so nothing changes per key. Keep the glide's 140 ms and its curve out of the theme.
- **Init-time capture** (§1.3): five places. A missed one shows as a box half in the old theme. The stub theme in pass
  1 is what exposes them.
- **Light-only work** (§7): the blend, the alphas, the shadow, the appearance. It is invisible until a light theme
  exists, hence the stub in pass 1, not in pass 2.
- **A proportional face** (§6): Drift's speed, `Line.tail`, the note's y.
- **Defaults**: only `theme` and `bed` are new under A. A missing `theme` reads as `lemna`, so nothing migrates. (B would
  migrate three keys.)
- **Asset lists** in three places (§3): one glob in `make-app.sh` removes one of them.
- **Evidence** (§0): K1 D1, K1's ruled-out notes and water drops, the breathing glow beside a task, A1's continuous
  motion. Each change gets a DESIGN amendment with the user's words and the evidence restated, as passes 18 and 19 did.
- **Scope**: no per-theme mark or icon (§1.4), no JSON themes (§3), no B-style overrides (§2), unless asked for.
