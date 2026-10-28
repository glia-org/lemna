# Sibling apps: shared visual and motion language (2026-10-28)

the terminal app is the source. the brief app's face (Rust and GPUI) reads the terminal app's theme through glia-core and copies the terminal app's motion constants. It adds a softer card layer of its own. Paths are relative to each repo root.

## Shared tokens

| Token | Value | Source |
|---|---|---|
| Background | Tokyo Night #1A1B26 | app-a/crates/glia-core/src/theme.rs:107 |
| Raised surface | background shifted 4 % toward the foreground (#16161E in the design table) | theme.rs:84, glia/DESIGN.md §12 |
| Foreground (text.hi) | #C0CAF5 | glia/DESIGN.md §12 |
| Muted (text.mid / text.low) | #A9B1D6 / #7F88B2, corrected to 4.5:1 contrast | glia/DESIGN.md §12 |
| Accent | ANSI blue #7AA2F7 | theme.rs:112 |
| Border (line) | background mixed 25 % toward the foreground (#3B4261) | theme.rs:86 |
| Selection | background mixed 25 % toward the accent (#283457) | theme.rs:89 |
| Status colours | working #E0AF68, needs #F7768E, done #9ECE6A, idle #6B7399 | glia/DESIGN.md §12 |
| Dim strength | terminal text at 0.66 opacity; overlays dim to 0.3 | glia-ui/src/terminal/element.rs:29, glia-app/src/window/overview.rs:441 |
| Radii | the terminal app 0, no rounded corners. the brief app 8 pt cards, 3 pt chips | glia/DESIGN.md §12 rule 2, tanycyte/face/README.md, face/src/view.rs:357 |
| Font | the terminal app: one mono font for all chrome, 13 px, terminal cells. the brief app: system face for prose, mono 11 for data | tanycyte/face/src/theme.rs:11-16 |
| Lines | 1 px (1 pt in the brief app), pixel-snapped quads | glia/DESIGN.md §12 rule 3 |

Other shipped schemes: Catppuccin Mocha and Latte, Gruvbox, Everforest, Kanagawa, Nord, Rose Pine, Graphite. A theme change restyles everything at once. Light or dark follows the window.

## Motions

| Name | Trigger | Duration | Curve | What it shows | Source |
|---|---|---|---|---|---|
| Glide | layout change: canvas/tiles switch, pane open/close, zoom | 140 ms | ease-out cubic, 1−(1−t)³ | where a pane came from or went | glia-ui/src/canvas/transition.rs:14,116 |
| Push | focus moved behind a zoom | 140 ms, travel 1/8 of the area (PUSH_TRAVEL), with a fade | ease-out cubic | direction of the move | glia-ui/src/canvas/mod.rs:34,592 |
| Overlay dim | minimap, navigator or zoom overview goes to rest | 140 ms, opaque to 0.3 | ease-out cubic | recedes; brightening is instant | glia-app/src/window/overview.rs:441 |
| Jump flash | scroll to a line | hold 1000 ms, then fade 140 ms | n/a | the target line | glia-ui/src/terminal/results.rs:87-89 |
| Scroll snap | scroll comes to rest near a prompt | 120 ms quiet before it settles | n/a | settles on the prompt | glia-ui/src/terminal/pane.rs:68 |
| Cursor blink | status cue | 530 ms half-period; runs even under reduced motion | n/a | the working state | pane.rs:43 |
| Stagger on open | brief opens | 180 ms each, 40 ms apart, 8 px rise, fade | ease-out cubic | sections arrive in reading order | tanycyte/face/src/motion.rs:17-19 |
| Hover lift | pointer over a card | 150 ms; rises 2 pt, line brightens, shadow grows, picture comes up from 84 % | ease-out | what is under the pointer | motion.rs:21, face/README.md |
| Fold | dropped row | 160 ms | ease-out | row closes | motion.rs:13 |
| Key scroll, lanes drawing in | key press, open | 200 ms | ease-out | position change | motion.rs:15 |
| Picture fade-in | image load ends | 200 ms | ease-out | content arrived | face/src/pictures.rs:20 |
| Card grow | open a paper | spring, 320 ms period, no overshoot | spring | row becomes card | motion.rs:23 |
| Strip dot pulse | brain running | 1200 ms breath, opacity 0.3 to 1 | cosine | work in progress | motion.rs:25,80 |
| Strip flash | brief composed | 1000 ms | n/a | the brief is in | motion.rs:27 |

the brief app's ease() is a copy of the terminal app's cubic (motion.rs:30).

## Stated rules

- Motion only with a function (glia/CLAUDE.md, interface rule 2): an animation shows where something came from or went, or keeps an unnoticed change in view. Never draws the eye to something the user did not act on; never decoration.
- A change that needs no explanation happens at once. When in doubt, no animation.
- Reuse the existing motions (the 140 ms ease-out glide, the push of an eighth with a fade) instead of adding new ones.
- Reduced motion turns them all off ([appearance] reduced_motion; unset follows macOS). the brief app makes each tween a zero-duration step (motion.rs:49).
- A press during a glide jumps it to its end state. Overlays brighten at once and dim slowly. Drops land at once.
- Status is a glyph plus a colour, never colour alone. Nothing moves at rest (the brief app).

## Omarchy-like traits already present

- the terminal app: a single mono font and flat, quiet chrome; square 1 px tiled frames with a small gap (half a cell); a focused border takes the accent, its title on an accent block; a working pane gets a second 1 px inner line in the status colour; one-row status line; theme = terminal colour scheme, a theme change restyles everything.
- Absent in the terminal app by rule: "No shadows, blur, gradients or rounded corners" (DESIGN.md §12 rule 2). Widgets use radius 0.
- the brief app departs: 8 pt rounded cards, a card shadow that grows on hover, a 2 pt lift, a two-tone wash on typographic tiles in the profile's hue. Pictures on an off-white plate (#F1F3F6) at 84 % under a window-coloured overlay. No glow or blur in either app.
- Gaps for Lemna: glow, blur and gradient are in neither sibling. Matching them means the shared theme roles, a 140 ms ease-out cubic, a 1/8 push, 0.3 dim, and reduced-motion support; the effects themselves would be new.
