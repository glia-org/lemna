# Omarchy: its visual and motion language, for Lemna (as of 2026-10-28)

Question: what exactly gives Omarchy its look and its motion, in numbers precise enough that a macOS app can borrow the feel, and which of it is tied to text and keys? Omarchy is DHH's opinionated Arch Linux + Hyprland setup. The repo `github.com/basecamp/omarchy` now redirects to `github.com/omacom/omarchy`.

Every value below comes from the repo's files at the commits in §1 unless it is marked otherwise. "Unverified" means I did not check it against a primary source.

## Takeaway

1. **Omarchy's window motion is mostly Hyprland's stock example config with three edits.** The curves, the `popin 87%` window pop and the cyan→green 45° gradient border are Hyprland's own defaults. Omarchy changed three things: square corners (rounding 0), tighter gaps (5/10), and no workspace animation at all. Workspace switching, the most frequent keyboard action, has been instant since the first version.
2. **One curve now runs everything.** Today (2026-10-28, commit 9333e19, on `quattro`, in no release yet) DHH put Hyprland under the shell's motion rules. One strong ease-out, `cubic-bezier(0.23, 1, 0.32, 1)` (Hyprland calls it `easeOutQuint`), for every leaf. Entrances take 250 ms, exits about two thirds of that (160 ms), the border colour 150 ms, fades 180 ms in and 120 ms out, windows pop from 95 %. No linear, no ease-in, no bounce, nothing over 300 ms. Until that commit (v1 through v4.0.6) the set was global 1000, border 539, windows 379, windowsIn 410 from 87 %, windowsOut 149 linear, fadeIn/Out 173/146, fade 303, layers/In/Out 381/400/150 ms, on the mixed curves in §2.3.
3. **The rules are written down, and they say: never animate a keystroke that acts and is done.** `agents/skills/motion.md` (2026-10-24), adapted from Emil Kowalski's animation skills, has three rules on this. Things opened by a single keystroke many times a day have no open or close motion: the menu, the launcher, the clipboard, the OSD. Keyboard dismissals jump. Every duration goes through `Style.duration(ms)`, which returns 0 when animations are off. The exception: *inside something the user stays and watches*, keys get the same motion as the pointer.
4. **Nothing in Omarchy animates per keystroke.** Every terminal has a block cursor, no blink and no trail. Neovim's smooth scrolling is turned **off**. Omarchy's own writing app, Omawrite, has a static 1 px caret and no typing motion. The lock screen's dots appear at once. The only behaviour tied to typing is that the mouse pointer hides on a key press. Omarchy's text effects (the 37 ttfx/TTE effects in the screensaver, the sheen across the About logo) all run while the user is *not* typing, and the first key ends them at once.
5. **The "glow" is a border, not light.** By default it is a 2 px border: the cyan→green gradient `rgba(33ccffee) → rgba(00ff99ee)` at 45° on Tokyo Night until Jan 2026 (v3.2), the theme's accent since then. The only real glows are themes with a coloured shadow (Lumon: `#6fb8e3`, range 16 then 6, power 4) and the Hackerman green gradient. The border angle never loops. Blur and shadows were on (blur size 2, passes 2, brightness 0.60, contrast 0.75; a dark 2 px shadow) and were **switched off by default on 2026-07-13**: "It's adding so little visual flair and is a source of GPU load". They are now an opt-in "Glassy" toggle (blur size 4, passes 2, brightness 0.75, vibrancy 0.35, noise 0.01).
6. **The default theme is Tokyo Night:** background `#1a1b26`, foreground `#a9b1d6`, cursor and bright text `#c0caf5`, accent and active border `#7aa2f7`, selection `#292e42`, muted `#414868`, inactive border `rgba(595959aa)`. Up to v3.2 it also had cyan `#33ccff` borders on notifications, launcher and OSD.
7. **Tension with Lemna.** The request for typing-dependent effects runs against Lemna's own F0 pick of today, and against Omarchy's written rules (§8). Omarchy's idiom suggests something else: still surfaces and a single sharp ease-out, with motion only where it shows where something went. Lemna's glide fits that exception. Three cheap ways to borrow the feel: Omarchy's curve for the glide (90 % of the distance in 50 ms instead of 75 ms), event-tied effects instead of per-key ones, and effects on the box's own CALayers, off the main thread.

## 1. Versions read and method

| Line | Ref | Commit | Date | Notes |
|---|---|---|---|---|
| Current default branch `quattro` (Omarchy 4 line; `version` file says `4.0.0.alpha`) | HEAD | 79dcccf | 2026-10-28 | Hyprland config in Lua (`default/hypr/*.lua`), Quickshell/QML shell in `shell/` replaces Waybar, Walker, Mako and SwayOSD |
| Latest stable | tag v4.0.6 | 237f1b4 | 2026-10-19 | same Lua layout, old animation set |
| Release candidates | v4.5.0-rc1, rc2 | (on quattro) | 2026-10-20, 2026-10-27 | rc2 predates 9333e19, so the new motion set is in no tag yet |
| Last Omarchy 3 | tag v3.8.4 (`version` file says 3.8.3) | 8fcc9d6 | 2026-07-20 | hyprlang `.conf`, Waybar, Walker, Mako, SwayOSD, colors.toml templates |
| Omarchy 2 | tag v2.1.2 | | 2025 | per-theme files for every app (`themes/<name>/hyprland.conf`, `mako.ini`, `walker.css` …) |
| First looknfeel | commit 3aada5f | | 2025-06-09 | the earliest `default/hypr/looknfeel.conf` |

Method: shallow clones of `quattro`, v4.0.6 and v3.8.4; raw files from `raw.githubusercontent.com` for older tags; GitHub REST API for commit messages and PR bodies (it rate-limited after about 60 calls, so a few commit bodies were not read); Hyprland's own example config (`hyprwm/Hyprland` `example/hyprland.lua`, main), `hyprwm/hyprutils` (default curve), the Hyprland wiki source (`hyprwm/hyprland-wiki` `content/configuring/core/animations.md`) and the variables page on wiki.hypr.land; the Omarchy package repo `omacom/omarchy-pkgs` (Neovim config, screensaver), `omacom/omarchy-screensaver`, `omacom/ttfx`, `omacom/omawrite`; DHH's blog posts; HN via the Algolia API. Reddit was not read directly.

## 2. Hyprland animations

### 2.1 Semantics

