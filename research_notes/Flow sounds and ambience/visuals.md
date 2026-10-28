# Visual ambience while typing: survey, evidence, candidates

Research notes, 2026-10-28. Question: should the box show any visual "ambience" while the writer types, beyond what it has (DESIGN.md S1 glide, V2 fade, W2 box and dim, K1 click)? Calm, mindful, no gamification; macOS 14+, Swift + AppKit + Core Animation/Metal; nothing may add latency to the key path; Reduce Motion turns all of it off; no network.

Method: two research passes (tools and user reception; perception and HCI evidence), Apple's HIG pages and API docs read from Apple's JSON, Apple's sleep-light patent read in full, the app's own code (`app/Sources`) read for the cost model. Numbers marked (computed) are my arithmetic. UNVERIFIED marks a claim from a secondary source or from memory that could not be checked against the primary. Reddit could not be read (403), so reception comes from GitHub issues, Hacker News, Marketplace/App Store and press reviews.

## 0. Answer first

**Recommendation: (h), nothing beyond the glide and the fade.** No candidate has evidence of benefit for a writer; four have evidence of cost; the rest are invisible or do nothing at the doses that would keep them calm. No problem has been reported that an ambience effect would solve (evidence of need: none).

| | Candidate | Driven by | Attention cost (0–3) | Evidence of benefit (0–3) | Verdict |
|---|---|---|---|---|---|
| a | glow under the caret, ~300 ms decay | each key | 2: an onset train at fixation at 3–8 Hz, never decays between keys | 0: redundant with keyboard + click; "juice" raises liking, not performance, and only games were tested | no |
| b | breathing background, 10 s, few % | clock | 0 if below threshold (then it does nothing); 2 if visible (a pacer asks to be followed) | 0: no study shows entrainment by an unattended luminance cycle; adherence to visible pacers falls to ~28 % under a hard task | no |
| c | rhythm trace: edge or dim warms while typing, cools in pauses | typing rhythm | 1 when slow and unseen; 3 once read as "keep it warm" | negative: a pause-tied visual raised output and made "stressed" the most common feeling (Dux Speltz 2021); contradicts P0 and the removed M1 progress line | no |
| d | particles/ink from the caret | each key | 3: travelling motion, the most distracting class; shake is what users turn off first | 0 | no |
| e | static paper/noise texture | none | 0 | 0 as ambience; a ±1-code noise is useful only as dither against banding | not as ambience; dither only if the V2 fade bands |
| e′ | animated grain | clock | 2: flicker behind the text, continuous redraw | 0 | no |
| f | colour temperature drifting warmer over the session | clock | 0 (gradual change goes unseen) | 0: the box's light at the eye is ~3 orders below any circadian threshold; stacks on Night Shift | no |
| g | faint ripple on Return | each paragraph | 1–2: a looming onset, once per paragraph, at the planning pause | 0: the `¶` glyph already marks the paragraph | no |
| h | nothing beyond glide + fade | — | glide only | Maglio & Campbell's guidelines, McCrickard's "slow fade", Case's principles 1 and 7, HIG "avoid adding motion to UI interactions that occur frequently"; every calm writing app ships still visuals and instant dims | **yes** |

Why, in five lines:
1. Abrupt onsets, motion onsets, looming and travelling motion capture attention; gradual change goes unnoticed (§2.1). So the effects that would be *seen* (a, d, g) are capture classes, and the calm ones (b, c-slow, f) are below notice: they cost little and do nothing.
2. In peripheral-display studies with a text-editing task, continuous motion hurt the task most (corrections −43 % against −26 % for discrete updates), and the authors' first guideline is "Motion or animation should be kept at a minimum" (§2.2).
3. Calm technology means an *informative* periphery (Weiser & Brown); the only informative candidate here (c) informs about pausing, which is pressure, and P0 says no pressure (§2.3, §2.8).
4. Apple's own calm visuals (Breathe, the sleep light) are foreground or idle-state signals, never shown beside a task; the HIG asks to avoid motion on frequent interactions and, under Reduce Motion, to reduce "automatic and repetitive animations" (§4).
5. In this app every continuous effect costs power for the whole session and has to fight two technical traps: the line band is opaque and drawn on the CPU, and near black one 8-bit step is +8.8 % luminance, so "a few percent" cannot be drawn smoothly (§5).

Findings outside the question, for the user's decision (§6): the 140 ms glide is the largest motion in the design and sits at the slow end of comparable tools, whose text or caret motion is instant by default or shortened for short moves; and the box is much darker than its dimmed surround, the opposite of the luminance ratios lighting standards recommend.

## 1. Survey: what tools show while you type

