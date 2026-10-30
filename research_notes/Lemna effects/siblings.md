# Sibling apps: shared visual and motion language (2026-10-28)

App A (the terminal app) is the source. App B's face (the brief app; Rust and GPUI) reads app A's theme through app A's core crate and copies app A's motion constants. It adds a softer card layer of its own. Sources are named by what they are, not by path.

## Shared tokens

| Token | Value | Source |
|---|---|---|
| Background | Tokyo Night #1A1B26 | app A's theme source |
| Raised surface | background shifted 4 % toward the foreground (#16161E in the design table) | app A's theme source and design spec |
| Foreground (text.hi) | #C0CAF5 | app A's design spec |
| Muted (text.mid / text.low) | #A9B1D6 / #7F88B2, corrected to 4.5:1 contrast | app A's design spec |
| Accent | ANSI blue #7AA2F7 | app A's theme source |
| Border (line) | background mixed 25 % toward the foreground (#3B4261) | app A's theme source |
| Selection | background mixed 25 % toward the accent (#283457) | app A's theme source |
| Status colours | working #E0AF68, needs #F7768E, done #9ECE6A, idle #6B7399 | app A's design spec |
| Dim strength | terminal text at 0.66 opacity; overlays dim to 0.3 | app A's terminal view and overview source |
| Radii | App A 0, no rounded corners. App B 8 pt cards, 3 pt chips | app A's design spec, app B's README and view source |
| Font | App A: one mono font for all chrome, 13 px, terminal cells. App B: system face for prose, mono 11 for data | app B's theme source |
| Lines | 1 px (1 pt in app B), pixel-snapped quads | app A's design spec |

Other shipped schemes: Catppuccin Mocha and Latte, Gruvbox, Everforest, Kanagawa, Nord, Rose Pine, Graphite. A theme change restyles everything at once. Light or dark follows the window.

## Motions

| Name | Trigger | Duration | Curve | What it shows | Source |
|---|---|---|---|---|---|
| Glide | layout change: canvas/tiles switch, pane open/close, zoom | 140 ms | ease-out cubic, 1−(1−t)³ | where a pane came from or went | app A's canvas transition source |
| Push | focus moved behind a zoom | 140 ms, travel 1/8 of the area (PUSH_TRAVEL), with a fade | ease-out cubic | direction of the move | app A's canvas source |
| Overlay dim | minimap, navigator or zoom overview goes to rest | 140 ms, opaque to 0.3 | ease-out cubic | recedes; brightening is instant | app A's overview source |
| Jump flash | scroll to a line | hold 1000 ms, then fade 140 ms | n/a | the target line | app A's terminal results source |
| Scroll snap | scroll comes to rest near a prompt | 120 ms quiet before it settles | n/a | settles on the prompt | app A's pane source |
| Cursor blink | status cue | 530 ms half-period; runs even under reduced motion | n/a | the working state | app A's pane source |
| Stagger on open | brief opens | 180 ms each, 40 ms apart, 8 px rise, fade | ease-out cubic | sections arrive in reading order | app B's motion source |
| Hover lift | pointer over a card | 150 ms; rises 2 pt, line brightens, shadow grows, picture comes up from 84 % | ease-out | what is under the pointer | app B's motion source and README |
| Fold | dropped row | 160 ms | ease-out | row closes | app B's motion source |
| Key scroll, lanes drawing in | key press, open | 200 ms | ease-out | position change | app B's motion source |
| Picture fade-in | image load ends | 200 ms | ease-out | content arrived | app B's picture source |
| Card grow | open a paper | spring, 320 ms period, no overshoot | spring | row becomes card | app B's motion source |
| Strip dot pulse | brain running | 1200 ms breath, opacity 0.3 to 1 | cosine | work in progress | app B's motion source |
| Strip flash | brief composed | 1000 ms | n/a | the brief is in | app B's motion source |

App B's ease() is a copy of app A's cubic.

## Stated rules

- Motion only with a function (app A's interface rule 2): an animation shows where something came from or went, or keeps an unnoticed change in view. Never draws the eye to something the user did not act on; never decoration.
- A change that needs no explanation happens at once. When in doubt, no animation.
- Reuse the existing motions (the 140 ms ease-out glide, the push of an eighth with a fade) instead of adding new ones.
- Reduced motion turns them all off ([appearance] reduced_motion; unset follows macOS). App B makes each tween a zero-duration step.
- A press during a glide jumps it to its end state. Overlays brighten at once and dim slowly. Drops land at once.
- Status is a glyph plus a colour, never colour alone. Nothing moves at rest (app B).

## Omarchy-like traits already present

- App A: a single mono font and flat, quiet chrome; square 1 px tiled frames with a small gap (half a cell); a focused border takes the accent, its title on an accent block; a working pane gets a second 1 px inner line in the status colour; one-row status line; theme = terminal colour scheme, a theme change restyles everything.
- Absent in app A by rule: "No shadows, blur, gradients or rounded corners" (its design spec). Widgets use radius 0.
- App B departs: 8 pt rounded cards, a card shadow that grows on hover, a 2 pt lift, a two-tone wash on typographic tiles in the profile's hue. Pictures on an off-white plate (#F1F3F6) at 84 % under a window-coloured overlay. No glow or blur in either app.
- Gaps for Lemna: glow, blur and gradient are in neither sibling. Matching them means the shared theme roles, a 140 ms ease-out cubic, a 1/8 push, 0.3 dim, and reduced-motion support; the effects themselves would be new.