- `speed` is in deciseconds: `speed = 1` is 100 ms (wiki, animations.md). A Hyprland bezier is a CSS-style cubic: x is time, y progress, P0 = (0,0), P3 = (1,1).
- The animations form a tree; an unset leaf inherits its parent's values. `windows` → `windowsIn` (open), `windowsOut` (close), `windowsMove`. `layers` → `layersIn`/`layersOut` (bar, launcher, notifications). `fade` → `fadeIn`, `fadeOut`, `fadeSwitch` (active window change), `fadeShadow`, `fadeDim` (dim of inactive windows), `fadeLayers…`, `fadePopups…`. Then `border` (colour change), `borderangle` (gradient angle, styles `once` or `loop`), `workspaces` → `specialWorkspace…`, and `zoomFactor`.
- `popin N%` starts a window at N % of its size and grows it to 100 %, while `fadeIn` fades it in alongside. `slide top|bottom|left|right` forces a side.
- The built-in `default` curve is `(0, 0.75), (0.15, 1)` (hyprutils `src/animation/AnimationManager.cpp:13`). If a leaf is never set, `global` is 8 ds on `default`, and `borderangle` is off (Hyprland `src/animation/AnimationManager.cpp:62–66`).
- The wiki warns: "Using the `loop` style for `*angle` animations requires Hyprland to _constantly_ render new frames at a frequency equal to your screen's refresh rate … which might stress your CPU/GPU and will impact battery life. This will apply even if animations are disabled or the affected decorations are not visible." Omarchy never sets `borderangle`, so the gradient never turns.

### 2.2 Curves (`default/hypr/looknfeel.lua` on quattro; the same five since 2025-06-09)

y = share of the distance covered at 10/30/50 % of the time (computed). t90 = share of the time to reach 90 %.

| Name | Control points | CSS | y at 10/30/50 % | t90 | Used for |
|---|---|---|---|---|---|
| `easeOutQuint` | 0.23, 1, 0.32, 1 | `cubic-bezier(0.23, 1, 0.32, 1)` | 0.40 / 0.84 / 0.97 | 0.36 | everything since 9333e19. The name is loose: easings.net's easeOutQuint is (0.22, 1, 0.36, 1). This is Emil Kowalski's "strong ease-out for UI" and the shell's `Style.easeOut` |
| `easeInOutCubic` | 0.65, 0.05, 0.36, 1 | `cubic-bezier(0.65, 0.05, 0.36, 1)` | 0.02 / 0.13 / 0.51 | 0.71 | the scratchpad console's retract until 2026-10-28; still defined, unused |
| `linear` | 0, 0, 1, 1 | `linear` | | | windowsOut and layersOut until 2026-10-28 |
| `almostLinear` | 0.5, 0.5, 0.75, 1.0 | `cubic-bezier(0.5, 0.5, 0.75, 1)` | 0.10 / 0.33 / 0.57 | 0.79 | all fades until 2026-10-28 |
| `quick` | 0.15, 0, 0.1, 1 | `cubic-bezier(0.15, 0, 0.1, 1)` | 0.18 / 0.64 / 0.85 | 0.57 | `fade` until 2026-10-28 (a slow start, which is what the motion rules forbid) |
| `default` (built in) | 0, 0.75, 0.15, 1 | `cubic-bezier(0, 0.75, 0.15, 1)` | 0.66 / 0.88 / 0.95 | 0.35 | `global` until 2026-10-28 |

The strong ease-out leaves P0 at slope 1/0.23 ≈ 4.3 times linear speed. Of a 250 ms move, 90 % is done after 90 ms and 99 % after 160 ms, so the motion you notice lasts about 100 ms and the rest is settling. At 120 Hz the first three frames of a 250 ms move cover 14/28/40 %; of a 140 ms move, 25/46/63 %.

### 2.3 The classic set: what Omarchy looked like from v1 to v4.0.6

From `default/hypr/looknfeel.conf` (v1–v3) and `default/hypr/looknfeel.lua` (v4.0.x). The numbers are Hyprland's stock example values except where marked.

