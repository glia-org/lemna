# Third-party material in the app

The key clicks and their licences are in `lib/LemnaClicks/THIRD_PARTY.md`.

## Literata (`Fonts/Literata/`)

Still's line face (DESIGN.md TH1, TY1 of `docs/design-panel-lemna-themes.html`), the e-book typeface commissioned for
Google Play Books (2015).

- `Literata[opsz,wght].ttf`: the upright variable font, version 3.103, axes opsz 7–72 (default 12) and wght 200–900
  (default 400); 955,132 bytes, SHA-256 `b41138c9373112f32abb589cc22e8674b06ed4048b0c513be922bdd26f274440`; the
  repository's `fonts/variable/Literata[opsz,wght].ttf`.
- `OFL.txt`: the licence, the repository's `OFL.txt` (SHA-256
  `8742963604cd89dc81437811a850018fc03b2bfad686d7422c8235967c87614e`).

Both from https://github.com/googlefonts/literata at commit `0c2761b727a1b3a7cffd313c37f0f5163dfc7a63` ("Built fonts
3.103", 2023-05-19, the latest on its `main` on 2026-10-31), downloaded 2026-10-31; the font's Git blob is
`0a81b4984a4a4eb101e0ddc28babc85bb137efef`, as GitHub's API lists it. Unchanged: no subset, no instance, no rename.
The italic is not taken (the line has no italics).

### Licence: SIL Open Font License 1.1

`OFL.txt`, beside the font in the repository and in the app (`Contents/Resources/Fonts/Literata/OFL.txt`, which
`make-app.sh` copies with it): "Copyright 2017 The Literata Project Authors (https://github.com/googlefonts/literata).
This Font Software is licensed under the SIL Open Font License, Version 1.1." It names no Reserved Font Name. The
licence lets the font be bundled and redistributed with software, sold with it but not on its own, provided the
copyright notice and the licence travel with it (its condition 2); Lemna's own code stays Apache-2.0.

### How the app uses it

`make-app.sh` copies `app/Fonts` into `Contents/Resources/Fonts`; at launch the app registers every font file there
for its own process (`Theme.Typeface.register`, Core Text's `CTFontManagerRegisterFontsForURL` with the process
scope), before the first style is made; nothing is installed for other apps. Core Text sets the optical size to the
size (opsz 30 at Still's 30 pt) and the weight stays the default 400. Missing or unregistered, Still takes Charter 31,
installed with macOS.