| Tool | Visual while typing | Driven by | Kept on? |
|---|---|---|---|
| OmmWriter (Dāna, GAIA) | still snowscape and gradient backgrounds; paid "chromatherapy backgrounds … that employ dynamically-changing color techniques"; GAIA: "backgrounds emulating the passing of the day", "the studied movement of colour"; toolbar fades when typing stops ([LowEndMac 2011, Wayback](https://web.archive.org/web/2016id_/http://lowendmac.com/misc/11mr/ommwriter-dana-review.html), [ommwriter.com](https://ommwriter.com/description/)) | clock / session; no visual response to keys (sound only) | backgrounds liked as a still mood; reviewers: "they can get old pretty quickly", "the musical hamster wheel" ([Macworld](https://www.macworld.com/article/217142/ommwriter_dana_helps_you_focus_when_writing.html)); WriteRoom's author found a soundtrack "that responds to your keystrokes … odd and a little wrong" ([HN](https://news.ycombinator.com/item?id=1050159)) |
| Calmly Writer | focus dim of all but the paragraph (amount adjustable), option to hide the caret while typing, themes; no animation documented ([help](https://www.calmlywriter.com/help.htm)) | caret position | no evidence |
| iA Writer focus mode | sentence/paragraph focus dims the rest; "works best in full-screen, dark mode" ([iA](https://ia.net/writer/support/editor/focus-mode)); dim transition instant or animated: UNVERIFIED | caret position | yes for drafting ("encourages me to treat a document as append-only", [HN](https://news.ycombinator.com/item?id=27812627)) |
| Typora focus | "fade out other contents except current line/block"; theme CSS `#C8C8C8`, images 50 %, **no transition** ([Typora](https://support.typora.io/Change-Styles-in-Focus-Mode)) | caret | no data |
| Obsidian Typewriter Mode (davisriedel) | defaults: line highlight on (`#444444` dark, `mix-blend-mode: screen`), dim unfocused **off** (0.25 when on), fade lines off, optional vignette `inset 0 0 2em 2em rgb(0 0 0 / 50%)`; no `transition` in any SCSS: all instant; issue #94 "the cursor and above text twinkles", #22 vignette "show[s] steps" (banding) ([repo](https://github.com/davisriedel/obsidian-typewriter-mode)) | caret | defaults ship the dim off |
| Ulysses typewriter mode | line/sentence/paragraph highlight, the rest "fades into the background"; "Mark Current Line puts a light grey tint" ([Ulysses](https://help.ulysses.app/editor-customization-guide)) | caret | no data |
| FocusWriter | still JPG themes behind a translucent panel (opacity 50, blur radius 32); "Old School" `#0cf155` on black; focus dims to alpha 128 instantly; sounds off by default; no animation in the code ([repo](https://github.com/gottcode/focuswriter)) | none / caret | static themes kept |
| WriteRoom, Dark Room, JDarkRoom, Q10, Byword | green-on-black or plain themes, typewriter scrolling; Q10 sounds and timer; no animation | none | static themes kept |
| ZenPen | light/dark flip, word-target bar, 400–600 ms UI fades not tied to typing ([repo](https://github.com/tholman/zenpen)) | UI only | no data |
| Flowstate | text fades if you stop, deleted after ~5–7 s ([No Film School](https://nofilmschool.com/2016/02/you-have-exactly-five-seconds-writing-app-flowstate-deletes-everything-you-just-wrote), [Digital Trends](https://www.digitaltrends.com/phones/flowstate-ios-app/)) | pauses (punitive) | short sessions by choice |
| The Most Dangerous Writing App (open source) | at 2 s idle the text turns `#F45653` with `blur(2px)` over `3s linear`, an inset red glow `0 0 40px 2px` over `3s ease-in`; killed at 5 s; hardcore: `blur(8px)`, only the last letter at 300 pt ([repo](https://github.com/maebert/themostdangerouswritingapp)) | pauses (punitive) | short sessions; panic reports in the earlier notes |
| Write or Die | background reddens after ~7 s, sound at ~18 s (UNVERIFIED, search summary) | pauses (punitive) | — |
| Freewrite Traveler / Alpha | e-ink lag ("constantly two or three words ahead", [PCWorld](https://www.pcworld.com/article/2917082/freewrite-traveler-review.html); "maybe half a second … it's maddening" yet "the Freewrite gets me 4k" vs 2k words, [Elison](https://megelison.com/freewrite)); Alpha's reflective LCD; no other visual feedback | hardware | polarised; the lag acts as an accidental "don't look back" |
| activate-power-mode (Atom) | combo counter (10 s streak, "Super!", "Radical!"), 5–15 particles per key (max 500, alpha ×0.96/frame ≈ 0.94 s life at 60 fps, computed), 1–3 px shake ([repo](https://github.com/JoelBesada/activate-power-mode)) | each key | "difficult to have this constantly enabled … ends up disabled always" (#183); "eyes will be easy to get tired because of vibration" (#68); "annoying when you are just reading" (#239) |
| Power Mode (VS Code) | particles/explosions every 2nd key, 1000 ms each; shake intensity 3; disabled by default; ~1.47 M installs ([repo](https://github.com/hoovercj/vscode-power-mode)) | each key | "it always catch the eye" (#16); "I would like to keep it on but … it's very distracting" (#101); "the screen-shake causes me discomfort" (PR #76) |
| hyperpower (Hyper) | 5–10 particles per spawn; "shaking is only enabled in wow mode now! Which makes `hyperpower` an extension that you can use full time" ([repo](https://github.com/vercel/hyperpower)) | each key | shake removed from the default to make it usable |
| Monkeytype | smooth caret default "medium" 100 ms (off/150/100/85), `inOut(1.25)`; **tape mode** (fixed caret, text scrolls; margin 50 %) default off, its scroll **instant** unless `smoothLineScroll` (default false) gives 125 ms; `typedEffect` fade 250 ms ease-in, off under reduced motion; "monkey power" sparks + 10 px shake, off by default ([repo](https://github.com/monkeytypegame/monkeytype), defaults checked in `default-config.ts`) | each key | smooth caret kept (complaints were about speed: "feels to unresponsive", PR #4368); "I found the default smooth version too distracting" (PR #746, the blink); the pace caret "flies distractingly" (#4382) |
| keybr | caret moves 100 ms linear; a new key cancels the animation; heatmaps and charts only after typing ([repo](https://github.com/aradzie/keybr.com)) | each key | default on |
| Neovide | cursor spring 150 ms, **40 ms for short moves**; PR #3054: "the additional latency the cursor animation causes"; VFX (railgun, torpedo, pixiedust, sonicboom, ripple, wireframe) off by default, listed under "Some Nonsense ;)" ([features](https://neovide.dev/features.html)) | caret moves | split: "Cute … but ultimately distracting and only adds a delay … after a week the novelty wears off" ([HN](https://news.ycombinator.com/item?id=39216169)); insert-mode animation "distracts me very much" (#3088) vs "my single favorite Neovide visual feature" (#3090) |
| kitty | `cursor_trail` off by default; skipped for moves under 2 cells, so typing never trails ([conf](https://sw.kovidgoyal.net/kitty/conf/)) | caret jumps | kept by some for tracking |
| VS Code smooth caret | `cursorSmoothCaretAnimation` default off; `explicit` animates only explicit moves (typing excluded, issue #168857); `all 80ms`; complaints: "The cursor lags consistently about 3 to 4 characters behind" ([#109787](https://github.com/microsoft/vscode/issues/109787)); "it doesn't render the character until the cursor arrives" ([HN](https://news.ycombinator.com/item?id=39230358)) | caret | typing excluded by design |
| Synthwave '84 (VS Code theme) | static neon `text-shadow` glow, off by default; "The glow effect started as a joke and was never intended for long-term coding sessions"; "To avoid eye strain, avoid using higher brightness values for extended periods" ([repo](https://github.com/robb0wen/synthwave-vscode)) | none | authors disown long use |
| StimuWrite | 12 pausable video backgrounds, goal bar, milestone emoji, earlier GPU particles; "the noise and flashing emoji feel like an assault on your senses" at first ([IAM](https://indieauthormagazine.com/stay-focused-keep-writing-how-stimuwrite-helps-neurodivergent-authors-beat-distraction/)); "my favorite feature" vs "laptop fan screaming … kills the writing vibe" ([itch.io](https://thatclowngoddess.itch.io/stimuwrite)) | clock | split; built for stimulation-seeking writers |
| WriteMonkey 3 | "austere progress bar", background images, Click Clack sounds; typewriter-scrolling plugin demoted to experimental, Visuals plugin removed ([changelog](https://github.com/writemonkey/wm3/wiki/Changelog)) | none | sounds loved ("10min typing absolute gibberish just to hear the typewriter sounds") |
| Noisli, myNoise, A Soft Murmur, Rainy Mood | Noisli's background colour "changes gradually automatically with time" ([Gigazine](https://gigazine.net/gsc_news/en/20150212-noisli-productivity-noise)), a 2025 review: the colours "change and can't be fixed, which can be counterproductive depending on mood" (translated, [review mirror](https://mwm.ai/de/apps/noisli/862773459)); myNoise animates its sliders; the others are static | clock | the one complaint is about the drift |
| Hemingway, Nebo, Cold Turkey Writer, Hanx Writer, OverType | colour highlights (Hemingway, hidden in write mode), ink (Nebo), lock-in (Cold Turkey; progress bar UNVERIFIED), typebar animation with "slight lag" (Hanx, UNVERIFIED) | — | — |

Cross-cutting:
- **No writing app found** with a keystroke glow, ink bleed, paper grain, or a background breathing with the typing rhythm. Calm writing apps ship still images, colour themes and **instant** dims (every focus-dim whose source could be read: Obsidian plugin, FocusWriter, Typora).
- **Visuals tied to pauses are the punitive camp's tool** (MDWA 2 s, Flowstate 5–7 s, Write or Die ~7 s). A rhythm trace that cools in pauses is the gentle version of the same signal.
- **Per-key motion is turned off first** (shake in every power-mode project); **animated caret or text position reads as lag** (VS Code, Neovide, HN), and mature tools converged on four fixes: snap the leading edge and animate only the trail (Neovide 0.15), shorter animation for short moves (Neovide 40 ms), leave typing out (VS Code `explicit`, kitty threshold), cancel on the next key (keybr).
- **Clock-driven ambience** (OmmWriter's chromatherapy, Noisli's drift) draws the "gets old" and "can't be fixed" complaints.

## 2. Evidence

Framing: most candidates are not peripheral. (a), (b), (d), (e), (f), (g) sit in the box, where the eyes already are (the caret is the fixation point); only (c) on the dim or the box edge, and the box's own ends, are peripheral. Geometry (computed, 14-inch screen 3024 × 1964 px at 50 cm): the box spans ≈21° (its left end 12° left of the caret, its right end 8° right), a 28 pt em ≈0.64°, the screen ±17°; on a 27-inch 2560 × 1440 screen at 60 cm the box spans ≈33°.

### 2.1 Capture, gradual change, thresholds

- Abrupt onsets capture attention ([Yantis & Jonides 1984](https://doi.org/10.1037/0096-1523.10.5.601), JEP:HPP 10:601–621); focused attention protects: onsets "do not necessarily capture attention" when attention is already focused by a valid cue ([Yantis & Jonides 1990](https://pubmed.ncbi.nlm.nih.gov/2137514/)). Search slopes not retrieved (UNVERIFIED).
- The *onset* of motion captures, not motion as such: static and continuously moving items do not ([Abrams & Christ 2003](https://pubmed.ncbi.nlm.nih.gov/12930472/), Psych Sci 14:427); isoluminant motion onsets capture too ([Guo et al. 2010](https://link.springer.com/article/10.3758/APP.72.5.1311)), so no luminance transient is needed. Looming and translating stimuli capture, receding ones do not ([Franconeri & Simons 2003](https://visualcognition.psych.northwestern.edu/publications/FranconeriSimons_Motion.pdf)).
- Gradual change in full view often goes unnoticed ([Simons, Franconeri & Reimer 2000](https://doi.org/10.1068/p3104), Perception 29:1143; per-condition rates UNVERIFIED); gradual facial-expression change: detection 3× lower than across a disruption, 15 % noticed within one trial ([David et al. 2006](https://psychologicabelgica.com/articles/128)); "change-blind" ambient displays built from gradual transitions ([Intille 2002](https://www.ccs.neu.edu/home/intille/papers-files/ubicomp02.pdf)). Matthews et al.'s notification levels (ignore / change blind / make aware / interrupt / demand attention): "change blind" and "make aware" "are at the core of the ambient information system design space" ([Pousman & Stasko 2006](https://faculty.cc.gatech.edu/~stasko/papers/avi06.pdf)).
- Temporal sensitivity: for an edgeless flickering field "a broad peak … from 10 to 20 cps at high photopic levels", band-pass, falling at low frequencies ([Kelly 1961](https://www.doi.org/10.1364/JOSA.51.000422)); flicker sensitivity is higher in the near-to-mid periphery ([Krajancich et al. 2021](https://arxiv.org/pdf/2104.13514)). No measured threshold at 0.1 Hz found (UNVERIFIED); at that rate a change reads as a change of illumination, not flicker. Weber fraction ~1–2 % in photopic vision, higher at low luminance (textbook, UNVERIFIED here). The box background (#0e1013) is ≈0.5 % of SDR white (computed relative luminance 0.0051), i.e. roughly 1–3 cd/m² at usual brightness settings (UNVERIFIED: depends on the brightness slider): low enough that thresholds rise.
- Typing rate puts a per-key effect in the sensitive band: 40–100 wpm = 3.3–8.3 keys/s, intervals 300–120 ms (computed, 5 characters per word); a large field study reports a mean of ~52 wpm, inter-key interval ~240 ms (Dhakal et al. 2018, CHI; values UNVERIFIED). Composition is burstier: a pause of ≥2 s is the conventional burst boundary (Chenoweth & Hayes 2001, Written Communication 18:80–98, p. 83 per secondary sources).

Implication: (a) is an onset at every key, (d) travelling motion, (g) looming: capture classes. (b), slow (c) and (f) are gradual: below notice, so they cost little and do little.

### 2.2 Peripheral displays and a primary task

- **Maglio & Campbell 2000, CHI** ([PDF](https://www.interruptions.net/literature/Maglio-CHI00-p241-maglio.pdf)): 10 min of text editing beside a 796 × 24 px ticker. Continuous scrolling hurt editing more than discrete (t(13)=2.46, p=.014); corrections fell from 24.67 to 15.00 with tickers; fall in corrections by display: discrete 26 %, continuous 43 %, continuous + 500 ms yellow flash 42 %, continuous + beep 55 % (checked in the PDF). Memory for the ticker was equal across displays, so the motion bought nothing. Guidelines (quoted): "1. Motion or animation should be kept at a minimum. 2. Motion or animation (when used) should not be continuous. 3. Discrete animation seems ideal for update feedback."
- **McCrickard, Catrambone, Chewar & Stasko 2003** ([IJHCS 58:547](https://people.cs.vt.edu/mccricks/papers/mccs03.pdf)): fade (500 ms every 2 s), ticker and blast left browsing time within 4 s in 60 s (p=.12); slow displays gave faster browsing (z=2.24, p=.03); "the slow fade appears to be the best secondary display animation type tested" (one shade every 150 ms, held 9 s).
- **Bartram, Ware & Calvert 2003, "Moticons"** ([IJHCS 58:515](https://www.interruptions.net/literature/Bartram-IJHCS03.pdf)): motion was detected ~100 % near (7–20°) and far (40–52°), colour change missed 5.5 % near and 24 % far; distraction depended on motion type (F(7,84)=86.89), least to most: blink, linear, zoom, travel; ~1 Hz cues less distracting than ~2 Hz; rated more distracting during a text task than during games; "Traveling motions … are substantially more distracting than anchored motions."
- **Burke et al. 2005, ToCHI** ([PDF](https://thoughtcrumbs.com/publications/ToCHI04.pdf)): flashing banners (150 ms) raised NASA-TLX workload to 160.7 against 107.8 static and 110.5 blank (F(3,36)=6.52, p<.001); people rarely looked at them yet search slowed: covert distraction.
- **Zhang 2000** ([JAIS 1(1)](https://aisel.aisnet.org/jais/vol1/iss1/1)): secondary animation degrades information seeking, more so when it resembles the task or is bright; less for harder tasks. Salient, abrupt ads disrupt reading (Simola et al. 2011, JEP:Applied 17:174).

Implication: when motion beside a text task carries nothing, it costs the task and buys nothing; continuous motion is the worst case.

### 2.3 Calm technology

- Weiser & Brown, "Designing Calm Technology" (1995/96, [calmtech.com](https://calmtech.com/papers/designing-calm-technology)): "Calm technology engages both the center and the periphery of our attention, and in fact moves back and forth between the two"; "We use 'periphery' to name what we are attuned to without attending to explicitly"; the Dangling String: "each bit of information that goes past causes a tiny twitch of the motor … At first it creates a new center of attention just by being unique. But this center soon becomes peripheral". The calm comes from the periphery *carrying information*: designs "encalm and inform".
- Amber Case's principles ([caseorganic.com](https://www.caseorganic.com/post/principles-of-calm-technology)): "Technology should require the smallest possible amount of attention"; "The right amount of technology is the minimum needed to solve the problem".

Implication: decoration without information (b, e, f) is outside the concept; (a), (d), (g) pull to the centre; principles 1 and 7 favour (h).

### 2.4 Breathing pacers

- Resonance breathing: maximum heart-rate oscillation "at approximately 0.1 Hz (six breaths per minute)", refined to "about 0.09 Hz, or 5.5 breaths per minute"; resting breathing "between 0.15 and 0.4 Hz, or 9 to 24 breaths per minute" ([Lehrer & Gevirtz 2014](https://www.frontiersin.org/articles/10.3389/fpsyg.2014.00756/full)). HRV biofeedback lowers self-rated stress and anxiety, g=0.81–0.83 (Goessl et al. 2017, Psychol Med 47:2578; 24 studies, N=484); slow breathing <10/min raises HRV, alpha, comfort ([Zaccaro et al. 2018](https://doi.org/10.3389/fnhum.2018.00353)). All of this is deliberate, trained breathing.
- Pacers during work: a desktop bar paced 20 % below each user's resting rate slowed breathing only while active, by ~1.8 breaths/min ([Moraveji et al. 2011, UIST](https://idl.uw.edu/papers/peripheral-paced-respiration); figure as cited by Gemicioglu 2024; primary-task data UNVERIFIED). Five cue modalities: ~4.8 breaths/min reduction, adherence ~28–30 % of the time, screen-brightness cues cost more workload than audio, haptic or object-animation cues, and "not all changes in respiratory rate lead to lowered stress … or better performance" (Tabor et al. 2021, CHI, as reported by Gemicioglu 2024). BreathePulse (N=23, N-back): time in slow breathing ~70 % with no task, 41.5 % on the easy task, 27.5 % on the hard one; attention predicted adherence; workload rose; current pacers "conceptualize breathing as an explicit task" ([Gemicioglu et al. 2024](https://lab.plopes.org/published/2024-IMWUT-BreathPulse.pdf)). BrightBeat (screen brightness + sound + wrist temperature, N=32, placebo-controlled) slowed breathing and raised self-rated calm and focus (Ghandeharioun & Picard 2017, CHI EA; effect sizes UNVERIFIED). A 5 s breathing light changed no self-rated arousal; EDA lower (N=20, 5 per cell; [Wang et al. 2022](https://pmc.ncbi.nlm.nih.gov/articles/PMC9603525/)).
- No study found in which an *unattended* luminance cycle of a few percent entrains breathing. Every working pacer was visible and followed on purpose, adherence fell under cognitive load, and the studies paced ~20 % below the person's own rate; a fixed 10 s cycle is 40–60 % below typical resting rates.

Implication for (b): invisible → no effect; visible → a pacer that competes with writing, through the costliest modality (brightness). The only defensible form is an explicit, separate breathing mode, which is a new feature with no evidence of need.

### 2.5 Colour temperature and arousal

- 6500 K vs 2500/3000 K at 40 lux for 2 h suppressed melatonin more and sped reaction times ([Chellappa et al. 2011](https://doi.org/10.1371/journal.pone.0016429)); half-maximal melatonin suppression at 24.6 lux, individuals 6–350 lux ([Phillips et al. 2019](https://pmc.ncbi.nlm.nih.gov/articles/PMC6575863)); recommended melanopic EDI: daytime ≥250 lux, evening ≤10, night ≤1 ([Brown et al. 2022](https://doi.org/10.1371/journal.pbio.3001571)); a computer screen gives about 80 lx at the eye in the evening ([Schöllhorn et al. 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC9974389/)).
- Night Shift: every condition suppressed melatonin and the Night Shift settings did not differ; the lab advises dimming as well ([Nagare et al.](https://pmc.ncbi.nlm.nih.gov/articles/PMC6561503), N=12); sleep did not differ between Night Shift on, off or no phone (Duraccio et al. 2021, Sleep Health, N=167).
- Dose (computed): the box is 6.8 % of the screen area (907 × 112 of 1512 × 982 pt) at a mean relative luminance of ~0.005–0.06 (background plus glyph ink), so it emits ≲0.4 % of a full white screen's light: ≲0.3 lx at the eye on the 80 lx figure; a hue drift changes a fraction of that. Two to three orders below the 10 lx evening limit. The 35 % dim changes the screen's total light far more (−35 %).

Implication for (f): physiologically null, perceptually null when gradual: aesthetics only.

### 2.6 Light text on dark, and a dark box on a dimmed screen

- Positive polarity (dark on light) gives smaller pupils and better proofreading: pupil 2.09 vs 3.65 mm (dz=2.96), accuracy dz=0.77, speed dz=0.68, through display luminance (Piepenbrock, Mayr & Buchner 2014, Ergonomics 57; [dissertation](https://docserv.uni-duesseldorf.de/servlets/DerivateServlet/Derivate-31413)); the advantage grows as characters shrink (Piepenbrock et al. 2014, Human Factors), holds for older adults (2013) and whatever the ambient light ([Buchner & Baumgartner 2007](https://doi.org/10.1080/00140130701306413)). At 28 pt Menlo on one line, small-character costs are minimal.
- Lighting standards want the task *brighter* than its surround: EN 12464-1 recommends task : near surround ≤3:1 and task : background ≤10:1 ([Fagerhult summary](https://www.fagerhult.com/knowledge-hub/EN-12464-1/luminance-ratios/ratios-for-working-areas--room-surfaces/)). Here the dimmed surround over a light app is ≈0.65 relative luminance against the box background's 0.0051 (computed): the surround ~130× brighter, the ratio inverted. The surround sets the eye's adaptation, keeps the pupil small (which limits the polarity cost) but scatters glare into the box and raises thresholds for small changes inside it.
- Halation for astigmatic readers on dark backgrounds: only accessibility guidance found, no primary study (weak).

Implication: anything that modulates the background behind the text (b, e) can only lower contrast; and how visible a box effect is depends on what app is behind the dim (§5.4).

### 2.7 Flow, feedback, "juice"

- Flow conditions: "Clear proximal goals and immediate feedback about the progress that is being made" and challenges that "stretch (neither overmatching nor underutilizing) existing skills" (Nakamura & Csikszentmihalyi 2002, Handbook of Positive Psychology pp. 89–105; wording from memory, UNVERIFIED); confirmed text: "Entering flow depends on establishing a balance between perceived action capacities and perceived action opportunities". Meta-analysis: challenge-skill balance, clear goals and sense of control are the robust antecedents; feedback not named (Fong, Zaleski & Leach 2015, J Posit Psychol 10:425; 28 studies).
- In writing the "feedback about progress" is the words appearing, which the line already shows; the click and the physical key already confirm the motor act.
- Juice: players rated the juicy version higher but performed worse (Juul & Begy 2016); curiosity, meaning, immersion rose, performance unchanged ([Hicks et al. 2019](https://doi.org/10.1145/3311350.3347171)); medium juice beat none and extreme (Kao 2020, Entertainment Computing 34; N UNVERIFIED). Only games were tested; Bartram found cues more distracting during a text task than during games.

Implication: (a) and (d) are decoration, not a flow condition.

### 2.8 Typing-rhythm signals

- A pause-tied visual changes writing strongly: text opacity fell "at the rate of 20% per second" of pause and was gone at 5 s; characters per minute 244 vs 203 including deletions, 195 vs 158 kept (p<.001); sentence-initial inter-key interval 320 vs 488 ms, within-word unchanged (122 vs 123 ms); "the most common feeling evoked by the intervention condition by far was 'stressed'"; 70 % felt they sacrificed accuracy (N=20, 10-min essays; [Dux Speltz & Chukharev-Hudilainen 2021, J Writing Res](https://www.jowr.org/jowr/article/view/790); numbers checked in the PDF).
- Removing the visual feedback of one's own text raised execution load only; texts barely changed (Olive & Piolat 2002, Int J Psychol 37). On a flat keyboard visual feedback content (asterisk vs letter) did not change speed (F(1,108)=.05); a beep 51.1, local haptic 55.6, none 43.1, physical keyboard 65.6 wpm ([Kim & Tan 2014](https://microsoft.com/en-us/research/wp-content/uploads/2014/08/C63_JRKimTan_HS2014.pdf)).

Implication for (c): once seen, a rhythm trace is pause pressure: more output, more stress, less accuracy, aimed at the sentence-initial pauses where planning happens. P0 rules pressure out.

### 2.9 Flashing, photosensitivity, vestibular

- WCAG 2.3.1 ([Understanding](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html)): pass with "no more than three general flashes and / or no more than three red flashes within any one-second period", or when the "combined area of flashes occurring concurrently occupies no more than a total of .006 steradians (25% of any 10 degree visual field …)" (≈341 × 256 px at 1024 × 768). A general flash is "a pair of opposing changes in relative luminance of 10% or more of the maximum relative luminance (1.0)" where "the relative luminance of the darker image is below 0.80". 2.3.2 (AAA): no flashing above 3/s at all. (Computed: 0.006 sr ≈ a 5° disc; relative luminance 0.10 above the box background is sRGB grey ≈#5b5b5b.)
- ITU-R BT.1702-3 ([ITU](https://www.itu.int/rec/R-REC-BT.1702)): below 160 cd/m² a flash is a change of ≥20 cd/m²; harmful when >25 % of the screen and >3 flashes/s; flashes whose leading edges are ≥334 ms apart are acceptable at any size.
- Photosensitive epilepsy ~1 in 4,000, most provocative at 15–25 Hz over 1–65 Hz (Fisher et al. reviews, [Essex repository](https://repository.essex.ac.uk/34275/)).
- A per-key glow at 3–8 keys/s is a flash *sequence* by timing (all intervals <334 ms); it passes only by being small (2 em ≈1.3°, 0.0004 sr, computed: 15× under the area limit) and dim (Δ relative luminance <0.1). Keep both caps if anything like it is ever built.
- 2.3.3 (AAA): "Motion animation triggered by interaction can be disabled, unless the animation is essential"; motion animation "does not include changes of color, blurring, or opacity" ([Understanding](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html)); vestibular reactions include "nausea, migraine headaches, and potentially needing bed rest". Vection comes mainly from wide fields (a central 30° failed to induce it in Brandt et al. 1973, contested; [summary](https://asma.kglmeridian.com/downloadpdf/view/journals/amhp/86/9/article-p794.pdf)); a one-line strip is low-risk, though scrolling screens appear among visually induced dizziness triggers ([Frontiers Neurol 2017](https://www.frontiersin.org/journals/neurology/articles/10.3389/fneur.2017.00656/text)).

## 3. The candidates, one by one

Settings: RM = Reduce Motion, RT = Reduce Transparency, IC = Increase Contrast. The brief turns *everything* off under RM; Apple and WCAG would allow colour/opacity changes (a, b, c, f) under RM and require it only for motion (d, g), but the HIG also asks RM to reduce "automatic and repetitive animations", which covers (b) and (f).

**(a) Keystroke glow.** A radial brightening under the caret, decaying ~300 ms.
- For: confirms the key at fixation; brief and precise (the HIG's wording for good feedback).
- Against: at 120–300 ms between keys a 300 ms decay never finishes: while typing it is a steady glow rippling at 3–8 Hz, inside the most flicker-sensitive range, at fixation; HIG "In apps, generally avoid adding motion to UI interactions that occur frequently"; redundant with the physical key and the click (K1), and the emerging glyph is already a per-key visual; juice evidence is games-only and shows liking without performance; brightening under the newest glyph lowers its contrast; Synthwave's authors disown even a static glow for long sessions. Glow is also the vocabulary of Apple's "the system is working" effects (Siri edge glow, Writing Tools), so it may read as machine activity (interpretation, UNVERIFIED).
- Settings: RM off, RT off (translucent layer), IC off; cap Δ relative luminance <0.1 and area ≪0.006 sr.
- Cost: one `CAGradientLayer` (`.radial`) above the band; per key one animation add after the frame is presented; compositing ≈12.5 k px for 300 ms: negligible GPU; main-thread commit tens of µs (UNMEASURED).
- Dim: visible over a dark app behind, faint over a light one.
- Verdict: no.

**(b) Breathing background, 10 s period, a few percent.**
- For: 0.1 Hz is the resonance rate; Apple's Breathe and sleep light show breathing visuals read as calm.
- Against: no evidence of entrainment without attention; visible pacers ask to be followed and lose to a hard task (27.5 % adherence); brightness is the costliest cue modality; HIG (visionOS) warns of sustained oscillation near 0.2 Hz; WCAG 2.2.2 wants a pause control for anything that starts automatically and lasts >5 s; Apple's breathing visuals are the foreground task (Breathe) or an idle state (sleep light), never a background to work; on #0e1013 a few percent is below one 8-bit step (§5.2 rule 4), so drawn naively it becomes a one-step blink twice a cycle; it runs every second of every session (power, ProMotion kept awake).
- Settings: RM off, RT off, IC off, Low Power off, plus its own toggle (2.2.2).
- Cost: one full-box overlay layer (the band is opaque, so it must go above the text) with an infinite `autoreverses` opacity animation at 10–30 Hz: small GPU, but continuous.
- Verdict: no. (A separate, explicit "breathe" pause mode would be a new feature with no evidence of need.)

**(c) Rhythm trace: the dim or the box edge warms while typing continues and cools in pauses.**
- For: the only candidate that carries information, which is what Weiser's calm periphery asks for.
- Against: the information is "you have stopped": Dux Speltz's pause-tied fade made writers faster and "stressed"; the punitive camp (MDWA, Flowstate, Write or Die) uses exactly this signal; P0 says no pressure; the user removed the peripheral progress line and all session counts on 2026-10-28 (M1, "it's not really necessary"), and (c) is a progress line by another name. With slow time constants it is change-blind and does nothing; with fast ones it is a large-area peripheral change (on the dim) or a 1 px border change nobody sees (on the edge).
- Settings: RM off, RT off (tinted scrim), DWC (differentiate without colour) would need a non-colour form.
- Cost: on the border negligible; on the dim it re-composites every screen (5.9 + 3.7 Mpx per frame while it changes), the costliest item here; per key one moving-average update (coalesce to ≤4 Hz).
- Verdict: no; it conflicts with P0 and M1's removal.

**(d) Particles or ink from the caret.**
- Against: travelling motion is the most distracting class (Bartram); every power-mode project turned shake off by default, and users report eye fatigue, discomfort and "it always catch the eye"; particles cross the text the writer just wrote; overheating reports (#124); "novelty wears off".
- Settings: RM off (it is motion under WCAG 2.3.3).
- Cost: `CAEmitterLayer` simulated by Core Animation, `birthRate` pulsed per key; cost scales with particles × lifetime.
- Verdict: no; it is gamification, which the brief excludes.

**(e) Paper/texture noise.**
- Static: zero attention and runtime cost; near black a ±1–2 code-value grain is barely visible and vanishes over a bright surround; it lowers text contrast a little. No evidence that texture calms. Its only real use is technical: dither for gradients near black (the V2 fade, any glow), where 8-bit steps band (the Obsidian plugin's vignette "show[s] steps"). Check the V2 fade for banding on both screens; if it bands, dither it inside `Line.draw` (static noise, cheap) rather than adding an ambience layer.
- Animated grain: continuous redraw and flicker behind the text: no.
- Settings: IC off; RT irrelevant if drawn opaque.
- Verdict: not as ambience.

**(f) Colour temperature drift over the session.**
- Against: physiologically null at the box's dose (§2.5); perceptually null when gradual (change blindness); when noticed (after a pause or on the next summon), the box looks different for no reason; Noisli's drift draws "can't be fixed" complaints; it stacks on Night Shift and True Tone; the text is drawn on the CPU, so tinting it needs either a per-frame redraw or a tint layer over the text.
- Settings: RM off (automatic, repetitive), RT off if done by overlay.
- Cost: a tint layer stepped once a minute with a 2 s animation.
- Verdict: no.

**(g) Faint ripple on Return.**
- For: rare (once per paragraph), at a real boundary, so it does not break "avoid motion on frequent interactions".
- Against: a looming onset captures attention at the moment the writer plans the next paragraph (writers' longest pauses fall at sentence and paragraph starts, §2.1, §2.8); the `¶` glyph already marks the boundary on the line; motion under WCAG 2.3.3.
- Settings: RM off.
- Cost: one `CAShapeLayer` ring, scale and opacity over ~500 ms, per paragraph: negligible.
- Verdict: no. If ever wanted, the smallest version is opacity-only (the `¶` fading from the text colour to `muted` over ~300 ms), not a ring.

**(h) Nothing beyond the glide and the fade.**
- For: §2.1–2.3 and §2.8 together; the field's calm apps ship still visuals and instant dims; HIG motion guidance; Case's minimum principle; zero cost; Reduce Motion already handled (the glide jumps).
- Verdict: yes.

## 4. Apple's own calm visuals, and the rules that bind them

### 4.1 Breathe / Mindfulness (Apple Watch)

- What it is: a blue-green "flower" of overlapping translucent circles that grows while you inhale and shrinks while you exhale; Apple's guide: "inhale slowly as the animation grows, then exhale as it shrinks" ([Apple Watch User Guide](https://support.apple.com/guide/watch/start-a-reflect-or-breathe-session-apd371dfe3d7/watchos)). Colour: "A blue-green mandela graphic slowly emerges on the watchface, expanding and contracting in time to your breath" ([Computerworld 2016](https://www.computerworld.com/article/1686266/wwdc-why-you-ll-use-apple-s-breathe-app.html)).
- Timing: Computerworld (2016, launch coverage): "you inhale for four seconds and exhale for six" and Apple "found that for the best relaxation response the exhale should be longer than the inhale" (a 10 s cycle, 6 breaths/min, 40/60 split). MacRumors (2016, Jay Blahnik): 7 breaths in the 1-min session is "the most comfortable rate for most people", adjustable 4–10 ([MacRumors](https://macrumors.com/2016/06/27/jay-blahnik-discusses-breathe)). The two are not consistent (7/min is an 8.6 s cycle); both are secondhand. Current guide: Breath Rate in breaths per minute, sessions 1–5 min, haptics None / Minimal / Prominent; no default stated. Apple's exact easing curve is not published (UNVERIFIED; recreations use ease-in-out plus a slow rotation).
- Haptics carry the rhythm so it works with eyes closed ([Computerworld](https://www.computerworld.com/article/1686266/wwdc-why-you-ll-use-apple-s-breathe-app.html)); Apple tested with "hundreds" of employees and a mindfulness advisory group ([MacRumors](https://macrumors.com/2016/06/27/jay-blahnik-discusses-breathe)).
- Lesson for Flow: Breathe is the *foreground* task: the user stops everything else and looks at it for 1–5 minutes. It is not an ambient display shown beside a task. Nothing in Apple's design suggests running a breathing animation next to a primary task.

### 4.2 The "breathing" sleep light (Apple patent US 6,658,577 B2)

- Replaced a 40 ms, once-a-second blink with a PWM-driven light that follows "a positively-biased sinusoid function having its maximum at about 25% duty cycle and its minimum at 0%"; "It was determined through experiment that increasing the duty cycle according to a non-linear function gives the most pleasing visual effect while a simple linear ramp does not seem as natural"; a quiet period at zero ("preferred ... about 0.4 second"); "a preferred overall 'breathing' periodicity is about 1.8 seconds"; it "mimics the rhythm of breathing which is psychologically appealing" ([Google Patents](https://patents.google.com/patent/US6658577)).
- The popular claim that the light breathes at the adult rate of 12–20 breaths/min comes from a 2010 blog ([512 Pixels quoting Flood Lite](https://512pixels.net/2010/08/on-sleep-indicators/)), not from the patent, whose preferred period (1.8 s, ≈33/min) is faster. Shipped rates over the years are UNVERIFIED. The AirPods Pro case light reportedly runs at 28/min ([Unsung](https://unsung.aresluna.org/shallow-breathing)).
- Lessons: (1) a sinusoid with a rest at the bottom reads as calm, a linear ramp does not; (2) the sleep light is a *status* signal of an idle device seen when nobody is working; it does not compete with a task.

### 4.3 Human Interface Guidelines (fetched 2026-10-28)

Motion ([HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion)):
- "Don't add motion for the sake of adding motion. Gratuitous or excessive animation can distract people and may make them feel disconnected or physically uncomfortable."
- "Make motion optional. ... avoid using it as the only way to communicate important information."
- "Aim for brevity and precision in feedback animations. When animated feedback is brief and precise, it tends to feel lightweight and unobtrusive."
- "In apps, generally avoid adding motion to UI interactions that occur frequently. ... you generally want to avoid making people spend extra time paying attention to unnecessary motion every time they interact with it." Typing is the most frequent interaction there is.
- visionOS (immersive, but the physiology is the same): "People can be particularly sensitive to motion that occurs in their peripheral vision: in addition to being distracting, such motion can even cause discomfort"; "Avoid showing objects that oscillate in a sustained way. In particular, you want to avoid showing an oscillation that has a frequency of around 0.2 Hz because people can be very sensitive to this frequency. If you need to show objects oscillating, aim to keep the amplitude low." (0.2 Hz = a 5 s period, i.e. breathing pace; the guidance is about moving objects and vection, not luminance.)

Accessibility ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)):
- "Be cautious with fast-moving and blinking animations. When you use these effects in excess, it can be distracting, cause dizziness, and in some cases even result in epileptic episodes. ... When [Reduce Motion] is active, ensure your app or game responds by reducing automatic and repetitive animations, including zooming, scaling, and peripheral motion." Listed practices include "Replacing transitions in x-, y-, and z-axes with fades" and "Avoiding animating into and out of blurs".
- Contrast: HIG Dark Mode: "make sure the contrast ratio between colors is no lower than 4.5:1. For custom foreground and background colors, strive for a contrast ratio of 7:1, especially in small text" ([HIG Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)). Flow today: text #d8dce3 on #0e1013 is 13.9:1, caret #7aa7f0 7.8:1, muted #5c646f 3.2:1 (computed here, WCAG formula).
- Feedback: "The most effective feedback tends to match the significance of the information to the way it's delivered"; watchOS: "An animated indicator can make people think they need to continue paying attention to the display" ([HIG Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback)).

macOS settings (Mac User Guide, macOS 26: [Motion](https://support.apple.com/en-mo/guide/mac-help/change-motion-settings-for-accessibility-mchla3c4f1da/26/mac/26), [Display](https://support.apple.com/guide/mac-help/change-display-settings-for-accessibility-unac089/mac)):
- Reduce motion: "Customize the movement of elements on the screen—for example, when you open apps, switch between desktops, or open and close Notification Center." API `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (macOS 10.12).
- Reduce transparency: "Replace the transparent effect used on some backgrounds in macOS with a solid background". API `accessibilityDisplayShouldReduceTransparency` (10.10).
- Increase contrast: `accessibilityDisplayShouldIncreaseContrast` (10.10). Differentiate without colour: `accessibilityDisplayShouldDifferentiateWithoutColor` (10.10).
- Changes post `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` on `NSWorkspace.shared.notificationCenter` (10.10) [Apple docs](https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayoptionsdidchangenotification).
- Dim flashing lights: "For compatible media, automatically dim the display of content that depicts flashing or strobing lights" (Apple silicon only); API `MADimFlashingLightsEnabled()` (macOS 13.3) [Apple docs](https://developer.apple.com/documentation/mediaaccessibility/madimflashinglightsenabled()). Meant for video; a calm app can still treat it as one more "off".
- Prefer non-blinking cursor: "Stop the blinking of the vertical bar that appears at the insertion point". Flow's caret already never blinks (steady #7aa7f0 bar).
- Auto-play animated images: "Turn off to automatically pause the display of rapid animated images". (No public AppKit getter found for this one; UNVERIFIED.)
- Low Power Mode: `ProcessInfo.processInfo.isLowPowerModeEnabled` (macOS 12) — a reason to pause any continuous effect.

### 4.4 WCAG 2.2 (web rules, but the only numeric standard)

- 2.3.1 Three Flashes or Below Threshold (A): nothing flashes more than 3 times in any 1 s, or the flash is below the general and red flash thresholds. (Numbers: §2.9.)
- 2.2.2 Pause, Stop, Hide (A): "For any moving, blinking or scrolling information that (1) starts automatically, (2) lasts more than five seconds, and (3) is presented in parallel with other content, there is a mechanism for the user to pause, stop, or hide it"; "'Blinking' refers to content that causes a distraction problem" ([Understanding 2.2.2](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)). A breathing background (b) or a session-long drift (f) is exactly this case: it needs an off switch beyond Reduce Motion.
- 2.3.3 Animation from Interactions (AAA): "Motion animation triggered by interaction can be disabled"; motion animation "does not include changes of color, blurring, or opacity which do not change the perceived size, shape, or position of the element" ([Understanding 2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html); its errata reportedly drops the blur exclusion). So (a) glow, (b), (c), (f) are colour/opacity changes, not "motion" under WCAG; (d) particles and (g) ripple are motion. The brief here (Reduce Motion turns off everything) is stricter than both WCAG and Apple, which accept fades under Reduce Motion.

## 5. Building any of it without touching the key path

### 5.1 What the app does today (read from `app/Sources`, 2026-10-28)

- The line's band is a `CAMetalLayer` (`Strip.swift`): opaque, `bgra8Unorm`, sRGB, `maximumDrawableCount = 2`. Each frame Core Graphics draws the whole band on the CPU into a shared `MTLBuffer`, and a blit copies it into the drawable. The key handler draws a frame itself (draw-on-key); a `CADisplayLink` (80–120 Hz, preferred 120) draws the glide frames and is paused whenever nothing glides (`LineView.swift`).
- The box (`Box.swift`): non-activating `NSPanel`, `alphaValue` 0.97, content layer #0e1013, 10 pt corners, 1 px border #262b32, system shadow; at 28 pt Menlo it is 4 × 28 = 112 pt tall and 60 % of the visible width (≈907 pt on a 1512 pt-wide built-in screen: 1814 × 224 px ≈ 0.41 Mpx at 2×).
- The dim: one borderless black `NSWindow` per screen at `alphaValue` 0.35, one level below the box, ignoring the mouse, on and off at once (no fade). A 3024 × 1964 built-in screen is 5.9 Mpx, a 2560 × 1440 external 3.7 Mpx.
- The caret is a steady bar (#7aa7f0), never blinking. Reduce Motion is read on each edit (`accessibilityDisplayShouldReduceMotion`) and turns the glide into a jump. Nothing reads Reduce Transparency or Increase Contrast yet (the box's 0.97 alpha would be the first thing Reduce Transparency should set to 1; noted, not an ambience item).

### 5.2 Rules any effect has to follow

1. **Never in `Line.draw`, never on the display link.** The band is redrawn on the CPU on the main thread; an effect drawn there adds CPU time to every key's frame and, if it moves on its own, keeps the display link (and the main thread) busy at 120 Hz for as long as it runs: the one thing the T2 spike tuned away. Put each effect in its own `CALayer` and animate it with Core Animation (`CABasicAnimation`/`CAKeyframeAnimation`), which interpolates off the main thread (Lottie's maintainers on its Core Animation engine: "Once animations begin playing, they do not consume any of the app's CPU resources" and they "render out-of-process", while their main-thread engine "would not update when the main thread was busy" ([lottie-ios #1627](https://github.com/airbnb/lottie-ios/discussions/1627), iOS context); on macOS the process that interpolates is UNVERIFIED, but the main thread is not it).
2. **The key path only sets a target.** A per-key effect adds one implicit `CATransaction` (an `add(_:forKey:)` on a small layer) after `render(at:)` has presented, so the glyph's frame is not delayed; the commit itself is on the main thread (tens of µs expected, UNMEASURED: wrap it in an `os_signpost` and compare key→present p50/p90 with the spike's harness before keeping it). Never wait on it, never read the presentation layer on the key path.
3. **The opaque band blocks anything below it.** A glow or breathing layer under the band is invisible in the band's 2 em strip; it has to sit *above* the band (and so over the text, which it then tints), or the band has to become non-opaque (blending, and Core Graphics text drawn into a transparent bitmap loses its font-smoothing look: UNVERIFIED for this font and size). The code already avoids a background a touch lighter than the band because "it would show the band as a stripe" (`Box.swift`): any background modulation must cover band and margins alike.
4. **8 bits are too coarse near black.** On #0e1013 one 8-bit code value is a +8.8 % step in luminance (computed: sRGB 14 → 15 is linear 0.00439 → 0.00478). A "few percent" breathing cycle drawn into the 8-bit band cannot be smooth: it is either nothing or a one-step jump (a blink) twice per cycle. An overlay layer animated by Core Animation is composited by the window server, possibly at higher precision and with the Apple-silicon display pipe's temporal dithering ([Stillcolor](https://github.com/aiaf/Stillcolor), community source; UNVERIFIED). Test on both screens before trusting a low-amplitude effect; `rgba16Float`/`bgr10a2Unorm` for the band is the other way.
5. **Ask for few frames.** `CAAnimation.preferredFrameRateRange` (macOS 12) lets a slow effect run at 10–30 Hz; a 10 s breath needs no 120 Hz. Apple: "Use lower frame rates for animations whenever possible" ([Energy Efficiency Guide for iOS](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/AvoidExtraneousGraphicsAndAnimations.html)); "Extraneous or inefficient drawing can pull system resources out of low-power states or prevent them from powering down all together"; "If you need to use opacity, avoid using it over content that changes frequently" ([Energy Efficiency Guide for Mac Apps](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/UsingEfficientGraphics.html)). A ProMotion panel lowers its refresh for static content and "so reduces its power consumption" ([WWDC21 10147](https://developer.apple.com/videos/play/wwdc2021/10147/), iPad wording); a perpetual animation keeps it up.
6. **One switchboard.** Read Reduce Motion, Reduce Transparency, Increase Contrast and Low Power Mode once, refresh on `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` (on `NSWorkspace.shared.notificationCenter`) and `NSProcessInfoPowerStateDidChange`, and remove the effect's animations (`removeAllAnimations`, layer hidden) at once, not at the next session. Stop every continuous animation while the box is hidden (the panel is ordered out; Core Animation does not composite it, but the app should not keep adding animations).
7. **Precedent for the cost of a "tiny" perpetual effect:** in 2017 VS Code's blinking cursor, a CSS animation Chromium ran at 60 fps, used ~13 % CPU while idle; the fix was a non-animated cursor ([The Register](https://www.theregister.com/2017/03/23/cursor_devours_cpu_cycles_ms_code_editor/)). Different engine, same lesson: a continuous effect is paid for every frame, for the whole session.

### 5.3 Per candidate: layer, API, cost (estimates, not measured)

| | How | Per-key main-thread work | GPU / compositor while active | Runs when idle? |
|---|---|---|---|---|
| (a) glow | `CAGradientLayer` (`.radial`), ~2 em (≈112 px) square at the caret, above the band; opacity keyframe peak → 0 over 300 ms, ease-out | one animation add per key | composite ≈12.5 k px per frame for 300 ms after each key: negligible | no |
| (b) breathing | one full-box layer above the band, black or white at 0–3 % opacity; `CABasicAnimation` opacity, `autoreverses`, 5 s each way, `repeatCount = .infinity`, ease-in-ease-out (≈ sinusoid), frame range 10–30 Hz | none | re-composite the box (0.41 Mpx) at the chosen rate, the whole session | yes, always: power cost every second |
| (c) rhythm trace on the box border | `borderColor` of the content layer (1 px), target from a key-rate average computed on the key event, animated over 2–4 s; a cool-down animation that starts after N s idle | one average update + replace animation per key, or coalesce to ≤4 Hz | border only: negligible | while cooling |
| (c′) rhythm trace on the dim | `backgroundColor` of each dim window's layer (tint black → very dark amber) | as (c) | re-composite every screen: 5.9 + 3.7 Mpx per frame while changing, the most expensive item here | while cooling |
| (d) particles | `CAEmitterLayer` at the caret, `birthRate` raised for one frame per key; simulated by Core Animation | one property set per key | scales with particle count × lifetime; overdraw over the text | while particles live |
| (e) texture, static | a pre-rendered grey noise tile (±1–2 code values) as `contents` of a layer, or drawn once into the band's background | none | composited with the box, no extra frames | no |
| (e′) texture, animated grain | new noise per frame | none | full box redraw at 24–60 Hz: flicker | yes: reject |
| (f) colour drift | a tint layer stepped once a minute with a 2 s animation (not one 30-minute animation, whose per-frame cost is UNVERIFIED) | none | the box re-composited during each 2 s step | in steps |
| (g) ripple on Return | `CAShapeLayer` ring from the caret, scale 1 → 3 and opacity 0.3 → 0 over ~500 ms | one animation per paragraph | small region, ~0.5 s | no |
| (h) nothing | — | — | — | — |

### 5.4 How the dim changes what any box effect looks like

- The dim passes 65 % of the screen behind it. Over a light app the surround is ≈0.65 relative luminance; the box background is 0.0051: about 130 times darker. The eye adapts to the large bright surround, which raises the threshold for small changes inside the dark box, so a few-percent box effect that is visible over a dark app behind can vanish over a light one. The same effect will look different depending on what is behind the box: a consistency problem for (a), (b), (e), (f).
- Effects *on the dim* (c′, a tinted or breathing scrim) change the luminance of most of the visual field. Over white, alpha 0.35 → 0.40 moves the surround from 0.65 to 0.60: a 0.05 change in relative luminance over the whole screen. Below WCAG's 0.1 flash threshold, and slow, so not a seizure risk; but it is a large-area change in the periphery, the textbook trigger for attention capture if it is fast, and invisible (change blindness) if it is slow enough not to be.
- Night Shift and True Tone already shift the whole display's colour; (f) would stack on them inside the box only.

## 6. Findings outside the question (for the user's decision; nothing here changes a pick)

### 6.1 The glide is the largest motion in the design

- At ~240 ms between keys a 140 ms glide keeps the line moving ~58 % of the typing time (computed). Bartram ranks travelling motion the most distracting; Maglio & Campbell found continuous motion worse than discrete.
- Comparable tools: VS Code smooth caret 80 ms (off by default, typing excluded); Monkeytype caret 100 ms default; keybr 100 ms linear, cancelled by the next key; Neovide 150 ms but 40 ms for short moves; Monkeytype's tape mode, the closest precedent (fixed caret, text scrolls), scrolls **instantly by default** and animates 125 ms only on opt-in. Users read animated caret or text position as lag ("it doesn't render the character until the cursor arrives").
- Against transferring that evidence: the glide is at fixation, caused by the writer's own key and fully predictable, while the ticker and moticon studies used peripheral motion the participant did not cause. Flow already applies two of the field's fixes: the leftover is capped at one advance (no runaway trail), and the key draws its own frame. The easing is a cubic ease-out (`Line.ease`), so the new glyph is ~17 % out from under the caret on the first 120 Hz frame, 49 % at 28 ms and 88 % at 70 ms (computed); the last half of the 140 ms is a slow tail.
- The user picked S1 after seeing it in the spike. If the question is ever reopened, the cheap test is a shorter glide for single-character steps (Neovide's 40 ms idea; ~60–80 ms) against 140 ms, judged by feel and by the session's pause data, not by this evidence.

### 6.2 The box is far darker than its surround

- Over a light app the dimmed surround is ~130× brighter than the box background (§2.6); lighting standards want the task brighter than the surround (EN 12464-1: ≤3:1 near, ≤10:1 background). Effects in the box are therefore hostage to what is behind it (§5.4). A deeper dim (e.g. alpha 0.5–0.6) or a lighter box narrows the gap at zero runtime cost but hides the target app more. No study tests this setup; taste plus a lighting standard, for the user to try.

### 6.3 Settings the app does not read yet

- Reduce Transparency: the box's `alphaValue` 0.97 should be 1 under it (the HIG wording: replace transparent backgrounds with solid ones). Increase Contrast: `muted` #5c646f on #0e1013 is 3.2:1, under the HIG's 4.5:1 minimum; raise it under Increase Contrast if `muted` carries anything the writer must read (the V2 fade itself is intentionally sub-threshold context). Both are small fixes, not ambience.

## 7. Open, unverified, and what would change the verdict

What would reopen the question: a reported lack, e.g. "I can't tell whether a key landed" (then check the click and glyph emergence first) or "the box feels dead" (then a static colour theme or texture, no motion, is the smallest answer). None has been reported.

Checks worth running only if an effect is ever built:
1. Key → present p50/p90 with the effect's layer present (the spike's harness; `os_signpost` around the transaction).
2. A 3 % opacity overlay animated slowly on the box, on both screens: smooth, or stepping by one code value?
3. The V2 fade on #0e1013 for banding on the external 8-bit screen.
4. Energy: Activity Monitor's Energy Impact or `powermetrics --samplers gpu_power` with the box up and idle, effect on vs off.

UNVERIFIED (could not check against the primary): Apple's Breathe easing curve and default rate (4 s / 6 s in one 2016 report vs 7 breaths per minute in another); shipped sleep-light rates (the patent prefers a 1.8 s period; the 12–20/min claim is a blog's); which process interpolates Core Animation on macOS; window-server compositing precision and Apple-silicon temporal dithering; the per-frame cost of very slow CA animations; no public AppKit getter found for "Auto-play animated images"; per-condition numbers in Simons et al. 2000; Yantis & Jonides search slopes; a measured threshold at 0.1 Hz and Weber fractions at 1–3 cd/m²; Moraveji 2011's primary-task data; BrightBeat effect sizes; Kao 2020's N; the exact wording of Nakamura & Csikszentmihalyi's conditions; Dhakal 2018's means; Chenoweth & Hayes's page for the 2 s rule; OmmWriter's colour-movement speed; iA Writer's dim transition; Write or Die's timings; Cold Turkey Writer's progress indicator; Hanx Writer details.

## Key sources

- Abrams & Christ 2003, Psych Sci 14:427 — https://pubmed.ncbi.nlm.nih.gov/12930472/
- Apple HIG: Motion, Accessibility, Dark Mode, Feedback — https://developer.apple.com/design/human-interface-guidelines/motion · …/accessibility · …/dark-mode · …/feedback (fetched as JSON 2026-10-28)
- Apple, Breathing status LED indicator, US 6,658,577 B2 — https://patents.google.com/patent/US6658577
- Apple Watch User Guide, Breathe — https://support.apple.com/guide/watch/start-a-reflect-or-breathe-session-apd371dfe3d7/watchos
- Bartram, Ware & Calvert 2003, IJHCS 58:515 — https://www.interruptions.net/literature/Bartram-IJHCS03.pdf
- Buchner & Baumgartner 2007, Ergonomics 50 — https://doi.org/10.1080/00140130701306413
- Burke et al. 2005, ToCHI — https://thoughtcrumbs.com/publications/ToCHI04.pdf
- Dux Speltz & Chukharev-Hudilainen 2021, J Writing Res — https://www.jowr.org/jowr/article/view/790
- Gemicioglu et al. 2024, BreathePulse, IMWUT 8(4) — https://lab.plopes.org/published/2024-IMWUT-BreathPulse.pdf
- Kelly 1961, JOSA 51:422 — https://www.doi.org/10.1364/JOSA.51.000422
- Lehrer & Gevirtz 2014 — https://www.frontiersin.org/articles/10.3389/fpsyg.2014.00756/full
- Maglio & Campbell 2000, CHI — https://www.interruptions.net/literature/Maglio-CHI00-p241-maglio.pdf
- McCrickard et al. 2003, IJHCS 58:547 — https://people.cs.vt.edu/mccricks/papers/mccs03.pdf
- Moraveji et al. 2011, UIST — https://idl.uw.edu/papers/peripheral-paced-respiration
- Pousman & Stasko 2006, AVI — https://faculty.cc.gatech.edu/~stasko/papers/avi06.pdf
- Simons, Franconeri & Reimer 2000, Perception 29:1143 — https://doi.org/10.1068/p3104
- Weiser & Brown 1995/96 — https://calmtech.com/papers/designing-calm-technology
- WCAG 2.2 Understanding 2.2.2, 2.3.1, 2.3.3 — https://www.w3.org/WAI/WCAG22/Understanding/
- ITU-R BT.1702 — https://www.itu.int/rec/R-REC-BT.1702
- Yantis & Jonides 1984, JEP:HPP 10:601 — https://doi.org/10.1037/0096-1523.10.5.601
- Tool sources (repos, docs, issues, reviews): inline in §1.