| Leaf | On | Speed (ds) | ms | Curve | Style | Note |
|---|---|---|---|---|---|---|
| global | 1 | 10 | 1000 | default | | stock |
| border | 1 | 5.39 | 539 | easeOutQuint | | stock; the colour change on every focus change |
| windows | 1 | 4.79, then **3.79** | 479, then **379** | easeOutQuint | | DHH "Speed up the window movements ever so slightly", c74c0cc, 2026-04-19 |
| windowsIn | 1 | 4.1 | 410 | easeOutQuint | popin 87% | stock |
| windowsOut | 1 | 1.49 | 149 | linear | popin 87% | stock |
| fadeIn | 1 | 1.73 | 173 | almostLinear | | stock |
| fadeOut | 1 | 1.46 | 146 | almostLinear | | stock |
| fade | 1 | 3.03 | 303 | quick | | stock |
| fadeSwitch | **0** | | | | | off since d570d99, 2026-07-13 ("Turn off fade switching between window groups") |
| layers | 1 | 3.81 | 381 | easeOutQuint | | stock |
| layersIn | 1 | 4 | 400 | easeOutQuint | fade | stock |
| layersOut | 1 | 1.5 | 150 | linear | fade | stock |
| fadeLayersIn | 1 | 1.79 | 179 | almostLinear | | stock |
| fadeLayersOut | 1 | 1.39 | 139 | almostLinear | | stock |
| workspaces | **0** | 0 | instant | ease | | **Omarchy's edit, since 2025-06-09.** Stock is `fade` at 194 ms (In 121, Out 194) |
| specialWorkspace | 1 | 4, then 3 | 400, then 300 | easeOutQuint | slidevert | added 2d859e2, 2026-03-07 (#4900); 3 ds from a719167, 2026-04-19 |

Stock Hyprland now also defines a spring, `easy` (mass 1, stiffness 238.1191, damping 24.2128, so ζ ≈ 0.78, a little bounce), for windows and windowsIn, and `zoomFactor` at 700 ms on `quick` (`example/hyprland.lua`). Omarchy never took the spring.

### 2.4 The current set: `quattro` 9333e19, 2026-10-28 (PR #16889, by DHH)

The file's comment: "Same rules as the shell's motion (agents/skills/motion.md) … one strong ease-out, entrances within 250ms, exits about two thirds of that, no linear or ease-in." The PR body says what it fixed: "Windows took 410ms to open from 87% scale, the border colour took 539ms on every focus change, Super-zoom took a full second, and several exits used linear or ease-in curves."

| Leaf | Speed (ds) | ms | Curve | Style |
|---|---|---|---|---|
| global (zoom, monitor added) | 2.5 | 250 | easeOutQuint | |
| border | 1.5 | **150** | easeOutQuint | |
| windows (and windowsMove) | 2.5 | 250 | easeOutQuint | |
| windowsIn | 2.5 | **250** | easeOutQuint | **popin 95%** |
| windowsOut | 1.6 | **160** | easeOutQuint | popin 95% |
| fadeIn / fadeOut | 1.8 / 1.2 | 180 / 120 | easeOutQuint | |
| fade | 2 | 200 | easeOutQuint | |
| fadeSwitch | off | | | |
| layers / layersIn | 2.5 / 2.5 | 250 / 250 | easeOutQuint | layersIn: fade |
| layersOut | 1.6 | 160 | easeOutQuint | fade |
| fadeLayersIn / fadeLayersOut | 1.8 / 1.2 | 180 / 120 | easeOutQuint | |
| workspaces | off | instant | | |
| specialWorkspaceIn (Quake console) | 3 | 300 | easeOutQuint | slide top |
| specialWorkspaceOut | 2 | 200 | easeOutQuint (was easeInOutCubic) | slide bottom |

The two console leaves are in `default/hypr/qconsole.lua:196–197`. "Reduced motion" is the `no-animations` toggle (`default/hypr/toggles/no-animations.lua`): animations, blur and shadows off. It is on by default in VMs (`install/user/hardware/vm-no-animations.sh`).

## 3. Decoration

| Setting | Hyprland stock example | Omarchy 2025-06 (3aada5f) | Omarchy v3.8 | Omarchy v4 / quattro | Toggles and themes |
|---|---|---|---|---|---|
| rounding | 10, power 2 | **0** | 0 | 0 | "Rounded" toggle: 6, `rounding_power = 3` ("Matches Solitude's corners"); popped windows 8 (`apps/system.lua:33`); Solitude theme 6/3 |
| border_size | 2 | 2 | 2 | 2 | no-gaps toggle: 0 |
| active border | `rgba(33ccffee) rgba(00ff99ee) 45deg` | same | theme accent (solid) since v3.3 | theme `hyprland_active_border`, else accent | Tokyo Night kept the gradient until v3.2 (see §4) |
| inactive border | `rgba(595959aa)` | same | same | same | Lumon `rgba(30486099)`, Solitude `rgb(1e1e1e)`, Last Horizon `rgba(584e51aa)` |
| gaps in / out | 5 / 20 | 5 / 10 | 5 / 10 | 5 / 10 | Lumon v3 8/16 |
| shadow | on, range 4, power 3, `0xee1a1a1a` | on, range **2**, power 3, `rgba(1a1a1aee)` | same | **off** (935283c, 2026-07-13) | Lumon: v3 range 16, power 4, `rgb(6fb8e3)` active, `rgba(30486077)` inactive; quattro range 6, power 4 |
| blur | on, size 3, passes 1, vibrancy 0.1696 | on, size 3, passes 1, vibrancy 0.1696 | size 2, passes 2, special, brightness 0.60, contrast 0.75 (a Walker layer blur rule added 2025-11-10 is gone by v3.8.4) | **off** (935283c) | "Glassy" (`default/hypr/glass.lua`): size 4, passes 2, new_optimizations, xray off, contrast 1.0, brightness 0.75, noise 0.01, vibrancy 0.35, vibrancy_darkness 0.35, popups, special; blur on the bar, menu, notifications and OSD layers with `ignore_alpha 0.3` |
| window opacity (active / inactive) | 1 / 1 | 0.98 / 0.95 global, replaced the same day by per-app rules: Alacritty 0.98/0.90, Chromium 0.98/0.95, Spotify and Obsidian 0.95/0.85 | `0.97 0.9` for every window (`windows.conf`); browsers 1.0/0.97; Kanagawa terminals 0.98/0.95 | terminals and a few apps (Omawrite, 1Password, Nautilus) `0.985 0.96` (`helpers.lua:328`); Kanagawa 0.99/0.985 | "Opaque" toggle 1/1; Glassy: terminal *background* alpha 0.65 in the terminal's own theme file, text stays at full strength (`bin/omarchy-theme-set-glass`) |
| dim_inactive | off | off | off; suggested in the user file: `dim_inactive = true`, `dim_strength = 0.15` | same suggestion | stock dim_strength is 0.5 |
| cursor | | | `hide_on_key_press = true` (from 70661d5, 2025-09-19, #1812, "Hide hyprland cursor while typing") | same | |
| groupbar | | | monospace 12, active text ultraheavy, `rgba(00000040)` / `rgba(00000020)` | same | |

Blur over time: size 3 passes 1 (2025-06), then passes 3 (cc2523f, 2025-10-18), then size 2, passes 2, brightness 0.60, contrast 0.75 with "Settings by @tobi" (29aae9a, 2025-11-10), then off (2026-07-13), then the Glassy toggle (#14726). The 2025-11 values (brightness 0.60, contrast 0.75) darken and flatten what shows through, so a 0.97/0.9 translucent window reads as dark smoked glass rather than frosted white.

**What makes the "glow/neon" look:**

1. The gradient border. Two saturated stops, `#33ccff` and `#00ff99`, both at alpha `ee` (0.93), at 45°, 2 px, on an otherwise flat dark screen with square corners. It is the most saturated colour on the screen, and it moves with focus. The 539 ms colour transition, now 150 ms, makes focus visibly travel.
2. Coloured shadows in a few themes: Lumon's cyan (range 16 in v3) and Hackerman's green gradient `rgba(26a269ee) → rgba(2ec27eee) 45deg`.
3. Slight translucency plus darkened blur (v1–v4.0): the wallpaper shows faintly through terminals.

Gaps keep every border separate, so each window reads as a lit outline. There is no bloom, no animated angle and no inner glow anywhere.

## 4. Themes

**Default theme: Tokyo Night.** `install/user/theme.sh:7,10` runs `omarchy-theme-set "Tokyo Night"`.

**List, quattro (23):** Catppuccin, Catppuccin Latte, Ethereal, Everforest, Flexoki Light, Gruvbox, Hackerman, Jade Horse, Kanagawa, Last Horizon, Lumon, Lupine, Matte Black, Miasma, Nord, Retro 82, Ristretto, Rosé Pine, Solitude, Starship, Tokyo Night, Vantablack, White. v4.0.6 and the website have Osaka Jade instead of Jade Horse ("Replace Osaka Jade with Jade Horse", a1ea609, 2026-10-25) and no Starship. Starship (quattro only) is built from Apple's dark system colours: `#1c1c1e`, `#2c2c2e`, `#3a3a3c`, `#8e8e93`, `#f5f5f7`, accent `#ff9f0a`.

**How a theme is applied:**
- **v1/v2:** a hand-written file per app.
- **v3.3+ and v4:** one `colors.toml` per theme, rendered through templates in `default/themed/*.tpl` (4a07b94, 2026-01-04, "Use theme config templates with singular color definition").
- **Hyprland:** active border = `hyprland_active_border` if the theme has one, else `accent`; inactive = `hyprland_inactive_border`, else `rgba(595959aa)` (`hyprland.lua.tpl`).
- **Terminals:** background, foreground, cursor = `bright_foreground`, palette 0–15 (`ghostty.conf.tpl`, `alacritty.toml.tpl`).
- **v3:** Walker selected text = accent, border = foreground; Mako border = accent; SwayOSD progress = accent, border = foreground.
- **v4 shell (`shell.toml.tpl`):**
  - Notifications, popups, polkit and lock border = the Hyprland active border (accent or gradient).
  - Menu, launcher and tooltip border = active-border-foreground (the foreground unless the theme has a gradient).
  - Launcher card at background α 0.95 over a **scrim of the theme background at α 0.5**; selected row: foreground at α 0.08, text in the accent.
  - Controls: fill α 0.04, border α 0.4 (1 px); hover fill 0.08; selected fill 0.18; pressed 0.22; selection 0.35.

Palettes as applied (quattro `themes/<name>/colors.toml`, identical in v4.0.6). "Active border" is what Hyprland draws in v3.3+; "v2 border" is the hand-written Hyprland border of v2.1.2.

| Theme | Background | Foreground | Bright fg (terminal cursor) | Accent = active border | Selection | Muted | v2 border |
|---|---|---|---|---|---|---|---|
| **Tokyo Night** (default) | `#1a1b26` | `#a9b1d6` | `#c0caf5` | `#7aa2f7` | `#292e42` (v3: `#7aa2f7`) | `#414868` | `rgba(33ccffee) rgba(00ff99ee) 45deg` (until v3.2) |
| Catppuccin (Mocha) | `#1e1e2e` | `#cdd6f4` | `#cdd6f4` | `#89b4fa` | `#45475a` | `#585b70` | `rgb(c6d0f5)` (v2 used Macchiato `#24273a`) |
| Gruvbox | `#282828` | `#d4be98` | `#d4be98` | `#7daea3` | `#504945` | `#665c54` | `rgb(a89984)` |
| Nord | `#2e3440` | `#d8dee9` | `#d8dee9` | `#81a1c1` | `#434c5e` | `#4c566a` | `rgb(D8DEE9)` |
| Kanagawa | `#1f1f28` | `#dcd7ba` | `#dcd7ba` | `#dcd7ba` (v3: `#7e9cd8`; border always `rgb(dcd7ba)`) | `#363646` | `#54546D` | `rgb(dcd7ba)` |
| Matte Black | `#121212` | `#bebebe` | `#bebebe` | `#e68e0d` | `#2a2a2a` | `#333333` | `rgb(8A8A8D)` |
| Everforest | `#2d353b` | `#d3c6aa` | `#d3c6aa` | `#7fbbb3` | `#3d484d` | `#475258` | `rgb(d3c6aa)` |
| Rosé Pine (light, Dawn) | `#faf4ed` | `#575279` | `#575279` | `#56949f` | `#dfdad9` | `#cecacd` | `rgb(575279)` |
| Osaka Jade (v4.0.6, gone on quattro) | `#111c18` | `#C1C497` | `#F7E8B2` | `#509475` | `#32473B` | `#53685B` | `rgb(71CEAD)` |
| Ristretto | `#2c2525` | `#e6d9db` | `#e6d9db` | `#f38d70` | `#403e41` | `#72696a` | `rgb(e6d9db)` |
| Lumon | `#16242d` | `#d6e2ee` | `#f2fcff` | border `rgb(f2fcff)`, accent `#8bc9eb`, shadow `#6fb8e3` | `#243d56` | `#304860` | |
| Hackerman | `#0B0C16` | `#ddf7ff` | `#ddf7ff` | `rgba(26a269ee) rgba(2ec27eee) 45deg` (accent `#82FB9C`) | `#1f253a` | `#2d3450` | |

**Tokyo Night as the classic Omarchy look (v2.1.2):**
- **Hyprland:** the cyan→green gradient.
- **Mako:** text `#a9b1d6`, **border `#33ccff`**, background `#1a1b26`, Liberation Sans 11, padding 10, border 2, outer margin 20.
- **Walker:** selected text `#7dcfff`, text `#cfc9c2`, base `#1a1b26`, **border `#33ccff`**.
- **SwayOSD:** background `#1a1b26`, **border `#33ccff`**, label and progress `#a9b1d6`.
- **Waybar:** foreground `#cdd6f4` on `#1a1b26`.
- **Alacritty:** `#1a1b26` / `#a9b1d6`, selection `#7aa2f7`.
- **Hyprlock:** check colour `rgb(68,157,171)` = `#449dab`.

Every bordered box was then cyan `#33ccff` on `#1a1b26`, which the eye reads as a single "neon" accent. Since v3.3 the same boxes take `#7aa2f7`, the foreground or the accent.

The maintainer's other apps already use Tokyo Night `#1a1b26` / `#c0caf5` / `#7aa2f7` (see `siblings.md`). Lemna's box is `#0e1013` with text `#d8dce3` (`app/Sources/LemnaCore/Line.swift:22`), darker than any Omarchy dark theme except Vantablack (`#000000`) and Hackerman (`#0B0C16`).

## 5. Effects tied to text and keys (asked for most)

### 5.1 Cursor and typing in the terminal and the editor: deliberately still

| Where | Setting | Source |
|---|---|---|
| Ghostty | `cursor-style = "block"`, `cursor-style-blink = false`, `shell-integration-features = no-cursor,ssh-env` (so shells cannot switch it to a blinking bar), `resize-overlay = never` | `config/ghostty/config` (v3 and quattro) |
| Kitty | `cursor_shape block`, `cursor_blink_interval 0`, `shell_integration no-cursor`; `cursor_trail` not set (off by default) | `etc/xdg/kitty/kitty.conf` (quattro), `config/kitty/kitty.conf` (v3) |
| Foot (default terminal in v4) | `[cursor] style=block`, `blink=no`; cursor colours `background` on `bright_foreground` | `config/foot/foot.ini`, `default/themed/foot.ini.tpl`; the manual: "Foot … is the default terminal for Omarchy" |
| Alacritty (default terminal in v3) | no cursor section (Alacritty's default is a steady block, unverified for the pinned version) | `config/alacritty/alacritty.toml` |
| Font, all terminals | JetBrainsMono Nerd Font, **9 pt**, padding **14 × 14** | the same files |
| Neovim (LazyVim) | `snacks.nvim` `scroll = { enabled = false }`, commented "Disable scrolling animations"; no smear-cursor, no mini.animate; every highlight group made transparent, CursorLine included | `omacom/omarchy-pkgs` `pkgbuilds/omarchy-nvim/lua/plugins/snacks-animated-scrolling-off.lua`, `plugin/after/transparency.lua` |
| Hyprland pointer | `cursor:hide_on_key_press = true`: the mouse pointer disappears on the first key | `looknfeel.conf/lua` |

### 5.2 Omawrite: Omarchy's own writing app (`omacom/omawrite`, preinstalled from v4, Super+Shift+W)

- **Type and caret:** "A dead-simple Markdown writing app", Qt Quick. IBM Plex Mono at **20 px**, a column of **65 average characters** (`src/Main.qml:29–36`). The caret is a `Rectangle { width: 1; color: textColor }` with no animation of its own (`Main.qml:660`). Whether Qt blinks a custom cursor delegate is unverified.
- **Scrolling:** a mouse wheel notch moves 3 × 40 px over **200 ms**, down to 100 ms when 480 px are outstanding (Chromium's curve), on `cubic-bezier(0.42, 0, 0.58, 1)`. A notch that lands mid-scroll carries the current velocity into the new curve. Positions snap to whole device pixels "which reads as shimmer" otherwise (`Main.qml:438–612`).
- **Typing:** no motion of any kind. The window is translucent at 0.985/0.96 like terminals (`windows.lua:23`).

### 5.3 Lock screen (v4 shell, `shell/plugins/lock/LockView.qml`)

- **Dots:** `●` with `passwordMaskDelay: 0`. They shrink to fit once the password outgrows the field, "so every keystroke stays visible".
- **Border:** switches from idle to active to error. Nothing animates per key.
- **v3 (Hyprlock):** `animations { enabled = false }`, input field 650 × 100, outline 4 px, rounding 0, background blur 3 passes.

### 5.4 The screensaver: text effects, but only while idle

- **v3 (`bin/omarchy-screensaver`):** runs TerminalTextEffects in a terminal.

  ```
  tte -i ~/.config/omarchy/branding/screensaver.txt --frame-rate 120 --canvas-width 0 --canvas-height 0 --reuse-canvas --anchor-canvas c --anchor-text c --random-effect --no-eol --no-restore-cursor
  ```

  Black background, cursor invisible, font 18 in Ghostty and Kitty. Any key or loss of focus exits.
- **v4 (`omacom/omarchy-screensaver` 1.3.1, Rust):** a native Wayland layer surface per display, written by Tobi Lütke, on **ttfx**. ttfx (`omacom/ttfx`) is a "parity-exact Rust port" of TTE 0.15.0, with byte-identical frames and about 423× faster.
  - It picks a random effect by default (`--effect`, `--include-effects`, `--exclude-effects`, `--seed`).
  - It "appears and disappears at once, exiting on input".
  - Idle times: screensaver at 150 s, lock at 300 s (manual chapter 13).
- **The 37 effects:** beams, binarypath, blackhole, bouncyballs, bubbles, burn, colorshift, crumble, decrypt, errorcorrect, expand, fireworks, highlight, laseretch, matrix, middleout, orbittingvolley, overflow, pour, print, rain, randomsequence, rings, scattered, slice, slide, smoke, spotlights, spray, swarm, sweep, synthgrid, thunderstorm, unstable, vhstape, waves, wipe.
- **Rendering notes (`LEARNINGS.md`):**
  - It advances ttfx at a fixed 120 Hz virtual clock.
  - It presents only when three gates pass: content changed, the 120 Hz deadline passed, and the compositor released the last buffer.
  - It keeps a per-output last-presented cell snapshot, so a small change does not rewrite a 5K buffer.
  - It declares a full-surface opaque region "so the compositor can skip blending the desktop underneath".
  - Dismissal by signal goes through the normal loop so that the cursor is restored.

### 5.5 The About logo's sheen (`bin/omarchy-branding-about-animation`)

"A band of light leans across the logo, rests, and leans across again":
- **Angle:** 2 columns per row, which is 45° on screen with 2:1 cells.
- **Band:** half-width 2 cells, bold bright white (`ESC[1m ESC[97m`), so the band shows whatever colour the terminal makes bold.
- **Timing:** 25 ms per frame (40 fps). It rests 8 ticks between sweeps, and each frame is written whole, "so a tick … never shows it half drawn".

It is the closest thing in Omarchy to a "shine" effect on text.

### 5.6 Notifications, OSD, launcher, panels, bar, wallpaper (quattro shell unless marked)

| Element | Motion | Source |
|---|---|---|
| Notification arrives | drops the last 24 px (`Style.space(24)`) into place from under the bar and fades in, **250 ms**, strong ease-out; one shared scene clock for the whole deck, retargeted from a snapshot, so a move interrupted by another never jumps | `shell/plugins/notifications/Service.qml:436–460, 700–712`; PR #16469 |
| Notification leaves (click, expiry) | rises the way it came and fades, **200 ms**; slips behind the stack; its text fades in half the time so two cards' words never show at once | `Service.qml:770–792` |
| Notification dismissed by key | **instant** ("Never animate keyboard actions") | `motion.md`, PR #16469 |
| Notification timeouts | low 5 s, normal 8 s, max 30 s, critical sticky | `Service.qml:141–151` |
| Mako (v3) | no motion of its own; Hyprland `layersIn` fade 400 ms + `fadeLayersIn` 179 ms, `layersOut` 150 ms linear; top right, width 420, margin 20, padding 10,15, border 2, sans-serif 14 px, timeout 5000 ms | `default/mako/core.ini` (v3) |
| Volume/brightness OSD | "appears and disappears at once"; only the bar's fill moves, 140 ms OutCubic | `shell/plugins/osd/Osd.qml:184`, `motion.md` |
| SwayOSD (v3) | radius 0, opacity 0.97, 2 px border in the foreground, progress in the accent, JetBrainsMono 11 pt | `config/swayosd/style.css` (v3) |
| Launcher, menu, clipboard, emoji picker | **no open or close motion** (v4); Walker in v3: `layerrule = no_anim on, match:namespace walker` since 2025-08-03 or earlier | `motion.md`; `default/hypr/apps/walker.conf` (v3) |
| Walker look (v3) | `* { all: unset }`, monospace **18 px**, card `alpha(@base, 0.95)`, padding 20, **2 px solid border** (foreground), selected row `alpha(@text, 0.07)` with accent text, item padding 14 | `default/walker/themes/omarchy-default/style.css` |
| Panels | grow from **0.97** at the point nearest their bar icon, with a fade, **180 ms in / 120 ms out**, strong ease-out; a switch within a bar section morphs one card over **220 ms**; content arriving later grows the card's drawn height over 200 ms (snaps in the first 60 ms) | `shell/Ui/KeyboardPanel.qml:58,366,530`; PRs #16470, #16483 |
| Buttons | held down: scale **0.97 over 160 ms**, strong ease-out; keyboard activation does **not** press them; hover colour 120 ms; spinner 900 ms per turn | `shell/Ui/Button.qml:137–147,195`; PR #16484 |
| Status phrases in panels | 150 ms out, 200 ms in, ease-out (was a 260 ms ease-in) | PR #16470 |
| Bar colours (theme switch) | 250 ms OutCubic | `shell/plugins/bar/Bar.qml:94–96` |
| Waybar (v3) | tray drawer `transition-duration: 600` | `config/waybar/config.jsonc` (v3) |
| Wallpaper change (v4) | a slanted cut opening from the centre: a parallelogram mask, slant −0.18 (about 10° off vertical), **840 ms OutCubic** | `shell/plugins/background/Background.qml:319–330, 483–486` |
| Theme switch and login (v4) | the outgoing wallpaper crossfades over **420 ms** once the new video intro is moving; at login an opaque black cover fades bar and wallpaper in together over 420 ms | `docs/theming.md` |
| v3 wallpaper | swaybg, no transition (unverified, inferred from the scripts) | |

The full spread of durations in the v4 shell (counts of `Style.duration(n)`): mostly 120–250 ms (120 ×13, 140 ×9, 150 ×10, 160 ×9, 200 ×9); longer ones (320–1250 ms) only for loops, pulses, intros and the wallpaper.

## 6. The written rules, and what people say

### 6.1 Omarchy's motion rules (`agents/skills/motion.md`, 19936335 and 6ddadd4, 2026-10-24, by DHH)

Quoted in part:
- "Every animation needs a reason: it shows where something came from or went, it confirms an input, or it keeps a change from jumping. 'It looks nice' on something seen many times a day is not a reason."
- "Things opened many times a day by a single keystroke and gone in a moment don't animate: the menu, launcher, clipboard and emoji pickers have no open or close motion, and the volume/brightness OSD appears and disappears at once."
- "A keystroke that acts and is done jumps."
- "Inside something the user stays and watches, keys get the same motion as the pointer … There the motion shows where things went."
- "Never an ease-in curve on UI: it starts slowest at the moment the eye is on it. No overshoot or bounce." "Never `Easing.Linear` except for constant motion such as a spinner."
- "UI motion stays under 300ms. Entrances take 180–250ms." "Whatever leaves goes faster than it came, about two thirds of the time." "Text fading out under something fading in takes half the time of the fade in." "Press feedback is 160ms."
- "Never scale from 0. Start at 0.95–0.97 with opacity 0."
- A test enforces it: `test/shell.d/motion-test.sh` fails on any bare `duration:`.

The source is Emil Kowalski's skills (`github.com/emilkowalski/skills`, `skills/review-animations/STANDARDS.md`):
- A frequency table: "100+ times/day (keyboard shortcuts, command palette toggle) | No animation. Ever."
- "Never animate keyboard-initiated actions — they repeat hundreds of times daily". "Raycast has no open/close animation."
- Durations: button press 100–160 ms, tooltips 125–200, dropdowns 150–250, modals 200–500.
- Curves: `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`, `--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`.

### 6.2 DHH on the look (blog)

- "Omarchy: Bottling that inspiration before it spoils" (2025-06-02) on Hyprland: "a tiling window manager with something as rare in the Linux world as a keen focus on aesthetics!"; "It looks like it was written by visual artists rather than neckbeards"; "It looks amazing; it feels amazing (if you prefer using a keyboard instead of a mouse!)".
- "Omarchy Is Out" (2025-06-26): "My Platonic ideal of what a developer environment should look like"; "a paved path into the glorious world of Linux ricing".
- "Omarchy 2.0" (2025-08-26): the Linux desktop is "shockingly more polished, capable, and beautiful".
- None of these posts gives durations or curves. The reasons for the numbers are in commit and PR texts: "ever so slightly" faster windows (2026-04), "so little visual flair and … a source of GPU load" (2026-07), the motion rules (2026-10).

### 6.3 Others

- HN (comments, so anecdotes):
  - "Everything was snappy. It is like back to DOS or Windows 3.11 era" (item 46934308, 2026-02-08).
  - An old MacBook Pro "felt brand new almost as snappy as my MBP M4" (44937638, 2025-08-18).
  - A Hyprland user: "I really like these animations" (45462145).
  - Criticism is about security, process and politics, not the look (threads 49499854, 49447682, 45667615).
- omarchy.org quotes users: "snappy, intuitive and a joy to use" and "Omarchy runs circles around macOS itself on this machine". These are marketing quotes.
- My reading of the evidence: the "snappy" feel comes from three things. Nothing that is used all the time animates (workspaces, launcher, OSD, keyboard dismissals). The motions that do run start fast and are short. Windows are not shadowed or rounded, so they look cut, not floated.

### 6.4 Cost (GPU, CPU, battery)

- **PR #13550** (DHH, 2026-09-28), measured on a VM without a GPU (llvmpipe), CPU time per interaction, stock vs. animations off:

  | Interaction | Stock | Animations off |
  |---|---|---|
  | Open and close a terminal | 5000 ms | 481 ms |
  | Switch workspace and back | 1670 ms | 409 ms |
  | Audio panel | 3446 ms | 796 ms |
  | Volume OSD | 2324 ms | 584 ms |
  | Omarchy menu | 2028 ms | 1241 ms |

  "Idle CPU is zero in every configuration." On a real GPU the cost is far smaller. No numbers are given for it.
- **935283c** (2026-07-13): shadows and blur off by default, "a source of GPU load".
- The Hyprland wiki warns about `borderangle loop` (constant frames, battery). Omarchy never uses it.
- Screensaver: rendering only changed cells and declaring an opaque region exist to save compositor work (§5.4). ttfx ships an energy benchmark (RAPL joules per run).
- Battery reports on Reddit and HN are about power management (TLP, power-profiles-daemon), not the animations (unverified, from a search-result summary).

## 7. Mapping to macOS (Core Animation and AppKit)

Lemna's current architecture, which decides the latency path:
- The line band is a `CAMetalLayer`. Core Graphics draws every frame into a shared Metal buffer, driven by a `CADisplayLink` on the main thread, with `presentsWithTransaction` (`app/Sources/Lemna/Strip.swift`, `LineView.swift`).
- The box is an `NSPanel`: clear background, `hasShadow = true`, `alphaValue = 0.97`, content layer `#0e1013` with `cornerRadius 10` (`app/Sources/Lemna/Box.swift:47–57`).
- The dim is one borderless window per screen, black at 0.35, on and off at once (`Box.swift:107–116`).

Anything drawn *inside* the band costs main-thread CPU every frame and competes with key handling. A property animation on a *separate* CALayer (opacity, transform, colours, gradient points, shadow) is interpolated by Core Animation's render server, not the main thread. On macOS crash logs show it as a `com.apple.coreanimation.render-server` thread (third-party sources; Apple documents no process boundary on macOS). Once committed, it costs no main-thread time per frame and does not delay keyDown → present. Its cost is GPU composition each frame.

| Omarchy element | Values | Nearest macOS equivalent | Off the key-latency path? |
|---|---|---|---|
| strong ease-out `easeOutQuint` | 0.23, 1, 0.32, 1 | `CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)`; in Lemna's own tween, solve the cubic for x→y (a lookup table, as Hyprland does). For comparison, Lemna's glide is `1 − (1 − u)³` = exactly `cubic-bezier(1/3, 1, 2/3, 1)` (`Line.swift:39,54`). Apple's named curves (from Apple's docs, quoted from memory): easeOut (0, 0, 0.58, 1), easeInEaseOut (0.42, 0, 0.58, 1), default (0.25, 0.1, 0.25, 1). All are far softer than Omarchy's | n/a (the glide tween runs in Lemna's own loop) |
| `windowsIn` popin 95 % + fadeIn | 250 ms scale 0.95→1, 180 ms opacity 0→1 | a `CAAnimationGroup` on the box's content layer: `transform.scale` 0.95→1 and `opacity` 0→1, then a model update. Scale the layer, not the window frame (`setFrame(display:animate:)` runs on the main thread and resizes) | yes |
| `windowsOut` | 160 ms scale 1→0.95, 120 ms fade | the same reversed, `orderOut` in the completion | yes |
| launcher and menu (the closest analogue to summoning Lemna) | **no motion**; scrim = theme background α 0.5; card α 0.95 | show and hide at once (what Lemna does now); dim window colour = box background rather than black, α 0.5 | n/a |
| `border` colour switch | 150 ms | `CABasicAnimation(keyPath: "borderColor")` on the content layer (`borderWidth 2`), or `strokeColor` of a `CAShapeLayer` | yes |
| gradient border, 45° | `rgba(33ccffee) → rgba(00ff99ee)`, 2 px | `CAGradientLayer` (axial; startPoint/endPoint for 45°; colours at α 0.93) masked by a `CAShapeLayer` stroking the box outline, `lineWidth 2`. Which corner Hyprland's 0° starts from is unverified; check against a screenshot | yes, static |
| `borderangle` once / loop | (Omarchy: none) | animate `startPoint`/`endPoint` (animatable) for "once"; a `.conic` gradient rotated with `repeatCount = .infinity` for "loop". Same warning as Hyprland: a loop forces composition every frame | yes, but a loop costs GPU and battery |
| rounding 6, `rounding_power 3` (Omarchy's rounded option) | radius 6, power between circle (2) and squircle (4) | `CALayer.cornerRadius = 6`, `cornerCurve = .continuous` (Apple's continuous corner; that it matches power 3 is an approximation, unverified). Omarchy's default is 0; Lemna uses 10 | n/a |
| shadow (dark edge) | range 2, power 3, `rgba(1a1a1aee)` | the system window shadow (`hasShadow`), or a CALayer shadow: `shadowColor #1a1a1a`, `shadowOpacity 0.93`, `shadowRadius ≈ 2`, `shadowOffset .zero`, **with `shadowPath`** (without it CA renders the shadow offscreen every frame) | yes |
| glow (Lumon) | range 6–16, power 4, `#6fb8e3` | a CALayer shadow in the accent, offset 0, `shadowRadius` ≈ range/2…range (Hyprland's range is "size in layout px", power the falloff exponent; the conversion is an estimate), `shadowPath` set. The panel must be larger than the box by about the range on each side, with a transparent margin, or the glow is clipped at the window edge | yes |
| blur behind | v3: size 2, passes 2, brightness 0.60, contrast 0.75; Glassy: size 4, passes 2, brightness 0.75, vibrancy 0.35, noise 0.01 | `NSVisualEffectView` with `blendingMode = .behindWindow`, a dark material (`.hudWindow`, `.popover`, `.underWindowBackground`), `state = .active`: no public radius, brightness or contrast. Tint with a layer over it (box colour at α 0.6–0.8 ≈ brightness 0.6–0.75). Noise: a noise image at 1 % opacity. A radius exists only through the private `CGSSetWindowBackgroundBlurRadius` (Ghostty and Zed use it, reportedly iTerm2 and Alacritty too; stable through macOS 15 per par-term, unknown on 26; App Store risk). `CALayer.backgroundFilters` cannot blur other apps' windows (unverified for current macOS). Off under Reduce Transparency | WindowServer recomposes the blur whenever the box or what is under it changes. The glide changes the box every frame for 140 ms per key, so blur is paid on every glide frame. Omarchy dropped blur for GPU load |
| window opacity 0.97 / 0.9 | | `NSWindow.alphaValue` fades text too. Omarchy's own lesson (Glassy, `omarchy-theme-set-glass`): put alpha on the background only, so text stays crisp. Lemna sets `panel.alphaValue = 0.97`, so its text is at 97 % as well | n/a |
| `dim_inactive` 0.15 / scrim 0.5 | `fadeDim` leaf | the per-screen dim windows Lemna has; animate their `alphaValue` only if at all (the launcher rule says no) | yes |
| `hide_on_key_press` | pointer hides on a key | `NSCursor.setHiddenUntilMouseMoves(true)` in `keyDown` | yes, a no-op on the draw path |
| `omarchy toggle animations` → `Style.duration(ms) = 0` | | read `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` and observe `accessibilityDisplayOptionsDidChangeNotification`; route every duration through one function (Lemna's Reduce Motion jump already does this for the glide) | n/a |
| notifications' "one scene clock, snapshot and retarget" | 250 / 200 ms | for per-key motion on CA layers: `CABasicAnimation` with `isAdditive = true` (from +advance to 0) per key. Overlapping additive animations add up and never jump, the same idea as Lemna's "leftover capped at one advance" | yes |
| About sheen | 45°, half-width 2 cells, 25 ms frames | a narrow `CAGradientLayer` band (white, α ~0.2–0.35, unverified taste), rotated 45°, used as an overlay or as a mask over a text layer, `position.x` animated once across. A layer over the Metal band works without redrawing the band | yes |
| ttfx / TTE effects | 120 Hz virtual clock, per-cell | simulate on a fixed clock off the main thread and present only on change (the screensaver's three gates). Inside Lemna's band this is CG drawing on the main thread; as a separate Metal or CA layer it is not | in the band: **no**; as its own layer: yes |

## 8. Where this meets Lemna's decisions (flagged, not resolved)

1. **F0 (picked 2026-10-28): "nothing beyond the glide and the fade; nothing else glows, moves or breathes while typing."** Omarchy's evidence supports F0, not the opposite:
   - Its written rules forbid motion on frequent single-keystroke actions.
   - It ships no per-keystroke effect anywhere: still block cursors, Neovim smooth scrolling off, Omawrite's static caret, lock-screen dots that appear at once.
   - Its text effects run only while idle and end at the first key.
   
   "Typing-dependent effects in Omarchy's spirit" therefore has no direct precedent in Omarchy. The nearest in its idiom are event-tied effects: the border colour at the start or stop of typing, a sheen on an event, an idle effect that the first key stops at once. The decision is the user's. Changing F0 would need new evidence or a changed preference recorded in DESIGN.md.
2. **The glide fits Omarchy's exception.** Lemna is "something the user stays and watches", and the glide shows where the text went. Omarchy's curve would make it snappier at the same 140 ms. With `cubic-bezier(0.23, 1, 0.32, 1)`, 90 % of the advance is done at **50 ms** (Lemna's cubic: 75 ms). At 120 Hz the first three frames cover 25/46/63 % instead of 17/32/45 %. This bears on G1/G2 ("kept until tried"): G2 asked for 60–80 ms if the line feels busy, and the strong curve gets the perceived motion into that range without shortening the tail. It is a one-line change in `Line.ease`, cheap to try.
3. **Summon and dim.** Omarchy's closest surface, the launcher, opens and closes with no motion, which Lemna already does. Its scrim is the *theme background* at α **0.5**, not black at 0.35. That is Lemna's H2 range ("a dim at α 0.5–0.6").
4. **Box alpha.** Lemna's `alphaValue 0.97` fades its text too. Omarchy moved translucency to the background alone for that reason.
5. **Corners and border.** Omarchy is square by default. Its rounded option is 6 px at power 3, with a 2 px border in the accent. Lemna is rounded at 10 px with no border and the system shadow. A 2 px accent border is the single most "Omarchy" element. It is static, so it falls outside F0's "moves while typing".

## 9. Candidate effects in the Omarchy idiom (input for a design panel; not decisions)

Each would be switchable, follow `Style.duration()`-like reduced-motion handling, and run on CA layers off the main thread unless marked. Ordered from best to worst fit with Omarchy's rules and F0.

| ID (draft) | Effect | Omarchy source | Fits Omarchy's rules? | Cost and path |
|---|---|---|---|---|
| e0 | Pointer hides on the first key | `hide_on_key_press` | yes, no visual | none |
| e1 | Static 2 px border: accent, or the classic `#33ccff → #00ff99` 45° gradient | Hyprland border, Tokyo Night v2 | yes (still) | CA, static |
| e2 | Border colour switch when typing starts and when it pauses (e.g. muted → accent, 150 ms strong ease-out; back after a pause) | `border` leaf (focus semantics) | yes if tied to start/stop, not to every key | CA, cheap |
| e3 | Sheen across the line on an event (Return, a hand-off, a session saved): one 45° band, once | About-logo sheen, ttfx `highlight` | yes: event-tied, confirms an input | CA overlay layer, or band drawing |
| e4 | Idle effect: after N s without a key, a slow `highlight`/`sweep` over the visible text; the first key ends it at once | screensaver | yes (screensaver rule: idle on, any key off) | the overlay layer, presented only on change |
| e5 | Glow on the box edge (Lumon shadow, range 6, power 4) whose strength follows the typing rate | Lumon theme | no: a per-key change of an ambient light; F0 rejected glow | CA shadow with `shadowPath`, a larger panel |
| e6 | Gradient angle nudged per key (borderangle "once", a few degrees, 150 ms) | `borderangle` | no: per-key onset at 3–8 Hz | CA |
| e7 | ttfx-style dissolve of text leaving at the left edge (decrypt, crumble, smoke) instead of the plain fade | ttfx effects | no: travelling motion in the periphery (F0 evidence: Bartram 2003) | in the band, main thread |

## 10. Unverified or open

- Hyprland's gradient angle: which corner 0° and 45° start from.
- Alacritty's default cursor style at the version Omarchy pinned.
- Whether Qt blinks Omawrite's custom cursor delegate.
- How Hyprland's shadow `range`/`render_power` and blur `size`/`passes` convert to CALayer `shadowRadius` and an NSVisualEffectView look. The conversions in §7 are estimates.
- On macOS, whether the Core Animation render server is a thread in the app process or WindowServer. Either way it runs off the main thread.
- `CGSSetWindowBackgroundBlurRadius` on macOS 26.
- Whether v3 had any wallpaper transition.
- The contents of three commit bodies (rate limit): the scratchpad animation #4900 and the cursor hide #1812, whose titles and dates are listed.
- DHH's own reasons for the classic durations: none found in his posts. The 2026 PRs are the only written rationale.

## Sources

**Omarchy repo** (`github.com/omacom/omarchy`, formerly basecamp/omarchy)
- quattro @ 79dcccf (2026-10-28): `default/hypr/looknfeel.lua`, `qconsole.lua`, `glass.lua`, `windows.lua`, `helpers.lua`, `toggles/*.lua`, `config/hypr/looknfeel.lua`, `agents/skills/motion.md`, `shell/Commons/Style.qml`, `shell/plugins/notifications/Service.qml`, `shell/Ui/{KeyboardPanel,Button,PopupCard}.qml`, `shell/plugins/osd/Osd.qml`, `shell/plugins/background/Background.qml`, `shell/plugins/lock/LockView.qml`, `shell/plugins/bar/Bar.qml`, `default/themed/*.tpl`, `themes/*/colors.toml`, `themes/*/hyprland.lua`, `config/{ghostty,foot,alacritty,kitty}`, `etc/xdg/kitty/kitty.conf`, `install/user/theme.sh`, `install/user/hardware/vm-no-animations.sh`, `bin/omarchy-theme-set-glass`, `bin/omarchy-branding-about-animation`, `docs/theming.md`, `manual/13-toggles-idle-screensaver.md`, `manual/15-terminal.md`
- v4.0.6 @ 237f1b4 (2026-10-19): `default/hypr/looknfeel.lua`, `themes/osaka-jade/colors.toml`
- v3.8.4 @ 8fcc9d6 (2026-07-20): `default/hypr/looknfeel.conf`, `windows.conf`, `apps/*.conf`, `config/hypr/hyprlock.conf`, `default/mako/core.ini`, `default/themed/*.tpl`, `default/walker/themes/omarchy-default/style.css`, `config/walker/config.toml`, `config/waybar/{style.css,config.jsonc}`, `config/swayosd/style.css`, `bin/omarchy-screensaver`, `bin/omarchy-launch-screensaver`, `themes/*/hyprland.conf`
- v2.1.2: `themes/<name>/{hyprland.conf,mako.ini,walker.css,swayosd.css,waybar.css,alacritty.toml,hyprlock.conf}`
- commits: 3aada5f, 94e0d55 (2025-06-09); 70661d5 (2025-09-19); cc2523f (2025-10-18); 29aae9a (2025-11-10); 4a07b94 (2026-01-04); 2d859e2 (2026-03-07); c74c0cc, a719167 (2026-04-19); 935283c, d570d99 (2026-07-13); d18cb4f (2026-08-18); a1ea609 (2026-10-25); 9333e19 (2026-10-28)
- PRs: https://github.com/omacom/omarchy/pull/13550, /16469, /16470, /16483, /16484, /16486, /16490, /16492, /16889
- Releases and tags: https://api.github.com/repos/omacom/omarchy/releases

**Related repos**
- https://github.com/omacom/omarchy-pkgs: `pkgbuilds/omarchy-nvim/*`, `pkgbuilds/omarchy-screensaver/PKGBUILD`
- https://github.com/omacom/omarchy-screensaver: `README.md`, `LEARNINGS.md`, `src/options.rs`
- https://github.com/omacom/ttfx: `README.md`
- https://github.com/omacom/omawrite: `README.md`, `src/Main.qml`

**Hyprland**
- https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
- `src/animation/AnimationManager.cpp`, `src/desktop/view/animationControllers/WindowAnimationController.cpp`
- https://github.com/hyprwm/hyprutils/blob/main/src/animation/AnimationManager.cpp
- https://github.com/hyprwm/hyprland-wiki/blob/main/content/configuring/core/animations.md
- https://wiki.hypr.land/Configuring/Basics/Variables/

**Motion rules**
- https://github.com/emilkowalski/skills (`skills/review-animations/STANDARDS.md`)

**DHH**
- https://world.hey.com/dhh/omarchy-bottling-that-inspiration-before-it-spoils-cd75e26b
- https://world.hey.com/dhh/omarchy-is-out-4666dd31
- https://world.hey.com/dhh/omarchy-2-0-16fefc15
- https://omarchy.org/

**HN** (via https://hn.algolia.com/api)
- items 46934308, 44937638, 45462145; threads 45001434, 45667615, 49499854, 49447682

**macOS private blur API**
- https://docs.rs/crate/par-term/0.40.0/source/src/macos_blur.rs
- https://git.secluded.site/zed/commit/49144d94bf0f34c95d18d89c5e9bb18ac90bf08c
- https://git.uoc.run.place/Applied-Software/ghostty/commit/9a079bb5b9f1adf8b73547d989d1db43d55110d1

**Core Animation render server** (third-party)
- https://medium.com/@beefon/should-you-use-pop-b986b10d4079
- https://habr.com/en/companies/e-legion/articles/436440/

**Lemna** (repo-relative)
- `DESIGN.md` (S1, W2, F0, G1 H1)
- `app/Sources/LemnaCore/Line.swift`
- `app/Sources/Lemna/{Box,Strip,LineView}.swift`
- `research_notes/Lemna effects/siblings.md`
